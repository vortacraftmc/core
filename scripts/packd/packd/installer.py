"""Applying a revision to a world's datapacks folder, and undoing it.

The write path is deliberately boring:

  1. materialise the new tree into a temporary directory beside the target,
  2. move the current directory aside into ``.packd-backups/``,
  3. move the new tree into place,
  4. if anything fails, put the old directory back.

So an interrupted update leaves the previous revision in place rather than a
half-written pack, which is the failure mode that makes people avoid automated
updates in the first place.

Backups are what make rollback work without a network: ``packd rollback``
restores from ``.packd-backups/`` when the revision is there, and only reaches
for GitHub when it is not.

Nothing here runs a shell command, and no path is ever derived from server
output - see SECURITY.md sections 3 and 4.
"""

from __future__ import annotations

import os
import shutil
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path

from .github import GitHub, GitHubError


class InstallError(Exception):
    """The revision could not be applied."""


@dataclass
class InstallResult:
    pack: str
    sha: str
    target: Path
    files: int
    bytes: int
    backup: Path | None
    restored_from_backup: bool = False


def _assert_safe_relative(rel: str) -> None:
    """Reject anything that would escape the target directory."""
    if not rel or rel.startswith("/"):
        raise InstallError(f"unsafe path in archive: {rel!r}")
    parts = rel.replace("\\", "/").split("/")
    if any(p in ("", ".", "..") for p in parts):
        raise InstallError(f"unsafe path in archive: {rel!r}")
    if rel.endswith(("/", "\\")):
        raise InstallError(f"unsafe path in archive: {rel!r}")


def _write_tree(tree: dict[str, bytes], target: Path) -> tuple[int, int]:
    """Write `tree` under `target`, creating parent directories."""
    count = 0
    total = 0
    for rel, data in sorted(tree.items()):
        _assert_safe_relative(rel)
        dest = target / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        count += 1
        total += len(data)
    return count, total


def _is_pack_dir(path: Path) -> bool:
    return path.is_dir() and (path / "pack.mcmeta").is_file()


def stage_tree(tree: dict[str, bytes], parent: Path, name: str) -> Path:
    """Materialise `tree` into a fresh temporary directory inside `parent`.

    Returns the directory, which the caller moves into place. Staging inside
    `parent` matters: a rename only works within one filesystem, and the
    world folder may live anywhere.
    """
    if not tree:
        raise InstallError("refusing to install an empty tree")
    parent.mkdir(parents=True, exist_ok=True)
    staged = Path(tempfile.mkdtemp(dir=str(parent), prefix=f".{name}-staging-"))
    try:
        _write_tree(tree, staged)
        if not (staged / "pack.mcmeta").is_file():
            raise InstallError(
                "the staged tree has no pack.mcmeta, so it is not a loadable "
                "datapack - refusing to install it"
            )
    except BaseException:
        shutil.rmtree(staged, ignore_errors=True)
        raise
    return staged


