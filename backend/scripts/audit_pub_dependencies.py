#!/usr/bin/env python3
"""Audit hosted Dart/Flutter lockfile packages against OSV.

This scanner does not need a Dart dependency plugin. It reads each committed
``pubspec.lock``, sends hosted package/name/version tuples to OSV's batch API,
and reports only public dependency coordinates and advisory IDs.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen


REPO_ROOT = Path(__file__).resolve().parents[2]
LOCKFILES = (
    Path("frontend/shared/pubspec.lock"),
    Path("frontend/school_portal/pubspec.lock"),
    Path("frontend/admin_portal/pubspec.lock"),
)
OSV_QUERY_BATCH_URL = "https://api.osv.dev/v1/querybatch"
PACKAGE_RE = re.compile(r"^  (?P<name>[A-Za-z0-9_-]+):$")
FIELD_RE = re.compile(r'^    (?P<key>source|version):\s*"?(?P<value>[^"\s]+)"?\s*$')


@dataclass(frozen=True)
class PubPackage:
    lockfile: Path
    name: str
    version: str


def read_hosted_packages(lockfile: Path) -> list[PubPackage]:
    """Parse the stable package/source/version portion of a pub lockfile."""
    packages: list[PubPackage] = []
    name: str | None = None
    fields: dict[str, str] = {}

    def finish() -> None:
        if name and fields.get("source") == "hosted" and fields.get("version"):
            packages.append(PubPackage(lockfile, name, fields["version"]))

    for line in lockfile.read_text(encoding="utf-8").splitlines():
        package_match = PACKAGE_RE.match(line)
        if package_match:
            finish()
            name = package_match.group("name")
            fields = {}
            continue
        field_match = FIELD_RE.match(line)
        if name and field_match:
            fields[field_match.group("key")] = field_match.group("value")
    finish()
    return packages


def query_osv(packages: list[PubPackage]) -> list[list[str]]:
    request_body = json.dumps(
        {
            "queries": [
                {"package": {"ecosystem": "Pub", "name": package.name}, "version": package.version}
                for package in packages
            ]
        }
    ).encode()
    request = Request(
        OSV_QUERY_BATCH_URL,
        data=request_body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=30) as response:  # nosec B310: fixed HTTPS OSV endpoint
            results = json.loads(response.read())
    except (OSError, URLError, json.JSONDecodeError) as error:
        raise RuntimeError(f"OSV advisory query failed ({type(error).__name__})") from error

    rows = results.get("results")
    if not isinstance(rows, list) or len(rows) != len(packages):
        raise RuntimeError("OSV advisory query returned an incomplete result set")
    return [sorted(vulnerability["id"] for vulnerability in row.get("vulns", [])) for row in rows]


def main() -> int:
    packages = [
        package
        for lockfile in LOCKFILES
        for package in read_hosted_packages(REPO_ROOT / lockfile)
    ]
    if not packages:
        print("No hosted Pub packages found in configured lockfiles.")
        return 1

    try:
        findings = query_osv(packages)
    except RuntimeError as error:
        print(str(error))
        return 1

    vulnerable = [
        (package, advisory_ids)
        for package, advisory_ids in zip(packages, findings, strict=True)
        if advisory_ids
    ]
    if not vulnerable:
        print(f"Pub dependency audit passed ({len(packages)} hosted package locks checked).")
        return 0

    print("Pub dependency audit failed.")
    for package, advisory_ids in vulnerable:
        print(f"{package.lockfile}:{package.name}@{package.version}: {', '.join(advisory_ids)}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
