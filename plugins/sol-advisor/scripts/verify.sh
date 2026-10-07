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
routing_fixtures=$script_dir/fixtures/research-routing-regressions.txt
primary_effort_fixtures=$script_dir/fixtures/primary-effort-regressions.txt

luna_impl=$agents/sol-advisor-luna-implementer.toml
terra_impl=$agents/sol-advisor-terra-implementer.toml
sol_review=$agents/sol-advisor-sol-reviewer.toml
luna_research=$agents/sol-advisor-luna-researcher.toml
terra_research=$agents/sol-advisor-terra-researcher.toml

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

for file in "$portable" "$compat" "$market" "$luna_impl" "$terra_impl" "$sol_review" \
  "$luna_research" "$terra_research" "$skill" "$ops" "$contracts" "$ui" "$readme" \
  "$installer" "$inspector" "$syntax" "$routing_fixtures" "$primary_effort_fixtures"; do
  [ -f "$file" ] || fail "missing required file: $file"
done

toml_count=$(find "$agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')
[ "$toml_count" -eq 5 ] || fail "expected exactly five agent TOMLs, found $toml_count"
pass "required files and exact five-role set"

python3 "$syntax" json "$portable" "$compat" "$market"
python3 "$syntax" toml "$luna_impl" "$terra_impl" "$sol_review" "$luna_research" "$terra_research"
python3 "$syntax" yaml "$ui"
python3 -m py_compile "$syntax"
pass "JSON, TOML, YAML, and Python syntax"

[ "$(jq -r '.name' "$portable")" = "sol-advisor" ] || fail "portable manifest name"
[ "$(jq -r '.version' "$portable")" = "0.103.0" ] || fail "portable manifest version"
[ "$(jq -r '."$schema"' "$portable")" = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" ] || fail "portable manifest schema"
[ "$(jq -r '.version' "$compat")" = "0.103.0" ] || fail "compat manifest version"
[ "$(jq -r '.plugins[0].source.path' "$market")" = "./plugins/sol-advisor" ] || fail "marketplace path"
pass "0.103.0 manifests and marketplace path"

grep -Fq 'model = "gpt-6-luna"' "$luna_impl" || fail "Luna implementation model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna_impl" || fail "Luna implementation effort pin"
grep -Fq 'model = "gpt-5.6-terra"' "$terra_impl" || fail "Terra implementation model pin"
grep -Fq 'model_reasoning_effort = "high"' "$terra_impl" || fail "Terra implementation effort pin"
grep -Fq 'model = "gpt-6.1-sol"' "$sol_review" || fail "Sol reviewer model pin"
grep -Fq 'model_reasoning_effort = "high"' "$sol_review" || fail "Sol reviewer effort pin"
grep -Fq 'sandbox_mode = "read-only"' "$sol_review" || fail "Sol reviewer read-only request"
grep -Fq 'model = "gpt-6-luna"' "$luna_research" || fail "Luna research model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna_research" || fail "Luna research effort pin"
grep -Fq 'sandbox_mode = "read-only"' "$luna_research" || fail "Luna researcher read-only request"
grep -Fq 'model = "gpt-5.6-terra"' "$terra_research" || fail "Terra research model pin"
grep -Fq 'model_reasoning_effort = "high"' "$terra_research" || fail "Terra research effort pin"
grep -Fq 'sandbox_mode = "read-only"' "$terra_research" || fail "Terra researcher read-only request"
for researcher in "$luna_research" "$terra_research"; do
  grep -Fq '[agents]' "$researcher" || fail "researcher omits agents table"
  grep -Fq 'enabled = false' "$researcher" || fail "researcher does not disable nested agents"
  grep -Fq 'Do not spawn, delegate to, or coordinate any subagent.' "$researcher" || fail "researcher instructions omit nested-delegation prohibition"
  grep -Fq 'strictly read-only' "$researcher" || fail "researcher instructions omit read-only contract"
  grep -Fq 'external systems' "$researcher" || fail "researcher instructions omit external-system mutation prohibition"
done

model_count=$(grep -R -hE '^[[:space:]]*model[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
effort_count=$(grep -R -hE '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
[ "$model_count" -eq 5 ] || fail "expected exactly five agent model assignments, found $model_count"
[ "$effort_count" -eq 5 ] || fail "expected exactly five agent effort assignments, found $effort_count"
pass "implementation, review, and research model/effort/isolation pins"

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

for role in sol_advisor_luna_implementer sol_advisor_terra_implementer sol_advisor_sol_reviewer sol_advisor_luna_researcher sol_advisor_terra_researcher; do
  grep -Fq "$role" "$contracts" || fail "role contract omits $role"
  grep -Fq "$role" "$ops" || fail "operations omit $role"
done

grep -Fq 'mode: solo | delegate | audit | full' "$skill" || fail "implementation/review route declaration missing from root skill"
grep -Fq 'research: none | inline | luna | terra | split' "$skill" || fail "research route declaration missing from root skill"
grep -Fq 'fork_turns: none' "$skill" || fail "fresh-context invariant missing from root skill"
grep -Fq 'explorer' "$skill" || fail "generic explorer prohibition missing from root skill"
grep -Fq 'workstreams, not whole tasks.' "$skill" || fail "workstream-level research routing missing"
grep -Fq 'result dependency' "$skill" || fail "result-dependency rule missing"
grep -Fq 'fan-in; still delegatable.' "$skill" || fail "result dependency incorrectly implies inline"
grep -Fq 'execution-state dependency' "$skill" || fail "execution-state dependency rule missing"
grep -Fq 'execution-state coupling -> `inline`' "$skill" || fail "execution-state coupling does not force inline"
grep -Fq 'context isolation/raw-context' "$skill" || fail "context isolation/compression benefit missing"
grep -Fq 'fresh-context benefit. Parallelism is not required.' "$skill" || fail "non-parallel delegation benefit missing"
grep -Fq 'primary-owned live/state-coupled' "$skill" || fail "primary-owned research coexistence missing"
grep -Fq '`split` = 2-5 delegated workstreams' "$skill" || fail "split hard cap semantics missing"
grep -Fq 'default 2.' "$skill" || fail "split soft default missing"
grep -Fq 'Each third-or-later researcher' "$skill" || fail "third-plus marginal-benefit rule missing"
grep -Fq 'Delegatability changes' "$skill" || fail "route update does not cover newly discovered delegatability"
grep -Fq 'ROUTE UPDATE' "$skill" || fail "route update contract missing"
grep -Fq 'Researchers must not spawn nested subagents.' "$skill" || fail "nested delegation invariant missing"
grep -Fq 'active cross-cutting execution constraints' "$skill" || fail "cross-cutting constraint propagation invariant missing"
grep -Fq 'For an ordinary `solo + inline` task, do not read either supporting reference' "$skill" ||
  fail "solo + inline progressive-disclosure rule missing"
grep -Fq '[references/role-contracts.md](references/role-contracts.md)' "$skill" ||
  fail "root skill does not link role contracts"
grep -Fq '[references/operations.md](references/operations.md)' "$skill" ||
  fail "root skill does not link operations"

for heading in QUESTION SCOPE CONTEXT 'ACTIVE CROSS-CUTTING CONSTRAINTS' 'EVIDENCE REQUIREMENTS' 'STOP CONDITIONS' RETURN 'RESEARCH REPORT' 'STATUS: complete | partial | blocked' FINDINGS: EVIDENCE: CONFLICTS: GAPS:; do
  grep -Fq "$heading" "$contracts" || fail "research packet missing $heading"
done
for heading in OBJECTIVE 'FILES AND OWNERSHIP' INTERFACES CONSTRAINTS VERIFICATION 'IMPLEMENTATION REPORT' CHANGES: VERIFIED: 'JUDGMENT CALLS:'; do
  grep -Fq "$heading" "$contracts" || fail "implementation contract missing $heading"
done
grep -Fq 'VERDICT: ship | fix-first | rethink' "$contracts" || fail "reviewer return contract missing"
grep -Fq 'agent_type: sol_advisor_luna_researcher' "$contracts" || fail "Luna research spawn contract missing"
grep -Fq 'agent_type: sol_advisor_terra_researcher' "$contracts" || fail "Terra research spawn contract missing"
sed -n '/## Luna bounded researcher/,/## Terra judgment-heavy researcher/p' "$contracts" | grep -Fq 'fork_turns: none' ||
  fail "Luna researcher spawn no longer uses fresh context"
sed -n '/## Terra judgment-heavy researcher/,/## Shared implementation contract/p' "$contracts" | grep -Fq 'fork_turns: none' ||
  fail "Terra researcher spawn no longer uses fresh context"
grep -Fq 'agent_type: sol_advisor_luna_implementer' "$contracts" || fail "Luna implementation spawn contract missing"
grep -Fq 'agent_type: sol_advisor_terra_implementer' "$contracts" || fail "Terra implementation spawn contract missing"
grep -Fq 'agent_type: sol_advisor_sol_reviewer' "$contracts" || fail "Sol review spawn contract missing"
grep -Fq 'researcher-owned until its report returns' "$contracts" || fail "delegated research ownership contract missing"
grep -Fq 'spot-check or reproduce decisive' "$contracts" || fail "research spot-verification contract missing"
grep -Fq 'duplicate full investigation' "$contracts" || fail "research non-duplication contract missing"
grep -Fq 'delegated-work-relevant subset' "$contracts" || fail "research packet omits compact applicable constraint subset"
grep -Fq 'particular skill name or path' "$contracts" || fail "constraint propagation is not generic"
grep -Fq 'instead of the parent conversation' "$contracts" || fail "research packet no longer excludes parent-history inheritance"
grep -Fq 'per-command caps do not make' "$contracts" || fail "aggregate output budget invariant missing"
grep -Fq 'never concatenate multiple raw results' "$contracts" || fail "parallel raw-result concatenation prohibition missing"
grep -Fq 'size/count/status' "$contracts" || fail "progressive retrieval first-pass invariant missing"
grep -Fq 'narrow/filter the scope and retrieve again' "$contracts" || fail "truncation narrowing invariant missing"
grep -Fq 'summary plus precise evidence references' "$contracts" || fail "compact evidence return invariant missing"
grep -Fq 'OBSERVATIONS, INFERENCES, CONFLICTS, ALTERNATIVES, and GAPS' "$contracts" || fail "Terra research return fields missing"

grep -Fq '## Researcher isolation' "$ops" || fail "operations omit researcher isolation"
grep -Fq 'actual child sandbox' "$ops" || fail "researcher isolation omits effective runtime evidence"
grep -Fq 'external-system, MCP, or app mutation' "$ops" || fail "researcher isolation omits external mutation rejection"
grep -Fq 'Filesystem sandboxing and external-tool permissions are separate controls.' "$ops" || fail "filesystem/external permission distinction missing"
grep -Fq 'Do not invent undocumented role-local tool-allowlist TOML fields.' "$ops" || fail "undocumented tool-allowlist guard missing"

if grep -Fq 'Route research workstreams, not whole tasks.' "$contracts"; then fail "role contracts duplicate root route selection"; fi
if grep -Fq 'execution-state dependency' "$contracts"; then fail "role contracts duplicate root route decision logic"; fi
if grep -Fq 'RESEARCH REPORT' "$skill"; then fail "root skill still embeds the research return contract"; fi
if grep -Fq 'IMPLEMENTATION REPORT' "$skill"; then fail "root skill still embeds the implementation return contract"; fi
if grep -Fq 'VERDICT: ship | fix-first | rethink' "$skill"; then fail "root skill still embeds the reviewer return contract"; fi
if grep -Fq -- '--check --check-role' "$skill"; then fail "root skill still embeds operational preflight commands"; fi
if grep -Fq 'SELECTIVE ROUTE' "$contracts"; then fail "role contracts duplicate root route declaration"; fi
if grep -Fq 'ACTIVE CROSS-CUTTING CONSTRAINTS' "$skill"; then fail "root skill embeds detailed research packet fields"; fi

grep -Fqi 'Routine coding is not automatically a solo task' "$readme" || fail "README does not preserve routine coding route"
grep -Fqi 'Auxiliary implementation must substitute' "$skill" || fail "skill permits duplicate auxiliary implementation"
grep -Fqi 'Verification evidence is required' "$skill" || fail "skill omits verification evidence gate"
grep -Fq 'agents.default_subagent_model' "$ops" || fail "operations omit default-subagent precedence"
grep -Fqi 'explicit spawn values take precedence' "$ops" || fail "operations omit explicit-spawn precedence"
pass "progressive-disclosure ownership plus implementation/review/research contracts"

grep -Fq 'primary_effort: medium-recommended | high' "$skill" ||
  fail "primary effort gate declaration missing"
grep -Fq 'using only the user' "$skill" || fail "primary effort gate is not pre-tool"
grep -Fq 'Ordinary planning,' "$skill" || fail "planning alone incorrectly implies High"
grep -Fq 'routine verification' "$skill" || fail "routine verification alone incorrectly implies High"
grep -Fq 'architecture or requirement ambiguity' "$skill" || fail "High architecture ambiguity rule missing"
grep -Fq 'complex root-cause analysis' "$skill" || fail "High RCA rule missing"
grep -Fq 'wide or cross-system blast' "$skill" || fail "High blast-radius rule missing"
grep -Fq 'failure/retry or rollback' "$skill" || fail "High retry-cost rule missing"
grep -Fq 'Do not attempt an in-session' "$skill" || fail "in-session effort switching is not prohibited"
grep -Fq 'fresh Medium task' "$readme" || fail "README omits fresh Medium restart contract"
grep -Fq 'step-scoped reasoning-effort machinery' "$ops" ||
  fail "operations omit current Codex effort-update implementation note"
grep -Fq 'one task has one primary effort' "$ops" ||
  fail "operations omit one-effort-per-task invariant"
pass "primary effort gate and no in-session switching contract"

expected_primary_effort_fixture_lines=9
[ "$(wc -l < "$primary_effort_fixtures" | tr -d ' ')" -eq "$expected_primary_effort_fixture_lines" ] ||
  fail "primary effort regression fixture line count"
grep -Fqx 'scenario|expected_primary_effort' "$primary_effort_fixtures" ||
  fail "primary effort fixture header"
grep -Fqx 'settled low-risk planning with bounded scope|medium-recommended' "$primary_effort_fixtures" ||
  fail "bounded planning effort regression"
grep -Fqx 'routine verification of a reversible localized change|medium-recommended' "$primary_effort_fixtures" ||
  fail "routine verification effort regression"
grep -Fqx 'bounded implementation with stable interfaces and cheap retry|medium-recommended' "$primary_effort_fixtures" ||
  fail "bounded implementation effort regression"
grep -Fqx 'architecture choice with unresolved cross-component requirements|high' "$primary_effort_fixtures" ||
  fail "architecture ambiguity effort regression"
grep -Fqx 'multi-layer root-cause analysis with several plausible causes|high' "$primary_effort_fixtures" ||
  fail "complex RCA effort regression"
grep -Fqx 'security-sensitive or data-loss-risking migration|high' "$primary_effort_fixtures" ||
  fail "security/data-loss effort regression"
grep -Fqx 'wide-blast-radius production change with expensive rollback|high' "$primary_effort_fixtures" ||
  fail "blast-radius/retry-cost effort regression"
grep -Fqx 'acceptance-critical irreversible release decision|high' "$primary_effort_fixtures" ||
  fail "critical acceptance effort regression"
pass "primary Medium/High regression fixtures"

expected_fixture_lines=7
[ "$(wc -l < "$routing_fixtures" | tr -d ' ')" -eq "$expected_fixture_lines" ] ||
  fail "routing regression fixture line count"
grep -Fqx 'scenario|expected_research|expected_fanout' "$routing_fixtures" || fail "routing fixture header"
grep -Fqx 'one-symbol lookup|inline|0' "$routing_fixtures" || fail "one-symbol lookup regression"
grep -Fqx 'live process manipulation only|inline|0' "$routing_fixtures" || fail "live process regression"
grep -Fqx 'live mutation + independent multi-file repo/log trace|luna|1' "$routing_fixtures" || fail "S8 mixed live/static regression"
grep -Fqx 'two unrelated substantial static subsystems|split|2' "$routing_fixtures" || fail "two-workstream split regression"
grep -Fqx 'conflicting scientific/methodological evidence|terra|1' "$routing_fixtures" || fail "Terra methodology regression"
grep -Fqx 'five tiny related files|inline-or-luna|0-or-1' "$routing_fixtures" || fail "tiny-related-files regression"
if grep -Fq 'five tiny related files|split|5' "$routing_fixtures"; then fail "tiny files incorrectly split five ways"; fi
pass "research routing regression fixtures"

for role in luna-implementation terra-implementation sol-review luna-research terra-research; do
  grep -Fq "$role" "$installer" || fail "installer omits unambiguous role check name $role"
done
for digest in 1594d2ac0fa527301b92afaf635a14a4e89b640d20f8673b6406d87298bc31c5 85a257f74155ea717c4591acb3c24667d1498d5fbc3244029fda6290f7f080af b11c1c8a9773cfbcb62fa855f7723bbf5fc9df4cf91a5c9dc2be2a01b898f597; do
  grep -Fq "$digest" "$installer" || fail "installer omits known 0.7.0 migration digest"
done
grep -Fq 'OBSOLETE 0.7.0 UNMODIFIED:' "$installer" || fail "installer does not distinguish exact 0.7.0 profiles"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$installer" || fail "installer does not distinguish modified obsolete profiles"
pass "installer role names and 0.7.0 migration detection contract"

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
trap 'rm -rf "$tmp"' 0 HUP INT TERM

default_home=$tmp/default-home
mkdir -p "$default_home"
env -u CODEX_HOME HOME="$default_home" sh "$installer" >/dev/null
env -u CODEX_HOME HOME="$default_home" sh "$installer" --check >/dev/null
[ -f "$default_home/.codex/agents/sol-advisor-luna-implementer.toml" ] ||
  fail "default HOME install missing Luna implementation"
[ -f "$default_home/.codex/agents/sol-advisor-luna-researcher.toml" ] ||
  fail "default HOME install missing Luna research"
[ -f "$default_home/.codex/agents/sol-advisor-terra-researcher.toml" ] ||
  fail "default HOME install missing Terra research"
pass "installer works with CODEX_HOME unset"

fresh=$tmp/fresh
sh "$installer" --target-dir "$fresh" >/dev/null
sh "$installer" --target-dir "$fresh" --check >/dev/null
for role in luna-implementation terra-implementation sol-review luna-research terra-research; do
  sh "$installer" --target-dir "$fresh" --check --check-role "$role" >/dev/null
done
cmp -s "$luna_impl" "$fresh/sol-advisor-luna-implementer.toml" || fail "fresh Luna implementation mismatch"
cmp -s "$terra_impl" "$fresh/sol-advisor-terra-implementer.toml" || fail "fresh Terra implementation mismatch"
cmp -s "$sol_review" "$fresh/sol-advisor-sol-reviewer.toml" || fail "fresh Sol review mismatch"
cmp -s "$luna_research" "$fresh/sol-advisor-luna-researcher.toml" || fail "fresh Luna research mismatch"
cmp -s "$terra_research" "$fresh/sol-advisor-terra-researcher.toml" || fail "fresh Terra research mismatch"
pass "installer fresh install and selective checks"

upgrade=$tmp/upgrade-0100
mkdir "$upgrade"
cp "$luna_impl" "$upgrade/sol-advisor-luna-implementer.toml"
cp "$terra_impl" "$upgrade/sol-advisor-terra-implementer.toml"
cp "$sol_review" "$upgrade/sol-advisor-sol-reviewer.toml"
before_luna=$(cksum "$upgrade/sol-advisor-luna-implementer.toml")
before_terra=$(cksum "$upgrade/sol-advisor-terra-implementer.toml")
before_sol=$(cksum "$upgrade/sol-advisor-sol-reviewer.toml")
sh "$installer" --target-dir "$upgrade" >/dev/null
[ "$before_luna" = "$(cksum "$upgrade/sol-advisor-luna-implementer.toml")" ] || fail "0.100.0 Luna implementation profile changed during update"
[ "$before_terra" = "$(cksum "$upgrade/sol-advisor-terra-implementer.toml")" ] || fail "0.100.0 Terra implementation profile changed during update"
[ "$before_sol" = "$(cksum "$upgrade/sol-advisor-sol-reviewer.toml")" ] || fail "0.100.0 Sol review profile changed during update"
cmp -s "$luna_research" "$upgrade/sol-advisor-luna-researcher.toml" || fail "0.100.0 -> current update missing Luna researcher"
cmp -s "$terra_research" "$upgrade/sol-advisor-terra-researcher.toml" || fail "0.100.0 -> current update missing Terra researcher"
pass "0.100.0 -> current preserves current profiles and adds researchers"

unknown=$tmp/unknown
if sh "$installer" --target-dir "$unknown" --check-role unknown >/dev/null 2>&1; then
  fail "unknown role unexpectedly succeeded"
fi
[ ! -e "$unknown" ] || fail "unknown role mutated destination"
pass "unknown role is non-mutating"

modified=$tmp/modified
mkdir "$modified"
cp "$luna_impl" "$modified/sol-advisor-luna-implementer.toml"
printf '%s\n' '# local edit' >> "$modified/sol-advisor-luna-implementer.toml"
before=$(cksum "$modified/sol-advisor-luna-implementer.toml")
if sh "$installer" --target-dir "$modified" >/dev/null 2>&1; then
  fail "modified destination unexpectedly succeeded"
fi
[ "$before" = "$(cksum "$modified/sol-advisor-luna-implementer.toml")" ] ||
  fail "modified destination changed"
[ ! -e "$modified/sol-advisor-luna-researcher.toml" ] ||
  fail "partial mutation after conflict"
pass "modified current profile fails before mutation"

obsolete=$tmp/obsolete
mkdir "$obsolete"
printf '%s\n' 'user-owned obsolete file' > "$obsolete/sol-advisor-delegate-implementer.toml"
before=$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")
if sh "$installer" --target-dir "$obsolete" >"$tmp/obsolete.out" 2>&1; then fail "obsolete capability profile unexpectedly succeeded"; fi
[ "$before" = "$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")" ] || fail "obsolete capability profile changed"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$tmp/obsolete.out" || fail "obsolete modified profile was not classified"
[ ! -e "$obsolete/sol-advisor-luna-researcher.toml" ] || fail "obsolete refusal partially installed new roles"
pass "0.7.0 obsolete capability profile is detected without mutation"

runtime_sessions=$tmp/runtime-sessions
runtime_day=$runtime_sessions/2026/10/05
mkdir -p "$runtime_day"

runtime_impl_id=11111111-1111-7111-8111-111111111111
runtime_impl_rollout=$runtime_day/rollout-2026-10-05T00-00-00-$runtime_impl_id.jsonl
printf '%s\n' \
  '{"type":"response_item","payload":{"prompt":"DO_NOT_LEAK_PROMPT"}}' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_impl_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"sol_advisor_luna_implementer\",\"agent_path\":\"/root/fixture\",\"model_provider\":\"openai\",\"cwd\":\"/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-6-luna","effort":"max","sandbox_policy":{"type":"danger-full-access"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' \
  > "$runtime_impl_rollout"
runtime_impl_output=$(sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_impl_id")
printf '%s\n' "$runtime_impl_output" | jq -e --arg id "$runtime_impl_id" '
  .thread_id == $id
  and .agent_role == "sol_advisor_luna_implementer"
  and .model == "gpt-6-luna"
  and .effort == "max"
' >/dev/null || fail "runtime inspector returned wrong Luna/Max implementation evidence"
if printf '%s\n' "$runtime_impl_output" | grep -Fq DO_NOT_LEAK; then
  fail "runtime inspector leaked implementation payload"
fi

runtime_id=22222222-2222-7222-8222-222222222222
runtime_rollout=$runtime_day/rollout-2026-10-05T00-00-01-$runtime_id.jsonl
printf '%s\n' \
  '{"type":"response_item","payload":{"prompt":"DO_NOT_LEAK_RESEARCH"}}' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"sol_advisor_luna_researcher\",\"agent_path\":\"/root/fixture\",\"model_provider\":\"openai\",\"cwd\":\"/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-6-luna","effort":"max","sandbox_policy":{"type":"read-only"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' \
  > "$runtime_rollout"
runtime_output=$(sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_id")
printf '%s\n' "$runtime_output" | jq -e --arg id "$runtime_id" '
  .thread_id == $id
  and .agent_role == "sol_advisor_luna_researcher"
  and .model == "gpt-6-luna"
  and .effort == "max"
  and .sandbox_policy_type == "read-only"
' >/dev/null || fail "runtime inspector returned wrong Luna/Max research evidence"
if printf '%s\n' "$runtime_output" | grep -Fq DO_NOT_LEAK; then fail "runtime inspector leaked research payload"; fi

runtime_broad_id=33333333-3333-7333-8333-333333333333
runtime_broad_rollout=$runtime_day/rollout-2026-10-05T00-00-02-$runtime_broad_id.jsonl
printf '%s\n' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_broad_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"sol_advisor_luna_researcher\",\"agent_path\":\"/root/fixture-broad\",\"model_provider\":\"openai\",\"cwd\":\"/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-6-luna","effort":"max","sandbox_policy":{"type":"workspace-write"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' \
  > "$runtime_broad_rollout"
runtime_broad_output=$(sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_broad_id")
printf '%s\n' "$runtime_broad_output" | jq -e --arg id "$runtime_broad_id" '
  .thread_id == $id
  and .agent_role == "sol_advisor_luna_researcher"
  and .sandbox_policy_type == "workspace-write"
' >/dev/null || fail "runtime inspector did not expose broadened researcher sandbox evidence"
pass "runtime inspector implementation, read-only research, and broadened-sandbox evidence fixtures"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  pass "git diff --check"
fi

printf '%s\n' "VERIFY PASSED: Sol Advisor Haru fork 0.103.0 research delegation-contract checks completed"
