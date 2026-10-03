#!/usr/bin/env python3
"""Dependency-light syntax checks for Sol Advisor's small config surface."""

from __future__ import annotations

import ast
import json
import re
import sys
from pathlib import Path


def fail(path: Path, message: str) -> None:
    raise SystemExit(f"{path}: {message}")


def check_json(path: Path) -> None:
    with path.open("r", encoding="utf-8") as handle:
        json.load(handle)


def fallback_toml(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    seen: set[str] = set()
    in_multiline = False
    multiline_key = ""
    for number, raw in enumerate(lines, 1):
        line = raw.strip()
        if in_multiline:
            if '"""' in line:
                before, after = line.split('"""', 1)
                if after.strip():
                    fail(path, f"line {number}: trailing data after multiline string")
                in_multiline = False
                multiline_key = ""
            continue
        if not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z0-9_-]+)\s*=\s*(.+)", line)
        if not match:
            fail(path, f"line {number}: unsupported or invalid TOML syntax")
        key, value = match.groups()
        if key in seen:
            fail(path, f"line {number}: duplicate key {key}")
        seen.add(key)
        value = value.strip()
        if value == '"""':
            in_multiline = True
            multiline_key = key
            continue
        if not (value.startswith('"') and value.endswith('"')):
            fail(path, f"line {number}: fallback parser expects a quoted string")
        try:
            parsed = ast.literal_eval(value)
        except (SyntaxError, ValueError) as exc:
            fail(path, f"line {number}: invalid string literal: {exc}")
        if not isinstance(parsed, str):
            fail(path, f"line {number}: expected string value")
    if in_multiline:
        fail(path, f"unterminated multiline string for {multiline_key}")


def check_toml(path: Path) -> None:
    parser = None
    try:
        import tomllib as parser  # type: ignore[import-not-found]
    except ModuleNotFoundError:
        try:
            import tomli as parser  # type: ignore[import-not-found]
        except ModuleNotFoundError:
            fallback_toml(path)
            return
    with path.open("rb") as handle:
        parser.load(handle)


def fallback_yaml(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "interface:":
        fail(path, "fallback parser expects top-level interface mapping")
    keys: set[str] = set()
    for number, raw in enumerate(lines[1:], 2):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r'  ([A-Za-z0-9_]+):\s*("(?:[^"\\]|\\.)*")', raw)
        if not match:
            fail(path, f"line {number}: unsupported or invalid YAML syntax")
        key, quoted = match.groups()
        if key in keys:
            fail(path, f"line {number}: duplicate key {key}")
        keys.add(key)
        try:
            value = json.loads(quoted)
        except json.JSONDecodeError as exc:
            fail(path, f"line {number}: invalid quoted scalar: {exc}")
        if not isinstance(value, str):
            fail(path, f"line {number}: expected string scalar")
    required = {"display_name", "short_description", "default_prompt"}
    if keys != required:
        fail(path, f"expected keys {sorted(required)}, got {sorted(keys)}")


def check_yaml(path: Path) -> None:
    try:
        import yaml  # type: ignore[import-not-found]
    except ModuleNotFoundError:
        fallback_yaml(path)
        return
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict) or not isinstance(data.get("interface"), dict):
        fail(path, "expected interface mapping")


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: check-config-syntax.py TYPE FILE [FILE ...]")
    kind = sys.argv[1]
    checkers = {"json": check_json, "toml": check_toml, "yaml": check_yaml}
    if kind not in checkers:
        raise SystemExit(f"unknown type: {kind}")
    for item in sys.argv[2:]:
        checkers[kind](Path(item))


if __name__ == "__main__":
    main()