class Installer:
    """Applies and reverts pack revisions in a world."""

    def __init__(
        self,
        datapacks_dir: Path,
        *,
        backups_dir: Path | None = None,
        keep_backups: int = 5,
    ) -> None:
        self.datapacks_dir = Path(datapacks_dir)
        self.backups_dir = Path(backups_dir) if backups_dir else self.datapacks_dir / ".packd-backups"
        self.keep_backups = max(1, keep_backups)

    # ---------------------------------------------------------------- paths

    def target_for(self, install_as: str) -> Path:
        return self.datapacks_dir / install_as

    def backup_for(self, install_as: str, contained_sha: str) -> Path:
        """Where a copy of `contained_sha` is stored.

        Named after the revision the directory *holds*, not the one being
        installed - the two are different, and getting this backwards is what
        makes rollback unable to find its own backups.
        """
        return self.backups_dir / f"{install_as}-{contained_sha[:12]}"

    def existing_backup(self, install_as: str, sha: str) -> Path | None:
        """A stored copy of this exact revision, if we have one."""
        exact = self.backup_for(install_as, sha)
        if _is_pack_dir(exact):
            return exact
        # A short sha may match a longer stored name.
        if self.backups_dir.is_dir():
            prefix = f"{install_as}-{sha[:12]}"
            for candidate in sorted(self.backups_dir.iterdir()):
                if candidate.name.startswith(prefix) and _is_pack_dir(candidate):
                    return candidate
        return None

    # --------------------------------------------------------------- install

    def install(
        self,
        install_as: str,
        sha: str,
        tree: dict[str, bytes],
        *,
        previous_sha: str = "",
    ) -> InstallResult:
        """Replace the installed copy of `install_as` with `tree`.

        `previous_sha` is the revision currently installed, used to name the
        backup after what it contains. When it is unknown the backup is named
        with a timestamp instead, so it is still restorable by hand even though
        `rollback` cannot find it by sha.
        """
        _assert_safe_relative(install_as)
        target = self.target_for(install_as)
        if target.exists() and not target.is_dir():
            raise InstallError(
                f"{target} exists and is not a directory - refusing to remove it"
            )

        staged = stage_tree(tree, self.datapacks_dir, install_as)
        backup: Path | None = None
        try:
            if target.exists():
                backup = (
                    self.backup_for(install_as, previous_sha)
                    if previous_sha
                    else self.backups_dir / f"{install_as}-unknown-{int(time.time())}"
                )
                if backup.exists():
                    shutil.rmtree(backup)
                backup.parent.mkdir(parents=True, exist_ok=True)
                os.replace(str(target), str(backup))
            os.replace(str(staged), str(target))
        except BaseException:
            # Put the old revision back if it was moved aside.
            if backup is not None and backup.exists() and not target.exists():
                try:
                    os.replace(str(backup), str(target))
                except OSError:
                    pass
            shutil.rmtree(staged, ignore_errors=True)
            raise

        files = sum(1 for _ in target.rglob("*") if _.is_file())
        size = sum(p.stat().st_size for p in target.rglob("*") if p.is_file())
        self._prune_backups(install_as)
        return InstallResult(
            pack=install_as, sha=sha, target=target, files=files, bytes=size, backup=backup
        )

    def rollback(self, install_as: str, sha: str) -> InstallResult:
        """Restore `sha` from a local backup. Raises if it is not stored."""
        _assert_safe_relative(install_as)
        stored = self.existing_backup(install_as, sha)
        if stored is None:
            raise InstallError(
                f"no local backup of {install_as} at {sha[:12]}. Use "
                f"`packd use <sha>` to fetch it from GitHub instead."
            )
        tree = {
            str(p.relative_to(stored)): p.read_bytes()
            for p in sorted(stored.rglob("*"))
            if p.is_file()
        }
        result = self.install(install_as, sha, tree)
        result.restored_from_backup = True
        return result

    def fetch_and_install(
        self,
        github: GitHub,
        install_as: str,
        repo_path: str,
        sha: str,
        *,
        previous_sha: str = "",
    ) -> InstallResult:
        """Download `repo_path` at `sha` and install it."""
        try:
            tree = github.download_tree(sha, repo_path)
        except GitHubError as exc:
            raise InstallError(f"cannot fetch {repo_path} at {sha[:12]}: {exc}") from None
        return self.install(install_as, sha, tree, previous_sha=previous_sha)

    # --------------------------------------------------------------- backup

    def _prune_backups(self, install_as: str) -> None:
        if not self.backups_dir.is_dir():
            return
        prefix = f"{install_as}-"
        backups = sorted(
            (p for p in self.backups_dir.iterdir() if p.name.startswith(prefix)),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        for stale in backups[self.keep_backups:]:
            shutil.rmtree(stale, ignore_errors=True)

    def list_backups(self, install_as: str) -> list[str]:
        """Stored revisions for a pack, newest first, as short SHAs."""
        if not self.backups_dir.is_dir():
            return []
        prefix = f"{install_as}-"
        out = []
        for path in sorted(
            (p for p in self.backups_dir.iterdir() if p.name.startswith(prefix)),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        ):
            if _is_pack_dir(path):
                out.append(path.name[len(prefix):])
        return out

    # ------------------------------------------------------------- detection

    def detect_installed(self, install_as: str) -> bool:
        """Is there a loadable pack installed under this name?"""
        return _is_pack_dir(self.target_for(install_as))
