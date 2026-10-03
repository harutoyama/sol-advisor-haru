# Sol Advisor

Sol Advisor is a Codex-native selective-routing workflow for software delivery. It keeps the
current primary Codex model in charge and routes by task capability rather than model family
names or generation numbers.

## Routing modes

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Default; risk is contained. | Primary plans, implements, verifies, and self-reviews. |
| `delegate` | Work is bounded, fully specified, low-risk, and interface-stable. | Lightweight implementer executes the complete spec; primary verifies. |
| `audit` | Independent fresh-context scrutiny matters. | Primary implements and verifies; fresh read-only reviewer audits. |
| `full` | Broad or high-risk exception. | Delegate or escalation implementer, primary verification, then fresh audit. |

A `delegate` route may escalate only when newly observed evidence shows that the work is
judgment-heavy, high-risk, context-heavy, architecture-sensitive, or has a wide blast radius.
Auxiliary work substitutes for primary work; it must not duplicate it.

## Install

Requirements: a current Codex CLI with plugin and custom-agent support, `jq`, and a model
available to your account for the primary session.

```sh
codex plugin marketplace add harutoyama/sol-advisor-haru --ref main
plugin_dir="$(codex plugin add sol-advisor@sol-advisor --json | jq -r '.installedPath')"
test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir"
sh "$plugin_dir/scripts/install-agents.sh"
```

The companion installer writes the three Sol Advisor custom-agent profiles to
`$CODEX_HOME/agents` or `~/.codex/agents`. It is fail-closed: it never overwrites a
modified file, symlink, non-regular file, or obsolete Sol Advisor profile.

Start a fresh Codex task after installing the agents.

```text
Use $sol-advisor:orchestration to build this feature and verify it. Declare the SELECTIVE ROUTE before task tools.
```

## Update

```sh
codex plugin marketplace upgrade sol-advisor
plugin_dir="$(codex plugin add sol-advisor@sol-advisor --json | jq -r '.installedPath')"
test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir"
sh "$plugin_dir/scripts/install-agents.sh"
```

If the installer reports obsolete Sol Advisor profiles, inspect and remove only the exact paths
it reports, then rerun the installer. It intentionally does not delete or migrate those files.

## Uninstall

Remove the plugin first:

```sh
codex plugin remove sol-advisor@sol-advisor
```

Then review `~/.codex/agents/` (or `$CODEX_HOME/agents/`) and remove Sol Advisor agent
profiles you no longer want. Do not delete modified profiles blindly.

## Maintainers

See [native operations](plugins/sol-advisor/skills/orchestration/references/operations.md) for
role installation, runtime evidence, sandbox interpretation, migration behavior, and release
verification.
