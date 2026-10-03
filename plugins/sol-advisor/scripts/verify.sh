#!/bin/sh
# Repository verification for Sol Advisor's capability-based routing.

set -eu

pass() { printf '%s\n' "PASS: $*"; }
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
plugin_dir=$(CDPATH= cd "$script_dir/.." && pwd) || exit 1
repo_root=$(CDPATH= cd "$plugin_dir/../.." && pwd) || exit 1

portable=$plugin_dir/plugin.json
compat=$plugin_dir/.codex-plugin/plugin.json
market=$repo_root/.agents/plugins/marketplace.json
agents=$plugin_dir/agents
skill=$plugin_dir/skills/orchestration/SKILL.md
ops=$plugin_dir/skills/orchestration/references/operations.md
contracts=$plugin_dir/skills/orchestration/references/role-contracts.md
ui=$plugin_dir/skills/orchestration/agents/openai.yaml
installer=$script_dir/install-agents.sh
inspector=$script_dir/inspect-agent-runtime.sh
syntax=$script_dir/check-config-syntax.py

delegate=$agents/sol-advisor-delegate-implementer.toml
escalation=$agents/sol-advisor-escalation-implementer.toml
audit=$agents/sol-advisor-audit-reviewer.toml

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

for path in "$portable" "$compat" "$market" "$delegate" "$escalation" "$audit"   "$skill" "$ops" "$contracts" "$ui" "$installer" "$inspector" "$syntax"; do
  [ -f "$path" ] || fail "missing required file: $path"
done

for retired in   "$agents/sol-advisor-luna-implementer.toml"   "$agents/sol-advisor-terra-implementer.toml"   "$agents/sol-advisor-sol-reviewer.toml"; do
  [ ! -e "$retired" ] || fail "retired runtime role remains: $retired"
done

