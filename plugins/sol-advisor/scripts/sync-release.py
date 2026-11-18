#!/usr/bin/env python3
"""Synchronize release values from config/release.toml without extra dependencies."""

from __future__ import annotations

import argparse
import json
import re
import tomllib
from pathlib import Path

ROLE_MODELS = {
    "luna-explorer": "luna",
    "luna-worker": "luna",
    "luna-tester": "luna",
    "luna-implementer": "luna",
    "luna-researcher": "luna",
    "terra-implementer": "terra",
    "terra-researcher": "terra",
    "sol-reviewer": "sol",
}
MANIFESTS = (
    "plugins/sol-advisor/plugin.json",
    "plugins/sol-advisor/.codex-plugin/plugin.json",
)
DOCS = (
    "README.md",
    "plugins/sol-advisor/skills/orchestration/SKILL.md",
    "plugins/sol-advisor/skills/orchestration/references/operations.md",
    "plugins/sol-advisor/skills/orchestration/references/role-contracts.md",
)


def fail(message: str) -> None:
    raise SystemExit(message)


def load_release(root: Path) -> dict:
    path = root / "config/release.toml"
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    if set(data) != {"version", "models"} or not isinstance(data["models"], dict):
        fail(f"{path}: expected version and [models] only")
    if not isinstance(data["version"], str) or not re.fullmatch(
        r"\d+\.\d+\.\d+", data["version"]
    ):
        fail(f"{path}: version must be a numeric semantic version")
    if set(data["models"]) != {"sol", "terra", "luna"}:
        fail(f"{path}: expected exactly models.sol, models.terra and models.luna")
    for role, value in data["models"].items():
        if not isinstance(value, str) or not re.fullmatch(
            rf"gpt-\d+(?:\.\d+)?-{role}", value
        ):
            fail(f"{path}: invalid model identifier for {role}: {value!r}")
    return data


def replace_one(text: str, expression: str, replacement: str, path: str) -> str:
    result, count = re.subn(expression, lambda _: replacement, text, count=1, flags=re.M)
    if count != 1:
        fail(f"{path}: expected exactly one managed field matching {expression!r}")
    return result


def labels(text: str, models: dict[str, str]) -> str:
    for role in ("sol", "terra", "luna"):
        number = models[role].split("-")[1]
        name = role.title()
        text = re.sub(
            rf"\bGPT-\d+(?:\.\d+)? {name}\b", f"GPT-{number} {name}", text
        )
        text = re.sub(
            rf"\b{name} \d+(?:\.\d+)?\b", f"{name} {number}", text
        )
    return text


def render_docs(path: str, text: str, release: dict) -> str:
    models = release["models"]
    version = release["version"]
    if path.endswith("role-contracts.md"):
        for role, value in models.items():
            text = re.sub(rf"\bgpt-\d+(?:\.\d+)?-{role}\b", value, text)
    elif path.endswith("operations.md"):
        # Only the active role table is managed. Preserve historical migration examples.
        lines = text.splitlines(keepends=True)
        for index, line in enumerate(lines):
            if line.startswith("| " + chr(96) + "sol_advisor_"):
                for role, value in models.items():
                    line = re.sub(rf"\bgpt-\d+(?:\.\d+)?-{role}\b", value, line)
                lines[index] = line
        text = "".join(lines)
    text = labels(text, models)
    text = re.sub(r"(sol-advisor-haru-)\d+\.\d+\.\d+",
                  lambda m: m.group(1) + version, text)
    text = re.sub(r"fresh \d+\.\d+\.\d+ checkout",
                  f"fresh {version} checkout", text)
    text = re.sub(r"The \d+\.\d+\.\d+ installer",
                  f"The {version} installer", text)
    text = re.sub(r"The verifier checks the \d+\.\d+\.\d+ manifests",
                  f"The verifier checks the {version} manifests", text)
    return text


def targets(root: Path, release: dict):
    for slug, role in ROLE_MODELS.items():
        name = f"plugins/sol-advisor/agents/sol-advisor-{slug}.toml"
        original = (root / name).read_text(encoding="utf-8")
        updated = replace_one(original, r'^model = "[^"\n]+"$',
                              f'model = "{release["models"][role]}"', name)
        yield name, original, updated

    for name in MANIFESTS:
        original = (root / name).read_text(encoding="utf-8")
        updated = replace_one(original, r'^(\s*)"version": "[^"\n]+"',
                              f'  "version": "{release["version"]}"', name)
        if name.endswith(".codex-plugin/plugin.json"):
            updated = labels(updated, release["models"])
        json.loads(updated)
        yield name, original, updated

    for name in DOCS:
        original = (root / name).read_text(encoding="utf-8")
        yield name, original, render_docs(name, original, release)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[3])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="fail on unsynchronized files")
    mode.add_argument("--get", choices=["version", "models.sol", "models.terra", "models.luna"])
    args = parser.parse_args()
    root = args.root.resolve()
    release = load_release(root)
    if args.get:
        print(release["version"] if args.get == "version"
              else release["models"][args.get.split(".")[1]])
        return

    changed = []
    for name, before, after in targets(root, release):
        if before == after:
            continue
        changed.append(name)
        if not args.check:
            (root / name).write_text(after, encoding="utf-8")
    if args.check and changed:
        fail("Release configuration drift:\n" + "\n".join(f"  {name}" for name in changed))
    if changed:
        print("Synchronized: " + ", ".join(changed))
    else:
        print("Release configuration in sync")


if __name__ == "__main__":
    main()
