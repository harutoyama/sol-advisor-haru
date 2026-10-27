# Sol Advisor

Sol Advisor orchestrates work under the **primary model and reasoning effort the user
already selected**. It starts the task immediately: no startup model confirmation, Medium/High
restart gate, or mandatory `PRIMARY EFFORT` / `SELECTIVE ROUTE` output. Task risk determines
delegation and independent acceptance checks, not the primary model selection.

The primary retains Sol-style architecture, decomposition, integration, and final acceptance.
The skill's [root contract](plugins/sol-advisor/skills/orchestration/SKILL.md) is the
single source of routing policy. Detailed role contracts and operational verification
are loaded only as needed.

| Auxiliary role | Pin | Purpose |
|---|---|---|
| Luna explorer / worker / tester / researcher | GPT-6 Luna / Max | Independently bounded exploration, implementation, verification, and read-only research |
| Terra implementer | GPT-6.1 Terra / High | Judgment-heavy implementation, including direct routing inside settled architecture |
| Terra researcher | GPT-6.1 Terra / High | Scientific, methodological, causal, and conflicting-evidence research |
| Fresh Sol reviewer | GPT-6.1 Sol / High | Independent final scrutiny only on high-risk changes |
| Legacy Luna implementer | GPT-6 Luna / Max | Compatibility only |

Route work by judgment and risk. Luna / Max handles routine bounded implementation,
focused exploration, ordinary evidence gathering, and testing. Terra 6.1 / High
handles complex implementation, difficult causal debugging, methodological validation,
and contradictory evidence. Choose Terra directly when difficulty is evident at intake;
file count or task size alone does not determine the route. The primary retains
architecture, integration and final acceptance; high-risk Sol review is unchanged.

Delegation is substitution, not addition. The primary inspects actual diffs and performs
acceptance-critical checks, but does not duplicate child investigations or implementation.
Normal fanout is 0–1, with larger fanout reserved for independent workstreams. Children
receive bounded constraints and return compact evidence; no nested delegation, and
`fork_turns: none` throughout. Preserve completion reserve. Only selected auxiliary
roles are preflight-checked; successful role checks are reused within an unchanged
task configuration, whereas each child thread's runtime evidence is checked afresh.
A public runtime record is enough when complete; otherwise inspect only the exact
child's JSONL. Fail closed on missing or contradictory required auxiliary evidence.

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
workdir="$HOME/Downloads/sol-advisor-haru-0.106.0"
git clone --depth 1 --branch main https://github.com/harutoyama/sol-advisor-haru.git "$workdir"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh"
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --check
```

The installer writes eight profiles to `$CODEX_HOME/agents` when `CODEX_HOME` is set,
otherwise to `~/.codex/agents`. The Luna execution roles are explorer, worker, and tester;
both Terra roles are normally selectable. It is fail-closed and never overwrites
modified, symlinked, non-regular, unknown, or obsolete 0.7.0 profiles.

Start a fresh Codex task after installing the agents:

```text
Use $sol-advisor:orchestration to build this feature and verify it.
```

## Update from Haru fork 0.7.0

Refresh the configured marketplace snapshot:

```sh
codex plugin marketplace list
codex plugin marketplace upgrade sol-advisor
```

Refresh or reinstall **Sol Advisor (Haru fork)** from the ChatGPT desktop Plugins Directory.

Then use a fresh 0.106.0 checkout. Updating the plugin alone leaves old
`gpt-5.6-terra` pins in existing agent TOMLs. To migrate unchanged prior-release
Terra implementer and researcher profiles only:

```sh
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --upgrade-known
sh "$workdir/plugins/sol-advisor/scripts/install-agents.sh" --check
```

Any modified or unknown destination blocks all writes. Reconcile custom profiles
manually rather than overwriting them. Unchanged other roles remain untouched.
If any 0.7.0 capability profiles are
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
own fail-closed installer, runtime evidence checks, `fork_turns: none`, direct Terra
judgment-heavy routing, and high-risk-only fresh Sol review.

## Maintainers

See [native operations](plugins/sol-advisor/skills/orchestration/references/operations.md) for
exact role contracts, runtime evidence, migration behavior, and release verification.
