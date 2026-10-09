"""Install, backup and rollback behaviour."""

from __future__ import annotations

import pytest

from packd.installer import InstallError, Installer, _assert_safe_relative


def tree(marker: str = "a", extra: dict[str, bytes] | None = None) -> dict[str, bytes]:
    files = {
        "pack.mcmeta": b'{"pack":{"min_format":[122,0],"max_format":[122,0]}}',
        "data/demo/function/load.mcfunction": f"# {marker}\n".encode(),
        "data/demo/function/_vc_origin.mcfunction": b"# watermark\n",
    }
    if extra:
        files.update(extra)
    return files


# ------------------------------------------------------------------ install


def test_install_creates_a_loadable_pack(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    result = installer.install("demo", "a" * 40, tree())
    assert (result.target / "pack.mcmeta").is_file()
    assert result.files == 3
    assert result.bytes > 0
    assert installer.detect_installed("demo")


def test_install_replaces_the_previous_revision_and_keeps_a_backup(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree("first"))
    result = installer.install("demo", "b" * 40, tree("second"))

    content = (result.target / "data/demo/function/load.mcfunction").read_text()
    assert "second" in content
    assert result.backup is not None and result.backup.is_dir()
    old = (result.backup / "data/demo/function/load.mcfunction").read_text()
    assert "first" in old


def test_other_packs_are_untouched(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("keepme", "c" * 40, tree("keeper"))
    installer.install("demo", "a" * 40, tree())
    assert (tmp_path / "datapacks/keepme/data/demo/function/load.mcfunction").is_file()


def test_refuses_to_install_over_a_file(tmp_path):
    datapacks = tmp_path / "datapacks"
    datapacks.mkdir(parents=True)
    (datapacks / "demo").write_text("not a directory")
    installer = Installer(datapacks)
    with pytest.raises(InstallError, match="not a directory"):
        installer.install("demo", "a" * 40, tree())


def test_refuses_a_tree_without_pack_mcmeta(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    with pytest.raises(InstallError, match="no pack.mcmeta"):
        installer.install("demo", "a" * 40, {"data/x.mcfunction": b"x"})


def test_refuses_an_empty_tree(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    with pytest.raises(InstallError, match="empty tree"):
        installer.install("demo", "a" * 40, {})


def test_no_staging_directory_is_left_behind(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree())
    leftovers = [p.name for p in (tmp_path / "datapacks").iterdir() if "staging" in p.name]
    assert leftovers == []


def test_failed_install_leaves_nothing_behind(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    with pytest.raises(InstallError):
        installer.install("demo", "a" * 40, {"data/x.mcfunction": b"x"})
    assert not (tmp_path / "datapacks/demo").exists()
    leftovers = [p.name for p in (tmp_path / "datapacks").iterdir() if "staging" in p.name]
    assert leftovers == []


# -------------------------------------------------------------- path safety


@pytest.mark.parametrize(
    "unsafe",
    ["", "/abs", "../escape", "a/../../b", "a//b", "a/./b", "trailing/"],
)
def test_unsafe_paths_are_rejected(unsafe):
    with pytest.raises(InstallError, match="unsafe path"):
        _assert_safe_relative(unsafe)


def test_unsafe_archive_path_cannot_escape_the_target(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    with pytest.raises(InstallError):
        installer.install("demo", "a" * 40, tree(extra={"../../evil.mcfunction": b"x"}))
    assert not (tmp_path / "evil.mcfunction").exists()


@pytest.mark.parametrize("unsafe", ["../../etc", "a/../../b", "..", "x/../y", "a/.", "/x"])
def test_unsafe_install_names_are_rejected(tmp_path, unsafe):
    installer = Installer(tmp_path / "datapacks")
    with pytest.raises(InstallError):
        installer.install(unsafe, "a" * 40, tree())


# ----------------------------------------------------------------- rollback


def test_rollback_restores_from_the_local_backup(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree("first"))
    # The backup is named after the revision it *contains*, so installing "b"
    # stores the outgoing "a" under a's name.
    installer.install("demo", "b" * 40, tree("second"), previous_sha="a" * 40)

    result = installer.rollback("demo", "a" * 40)
    assert result.restored_from_backup is True
    content = (result.target / "data/demo/function/load.mcfunction").read_text()
    assert "first" in content


def test_rollback_without_a_backup_says_so(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree())
    with pytest.raises(InstallError, match="no local backup"):
        installer.rollback("demo", "f" * 40)


def test_existing_backup_matches_a_short_sha(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    full = "a" * 40
    installer.install("demo", full, tree("first"))
    installer.install("demo", "b" * 40, tree("second"), previous_sha=full)
    assert installer.existing_backup("demo", full[:7]) is not None
    assert installer.existing_backup("demo", "f" * 7) is None


def test_backups_are_pruned_to_the_limit(tmp_path):
    installer = Installer(tmp_path / "datapacks", keep_backups=2)
    for i in range(5):
        installer.install("demo", f"{i}" * 40, tree(f"v{i}"))
    assert len(installer.list_backups("demo")) <= 2


def test_list_backups_returns_newest_first(tmp_path):
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree("first"))
    installer.install("demo", "b" * 40, tree("second"), previous_sha="a" * 40)
    installer.install("demo", "c" * 40, tree("third"), previous_sha="b" * 40)
    stored = installer.list_backups("demo")
    assert stored[0].startswith("b"), stored
    assert any(s.startswith("a") for s in stored), stored


def test_backup_without_a_known_previous_is_still_kept_and_labelled(tmp_path):
    """A direct install with no recorded previous revision must not lose the
    outgoing files - it just cannot be addressed by sha."""
    installer = Installer(tmp_path / "datapacks")
    installer.install("demo", "a" * 40, tree("first"))
    result = installer.install("demo", "b" * 40, tree("second"))
    assert result.backup is not None and result.backup.is_dir()
    assert "unknown-" in result.backup.name
    old = (result.backup / "data/demo/function/load.mcfunction").read_text()
    assert "first" in old
    assert installer.existing_backup("demo", "a" * 40) is None


# ---------------------------------------------------------------- detection


def test_detect_installed_is_false_for_a_missing_pack(tmp_path):
    assert Installer(tmp_path / "datapacks").detect_installed("nope") is False


def test_detect_installed_is_false_for_a_directory_without_pack_mcmeta(tmp_path):
    (tmp_path / "datapacks/demo").mkdir(parents=True)
    assert Installer(tmp_path / "datapacks").detect_installed("demo") is False
