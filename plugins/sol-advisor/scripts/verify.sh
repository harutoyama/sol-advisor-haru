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
delegation_fixtures=$script_dir/fixtures/delegation-routing-regressions.txt
startup_fixtures=$script_dir/fixtures/startup-contract-regressions.txt

luna_explorer=$agents/sol-advisor-luna-explorer.toml
luna_worker=$agents/sol-advisor-luna-worker.toml
luna_tester=$agents/sol-advisor-luna-tester.toml
luna_impl=$agents/sol-advisor-luna-implementer.toml
terra_impl=$agents/sol-advisor-terra-implementer.toml
sol_review=$agents/sol-advisor-sol-reviewer.toml
luna_research=$agents/sol-advisor-luna-researcher.toml
terra_research=$agents/sol-advisor-terra-researcher.toml

command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

for file in "$portable" "$compat" "$market" "$luna_explorer" "$luna_worker" "$luna_tester" \
  "$luna_impl" "$terra_impl" "$sol_review" "$luna_research" "$terra_research" "$skill" "$ops" \
  "$contracts" "$ui" "$readme" "$installer" "$inspector" "$syntax" "$routing_fixtures" "$delegation_fixtures" "$startup_fixtures"; do
  [ -f "$file" ] || fail "missing required file: $file"
done

