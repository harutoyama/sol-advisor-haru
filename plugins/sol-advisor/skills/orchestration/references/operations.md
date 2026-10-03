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
| `sol_advisor_escalation_implementer` | Explicit spawn value copied from primary | Explicit spawn value copied from primary | Judgment-heavy/high-risk implementation |
| `sol_advisor_audit_reviewer` | Explicit spawn value copied from primary | Explicit spawn value copied from primary | Fresh final audit |

The concrete delegate model identifier appears only in the delegate TOML. Do not copy it into
routing docs, manifests, installer logic, or verification fixtures.

Current Codex configuration exposes `agents.default_subagent_model` and
`agents.default_subagent_reasoning_effort`; an explicit value at subagent creation takes
precedence over those defaults. Therefore omission is not a safe guarantee of parent-model
reuse. Escalation and audit intentionally keep their TOMLs unpinned and require explicit spawn
values equal to the primary session's resolved model and reasoning effort.

## Exact spawn contracts

Delegate:

```text
agent_type: sol_advisor_delegate_implementer
fork_turns: none
```

Escalation:

```text
agent_type: sol_advisor_escalation_implementer
fork_turns: none
model: <primary-resolved-model>
reasoning_effort: <primary-resolved-effort>
```

Audit:

```text
agent_type: sol_advisor_audit_reviewer
fork_turns: none
model: <primary-resolved-model>
reasoning_effort: <primary-resolved-effort>
```

Missing, conflicting, unavailable, or unobservable role/model/effort evidence fails closed.
Do not substitute another model to keep the route moving.

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
confirm the child resolves to the same model and reasoning effort as the primary session and
that explicit spawn values, rather than an ambient subagent default, selected that lane.

## Reviewer isolation

The audit TOML requests `sandbox_mode = "read-only"`. Runtime policy can still broaden the
effective child sandbox, so:

- observed read-only: proceed;
- broader observed sandbox: proceed only when hard isolation is not required, the prompt forbids
  mutation, and the parent captures exact before/after repository and artifact state;
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

The verifier checks manifests, the three capability roles, one-point model pinning, primary
spawn-reuse contracts, installer safety fixtures, JSON/TOML/YAML syntax, and shell syntax
without requiring Python 3.11's `tomllib`.
