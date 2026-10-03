---
name: orchestration
description: "Codex-native capability-based selective routing: solo default, bounded delegation, primary verification, fresh audit, and evidence-gated escalation."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, route choice,
decomposition, implementation or delegation, verification, escalation decisions, and final
acceptance. The exact modes are `solo`, `delegate`, `audit`, and `full`.

Read [references/role-contracts.md](references/role-contracts.md) before delegation or review.
Use [references/operations.md](references/operations.md) for installation, exact role names,
runtime evidence, sandbox interpretation, and maintainer procedures.

## Use the current primary model

Do not require a named model family or generation for the primary session. The current model
chosen by the user is the primary capability lane and `solo` uses it directly.

For `escalation` and `audit`, the custom-agent TOMLs intentionally omit model and reasoning
pins. Before spawning either role, resolve the current primary session's model and reasoning
effort from runtime metadata and pass those resolved values explicitly to the spawn. This avoids
accidental routing through `[agents]` defaults, which take precedence over parent fallback when
a custom-agent file omits model or effort.

If the primary model or effort cannot be observed well enough to preserve the high-capability
lane, stop that auxiliary path rather than silently substituting a different configuration.

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
- `audit`: primary implements and verifies, then a fresh audit reviewer on the same resolved
  primary model/effort inspects the accumulated change set. No implementer auxiliary.
- `full`: exceptional broad or high-risk case. Use one delegate implementer only if the
  implementation remains bounded; otherwise use the escalation implementer on the same
  resolved primary model/effort. Primary verifies, then a fresh audit reviewer reviews.

Auxiliary work must substitute for primary work, not duplicate it.

## Escalation

Use the escalation implementer when delegate work proves judgment-heavy, high-risk,
context-heavy, architecture-sensitive, or wider in blast radius than specified. Escalation
requires newly observed evidence if the task began on a lower-risk route.

A specification correction may justify one corrected delegate attempt, but a retry is not a
prerequisite for escalation when the result itself reveals material risk.

## Primary verification

Every implementer prompt must contain OBJECTIVE, FILES AND OWNERSHIP, INTERFACES,
CONSTRAINTS, VERIFICATION, and the structured return contract in role-contracts.md.

Treat auxiliary reports as claims. The primary must inspect the actual diff, confirm changed
file scope, rerun the requested checks, and evaluate artifact/runtime evidence before
acceptance. Verification evidence is required before completion.

## Fresh audit

For `audit` and `full`, spawn a new audit reviewer with fresh context after primary
verification and explicitly preserve the current primary model/effort. The role requests
`read-only`, but the effective sandbox must be observed at runtime. Accept a review only after
the actual sandbox/permission evidence is consistent with the required isolation policy in
operations.md.

The reviewer returns exactly `ship`, `fix-first`, or `rethink` and never implements its
own fixes. Any implementation change invalidates the prior verdict and requires primary
re-verification plus a new fresh audit.