toml_count=$(find "$agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')
[ "$toml_count" -eq 8 ] || fail "expected exactly eight agent TOMLs, found $toml_count"
pass "required files and exact eight-role set"

python3 "$syntax" json "$portable" "$compat" "$market"
python3 "$syntax" toml "$luna_explorer" "$luna_worker" "$luna_tester" "$luna_impl" "$terra_impl" "$sol_review" "$luna_research" "$terra_research"
python3 "$syntax" yaml "$ui"
python3 -m py_compile "$syntax"
pass "JSON, TOML, YAML, and Python syntax"

[ "$(jq -r '.name' "$portable")" = "sol-advisor" ] || fail "portable manifest name"
[ "$(jq -r '.version' "$portable")" = "0.104.1" ] || fail "portable manifest version"
[ "$(jq -r '."$schema"' "$portable")" = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" ] || fail "portable manifest schema"
[ "$(jq -r '.version' "$compat")" = "0.104.1" ] || fail "compat manifest version"
[ "$(jq -r '.plugins[0].source.path' "$market")" = "./plugins/sol-advisor" ] || fail "marketplace path"
pass "0.104.1 manifests and marketplace path"

grep -Fq 'model = "gpt-6-luna"' "$luna_explorer" || fail "Luna explorer model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna_explorer" || fail "Luna explorer effort pin"
grep -Fq 'sandbox_mode = "read-only"' "$luna_explorer" || fail "Luna explorer read-only request"
grep -Fq 'model = "gpt-6-luna"' "$luna_worker" || fail "Luna worker model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna_worker" || fail "Luna worker effort pin"
grep -Fq 'model = "gpt-6-luna"' "$luna_tester" || fail "Luna tester model pin"
grep -Fq 'model_reasoning_effort = "max"' "$luna_tester" || fail "Luna tester effort pin"
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
for isolated in "$luna_explorer" "$luna_worker" "$luna_tester" "$luna_research" "$terra_research"; do
  grep -Fq '[agents]' "$isolated" || fail "delegated role omits agents table"
  grep -Fq 'enabled = false' "$isolated" || fail "delegated role does not disable nested agents"
done
for readonly in "$luna_explorer" "$luna_research" "$terra_research"; do
  grep -Fq 'sandbox_mode = "read-only"' "$readonly" || fail "read-only role omits read-only request"
done
for researcher in "$luna_research" "$terra_research"; do
  grep -Fq 'Do not spawn, delegate to, or coordinate any subagent.' "$researcher" || fail "researcher instructions omit nested-delegation prohibition"
  grep -Fq 'strictly read-only' "$researcher" || fail "researcher instructions omit read-only contract"
  grep -Fq 'external systems' "$researcher" || fail "researcher instructions omit external-system mutation prohibition"
done

model_count=$(grep -R -hE '^[[:space:]]*model[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
effort_count=$(grep -R -hE '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$agents" | wc -l | tr -d ' ')
[ "$model_count" -eq 8 ] || fail "expected exactly eight agent model assignments, found $model_count"
[ "$effort_count" -eq 8 ] || fail "expected exactly eight agent effort assignments, found $effort_count"
pass "bounded Luna execution, exception, review, and research model/effort/isolation pins"

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

for role in sol_advisor_luna_explorer sol_advisor_luna_worker sol_advisor_luna_tester \
  sol_advisor_luna_implementer sol_advisor_terra_implementer sol_advisor_sol_reviewer \
  sol_advisor_luna_researcher sol_advisor_terra_researcher; do
  grep -Fq "$role" "$contracts" || fail "role contract omits $role"
  grep -Fq "$role" "$ops" || fail "operations omit $role"
done

grep -Fq 'mode: solo | delegate | audit | full' "$skill" || fail "route declaration missing"
grep -Fq 'research: none | inline | luna | split' "$skill" || fail "research route declaration missing"
grep -Fq 'Use **Sol-led bounded delegation**.' "$skill" || fail "Sol-led bounded delegation rule missing"
grep -Fq 'Delegation is substitution, not addition.' "$skill" || fail "delegation substitution rule missing"
grep -Fq 'Normal active auxiliary fanout is `0-1`.' "$skill" || fail "bounded fanout rule missing"
grep -Fq 'Use at most one follow-up' "$skill" || fail "bounded follow-up rule missing"
grep -Fq 'Prefer Luna whenever a substantial bounded workstream' "$skill" || fail "positive Luna delegation preference missing"
grep -Fq 'Parent integration, actual-diff inspection, and acceptance-critical verification are not' "$skill" || fail "parent acceptance incorrectly blocks delegation"
grep -Fq 'Do not choose `solo` merely because it seems faster or delegation' "$skill" || fail "solo-overhead regression guard missing"
if grep -Fq 'meaningfully replaces primary execution' "$skill" "$readme" "$compat" "$ui"; then
  fail "restrictive primary-replacement delegation wording remains"
fi
if grep -Eq 'delegate only bounded work that (replaces|substitutes for) primary execution' "$ui" "$compat"; then
  fail "restrictive entry-prompt delegation threshold remains"
fi
if grep -Fq 'perform nearly the same investigation, edit, or verification afterward' "$skill"; then
  fail "restrictive parent-reverification delegation wording remains"
fi
grep -Fq 'completion reserve' "$skill" || fail "completion reserve rule missing"
grep -Fq 'sol_advisor_luna_explorer' "$skill" || fail "explorer routing missing"
grep -Fq 'sol_advisor_luna_worker' "$skill" || fail "worker routing missing"
grep -Fq 'sol_advisor_luna_tester' "$skill" || fail "tester routing missing"
grep -Fq 'fresh Sol / High final review' "$skill" || fail "high-risk review rule missing"
grep -Fq 'fork_turns: none' "$skill" || fail "fresh-context invariant missing"
grep -Fq 'Prefer `luna` / fanout 1 for any substantive, self-contained, read-only workstream.' "$skill" || fail "bounded Luna research preference missing"
grep -Fq 'Result dependency is not a reason' "$skill" || fail "result-dependency delegation rule missing"
grep -Fq 'Independent read-only exploration/research workstreams' "$skill" || fail "parallel read-only workstream rule missing"
grep -Fq 'the same investigation or implementation in parallel' "$skill" || fail "parent non-duplication rule missing"
grep -Fq 'Do not route research to Terra.' "$skill" || fail "Terra research exclusion missing"
grep -Fq 'Terra is an exception' "$skill" || fail "Terra implementation exception rule missing"
grep -Fq 'Fresh Sol review is a high-risk final gate' "$skill" || fail "reviewer exception rule missing"

grep -Fq 'agent_type: sol_advisor_luna_explorer' "$contracts" || fail "explorer spawn contract missing"
grep -Fq 'agent_type: sol_advisor_luna_worker' "$contracts" || fail "worker spawn contract missing"
grep -Fq 'agent_type: sol_advisor_luna_tester' "$contracts" || fail "tester spawn contract missing"
grep -Fq 'agent_type: sol_advisor_luna_researcher' "$contracts" || fail "Luna research spawn contract missing"
grep -Fq 'agent_type: sol_advisor_terra_researcher' "$contracts" || fail "Terra research spawn contract missing"
grep -Fq 'agent_type: sol_advisor_terra_implementer' "$contracts" || fail "Terra implementation spawn contract missing"
grep -Fq 'agent_type: sol_advisor_sol_reviewer' "$contracts" || fail "Sol review spawn contract missing"
grep -Fq 'edit -> verify -> repair' "$contracts" || fail "worker repair-loop contract missing"
grep -Fq 'compact `EXPLORATION REPORT`' "$contracts" || fail "compact explorer report missing"
grep -Fq '`WORKER REPORT`' "$contracts" || fail "worker report contract missing"
grep -Fq 'compact `TEST REPORT`' "$contracts" || fail "compact tester report missing"
grep -Fq 'compatibility only' "$contracts" || fail "legacy implementer compatibility boundary missing"

grep -Fq '## Explorer and researcher isolation' "$ops" || fail "operations omit read-only role isolation"
grep -Fq 'luna-exploration' "$ops" || fail "operations omit explorer preflight"
grep -Fq 'luna-worker' "$ops" || fail "operations omit worker preflight"
grep -Fq 'luna-testing' "$ops" || fail "operations omit tester preflight"
grep -Fq 'exact eight-role set' "$ops" || fail "operations omit eight-role verifier contract"
grep -Fq 'Delegation is substitution, not addition.' "$readme" || fail "README does not describe substitution-based delegation"
grep -Fq 'Design references' "$readme" || fail "README omits upstream design/license note"
pass "Sol-led bounded delegation and role contracts"

python3 - "$plugin_dir" "$startup_fixtures" <<'PY'
import json
import pathlib
import re
import sys

plugin = pathlib.Path(sys.argv[1])
fixture = pathlib.Path(sys.argv[2])
skill = (plugin / "skills/orchestration/SKILL.md").read_text()
ops = (plugin / "skills/orchestration/references/operations.md").read_text()
compat = json.loads((plugin / ".codex-plugin/plugin.json").read_text())
ui = (plugin / "skills/orchestration/agents/openai.yaml").read_text()

# These are activation-time instructions. Prevent gates and repetitive user-facing
# route reports from being reintroduced under either entry point.
activation = "\\n".join((skill, " ".join(compat["interface"]["defaultPrompt"]),
                          ui.split("  default_prompt:", 1)[-1]))
def forbidden(fragment):
    patterns = (
        r"PRIMARY +EFFORT",
        r"SELECTIVE +ROUTE",
        r"ROUTE +UPDATE",
        r"medium-recommended",
        r"primary_effort *:",
        r"restart.{0,90}(Sol|Medium|High)",
        r"require.{0,70}primary.{0,70}(model|effort|configuration)",
    )
    return any(re.search(p, fragment, re.I | re.S) for p in patterns)

assert not forbidden(activation), "primary gate/visible route report reintroduced"
assert len(compat["interface"]["defaultPrompt"]) == 1, "duplicate entry instructions"
assert "$sol-advisor:orchestration" in compat["interface"]["defaultPrompt"][0]
assert "$orchestration" in ui
assert len(compat["interface"]["defaultPrompt"][0]) < 320, "entry prompt repeats routing contract"
assert "Use the primary model and reasoning effort already selected by the user" in skill
assert "internally" in skill and "risk" in skill
assert "SKILL.md" in ops and "runtime" in ops.lower()
assert "Invalidate that result after agent-file edits" in ops
assert "Any new child must be checked independently" in ops
assert "Public" in ops and "metadata" in ops and "JSONL" in ops

# Mutation-style guard tests: each former startup failure mode must be detected.
for line in fixture.read_text().splitlines():
    if not line or line.startswith("#"):
        continue
    category, snippet = line.split("|", 1)
    assert category in {"effort-gate", "route-report", "restart", "primary-pin"}, category
    assert forbidden(snippet), f"startup policy guard accepted {category}: {snippet}"

# The entry-point gate is removed, but child pins remain actual parsed config.
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
expected = {
    "luna-explorer": ("gpt-6-luna", "max", "read-only"),
    "luna-worker": ("gpt-6-luna", "max", "workspace-write"),
    "luna-tester": ("gpt-6-luna", "max", None),
    "luna-researcher": ("gpt-6-luna", "max", "read-only"),
    "luna-implementer": ("gpt-6-luna", "max", None),
    "terra-implementer": ("gpt-5.6-terra", "high", None),
    "sol-reviewer": ("gpt-6.1-sol", "high", "read-only"),
    "terra-researcher": ("gpt-5.6-terra", "high", "read-only"),
}
for slug, (model, effort, sandbox) in expected.items():
    path = plugin / f"agents/sol-advisor-{slug}.toml"
    with path.open("rb") as handle:
        profile = tomllib.load(handle)
    assert profile["name"] == "sol_advisor_" + slug.replace("-", "_"), path
    assert (profile["model"], profile["model_reasoning_effort"]) == (model, effort), path
    if sandbox:
        assert profile.get("sandbox_mode") == sandbox, path
    if slug not in {"sol-reviewer", "terra-implementer"}:
        assert profile["agents"]["enabled"] is False, path

assert "fork_turns: none" in skill
assert "Delegation is substitution, not addition." in skill
assert "the same investigation or implementation in parallel" in skill
assert "completion reserve" in skill
assert "read-only" in ops and "external-system mutation" in ops
print("PASS: startup-policy negatives, compact entry points, and parsed child role invariants")
PY
pass "primary startup is ungated; child checks remain mandatory"

expected_fixture_lines=7
[ "$(wc -l < "$routing_fixtures" | tr -d ' ')" -eq "$expected_fixture_lines" ] ||
  fail "routing regression fixture line count"
grep -Fqx 'scenario|expected_research|expected_fanout' "$routing_fixtures" || fail "routing fixture header"
grep -Fqx 'one-symbol lookup|inline|0' "$routing_fixtures" || fail "one-symbol lookup regression"
grep -Fqx 'live process manipulation only|inline|0' "$routing_fixtures" || fail "live process regression"
grep -Fqx 'live mutation + independent multi-file repo/log trace|luna|1' "$routing_fixtures" || fail "S8 mixed live/static regression"
grep -Fqx 'two unrelated substantial static subsystems|split|2' "$routing_fixtures" || fail "two-workstream split regression"
grep -Fqx 'conflicting scientific/methodological evidence|luna|1' "$routing_fixtures" || fail "Luna evidence-gathering methodology regression"
grep -Fqx 'five tiny related files|inline-or-luna|0-or-1' "$routing_fixtures" || fail "tiny-related-files regression"
if grep -Fq 'five tiny related files|split|5' "$routing_fixtures"; then fail "tiny files incorrectly split five ways"; fi
pass "research routing regression fixtures"

expected_delegation_fixture_lines=7
[ "$(wc -l < "$delegation_fixtures" | tr -d ' ')" -eq "$expected_delegation_fixture_lines" ] ||
  fail "delegation routing regression fixture line count"
grep -Fqx 'scenario|expected_mode|expected_research|expected_role|expected_fanout' "$delegation_fixtures" ||
  fail "delegation routing fixture header"
grep -Fqx 'substantial repo mapping with unknown implementation surface|delegate|none|sol_advisor_luna_explorer|1' "$delegation_fixtures" ||
  fail "substantial repo mapping should prefer Luna explorer"
grep -Fqx 'settled bounded implementation|delegate|none|sol_advisor_luna_worker|1' "$delegation_fixtures" ||
  fail "settled bounded implementation should prefer Luna worker"
grep -Fqx 'non-trivial independent regression verification|delegate|none|sol_advisor_luna_tester|1' "$delegation_fixtures" ||
  fail "independent regression verification should prefer Luna tester"
grep -Fqx 'substantive static self-contained research|solo|luna|sol_advisor_luna_researcher|1' "$delegation_fixtures" ||
  fail "substantive static research should prefer Luna researcher"
grep -Fqx 'tiny local change|solo|none|none|0' "$delegation_fixtures" ||
  fail "tiny local change should remain solo"
grep -Fqx 'strongly live-state-coupled operation|solo|none|none|0' "$delegation_fixtures" ||
  fail "live-state-coupled operation should remain solo"
pass "positive Luna delegation routing regression fixtures"

for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
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
[ -f "$default_home/.codex/agents/sol-advisor-luna-explorer.toml" ] ||
  fail "default HOME install missing Luna explorer"
[ -f "$default_home/.codex/agents/sol-advisor-luna-worker.toml" ] ||
  fail "default HOME install missing Luna worker"
[ -f "$default_home/.codex/agents/sol-advisor-luna-tester.toml" ] ||
  fail "default HOME install missing Luna tester"
[ -f "$default_home/.codex/agents/sol-advisor-luna-implementer.toml" ] ||
  fail "default HOME install missing legacy Luna implementation"
[ -f "$default_home/.codex/agents/sol-advisor-luna-researcher.toml" ] ||
  fail "default HOME install missing Luna research"
[ -f "$default_home/.codex/agents/sol-advisor-terra-researcher.toml" ] ||
  fail "default HOME install missing Terra research"
pass "installer works with CODEX_HOME unset"

fresh=$tmp/fresh
sh "$installer" --target-dir "$fresh" >/dev/null
sh "$installer" --target-dir "$fresh" --check >/dev/null
for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
  sh "$installer" --target-dir "$fresh" --check --check-role "$role" >/dev/null
done
cmp -s "$luna_explorer" "$fresh/sol-advisor-luna-explorer.toml" || fail "fresh Luna explorer mismatch"
cmp -s "$luna_worker" "$fresh/sol-advisor-luna-worker.toml" || fail "fresh Luna worker mismatch"
cmp -s "$luna_tester" "$fresh/sol-advisor-luna-tester.toml" || fail "fresh Luna tester mismatch"
cmp -s "$luna_impl" "$fresh/sol-advisor-luna-implementer.toml" || fail "fresh legacy Luna implementation mismatch"
cmp -s "$terra_impl" "$fresh/sol-advisor-terra-implementer.toml" || fail "fresh Terra implementation mismatch"
cmp -s "$sol_review" "$fresh/sol-advisor-sol-reviewer.toml" || fail "fresh Sol review mismatch"
cmp -s "$luna_research" "$fresh/sol-advisor-luna-researcher.toml" || fail "fresh Luna research mismatch"
cmp -s "$terra_research" "$fresh/sol-advisor-terra-researcher.toml" || fail "fresh Terra research mismatch"
pass "installer fresh install and selective checks"

# Selective checks must not inspect unused roles. Rechecking after a changed
# selected profile must fail; restoring the original makes it valid again.
cp "$fresh/sol-advisor-luna-researcher.toml" "$tmp/researcher-original"
printf '%s\n' '# user changed unused profile' >> "$fresh/sol-advisor-luna-researcher.toml"
sh "$installer" --target-dir "$fresh" --check --check-role luna-worker >/dev/null ||
  fail "selective worker check depended on unused researcher"
if sh "$installer" --target-dir "$fresh" --check --check-role luna-research >/dev/null 2>&1; then
  fail "changed selected researcher profile passed preflight"
fi
cp "$tmp/researcher-original" "$fresh/sol-advisor-luna-researcher.toml"
sh "$installer" --target-dir "$fresh" --check --check-role luna-research >/dev/null ||
  fail "restored selected profile did not pass revalidation"
pass "unused role skipped; changed selected role invalidates preflight"


upgrade=$tmp/upgrade-0102
mkdir "$upgrade"
cp "$luna_impl" "$upgrade/sol-advisor-luna-implementer.toml"
cp "$terra_impl" "$upgrade/sol-advisor-terra-implementer.toml"
cp "$sol_review" "$upgrade/sol-advisor-sol-reviewer.toml"
cp "$luna_research" "$upgrade/sol-advisor-luna-researcher.toml"
cp "$terra_research" "$upgrade/sol-advisor-terra-researcher.toml"
before_luna=$(cksum "$upgrade/sol-advisor-luna-implementer.toml")
before_terra=$(cksum "$upgrade/sol-advisor-terra-implementer.toml")
before_sol=$(cksum "$upgrade/sol-advisor-sol-reviewer.toml")
before_luna_research=$(cksum "$upgrade/sol-advisor-luna-researcher.toml")
before_terra_research=$(cksum "$upgrade/sol-advisor-terra-researcher.toml")
sh "$installer" --target-dir "$upgrade" >/dev/null
[ "$before_luna" = "$(cksum "$upgrade/sol-advisor-luna-implementer.toml")" ] || fail "0.102.2 Luna implementation profile changed during update"
[ "$before_terra" = "$(cksum "$upgrade/sol-advisor-terra-implementer.toml")" ] || fail "0.102.2 Terra implementation profile changed during update"
[ "$before_sol" = "$(cksum "$upgrade/sol-advisor-sol-reviewer.toml")" ] || fail "0.102.2 Sol review profile changed during update"
[ "$before_luna_research" = "$(cksum "$upgrade/sol-advisor-luna-researcher.toml")" ] || fail "0.102.2 Luna research profile changed during update"
[ "$before_terra_research" = "$(cksum "$upgrade/sol-advisor-terra-researcher.toml")" ] || fail "0.102.2 Terra research profile changed during update"
cmp -s "$luna_explorer" "$upgrade/sol-advisor-luna-explorer.toml" || fail "0.102.x -> current update missing Luna explorer"
cmp -s "$luna_worker" "$upgrade/sol-advisor-luna-worker.toml" || fail "0.102.x -> current update missing Luna worker"
cmp -s "$luna_tester" "$upgrade/sol-advisor-luna-tester.toml" || fail "0.102.x -> current update missing Luna tester"
cmp -s "$luna_research" "$upgrade/sol-advisor-luna-researcher.toml" || fail "0.102.x update changed Luna researcher unexpectedly"
cmp -s "$terra_research" "$upgrade/sol-advisor-terra-researcher.toml" || fail "0.102.x update changed Terra researcher unexpectedly"
pass "0.102.x -> current preserves previous profiles and adds bounded Luna roles"

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
[ ! -e "$modified/sol-advisor-luna-explorer.toml" ] ||
  fail "partial mutation after conflict"
pass "modified current profile fails before mutation"

obsolete=$tmp/obsolete
mkdir "$obsolete"
printf '%s\n' 'user-owned obsolete file' > "$obsolete/sol-advisor-delegate-implementer.toml"
before=$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")
if sh "$installer" --target-dir "$obsolete" >"$tmp/obsolete.out" 2>&1; then fail "obsolete capability profile unexpectedly succeeded"; fi
[ "$before" = "$(cksum "$obsolete/sol-advisor-delegate-implementer.toml")" ] || fail "obsolete capability profile changed"
grep -Fq 'OBSOLETE MODIFIED OR UNKNOWN:' "$tmp/obsolete.out" || fail "obsolete modified profile was not classified"
[ ! -e "$obsolete/sol-advisor-luna-explorer.toml" ] || fail "obsolete refusal partially installed new roles"
pass "0.7.0 obsolete capability profile is detected without mutation"

runtime_sessions=$tmp/runtime-sessions
runtime_day=$runtime_sessions/2026/10/05
mkdir -p "$runtime_day"

runtime_impl_id=11111111-1111-7111-8111-111111111111
runtime_impl_rollout=$runtime_day/rollout-2026-10-05T00-00-00-$runtime_impl_id.jsonl
printf '%s\n' \
  '{"type":"response_item","payload":{"prompt":"DO_NOT_LEAK_PROMPT"}}' \
  "{\"type\":\"session_meta\",\"payload\":{\"id\":\"$runtime_impl_id\",\"parent_thread_id\":\"00000000-0000-7000-8000-000000000000\",\"agent_role\":\"sol_advisor_luna_worker\",\"agent_path\":\"/root/fixture\",\"model_provider\":\"openai\",\"cwd\":\"/fixture\"}}" \
  '{"type":"turn_context","payload":{"model":"gpt-6-luna","effort":"max","sandbox_policy":{"type":"danger-full-access"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' \
  > "$runtime_impl_rollout"
runtime_impl_output=$(sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_impl_id")
printf '%s\n' "$runtime_impl_output" | jq -e --arg id "$runtime_impl_id" '
  .thread_id == $id
  and .agent_role == "sol_advisor_luna_worker"
  and .model == "gpt-6-luna"
  and .effort == "max"
' >/dev/null || fail "runtime inspector returned wrong Luna/Max worker evidence"
if printf '%s\n' "$runtime_impl_output" | grep -Fq DO_NOT_LEAK; then
  fail "runtime inspector leaked implementation payload"
fi


cp "$runtime_impl_rollout" "$tmp/worker-rollout-before-conflict"
printf '%s\n' '{"type":"turn_context","payload":{"model":"gpt-5.6-terra","effort":"high","sandbox_policy":{"type":"danger-full-access"},"permission_profile":{"type":"disabled"},"cwd":"/fixture"}}' >> "$runtime_impl_rollout"
if sh "$inspector" --sessions-dir "$runtime_sessions" "$runtime_impl_id" >/dev/null 2>&1; then
  fail "conflicting child model/effort runtime evidence unexpectedly accepted"
fi
cp "$tmp/worker-rollout-before-conflict" "$runtime_impl_rollout"
pass "child runtime evidence conflict fails closed"

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
pass "runtime inspector worker, read-only research, and broadened-sandbox evidence fixtures"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo_root" diff --check
  pass "git diff --check"
fi

printf '%s\n' "VERIFY PASSED: Sol Advisor Haru fork Sol-led bounded delegation and ungated primary startup checks completed"