toml_count=$(find "$agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')
[ "$toml_count" -eq 3 ] || fail "expected exactly three agent TOMLs, found $toml_count"
pass "required files and exact three-role set"

python3 "$syntax" json "$portable" "$compat" "$market"
python3 "$syntax" toml "$delegate" "$escalation" "$audit"
python3 "$syntax" yaml "$ui"
python3 -m py_compile "$syntax"
pass "JSON, TOML, YAML, and Python syntax"

[ "$(jq -r '.name' "$portable")" = "sol-advisor" ] || fail "portable manifest name"
[ "$(jq -r '.version' "$portable")" = "0.7.0" ] || fail "portable manifest version"
[ "$(jq -r '."$schema"' "$portable")" = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" ] ||
  fail "portable manifest schema"
[ "$(jq -r '.version' "$compat")" = "0.7.0" ] || fail "compat manifest version"
[ "$(jq -r '.plugins[0].source.path' "$market")" = "./plugins/sol-advisor" ] ||
  fail "marketplace path"
pass "portable canonical manifest and compatibility fallback"

model_assignments=$(grep -R -nE '^[[:space:]]*model[[:space:]]*=' "$agents" || true)
model_count=$(printf '%s\n' "$model_assignments" | awk 'NF { n++ } END { print n+0 }')
[ "$model_count" -eq 1 ] || fail "expected exactly one concrete model assignment, found $model_count"
printf '%s\n' "$model_assignments" | grep -Fq 'sol-advisor-delegate-implementer.toml:' ||
  fail "the sole concrete model assignment must live in delegate TOML"
if grep -Eq '^[[:space:]]*model[[:space:]]*=' "$escalation" "$audit"; then
  fail "escalation/audit must inherit parent model"
fi
if grep -Eq '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$escalation" "$audit"; then
  fail "escalation/audit must inherit parent reasoning effort"
fi
grep -Fq 'sandbox_mode = "read-only"' "$audit" || fail "audit does not request read-only"
pass "single-point delegate model pin and parent inheritance"

if grep -R -nEi 'GPT-5\.6|gpt-5\.6|5\.6-sol|5\.6-luna|5\.6-terra'   "$repo_root" --exclude-dir=.git >/dev/null 2>&1; then
  fail "retired generation-specific model identifiers remain"
fi

terra_hits=$(grep -R -nEi 'terra' "$repo_root" --exclude-dir=.git || true)
if [ -n "$terra_hits" ]; then
  bad_terra=$(printf '%s\n' "$terra_hits" | grep -vF 'scripts/install-agents.sh' || true)
  [ -z "$bad_terra" ] || {
    printf '%s\n' "$bad_terra" >&2
    fail "retired family name remains outside the detection-only migration fixture"
  }
fi
pass "retired generation/family routing removed; legacy literal is detection-only"

for phrase in   'SELECTIVE ROUTE'   'Solo is the default'   'Auxiliary work must substitute'   'newly observed'   'parent model and reasoning settings'   'Verification evidence is required'; do
  grep -Fqi "$phrase" "$skill" || fail "skill omits: $phrase"
done
for role in sol_advisor_delegate_implementer sol_advisor_escalation_implementer sol_advisor_audit_reviewer; do
  grep -Fq "$role" "$contracts" || fail "role contract omits $role"
  grep -Fq "$role" "$ops" || fail "operations omit $role"
done
pass "routing and role contracts"

sh -n "$installer"
sh -n "$inspector"
sh -n "$0"
pass "shell syntax"

tmp=$(mktemp -d "/tmp/sol-advisor-verify.XXXXXX") || fail "mktemp failed"
cleanup() { rm -rf "$tmp"; }
trap cleanup 0 HUP INT TERM

fresh=$tmp/fresh
sh "$installer" --target-dir "$fresh" >/dev/null
sh "$installer" --target-dir "$fresh" --check >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role delegate >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role escalation >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role audit >/dev/null
cmp -s "$delegate" "$fresh/sol-advisor-delegate-implementer.toml" || fail "fresh delegate mismatch"
cmp -s "$escalation" "$fresh/sol-advisor-escalation-implementer.toml" || fail "fresh escalation mismatch"
cmp -s "$audit" "$fresh/sol-advisor-audit-reviewer.toml" || fail "fresh audit mismatch"
pass "installer fresh install, full check, and selective checks"

unknown=$tmp/unknown
if sh "$installer" --target-dir "$unknown" --check-role unknown >/dev/null 2>&1; then
  fail "unknown role unexpectedly succeeded"
fi
[ ! -e "$unknown" ] || fail "unknown role mutated destination"
pass "installer unknown role is non-mutating"

modified=$tmp/modified
mkdir "$modified"
cp "$delegate" "$modified/sol-advisor-delegate-implementer.toml"
printf '%s\n' '# local edit' >> "$modified/sol-advisor-delegate-implementer.toml"
before=$(cksum "$modified/sol-advisor-delegate-implementer.toml")
if sh "$installer" --target-dir "$modified" >/dev/null 2>&1; then
  fail "modified destination unexpectedly succeeded"
fi
after=$(cksum "$modified/sol-advisor-delegate-implementer.toml")
[ "$before" = "$after" ] || fail "modified destination changed"
[ ! -e "$modified/sol-advisor-escalation-implementer.toml" ] || fail "partial mutation after conflict"
[ ! -e "$modified/sol-advisor-audit-reviewer.toml" ] || fail "partial mutation after conflict"
pass "installer modified destination fails before mutation"

symlink_case=$tmp/symlink
mkdir "$symlink_case"
external=$tmp/external
printf '%s\n' keep > "$external"
ln -s "$external" "$symlink_case/sol-advisor-delegate-implementer.toml"
external_before=$(cksum "$external")
if sh "$installer" --target-dir "$symlink_case" >/dev/null 2>&1; then
  fail "symlink destination unexpectedly succeeded"
fi
[ "$external_before" = "$(cksum "$external")" ] || fail "symlink target changed"
[ ! -e "$symlink_case/sol-advisor-escalation-implementer.toml" ] || fail "partial mutation after symlink"
pass "installer symlink refusal is non-mutating"

legacy=$tmp/legacy
mkdir "$legacy"
printf '%s\n' old > "$legacy/sol-advisor-luna-implementer.toml"
legacy_before=$(cksum "$legacy/sol-advisor-luna-implementer.toml")
if sh "$installer" --target-dir "$legacy" >/dev/null 2>&1; then
  fail "obsolete profile unexpectedly succeeded"
fi
[ "$legacy_before" = "$(cksum "$legacy/sol-advisor-luna-implementer.toml")" ] ||
  fail "obsolete profile changed"
[ ! -e "$legacy/sol-advisor-delegate-implementer.toml" ] || fail "obsolete profile caused partial install"
pass "installer obsolete-profile handling is fail-closed and non-mutating"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  pass "git diff --check"
fi

printf '%s\n' "PASS: all Sol Advisor verification checks completed"
