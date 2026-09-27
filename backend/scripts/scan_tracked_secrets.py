#!/usr/bin/env python3
"""Fail CI when a likely secret is committed, without exposing its value.

The scanner intentionally reads only Git-tracked text files. Findings report a
file, line and category; they never include the matching source text or value.
It is a guardrail for accidental commits, not a substitute for managed secrets
or a full history-rewriting response to a confirmed exposure.
"""

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[2]
MAX_TEXT_BYTES = 5 * 1024 * 1024

PRIVATE_KEY_RE = re.compile(r"-----BEGIN (?:[A-Z0-9 ]+ )?PRIVATE KEY-----")
TOKEN_RE = re.compile(r"\b(?:gh[pousr]_|glpat-|AIza)[A-Za-z0-9_-]{16,}\b")
ASSIGNMENT_RE = re.compile(
    r"""(?x)
    \b
    [A-Z][A-Z0-9_]*(?:PASSWORD|SECRET|TOKEN|API_KEY|PRIVATE_KEY|ACCESS_KEY)[A-Z0-9_]*
    \s* [:=] \s* [\"']? (?P<value>[^\s\"'#]+)
    """
)

# Firebase client API keys identify a project but are intentionally public in
# Android/iOS/web client configuration. Server-side credentials remain scanned.
PUBLIC_CLIENT_TOKEN_FILES = {
    "frontend/school_portal/android/app/google-services.json",
    "frontend/school_portal/ios/Runner/GoogleService-Info.plist",
    "frontend/school_portal/macos/Runner/GoogleService-Info.plist",
    "frontend/school_portal/lib/firebase_options.dart",
}

# Committed documentation and configuration templates may name secrets, but
# placeholders/dynamic environment expansion are not secret material.
PLACEHOLDER_RE = re.compile(
    r"""(?ix) ^(?:
        \$\{?[A-Z][A-Z0-9_]*\}? |
        <[^>]+> |
        (?:your|example|replace|placeholder|dummy|test)[_-].* |
        change[-_].* |
        change[-_]?me.* |
        changeme |
        ci-test-secret-not-used-in-prod
    )$ """
)


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    category: str


def _tracked_paths(root: Path) -> Iterable[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    for raw_path in result.stdout.split(b"\0"):
        if raw_path:
            yield root / raw_path.decode("utf-8", errors="surrogateescape")


def scan_text(path: Path, content: str) -> list[Finding]:
    """Return redacted findings for one decoded text file."""
    findings: list[Finding] = []
    for line_number, line in enumerate(content.splitlines(), start=1):
        if PRIVATE_KEY_RE.search(line):
            findings.append(Finding(path, line_number, "private-key"))
        if TOKEN_RE.search(line) and path.as_posix() not in PUBLIC_CLIENT_TOKEN_FILES:
            findings.append(Finding(path, line_number, "token-pattern"))
        for match in ASSIGNMENT_RE.finditer(line):
            value = match.group("value")
            # Short literals are type/default values (for example, `str`,
            # `postgres`, expiry days). Dynamic expansion is safe to commit.
            if (
                len(value) >= 16
                and not value.startswith("$")
                and not PLACEHOLDER_RE.fullmatch(value)
            ):
                findings.append(Finding(path, line_number, "secret-assignment"))
    return findings


def scan_repository(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in _tracked_paths(root):
        try:
            content = path.read_bytes()
        except OSError:
            continue
        if len(content) > MAX_TEXT_BYTES or b"\0" in content:
            continue
        findings.extend(scan_text(path.relative_to(root), content.decode("utf-8", errors="replace")))
    return findings


def main() -> int:
    findings = scan_repository(REPO_ROOT)
    if not findings:
        print("Tracked-secret scan passed.")
        return 0

    print("Tracked-secret scan failed; rotate any exposed credential before removing it.")
    for finding in findings:
        print(f"{finding.path}:{finding.line}: {finding.category}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
