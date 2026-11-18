#!/bin/sh
# Refresh checkout, marketplace/plugin and pristine distributed agent profiles.
set -eu

fail() { printf '%s\n' "ERROR: $*" >&2; exit 1; }

[ "$#" -eq 0 ] || fail "usage: sh plugins/sol-advisor/scripts/update-local.sh"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
root=$(CDPATH= cd "$script_dir/../../.." && pwd) || exit 1
command -v git >/dev/null 2>&1 || fail "git is required"
command -v python3 >/dev/null 2>&1 || fail "Python 3.11+ is required"
command -v codex >/dev/null 2>&1 || fail "Codex CLI is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
[ "$(git -C "$root" rev-parse --show-toplevel)" = "$root" ] ||
  fail "run from a Git checkout of this repository"
[ "$(git -C "$root" branch --show-current)" = main ] ||
  fail "checkout must be on main"
[ -z "$(git -C "$root" status --porcelain)" ] ||
  fail "checkout has local changes; commit or stash them first"

# Full history is necessary to verify an installed profile against earlier releases.
if [ "$(git -C "$root" rev-parse --is-shallow-repository)" = true ]; then
  git -C "$root" fetch --unshallow origin
fi
git -C "$root" pull --ff-only origin main

python3 "$script_dir/sync-release.py" --check
sh "$script_dir/verify.sh"

codex plugin marketplace upgrade sol-advisor
if ! codex plugin add sol-advisor@sol-advisor; then
  fail "Codex plugin refresh failed; inspect Plugins Directory before proceeding"
fi

sh "$script_dir/install-agents.sh" --upgrade-known
sh "$script_dir/install-agents.sh" --check

expected=$(python3 "$script_dir/sync-release.py" --get version)
actual=$(codex plugin list --json | jq -r '
  [.installed[]? | select(.name == "sol-advisor" and .marketplaceName == "sol-advisor")
   | .version] | first // empty')
[ "$actual" = "$expected" ] ||
  fail "plugin version is '$actual', expected '$expected'; refresh in Plugins Directory"

printf '%s\n' "Updated marketplace, plugin and pristine local agent profiles to $expected."
printf '%s\n' "Restart the ChatGPT desktop app or start a new Codex session to reload the plugin."
