import json
from pathlib import Path

from scripts.audit_pub_dependencies import PubPackage, query_osv, read_hosted_packages


def test_read_hosted_packages_skips_sdk_and_path_dependencies(tmp_path):
    lockfile = tmp_path / "pubspec.lock"
    lockfile.write_text(
        """packages:
  hosted_package:
    dependency: direct main
    source: hosted
    version: \"1.2.3\"
  flutter:
    dependency: direct main
    source: sdk
    version: \"0.0.0\"
  local_package:
    dependency: direct main
    source: path
    version: \"1.0.0\"
"""
    )

    assert read_hosted_packages(lockfile) == [PubPackage(lockfile, "hosted_package", "1.2.3")]


def test_query_osv_returns_advisory_ids(monkeypatch):
    class Response:
        def read(self):
            return json.dumps({"results": [{"vulns": [{"id": "OSV-1"}]}]}).encode()

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

    monkeypatch.setattr("scripts.audit_pub_dependencies.urlopen", lambda *_args, **_kwargs: Response())

    assert query_osv([PubPackage(Path("pubspec.lock"), "package", "1.0.0")]) == [["OSV-1"]]
