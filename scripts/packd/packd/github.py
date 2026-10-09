"""GitHub API access: commits, tarballs and issues.

Standard library only (``urllib``), matching the rest of the tooling in this
repository. Every request is pinned to ``api.github.com`` and the download host
is checked against an allowlist, following the pattern already used by
``scripts/dp-depman/scripts/dp-resolve.py`` so a crafted redirect cannot send a
token to an arbitrary host.

Read-only throughout. Nothing here writes to GitHub.
"""

from __future__ import annotations

import gzip
import io
import json
import os
import tarfile
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Iterable

API_HOST = "api.github.com"
DOWNLOAD_HOSTS = frozenset({"github.com", "codeload.github.com", "objects.githubusercontent.com"})
USER_AGENT = "packd (vortacraftmc/core)"
TOKEN_ENV = "GITHUB_TOKEN"


class GitHubError(Exception):
    """An API or download failure."""


@dataclass(frozen=True)
class Commit:
    sha: str
    message: str
    date: str
    author: str
    url: str

    @property
    def short_sha(self) -> str:
        return self.sha[:7]

    @property
    def subject(self) -> str:
        return self.message.split("\n", 1)[0].strip()


@dataclass(frozen=True)
class Issue:
    number: int
    title: str
    state: str
    author: str
    created: str
    updated: str
    url: str
    labels: tuple[str, ...]
    body: str

    @property
    def short_body(self) -> str:
        """First non-empty line of the body, for a one-line preview."""
        for line in self.body.splitlines():
            line = line.strip()
            if line and not line.startswith(("<!--", ">")):
                return line
        return ""


def _validate_api_url(url: str) -> None:
    parts = urllib.parse.urlsplit(url)
    if parts.scheme != "https":
        raise GitHubError(f"refusing non-https API URL: {url}")
    if parts.hostname != API_HOST:
        raise GitHubError(
            f"refusing API host {parts.hostname!r}; only {API_HOST} is allowed"
        )


def _validate_download_url(url: str) -> None:
    parts = urllib.parse.urlsplit(url)
    if parts.scheme != "https":
        raise GitHubError(f"refusing non-https download URL: {url}")
    if parts.hostname not in DOWNLOAD_HOSTS:
        raise GitHubError(
            f"refusing download host {parts.hostname!r}; allowed: "
            f"{sorted(DOWNLOAD_HOSTS)}"
        )


