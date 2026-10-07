# Sol Advisor

Sol Advisor is a Codex-native Sol-led orchestration workflow. This Haru fork starts the primary
GPT-6.1 Sol task on High by default, performs a tool-free pre-task effort gate, and then prefers
specialized Luna roles for substantial bounded workstreams that can be instructed independently.

| Role | Model | Effort | Use |
|---|---|---|---|
| Primary architect/integrator | GPT-6.1 Sol | High default; Medium when the pre-task gate permits | Architecture, decomposition, integration, escalation, final acceptance |
| Explorer | GPT-6 Luna | Max | Read-only repo mapping, call/data-flow, tests/config, implementation boundaries |
| Worker | GPT-6 Luna | Max | Bounded implementation with local edit -> verify -> repair |
| Tester | GPT-6 Luna | Max | Reproduction, targeted verification, regression evidence |
| Researcher | GPT-6 Luna | Max | Bounded substantive read-only docs/repo/log/Web research |
| Higher-complexity implementer | GPT-5.6 Terra | High | Judgment-heavy implementation exception only |
| Fresh reviewer | GPT-6.1 Sol | High | High-risk independent final review only |
| Legacy Luna implementer | GPT-6 Luna | Max | 0.102.x compatibility; not preferred for new routing |
| Legacy Terra researcher | GPT-5.6 Terra | High | 0.102.x compatibility; not selected by current routing |

Start the Codex / ChatGPT Desktop task with GPT-6.1 Sol / High selected by default. Before any
task tool call, the skill classifies the whole task as `medium-recommended` or `high`. If Medium
is sufficient, it stops the High task and tells you to restart the same task as a fresh Sol / Medium task;
it does not change reasoning effort inside the active task. Planning, routine verification, ordinary
bounded coding, or normal review alone are not reasons to keep High. Architecture ambiguity,
complex RCA, wide blast radius, irreversible/security/data-loss/production risk, expensive retry
cost, or acceptance with materially high error cost keep High.

## Routing modes

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Truly tiny/localized work, planning, or parent-owned architecture/security/breaking-change decisions. | Sol handles it directly. |
| `delegate` | A substantial bounded workstream can be instructed independently with clear ownership and evidence. | Prefer the needed Luna role; Terra remains a judgment-heavy implementation exception. |
| `audit` | Implementation must remain Sol-owned and high-risk independent scrutiny is warranted. | Sol implements/verifies; fresh Sol / High reviews. |
| `full` | Delegated broad/high-risk implementation needs a fresh final review. | Bounded delegated execution (Terra only by exception), parent integration/verification, fresh Sol review. |

Delegation is substitution, not addition. Normal fanout is 0-1; use two children only for genuinely
independent substantial surfaces, and treat three or more as exceptional. Do not mechanically chain
explorer -> worker -> tester. Each child is one-shot, with at most one follow-up for a concrete gap.
The primary reuses returned evidence, inspects the actual diff, and performs acceptance-critical
verification without re-running the delegated investigation or edit. Parent integration and final
acceptance are not delegation contraindications.

Budgeting uses a completion reserve rather than fixed model percentages: stop spawning when the
remaining primary capacity may not cover integration, acceptance, and the final response.

## Research routing

Research remains orthogonal to implementation/review mode. Declare
`research: none | inline | luna | split` and `fanout: 0..5`.

- `none`: no substantive research.
- `inline`: tiny lookup or evidence coupled to live primary mutation/state.
- `luna`: prefer for substantive, self-contained, read-only repo/log/docs/Web/API/version
  investigation; parent synthesis or handoff overhead alone does not make it inline.
- Judgment-heavy research remains Luna for evidence gathering; Luna returns conflicts/gaps and the
  primary Sol performs scientific/methodological or architecture-sensitive adjudication.
- `split`: two genuinely independent substantial questions; three to five researchers are
  exceptional and require explicit marginal-value justification.

Waiting for a delegated report is only a result dependency and does not force inline research.
Researchers use `fork_turns: none`, return compact evidence, cannot spawn nested agents, and do
not mutate the workspace or external systems.

## Install

Requirements: a current Codex CLI or ChatGPT desktop app with plugin and custom-agent support,
`jq`, `git`, and access to the selected models.

Register this fork as a marketplace:

