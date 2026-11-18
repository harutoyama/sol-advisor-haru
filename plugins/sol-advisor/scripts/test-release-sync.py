#!/usr/bin/env python3
"""Regression checks for four-field release synchronization."""

import json
import tomllib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

source_root = Path(__file__).resolve().parents[3]
script = source_root / "plugins/sol-advisor/scripts/sync-release.py"
tracked = [
    "config/release.toml",
    "README.md",
    "plugins/sol-advisor/plugin.json",
    "plugins/sol-advisor/.codex-plugin/plugin.json",
    "plugins/sol-advisor/skills/orchestration/SKILL.md",
    "plugins/sol-advisor/skills/orchestration/references/operations.md",
    "plugins/sol-advisor/skills/orchestration/references/role-contracts.md",
] + [
    f"plugins/sol-advisor/agents/sol-advisor-{slug}.toml"
    for slug in (
        "luna-explorer", "luna-worker", "luna-tester", "luna-implementer",
        "luna-researcher", "terra-implementer", "terra-researcher", "sol-reviewer"
    )
]


def run(root, *args, ok=True):
    completed = subprocess.run(
        [sys.executable, str(script), "--root", str(root), *args],
        capture_output=True, text=True
    )
    if (completed.returncode == 0) != ok:
        raise AssertionError(f"{args}: {completed.stdout}\n{completed.stderr}")
    return completed


with tempfile.TemporaryDirectory(prefix="sol-advisor-release-") as directory:
    root = Path(directory)
    for name in tracked:
        destination = root / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_root / name, destination)

    run(root, "--check")
    config = root / "config/release.toml"
    content = config.read_text(encoding="utf-8")
    with config.open("rb") as handle:
        original_release = tomllib.load(handle)
    changes = {
        f'version = "{original_release["version"]}"': 'version = "9.9.9"',
        **{
            f'{role} = "{current}"': f'{role} = "gpt-{suffix}-{role}"'
            for role, (current, suffix) in {
                "sol": (original_release["models"]["sol"], "9.2"),
                "terra": (original_release["models"]["terra"], "9.1"),
                "luna": (original_release["models"]["luna"], "9"),
            }.items()
        },
    }
    for old, new in changes.items():
        assert old in content, f"test setup mismatch: {old}"
        content = content.replace(old, new)
    config.write_text(content, encoding="utf-8")

    run(root, "--check", ok=False)
    run(root)
    run(root, "--check")
    snapshot = {name: (root / name).read_bytes() for name in tracked}
    run(root)
    assert all((root / name).read_bytes() == data for name, data in snapshot.items()), \
        "sync not idempotent"

    for slug in ("sol-reviewer", "terra-researcher", "luna-worker"):
        name = f"plugins/sol-advisor/agents/sol-advisor-{slug}.toml"
        model = {"sol-reviewer": "gpt-9.2-sol",
                 "terra-researcher": "gpt-9.1-terra",
                 "luna-worker": "gpt-9-luna"}[slug]
        assert f'model = "{model}"' in (root / name).read_text(encoding="utf-8")
    for name in ("plugins/sol-advisor/plugin.json",
                 "plugins/sol-advisor/.codex-plugin/plugin.json"):
        assert json.loads((root / name).read_text())["version"] == "9.9.9"

    tampered = root / "plugins/sol-advisor/agents/sol-advisor-luna-worker.toml"
    tampered.write_text(tampered.read_text().replace(
        'model = "gpt-9-luna"', 'model = "gpt-8-luna"'))
    run(root, "--check", ok=False)
    run(root)
    run(root, "--check")
    print("PASS: four-field synchronization, drift detection, idempotence and recovery")
