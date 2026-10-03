# Native operations

This page is the maintainer and operator reference. The README stays user-facing.

## Canonical plugin layout

The portable Agent Plugins manifest at `plugins/sol-advisor/plugin.json` is canonical.
`plugins/sol-advisor/.codex-plugin/plugin.json` remains as an OpenAI compatibility fallback.
The repo marketplace at `.agents/plugins/marketplace.json` points to
`./plugins/sol-advisor`.

## Role model policy

| Role | Model policy | Effort policy | Use |
|---|---|---|---|
| `sol_advisor_delegate_implementer` | Explicit lightweight pin in its TOML | Explicit in same TOML | Bounded, fully specified, low-risk implementation |
| `sol_advisor_escalation_implementer` | TOML unpinned; explicit spawn copies resolved primary | Same | Judgment-heavy/high-risk implementation |
| `sol_advisor_audit_reviewer` | TOML unpinned; explicit spawn copies resolved primary | Same | Fresh final audit |

The concrete delegate model identifier appears only in the delegate TOML. Do not copy it into
routing docs, manifests, installer logic, or verification fixtures.

Current Codex custom-agent semantics resolve each omitted model or reasoning setting from an
explicit spawn value, then the corresponding `[agents]` default, then the parent's value.
A custom-agent file setting overrides those sources. Therefore TOML omission alone does not
guarantee parent inheritance when global subagent defaults exist.

For escalation and audit, resolve the current primary model and reasoning effort from runtime
metadata and supply those values explicitly at spawn time. If either is unobservable, fail
closed rather than risk a lower-capability lane.

## Exact spawn contracts

Delegate:

```text
agent_type: sol_advisor_delegate_implementer
fork_turns: none
```

Escalation and audit use their exact capability role plus fresh context and explicit
`model`/`model_reasoning_effort` values copied from the current resolved primary session.
Do not hardcode those values in this repository.

Missing, conflicting, unavailable, or unobservable role/model/effort evidence fails closed.

## Install and preflight

```sh
sh plugins/sol-advisor/scripts/install-agents.sh
sh plugins/sol-advisor/scripts/install-agents.sh --check
```

Selective checks:

```sh
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role delegate
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role escalation
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role audit
```

Unknown roles fail before mutation.

### Obsolete profiles

Older Sol Advisor releases used family-named profile filenames. The installer recognizes those
filenames only as migration hazards. If any exists, installation stops before changing the
destination and prints every obsolete path. It never deletes, overwrites, or byte-migrates an
obsolete profile. The user must inspect and remove or archive it explicitly before retrying.

The old family-name literals intentionally remain only in this detection fixture inside
`install-agents.sh`; they are not runtime routing policy.

## Runtime routing evidence

Public spawn/details metadata is authoritative when available. If it omits routing fields, the
local inspector can read one exact native rollout:

```sh
skill_dir=<directory-containing-SKILL.md>
runtime_inspector="$skill_dir/../../scripts/inspect-agent-runtime.sh"
sh "$runtime_inspector" <native-subagent-thread-id>
```

If public and local evidence both exist, they must agree. The inspector is evidence, not a
model-selection fallback.

For delegate, confirm the selected custom role and its configured pin. For escalation and audit,
confirm the child resolves to the exact primary model and reasoning effort captured before
spawn.

## Reviewer isolation

The audit TOML requests `sandbox_mode = "read-only"`. Subagent sandbox behavior must be
validated from observed runtime evidence rather than inferred from the profile alone:

- observed read-only: proceed;
- broader observed sandbox: proceed only when hard isolation is not required, the prompt forbids
  mutation, and the primary captures exact before/after repository and artifact state;
- unobservable isolation, required hard isolation, or any mutation: stop and reject the review.

Never claim enforced read-only isolation from the TOML alone.

## Maintainer verification

From the repository root:

```sh
sh plugins/sol-advisor/scripts/verify.sh
git diff --check
git status --short
git diff --stat
```

The verifier checks manifests, the three capability roles, one-point model pinning, routing
contracts, installer safety fixtures, JSON/TOML/YAML syntax, and shell syntax without requiring
Python 3.11's `tomllib`.
