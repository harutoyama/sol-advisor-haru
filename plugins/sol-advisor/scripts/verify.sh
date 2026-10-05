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

for file in "$portable" "$compat" "$market" "$luna" "$terra" "$sol" \
  "$skill" "$ops" "$contracts" "$ui" "$readme" "$installer" "$inspector" "$syntax"; do
  [ -f "$file" ] || fail "missing required file: $file"
done

toml_count=$(find "$agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')
[ "$toml_count" -eq 3 ] || fail "expected exactly three agent TOMLs, found $toml_count"
pass "required files and exact three-role set"

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
grep -Fq 'sandbox_mode = "read-only"' "$sol" || fail "Sol reviewer read-only request"

model_count=$(grep -R -hE '^[[:space:]]*model[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
effort_count=$(grep -R -hE '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
[ "$model_count" -eq 3 ] || fail "expected exactly three agent model assignments, found $model_count"
[ "$effort_count" -eq 3 ] || fail "expected exactly three agent effort assignments, found $effort_count"
pass "exact model and reasoning pins"

stale_sol=gpt-5.6-"sol"
stale_luna=gpt-5.6-"luna"
if grep -R -nF "$stale_sol" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
  fail "stale prior Sol model remains"
fi
if grep -R -nF "$stale_luna" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
  fail "stale prior Luna model remains"
fi

old_delegate=sol_advisor_"delegate"_implementer
old_escalation=sol_advisor_"escalation"_implementer
old_audit=sol_advisor_"audit"_reviewer
for old_role in "$old_delegate" "$old_escalation" "$old_audit"; do
  if grep -R -nF "$old_role" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
    fail "obsolete capability runtime role remains: $old_role"
  fi
done

stale_primary_model=primary-resolved-"model"
stale_primary_effort=primary-resolved-"effort"
for stale in "$stale_primary_model" "$stale_primary_effort"; do
  if grep -R -nF "$stale" "$readme" "$repo_root/.agents" "$repo_root/plugins" 2>/dev/null; then
    fail "capability-based primary-reuse contract remains: $stale"
  fi
done
pass "stale runtime models and capability-role contracts absent"

for role in sol_advisor_luna_implementer sol_advisor_terra_implementer sol_advisor_sol_reviewer; do
  grep -Fq "$role" "$contracts" || fail "role contract omits $role"
  grep -Fq "$role" "$ops" || fail "operations omit $role"
done
grep -Fqi 'Routine coding is not automatically a solo task' "$readme" ||
  fail "README does not prefer Luna for routine coding"
grep -Fqi 'prefer this when the primary has resolved the requirements' "$skill" ||
  fail "skill does not prefer Luna for specified routine implementation"
grep -Fqi 'Auxiliary work must substitute' "$skill" ||
  fail "skill permits duplicate auxiliary implementation"
grep -Fqi 'Verification evidence is required' "$skill" ||
  fail "skill omits verification evidence gate"
grep -Fq 'agents.default_subagent_model' "$ops" ||
  fail "operations omit default-subagent precedence"
grep -Fq 'explicit spawn values take precedence' "$ops" ||
  fail "operations omit explicit-spawn precedence"
pass "routing and precedence contracts"

for digest in \
  1594d2ac0fa527301b92afaf635a14a4e89b640d20f8673b6406d87298bc31c5 \
  85a257f74155ea717c4591acb3c24667d1498d5fbc3244029fda6290f7f080af \
  b11c1c8a9773cfbcb62fa855f7723bbf5fc9df4cf91a5c9dc2be2a01b898f597
do
  grep -Fq "$digest" "$installer" || fail "installer omits known 0.7.0 migration digest"
done
grep -Fq 'OBSOLETE 0.7.0 UNMODIFIED:' "$installer" ||
  fail "installer does not distinguish exact 0.7.0 profiles"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$installer" ||
  fail "installer does not distinguish modified obsolete profiles"
pass "0.7.0 migration detection contract"

grep -Fq 'codex plugin marketplace add harutoyama/sol-advisor-haru --ref main' "$readme" ||
  fail "README marketplace install command is stale"
grep -Fq 'codex plugin marketplace upgrade sol-advisor' "$readme" ||
  fail "README marketplace upgrade command is stale"
grep -Fq 'Plugins Directory' "$readme" || fail "README omits Plugins Directory flow"
if grep -Eq 'codex plugin (add|remove|list)([[:space:]]|$)' "$readme"; then
  fail "README relies on undocumented direct plugin CLI commands"
fi
pass "README uses marketplace CLI plus Plugins Directory"

sh -n "$installer"
sh -n "$inspector"
sh -n "$0"
pass "shell syntax"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/sol-advisor-verify.XXXXXX") || fail "mktemp failed"

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
pass "installer fresh install and selective checks"

unknown=$tmp/unknown
if sh "$installer" --target-dir "$unknown" --check-role unknown >/dev/null 2>&1; then
  fail "unknown role unexpectedly succeeded"
fi
[ ! -e "$unknown" ] || fail "unknown role mutated destination"
pass "unknown role is non-mutating"

modified=$tmp/modified
mkdir "$modified"
cp "$luna" "$modified/sol-advisor-luna-implementer.toml"
printf '%s\n' '# local edit' >> "$modified/sol-advisor-luna-implementer.toml"
before=$(cksum "$modified/sol-advisor-luna-implementer.toml")
if sh "$installer" --target-dir "$modified" >/dev/null 2>&1; then
  fail "modified destination unexpectedly succeeded"
fi
[ "$before" = "$(cksum "$modified/sol-advisor-luna-implementer.toml")" ] ||
  fail "modified destination changed"
[ ! -e "$modified/sol-advisor-terra-implementer.toml" ] || fail "partial mutation after conflict"
pass "modified current profile fails before mutation"

obsolete=$tmp/obsolete
mkdir "$obsolete"
printf '%s\n' 'user-owned obsolete file' > "$obsolete/sol-advisor-delegate-implementer.toml"
before=$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")
if sh "$installer" --target-dir "$obsolete" >"$tmp/obsolete.out" 2>&1; then
  fail "obsolete capability profile unexpectedly succeeded"
fi
[ "$before" = "$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")" ] ||
  fail "obsolete capability profile changed"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$tmp/obsolete.out" ||
  fail "obsolete modified profile was not classified"
[ ! -e "$obsolete/sol-advisor-luna-implementer.toml" ] ||
  fail "obsolete refusal partially installed new roles"
pass "obsolete capability profile is detected without mutation"

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
pass "runtime inspector Luna/Max evidence"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  pass "git diff --check"
fi

printf '%s\n' "VERIFY PASSED: Sol Advisor Haru fork 0.100.0 model-specific routing checks completed"