class GitHub:
    """A tiny read-only GitHub client."""

    def __init__(
        self,
        owner: str,
        repo: str,
        token: str | None = None,
        *,
        timeout: float = 30.0,
    ) -> None:
        self.owner = owner
        self.repo = repo
        self.timeout = timeout
        # An explicit argument wins, otherwise the environment. Unauthenticated
        # works too, at 60 requests/hour - enough for `packd check`.
        self._token = token if token is not None else os.environ.get(TOKEN_ENV, "")

    # ------------------------------------------------------------- plumbing

    def _headers(self, extra: dict[str, str] | None = None) -> dict[str, str]:
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": USER_AGENT,
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"
        if extra:
            headers.update(extra)
        return headers

    def _get(self, path: str, params: dict[str, Any] | None = None) -> Any:
        query = f"?{urllib.parse.urlencode(params)}" if params else ""
        url = f"https://{API_HOST}/repos/{self.owner}/{self.repo}{path}{query}"
        _validate_api_url(url)
        request = urllib.request.Request(url, headers=self._headers())
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = ""
            try:
                detail = json.loads(exc.read().decode("utf-8")).get("message", "")
            except Exception:  # noqa: BLE001 - a non-JSON error body is normal
                pass
            hint = ""
            if exc.code == 403:
                hint = " (rate limited? set GITHUB_TOKEN)"
            elif exc.code == 404:
                hint = f" (no such path or ref: {path})"
            raise GitHubError(
                f"GitHub API {exc.code} for {path}: {detail or exc.reason}{hint}"
            ) from None
        except urllib.error.URLError as exc:
            raise GitHubError(f"cannot reach {API_HOST}: {exc.reason}") from None

    # --------------------------------------------------------------- commits

    def commits_for_path(
        self, path: str, ref: str = "main", limit: int = 20
    ) -> list[Commit]:
        """Commits that touched `path`, newest first."""
        data = self._get(
            "/commits",
            {"path": path, "sha": ref, "per_page": max(1, min(limit, 100))},
        )
        if not isinstance(data, list):
            raise GitHubError(f"unexpected response shape for /commits: {type(data)}")
        out: list[Commit] = []
        for entry in data:
            commit = entry.get("commit") or {}
            author = (commit.get("author") or {}).get("name", "?")
            out.append(
                Commit(
                    sha=str(entry.get("sha", "")),
                    message=str(commit.get("message", "")),
                    date=str((commit.get("author") or {}).get("date", "")),
                    author=author,
                    url=str(entry.get("html_url", "")),
                )
            )
        return out

    def latest_commit(self, path: str, ref: str = "main") -> Commit:
        commits = self.commits_for_path(path, ref=ref, limit=1)
        if not commits:
            raise GitHubError(f"no commits found for {path} on {ref}")
        return commits[0]

    def commit(self, sha: str) -> Commit:
        entry = self._get(f"/commits/{sha}")
        commit = entry.get("commit") or {}
        return Commit(
            sha=str(entry.get("sha", "")),
            message=str(commit.get("message", "")),
            date=str((commit.get("author") or {}).get("date", "")),
            author=str((commit.get("author") or {}).get("name", "?")),
            url=str(entry.get("html_url", "")),
        )

    def commits_between(self, path: str, old_sha: str, new_sha: str, limit: int = 50) -> list[Commit]:
        """Commits on `new_sha` not on `old_sha`, restricted to `path`.

        Uses the compare endpoint so the count is the real distance between the
        two revisions rather than a guess from a date.
        """
        if old_sha == new_sha:
            return []
        data = self._get(f"/compare/{old_sha}...{new_sha}")
        files = {f.get("filename") for f in (data.get("files") or [])}
        prefix = path.rstrip("/") + "/"
        touched = any(str(f).startswith(prefix) or str(f) == path for f in files)
        commits = [
            Commit(
                sha=str(e.get("sha", "")),
                message=str((e.get("commit") or {}).get("message", "")),
                date=str(((e.get("commit") or {}).get("author") or {}).get("date", "")),
                author=str(((e.get("commit") or {}).get("author") or {}).get("name", "?")),
                url=str(e.get("html_url", "")),
            )
            for e in (data.get("commits") or [])
        ]
        if not touched and commits:
            # The compare covers the whole repo; if none of the listed files are
            # under this pack, say so rather than reporting unrelated commits.
            return []
        return commits[:limit]

    # -------------------------------------------------------------- download

    def download_tree(self, sha: str, subdir: str) -> dict[str, bytes]:
        """Fetch the repository tarball at `sha` and return the files under
        `subdir`, keyed by their path relative to `subdir`.

        The tarball is the cheapest way to get one directory at an arbitrary
        commit without cloning. It is decompressed in memory and only regular
        files are kept.
        """
        url = f"https://api.github.com/repos/{self.owner}/{self.repo}/tarball/{sha}"
        _validate_api_url(url)
        request = urllib.request.Request(url, headers=self._headers())
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as resp:
                final = resp.geturl()
                _validate_download_url(final)
                blob = resp.read()
        except urllib.error.HTTPError as exc:
            raise GitHubError(f"download failed with HTTP {exc.code} for {sha}") from None
        except urllib.error.URLError as exc:
            raise GitHubError(f"cannot download tarball: {exc.reason}") from None

        try:
            raw = gzip.decompress(blob)
        except OSError as exc:
            raise GitHubError(f"downloaded archive is not gzip: {exc}") from None

        prefix = subdir.strip("/") + "/"
        out: dict[str, bytes] = {}
        with tarfile.open(fileobj=io.BytesIO(raw), mode="r:") as tar:
            for member in tar.getmembers():
                # The tarball's first path component is `owner-repo-sha`.
                parts = member.name.split("/", 1)
                if len(parts) < 2:
                    continue
                rel = parts[1]
                if not (rel == subdir.strip("/") or rel.startswith(prefix)):
                    continue
                inner = rel[len(prefix):] if rel.startswith(prefix) else ""
                if not inner:
                    continue
                if not member.isfile():
                    continue
                if ".." in inner.split("/") or inner.startswith("/"):
                    continue  # never let an archive dictate a path outside
                handle = tar.extractfile(member)
                if handle is None:
                    continue
                with handle:
                    out[inner] = handle.read()
        if not out:
            raise GitHubError(
                f"{subdir} was not found in the tarball at {sha[:12]} "
                f"(wrong repo_path, or the pack did not exist at that commit)"
            )
        return out

    # ---------------------------------------------------------------- issues

    def open_issues(self, limit: int = 20, labels: Iterable[str] = ()) -> list[Issue]:
        """Open issues, newest first. Pull requests are excluded.

        The issues endpoint returns PRs too; they carry a ``pull_request`` key,
        which is the documented way to tell them apart.
        """
        params: dict[str, Any] = {
            "state": "open",
            "sort": "created",
            "direction": "desc",
            "per_page": max(1, min(limit, 100)),
        }
        labels = [l for l in labels if l]
        if labels:
            params["labels"] = ",".join(labels)
        data = self._get("/issues", params)
        if not isinstance(data, list):
            raise GitHubError(f"unexpected response shape for /issues: {type(data)}")
        out: list[Issue] = []
        for entry in data:
            if "pull_request" in entry:
                continue
            out.append(
                Issue(
                    number=int(entry.get("number", 0)),
                    title=str(entry.get("title", "")),
                    state=str(entry.get("state", "")),
                    author=str((entry.get("user") or {}).get("login", "?")),
                    created=str(entry.get("created_at", "")),
                    updated=str(entry.get("updated_at", "")),
                    url=str(entry.get("html_url", "")),
                    labels=tuple(
                        str(l.get("name", "")) for l in (entry.get("labels") or [])
                    ),
                    body=str(entry.get("body") or ""),
                )
            )
        return out
