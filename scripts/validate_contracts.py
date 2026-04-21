#!/usr/bin/env python3
"""Validate preserved client contract manifest checks against repository files.

Usage:
  python3 scripts/validate_contracts.py [manifest_path]
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Iterable


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _validate_check(repo_root: Path, check: dict) -> list[str]:
    errors: list[str] = []
    name = check.get("name", "<unnamed>")
    check_type = check.get("type")
    files = check.get("files", [])

    if not isinstance(files, list) or not files:
        return [f"check '{name}' has no files"]

    for rel in files:
        fp = repo_root / rel
        if not fp.exists():
            errors.append(f"check '{name}': missing file {rel}")
            continue

        content = _read_text(fp)

        if check_type == "substring":
            pattern = check.get("pattern")
            if not isinstance(pattern, str):
                errors.append(f"check '{name}': substring check missing string pattern")
                continue
            if pattern not in content:
                errors.append(f"check '{name}' failed in {rel}: missing substring {pattern!r}")

        elif check_type == "all_substrings":
            patterns = check.get("patterns")
            if not isinstance(patterns, list) or not all(isinstance(p, str) for p in patterns):
                errors.append(f"check '{name}': all_substrings check missing string list 'patterns'")
                continue
            for p in patterns:
                if p not in content:
                    errors.append(f"check '{name}' failed in {rel}: missing substring {p!r}")

        elif check_type == "regex":
            pattern = check.get("pattern")
            if not isinstance(pattern, str):
                errors.append(f"check '{name}': regex check missing string pattern")
                continue
            if re.search(pattern, content) is None:
                errors.append(f"check '{name}' failed in {rel}: regex did not match {pattern!r}")

        else:
            errors.append(f"check '{name}': unsupported type {check_type!r}")

    return errors


def _validate_required_files(repo_root: Path, required_files: Iterable[str]) -> list[str]:
    errors: list[str] = []
    for rel in required_files:
        if not isinstance(rel, str):
            errors.append("required_files must contain only strings")
            continue
        if not (repo_root / rel).exists():
            errors.append(f"required file missing: {rel}")
    return errors


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    manifest_rel = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path("contracts/preserved-client-contracts.json")
    )
    manifest_path = manifest_rel if manifest_rel.is_absolute() else repo_root / manifest_rel

    if not manifest_path.exists():
        print(f"ERROR: manifest not found: {manifest_path}", file=sys.stderr)
        return 2

    try:
        manifest = json.loads(_read_text(manifest_path))
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid JSON in {manifest_path}: {exc}", file=sys.stderr)
        return 2

    errors: list[str] = []

    required_files = manifest.get("required_files", [])
    if required_files:
        errors.extend(_validate_required_files(repo_root, required_files))

    checks = manifest.get("checks", [])
    if not isinstance(checks, list) or not checks:
        errors.append("manifest must include non-empty 'checks' list")
    else:
        for check in checks:
            if not isinstance(check, dict):
                errors.append("each check entry must be an object")
                continue
            errors.extend(_validate_check(repo_root, check))

    contract_name = manifest.get("contract_name", manifest_path.name)
    if errors:
        print(f"CONTRACT VALIDATION FAILED: {contract_name}")
        for err in errors:
            print(f" - {err}")
        return 1

    print(f"CONTRACT VALIDATION PASSED: {contract_name}")
    print(f"checks: {len(checks)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