```sh
codex plugin marketplace add harutoyama/sol-advisor-haru --ref main
codex plugin marketplace list
```

Install **Sol Advisor (Haru fork)** from that marketplace in the ChatGPT desktop Plugins
Directory.

Install the companion custom-agent profiles from a fresh checkout:

```sh
workdir="$HOME/Downloads/sol-advisor-haru-0.104.1"
git clone --depth 1 --branch main https://github.com/harutoyama/sol-advisor-haru.git "$workdir"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --check
```

The installer writes eight profiles to `$CODEX_HOME/agents` when `CODEX_HOME` is set,
otherwise to `~/.codex/agents`. The three bounded Luna execution roles are explorer, worker, and tester; the
previous five profiles remain installed for compatibility and exception lanes. It is fail-closed: it never overwrites a modified file,
symlink, non-regular file, unknown conflicting profile, or obsolete 0.7.0 capability profile.

Start a fresh Codex task after installing the agents:

```text
Use $sol-advisor:orchestration to build this feature and verify it. Declare the SELECTIVE ROUTE before task tools.
```

## Update from Haru fork 0.7.0

Refresh the configured marketplace snapshot:

```sh
codex plugin marketplace list
codex plugin marketplace upgrade sol-advisor
```

Refresh or reinstall **Sol Advisor (Haru fork)** from the ChatGPT desktop Plugins Directory.

Then use a fresh 0.104.1 checkout and run the installer. Existing unmodified 0.102.2 profiles are
preserved byte-for-byte; the installer adds the explorer, worker, and tester profiles without
rewriting the previous implementation, review, or researcher profiles. If any 0.7.0 capability profiles are
still present, the installer stops before mutation and prints their exact paths. The known
unmodified 0.7.0 SHA-256 values are:

| Obsolete 0.7.0 profile | SHA-256 |
|---|---|
| `sol-advisor-delegate-implementer.toml` | `1594d2ac0fa527301b92afaf635a14a4e89b640d20f8673b6406d87298bc31c5` |
| `sol-advisor-escalation-implementer.toml` | `85a257f74155ea717c4591acb3c24667d1498d5fbc3244029fda6290f7f080af` |
| `sol-advisor-audit-reviewer.toml` | `b11c1c8a9773cfbcb62fa855f7723bbf5fc9df4cf91a5c9dc2be2a01b898f597` |

Inspect the exact installed files before deleting anything:

```sh
agent_dir="${CODEX_HOME:-$HOME/.codex}/agents"
for f in \
  sol-advisor-delegate-implementer.toml \
  sol-advisor-escalation-implementer.toml \
  sol-advisor-audit-reviewer.toml
do
  path="$agent_dir/$f"
  if [ -e "$path" ] || [ -L "$path" ]; then
    printf '%s  ' "$path"
    shasum -a 256 "$path"
  fi
done
```

Only if a file is a regular, non-symlink file and its digest exactly matches the table above,
remove that exact obsolete file:

```sh
agent_dir="${CODEX_HOME:-$HOME/.codex}/agents"
rm -- "$agent_dir/sol-advisor-delegate-implementer.toml"
rm -- "$agent_dir/sol-advisor-escalation-implementer.toml"
rm -- "$agent_dir/sol-advisor-audit-reviewer.toml"
```

If any digest differs, do not delete that file automatically; inspect or archive the user-modified
profile first. After the obsolete profiles are gone, rerun:

```sh
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --check
```

Start a new task/session after the role files change. The skill invocation remains
`$sol-advisor:orchestration`.

## Design references

The specialized Luna role split was compared against
`donvito/codex-astra-luna-orchestrator` and `Hanqi-b/luna-based-agent-orchestrator`, both
Apache-2.0 projects. Sol Advisor keeps its existing MIT codebase and uses independently adapted
routing/contracts rather than copying their role-file text. In particular, this fork adopts the
explorer/worker/tester/researcher separation and parallel-workstream discipline while retaining its
own fail-closed installer, runtime evidence checks, `fork_turns: none`, implementation-only Terra
exception lane, and high-risk-only fresh Sol review.

## Maintainers

See [native operations](plugins/sol-advisor/skills/orchestration/references/operations.md) for
exact role contracts, runtime evidence, migration behavior, and release verification.
