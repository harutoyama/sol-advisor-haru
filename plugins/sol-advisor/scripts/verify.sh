#!/bin/sh
# Repository verification for Sol Advisor Haru fork model-specific routing.

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
readme=$repo_root/README.md
installer=$script_dir/install-agents.sh
inspector=$script_dir/inspect-agent-runtime.sh
syntax=$script_dir/check-config-syntax.py

luna=$agents/sol-advisor-luna-implementer.toml
terra=$agents/sol-advisor-terra-implementer.toml
sol=$agents/sol-advisor-sol-reviewer.toml

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

for path in "$portable" "$compat" "$market" "$luna" "$terra" "$sol" \
  "$skill" "$ops" "$contracts" "$ui" "$readme" "$installer" "$inspector" "$syntax"; do
  [ -f "$path" ] || fail "missing required file: $path"
done

toml_count=$(find "$agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')
[ "$toml_count" -eq 3 ] || fail "expected exactly three agent TOMLs, found $toml_count"
for obsolete in \
  sol-advisor-delegate-implementer.toml \
  sol-advisor-escalation-implementer.toml \
  sol-advisor-audit-reviewer.toml
do
  [ ! -e "$agents/$obsolete" ] && [ ! -L "$agents/$obsolete" ] ||
    fail "obsolete capability role remains in shipped agents: $obsolete"
done
pass "required files and exact model-specific three-role set"

python3 "$syntax" json "$portable" "$compat" "$market"
python3 "$syntax" toml "$luna" "$terra" "$sol"
python3 "$syntax" yaml "$ui"
python3 -m py_compile "$syntax"
pass "JSON, TOML, YAML, and Python syntax"

[ "$(jq -r '.name' "$portable")" = "sol-advisor" ] || fail "portable manifest name"
[ "$(jq -r '.version' "$portable")" = "0.100.0" ] || fail "portable manifest version"
[ "$(jq -r '."$schema"' "$portable")" = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" ] ||
  fail "portable manifest schema"
[ "$(jq -r '.version' "$compat")" = "0.100.0" ] || fail "compat manifest version"
[ "$(jq -r '.plugins[0].source.path' "$market")" = "./plugins/sol-advisor" ] ||
  fail "marketplace path"
pass "0.100.0 manifests and marketplace path"

grep -Fq 'model = "gpt-6-luna"' "$luna" || fail "Luna model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna" || fail "Luna effort pin"
grep -Fq 'model = "gpt-5.6-terra"' "$terra" || fail "Terra model pin"
grep -Fq 'model_reasoning_effort = "high"' "$terra" || fail "Terra effort pin"
grep -Fq 'model = "gpt-6.1-sol"' "$sol" || fail "Sol reviewer model pin"
grep -Fq 'model_reasoning_effort = "high"' "$sol" || fail "Sol reviewer effort pin"
grep -Fq 'sandbox_mode = "read-only"' "$sol" || fail "Sol reviewer does not request read-only"

model_count=$(grep -R -hE '^[[:space:]]*model[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
effort_count=$(grep -R -hE '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
[ "$model_count" -eq 3 ] || fail "expected exactly three agent model assignments, found $model_count"
[ "$effort_count" -eq 3 ] || fail "expected exactly three agent effort assignments, found $effort_count"
pass "exact model and reasoning pins"

if grep -R -nF 'gpt-5.6-sol' "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
  fail "stale gpt-5.6-sol remains"
fi
if grep -R -nF 'gpt-5.6-luna' "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
  fail "stale gpt-5.6-luna remains"
fi
for obsolete_role in \
  sol_advisor_delegate_implementer \
  sol_advisor_escalation_implementer \
  sol_advisor_audit_reviewer
do
  if grep -R -nF "$obsolete_role" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
    fail "obsolete capability runtime role remains: $obsolete_role"
  fi
done
for stale in 'primary-resolved-model' 'primary-resolved-effort'; do
  if grep -R -nF "$stale" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
    fail "capability-based primary-reuse contract remains: $stale"
  fi
done
pass "stale runtime models and capability-role contracts absent"

for role in sol_advisor_luna_implementer sol_advisor_terra_implementer sol_advisor_sol_reviewer; do
  grep -Fq "$role" "$contracts" || fail "role contract omits $role"
  grep -Fq "$role" "$ops" || fail "operations omit $role"
done
for phrase in \
  'gpt-6.1-sol' \
  'Routine coding is not automatically a solo task' \
  'prefer Luna / Max' \
  'Auxiliary work must substitute' \
  'Verification evidence is required'; do
  grep -Fqi "$phrase" "$readme" "$skill" || fail "routing docs omit: $phrase"
done
grep -Fq 'agents.default_subagent_model' "$ops" || fail "operations omit subagent default precedence"
grep -Fq 'explicit spawn values take precedence' "$ops" || fail "operations omit explicit spawn precedence"
pass "routing and precedence contracts"

grep -Fq 'codex plugin marketplace add harutoyama/sol-advisor-haru --ref main' "$readme" ||
  fail "README marketplace install command is stale"
grep -Fq 'codex plugin marketplace upgrade sol-advisor' "$readme" ||
  fail "README marketplace upgrade command is stale"
grep -Fq 'Plugins Directory' "$readme" || fail "README omits Plugins Directory flow"
if grep -Eq 'codex plugin (add|remove|list)([[:space:]]|$)' "$readme"; then
  fail "README relies on undocumented direct plugin CLI commands"
fi
pass "README uses documented marketplace CLI plus Plugins Directory"

sh -n "$installer"
sh -n "$inspector"
sh -n "$0"
pass "shell syntax"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/sol-advisor-verify.XXXXXX") || fail "mktemp failed"
cleanup() { rm -rf "$tmp"; }
trap cleanup 0 HUP INT TERM

default_home=$tmp/default-home
mkdir -p "$default_home"
env -u CODEX_HOME HOME="$default_home" sh "$installer" >/dev/null
env -u CODEX_HOME HOME="$default_home" sh "$installer" --check >/dev/null
[ -f "$default_home/.codex/agents/sol-advisor-luna-implementer.toml" ] ||
  fail "default HOME install missing Luna"
pass "installer works with CODEX_HOME unset"

fresh=$tmp/fresh
sh "$installer" --target-dir "$fresh" >/dev/null
sh "$installer" --target-dir "$fresh" --check >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role luna >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role terra >/dev/null
sh "$installer" --target-dir "$fresh" --check --check-role sol >/dev/null
cmp -s "$luna" "$fresh/sol-advisor-luna-implementer.toml" || fail "fresh Luna mismatch"
cmp -s "$terra" "$fresh/sol-advisor-terra-implementer.toml" || fail "fresh Terra mismatch"
cmp -s "$sol" "$fresh/sol-advisor-sol-reviewer.toml" || fail "fresh Sol mismatch"
pass "installer fresh install, full check, and selective checks"

unknown=$tmp/unknown
if sh "$installer" --target-dir "$unknown" --check-role unknown >/dev/null 2>&1; then
  fail "unknown role unexpectedly succeeded"
fi
[ ! -e "$unknown" ] || fail "unknown role mutated destination"
pass "installer unknown role is non-mutating"

modified=$tmp/modified
mkdir "$modified"
cp "$luna" "$modified/sol-advisor-luna-implementer.toml"
printf '%s\n' '# local edit' >> "$modified/sol-advisor-luna-implementer.toml"
before=$(cksum "$modified/sol-advisor-luna-implementer.toml")
if sh "$installer" --target-dir "$modified" >/dev/null 2>&1; then
  fail "modified destination unexpectedly succeeded"
fi
after=$(cksum "$modified/sol-advisor-luna-implementer.toml")
[ "$before" = "$after" ] || fail "modified destination changed"
[ ! -e "$modified/sol-advisor-terra-implementer.toml" ] || fail "partial mutation after conflict"
[ ! -e "$modified/sol-advisor-sol-reviewer.toml" ] || fail "partial mutation after conflict"
pass "installer modified destination fails before mutation"

symlink_case=$tmp/symlink
mkdir "$symlink_case"
external=$tmp/external
printf '%s\n' keep > "$external"
ln -s "$external" "$symlink_case/sol-advisor-luna-implementer.toml"
external_before=$(cksum "$external")
if sh "$installer" --target-dir "$symlink_case" >/dev/null 2>&1; then
  fail "symlink destination unexpectedly succeeded"
fi
[ "$external_before" = "$(cksum "$external")" ] || fail "symlink target changed"
[ ! -e "$symlink_case/sol-advisor-terra-implementer.toml" ] || fail "partial mutation after symlink"
pass "installer symlink refusal is non-mutating"

write_v070_roles() {
  dir=$1
  mkdir -p "$dir"
  cat > "$dir/sol-advisor-delegate-implementer.toml" <<'EOF'
name = "sol_advisor_delegate_implementer"
description = "Bounded implementation lane for fully specified, low-risk work with clear interfaces."
model = "gpt-6-luna"
model_reasoning_effort = "high"

developer_instructions = """
You are Sol Advisor's bounded delegate implementer. Execute only the supplied complete
specification when the work is low-risk, fully specified, interface-stable, and narrow in
blast radius. Preserve every stated interface and constraint. Modify only the owned files.

You are not alone in the codebase. Preserve concurrent edits and do not revert unrelated
work. Surface ambiguity, scope conflicts, architectural decisions, verification failures,
or newly observed risk instead of guessing. If the work proves judgment-heavy,
context-heavy, architecture-sensitive, high-risk, or wider in blast radius than specified,
stop and return that evidence so the parent can escalate.

Run the requested verification and report exact evidence. Do not silently substitute a
different role, model, reasoning effort, or scope.
"""
EOF
  cat > "$dir/sol-advisor-escalation-implementer.toml" <<'EOF'
name = "sol_advisor_escalation_implementer"
description = "High-capability implementation lane for judgment-heavy or newly escalated work."

developer_instructions = """
You are Sol Advisor's escalation implementer. The parent must spawn this role with explicit
model and reasoning values equal to the primary session's resolved model and effort. This TOML
intentionally contains no model slug.

Execute the supplied complete specification within the settled architecture when the work is
judgment-heavy, context-heavy, architecture-sensitive, high-risk, or wide in blast radius.
Preserve every stated interface and constraint and modify only the owned files. Preserve
concurrent edits and do not revert unrelated work. Surface unresolved architecture or scope
conflicts instead of silently broadening the task. Run the requested verification and report
exact evidence. Do not silently substitute a different role, model, reasoning effort, or scope.
"""
EOF
  cat > "$dir/sol-advisor-audit-reviewer.toml" <<'EOF'
name = "sol_advisor_audit_reviewer"
description = "Fresh-context final reviewer using the primary capability lane with requested read-only isolation."
sandbox_mode = "read-only"

developer_instructions = """
You are Sol Advisor's fresh audit reviewer. The parent must spawn this role with explicit model
and reasoning values equal to the primary session's resolved model and effort. This TOML
intentionally contains no model slug.

Remain strictly read-only: do not create, modify, delete, format, or implement files, and do
not broaden the requested scope. Inspect the actual accumulated change set, stated interfaces
and constraints, and verification evidence in a fresh context. Return exactly one verdict:
ship, fix-first, or rethink. Base the verdict on concrete evidence. Use fix-first only for
bounded required corrections and rethink when architecture or scope must change. Never
implement your own findings.
"""
EOF
}

obsolete_exact=$tmp/obsolete-exact
write_v070_roles "$obsolete_exact"
before=$(find "$obsolete_exact" -maxdepth 1 -type f -exec cksum {} \; | sort)
obsolete_output=$tmp/obsolete-output
if sh "$installer" --target-dir "$obsolete_exact" >"$obsolete_output" 2>&1; then
  fail "exact obsolete 0.7.0 profiles unexpectedly succeeded"
fi
after=$(find "$obsolete_exact" -maxdepth 1 -type f -exec cksum {} \; | sort)
[ "$before" = "$after" ] || fail "obsolete 0.7.0 refusal mutated destination"
[ "$(find "$obsolete_exact" -maxdepth 1 -type f | wc -l | tr -d ' ')" -eq 3 ] ||
  fail "obsolete refusal added files"
[ "$(grep -c 'OBSOLETE 0.7.0 UNMODIFIED:' "$obsolete_output")" -eq 3 ] ||
  fail "installer did not classify all exact 0.7.0 profiles"
pass "exact 0.7.0 capability profiles are detected and left untouched"

obsolete_modified=$tmp/obsolete-modified
write_v070_roles "$obsolete_modified"
printf '%s\n' '# user edit' >> "$obsolete_modified/sol-advisor-delegate-implementer.toml"
before=$(find "$obsolete_modified" -maxdepth 1 -type f -exec cksum {} \; | sort)
if sh "$installer" --target-dir "$obsolete_modified" >"$tmp/obsolete-modified-output" 2>&1; then
  fail "modified obsolete 0.7.0 profile unexpectedly succeeded"
fi
after=$(find "$obsolete_modified" -maxdepth 1 -type f -exec cksum {} \; | sort)
[ "$before" = "$after" ] || fail "modified obsolete refusal mutated destination"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$tmp/obsolete-modified-output" ||
  fail "installer did not distinguish modified obsolete profile"
pass "modified obsolete profile is distinguished and preserved"

runtime_sessions=$tmp/runtime-sessions
runtime_day=$runtime_sessions/2026/10/05
mkdir -p "$runtime_day"
runtime_id=11111111-1111-7111-8111-111111111111
runtime_rollout=$runtime_day/rollout-2026-10-05T00-00-00-$runtime_id.jsonl
printf '%s\n' \
  '{"type":"response_item","payload":{"prompt":"DO_NOT_LEAK_PROMPT"}}' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"sol_advisor_luna_implementer\",\"agent_path\":\"/root/fixture\",\"model_provider\":\"openai\",\"cwd\":\"/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-6-luna","effort":"max","sandbox_policy":{"type":"danger-full-access"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' \
  > "$runtime_rollout"
runtime_output=$(sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_id")
printf '%s\n' "$runtime_output" | jq -e --arg id "$runtime_id" '
  .thread_id == $id
  and .agent_role == "sol_advisor_luna_implementer"
  and .model == "gpt-6-luna"
  and .effort == "max"
' >/dev/null || fail "runtime inspector returned wrong Luna/Max evidence"
if printf '%s\n' "$runtime_output" | grep -Fq DO_NOT_LEAK; then
  fail "runtime inspector leaked payload"
fi
pass "runtime inspector validates GPT-6 Luna / Max evidence without payload leakage"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  pass "git diff --check"
fi

printf '%s\n' "VERIFY PASSED: Sol Advisor Haru fork 0.100.0 model-specific routing checks completed"
