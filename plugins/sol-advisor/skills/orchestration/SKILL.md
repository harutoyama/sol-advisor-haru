---
name: orchestration
description: "Codex-native capability-based selective routing: solo default, bounded delegation, parent verification, fresh audit, and evidence-gated escalation."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, route choice,
decomposition, implementation or delegation, verification, escalation decisions, and final
acceptance. The exact modes are `solo`, `delegate`, `audit`, and `full`.

Read [references/role-contracts.md](references/role-contracts.md) before delegation or review.
Use [references/operations.md](references/operations.md) for installation, exact role names,
runtime evidence, sandbox interpretation, and maintainer procedures.

## Use the current primary model

Do not require a named model family or generation for the primary session. The current
resolved model and reasoning effort chosen for the user's Codex session define the primary
capability lane. `solo` uses that lane directly.

For escalation and audit, do not rely on omission alone to inherit the parent. Current Codex
configuration can define `agents.default_subagent_model` and
`agents.default_subagent_reasoning_effort`, which may otherwise take precedence. Spawn the
escalation implementer and audit reviewer with explicit model and effort values equal to the
current primary session's resolved values. If those values cannot be observed or explicitly
applied, fail closed for that auxiliary lane.

## Declare the route before task tools

Before the first task tool call, emit:

```text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise task-specific rationale>
```

Solo is the default. No task tool call may precede this declaration. A later route declaration
may only escalate after newly observed risk is recorded; never silently downgrade.

## Route selection

- `solo`: default. Primary plans, implements, verifies, and self-reviews. No auxiliary.
- `delegate`: only for bounded, fully specified, low-risk work with clear interfaces and
  little judgment. One delegate implementer executes the complete specification; primary
  verifies. No fresh reviewer.
- `audit`: primary implements and verifies, then a fresh audit reviewer inspects the
  accumulated change set. No implementer auxiliary.
- `full`: exceptional broad or high-risk case. Use one delegate implementer only if the
  implementation remains bounded; otherwise use the escalation implementer. Primary verifies,
  then a fresh audit reviewer reviews.

Auxiliary work must substitute for primary work, not duplicate it.

## Escalation

Use the escalation implementer when delegate work proves judgment-heavy, high-risk,
context-heavy, architecture-sensitive, or wider in blast radius than specified. Escalation
requires newly observed evidence if the task began on a lower-risk route. Spawn the escalation
role with the primary session's resolved model and reasoning effort explicitly.

A specification correction may justify one corrected delegate attempt, but a retry is not a
prerequisite for escalation when the result itself reveals material risk.

## Parent verification

Every implementer prompt must contain OBJECTIVE, FILES AND OWNERSHIP, INTERFACES,
CONSTRAINTS, VERIFICATION, and the structured return contract in role-contracts.md.

Treat auxiliary reports as claims. The primary must inspect the actual diff, confirm changed
file scope, rerun the requested checks, and evaluate artifact/runtime evidence before
acceptance. Verification evidence is required before completion.

## Fresh audit

For `audit` and `full`, spawn a new audit reviewer with fresh context after parent
verification. Pass the primary session's resolved model and reasoning effort explicitly. The
role requests `read-only`, but Codex can reapply parent live sandbox overrides. Accept a
review only after the actual model/effort and sandbox/permission evidence matches the contract
in operations.md.

The reviewer returns exactly `ship`, `fix-first`, or `rethink` and never implements its
own fixes. Any implementation change invalidates the prior verdict and requires parent
re-verification plus a new fresh audit.
