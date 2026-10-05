---
name: orchestration
description: "Codex-native model-specific selective routing: Sol architects and verifies, Luna handles routine coding, Terra handles harder implementation, and fresh Sol reviews selected routes."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, route choice,
decomposition, complete worker specifications, parent verification, escalation decisions, and
final acceptance. The exact modes are `solo`, `delegate`, `audit`, and `full`.

Read [references/role-contracts.md](references/role-contracts.md) before delegation or review.
Use [references/operations.md](references/operations.md) for exact role names, preflight,
runtime evidence, sandbox interpretation, migration, and maintainer procedures.

## Confirm the primary session

Run the primary Codex session on `gpt-6.1-sol` with `high` reasoning. Verify the current
model and effort when runtime metadata exposes them. If either differs, tell the user to select
GPT-6.1 Sol / High and stop before delegation or review. If runtime metadata does not expose
them, ask the user to confirm the selected primary before using an auxiliary lane. A skill cannot
change the primary model itself.

## Declare the route before task tools

Before the first task tool call, emit:

```text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise task-specific rationale>
```

No task tool call may precede this declaration. A later declaration may only escalate after
newly observed risk is recorded; never silently downgrade.

## Route selection

Do not use `solo` as a catch-all merely because delegation is optional.

- `solo`: use for very small changes, tasks where delegation overhead is larger than the work,
  architecture/planning/requirement resolution, coding-light work, or work the primary can
  clearly complete more simply itself.
- `delegate` -> Luna / Max: prefer this when the primary has resolved the requirements and can
  provide a bounded, fully specified, interface-stable, low-risk implementation contract.
  Typical examples include a clear function addition, routine tests, a small-to-medium
  refactor with settled interfaces, a clear bug fix, or specified multi-file edits.
- `delegate` -> Terra / High: use when implementation is judgment-heavy, architecture-sensitive,
  context-heavy, high-risk, or wide in blast radius, or when a Luna result reveals that the work
  was misclassified.
- `audit`: primary implements and verifies, then a fresh read-only Sol / High reviewer inspects
  the accumulated change set.
- `full`: broad or high-risk exception. One selected implementer executes the settled
  specification, the primary verifies, then a fresh read-only Sol / High reviewer reviews.

When route choice is unclear because requirements are unresolved, resolve that ambiguity in the
primary session first. Do not resolve uncertainty by defaulting all coding to `solo`.

Auxiliary work must substitute for primary implementation, not duplicate it. If a worker
implements the change, the primary inspects the actual diff, checks changed-file scope, reruns
verification, and decides acceptance instead of reimplementing the same code.

## Preflight selected auxiliaries only

Use the installed model-specific custom-agent profiles:

- `sol_advisor_luna_implementer` -> `gpt-6-luna` / `max`
- `sol_advisor_terra_implementer` -> `gpt-5.6-terra` / `high`
- `sol_advisor_sol_reviewer` -> `gpt-6.1-sol` / `high`, requested read-only sandbox

Preflight only roles selected by the declared route. Public spawn/details metadata is
authoritative when available; use the local runtime inspector only for fields omitted from
public metadata. Missing, conflicting, unavailable, or unobservable role/model/effort evidence
stops that auxiliary lane. Never silently substitute a role, model, or effort.

The role TOMLs own the model and effort pins. Do not attach per-spawn model or reasoning
overrides. If a host or caller supplies an explicit override, it must resolve to the exact same
role pin; a conflicting override invalidates the lane.

## Worker specification and parent verification

Every implementer prompt must contain OBJECTIVE, FILES AND OWNERSHIP, INTERFACES,
CONSTRAINTS, VERIFICATION, and the structured return contract in role-contracts.md.

Treat worker reports as claims. The primary must inspect the complete actual diff, confirm changed
file scope, rerun the requested checks, and evaluate artifact/runtime evidence before acceptance.
Verification evidence is required before completion.

A Luna result may justify escalation to Terra only when it reveals newly observed complexity,
risk, architectural sensitivity, context burden, or wider blast radius. A corrected Luna retry
is appropriate for a specification error but is not a prerequisite for Terra escalation.

## Fresh review

For `audit` and `full`, spawn a new `sol_advisor_sol_reviewer` after primary verification.
The reviewer requests `sandbox_mode = "read-only"`, but runtime policy can broaden the effective
sandbox. Accept a verdict only after checking observed role/model/effort and sandbox/permission
evidence as described in operations.md.

The reviewer returns exactly `ship`, `fix-first`, or `rethink` and never implements its
own fixes. Any implementation change invalidates the prior verdict and requires primary
re-verification plus a new fresh review.
