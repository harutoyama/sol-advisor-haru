# Sol Advisor

Sol Advisor is a Codex-native selective-routing workflow. This Haru fork keeps
architecture, requirement resolution, verification, and acceptance in a GPT-6.1 Sol / High
primary session, while routing implementation by model:

| Role | Model | Effort | Use |
|---|---|---|---|
| Primary architect | GPT-6.1 Sol | High | Architecture, planning, requirement resolution, verification, acceptance |
| Routine implementer | GPT-6 Luna | Max | Bounded, fully specified, interface-stable routine implementation |
| Higher-complexity implementer | GPT-5.6 Terra | High | Judgment-heavy, architecture-sensitive, context-heavy, high-risk, or wide-blast-radius implementation |
| Fresh reviewer | GPT-6.1 Sol | High | Independent final review for audit/full; requests read-only sandbox |
| Bounded researcher | GPT-6 Luna | High | Focused read-only code/log/docs/Web investigation with compact evidence return |
| Judgment-heavy researcher | GPT-5.6 Terra | High | Read-only investigation requiring conflict resolution, methodology, architecture, or complex root-cause judgment |

The skill does not switch the primary model. Start the Codex / ChatGPT Desktop task with
GPT-6.1 Sol / High selected.

## Routing modes

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Very small change; delegation overhead dominates; architecture/planning/requirement resolution; coding-light work. | Primary handles the task directly. |
| `delegate` | Implementation is fully specified and should be handed to one worker. | Prefer Luna / Max for routine bounded work; use Terra / High when judgment or risk is materially higher. Primary verifies. |
| `audit` | Primary implementation needs independent final scrutiny. | Primary implements and verifies; fresh Sol / High reviews. |
| `full` | Broad or high-risk exception. | One selected implementer, primary verification, then fresh Sol / High review. |

**Routine coding is not automatically a solo task.** Once the primary can state a complete,
bounded, low-risk, interface-stable implementation contract, prefer Luna / Max. Do not delegate
architecture or unresolved requirements merely to increase agent count. Auxiliary work substitutes
for primary implementation; the primary inspects the actual diff and reruns verification instead
of reimplementing the same change.

## Research routing

Research is orthogonal to `mode`. Declare `research: none | inline | luna | terra | split` and
`fanout: 0..5` alongside the implementation/review mode. `mode: solo` means no implementation
or review auxiliary; it does **not** prohibit a research auxiliary.

Route **research workstreams, not whole tasks**. A result dependency (the primary must wait for the
report) is still delegatable. Keep a workstream inline when useful observations repeatedly depend on
primary-owned mutation, live state, intervening judgment, or operation results. Delegate only
read-only, self-contained workstreams whose substantial raw evidence can be compressed into a much
shorter report and whose context isolation/compression, latency, coverage, or fresh-context benefit
exceeds handoff and integration cost. Parallel execution is useful but is not required.

Use Luna / High for one bounded objective evidence-gathering workstream. Use Terra / High only when
that delegated workstream itself requires conflicting-evidence adjudication, scientific or
methodological judgment, architecture-sensitive causal analysis, or complex root-cause synthesis;
overall task risk alone is not enough. `research: luna` or `terra` may coexist with
primary-owned live/state-coupled research. Use `split` for two to five genuinely independent
delegated workstreams, with a soft default of two; each third-or-later researcher needs distinct
scope, a reason it cannot be bundled, and material marginal benefit. File count alone is not a
split reason.

Every research spawn uses the dedicated `sol_advisor_luna_researcher` or
`sol_advisor_terra_researcher` profile with `fork_turns: none`. Generic `explorer`, `worker`,
`default`, or inherited-model fallback is forbidden. Researchers are read-only and cannot spawn
nested subagents. Delegated research is not repeated wholesale by the primary; the primary performs
targeted spot verification of decisive or suspicious evidence. Newly discovered delegatability,
removed state coupling, conflicting evidence, or an additional independent workstream requires an
explicit route update; silent route changes remain forbidden.

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
workdir="$HOME/Downloads/sol-advisor-haru-0.102.0"
git clone --depth 1 --branch main https://github.com/harutoyama/sol-advisor-haru.git "$workdir"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --check
```

The installer writes five profiles to `$CODEX_HOME/agents` when `CODEX_HOME` is set,
otherwise to `~/.codex/agents`. It is fail-closed: it never overwrites a modified file,
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

Then use a fresh 0.102.0 checkout and run the installer. Existing unmodified 0.100.0 model-specific
implementer/reviewer profiles are preserved byte-for-byte; the installer includes the two researcher
profiles introduced in 0.101.0. If any 0.7.0 capability profiles are
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

## Maintainers

See [native operations](plugins/sol-advisor/skills/orchestration/references/operations.md) for
exact role contracts, runtime evidence, migration behavior, and release verification.
