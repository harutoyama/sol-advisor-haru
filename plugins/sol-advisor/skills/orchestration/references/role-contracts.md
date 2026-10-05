# Native Codex role contracts

Use these contracts with Sol Advisor's model-specific native custom agents. They do not launch a
nested Codex CLI or change the primary model.

For task-scoped preflight, runtime evidence, sandbox interpretation, and maintainer commands, use
[operations.md](operations.md).

## Selective route

Before the first task tool call, the primary emits:

```text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise task-specific rationale>
```

Do not treat `solo` as the automatic answer to every coding task. Use it for very small changes,
delegation-overhead cases, architecture/planning/requirement resolution, coding-light work, or
work plainly simpler in the primary. Prefer Luna / Max when routine implementation is bounded,
fully specified, interface-stable, and low-risk. Use Terra / High for materially harder or
higher-risk implementation. A route may only escalate after newly observed risk is recorded;
never silently downgrade.

Confirm GPT-6.1 Sol / High in the primary session before using auxiliaries. Preflight only the
roles selected by the route.

## Shared implementation contract

Every Luna or Terra prompt must contain all five sections:

```text
OBJECTIVE
<Observable outcome and why it matters.>

FILES AND OWNERSHIP
You own only:
- <exact file or module>

Preserve concurrent edits. Do not revert unrelated work or modify files outside ownership.

INTERFACES
- <Signatures, schemas, commands, behavior, or compatibility requirements.>

CONSTRAINTS
- <Repository rules, safety boundaries, excluded scope, and settled decisions.>

VERIFICATION
- Run: <exact command>
  Success: <concrete expected result>
- Inspect: <exact file, diff, or artifact>
  Success: <concrete expected evidence>

RETURN
IMPLEMENTATION REPORT
STATUS: complete | partial | blocked
OBJECTIVE: <one-line restatement>
CHANGES: <file-by-file summary from the actual diff>
VERIFIED: <exact commands and concrete evidence>
JUDGMENT CALLS: <material decisions or none>
GAPS: <unfinished work, ambiguity, or none>
```

The primary inspects the actual diff and reruns verification.

## Mode contracts

- `solo`: primary implements and verifies; no auxiliary.
- `delegate`: spawn exactly one Luna or Terra implementer; primary verifies; no fresh reviewer.
- `audit`: primary implements and verifies; spawn a fresh Sol reviewer; reviewer does not
  implement.
- `full`: broad/high-risk exception. Spawn one selected implementer, primary verifies, then
  spawn a fresh Sol reviewer.

Auxiliary work substitutes for primary implementation; it must not duplicate it.

## Luna / Max routine implementation

Use when the primary has already resolved requirements and the work is bounded, fully specified,
interface-stable, low-risk, and routine. The installed role pins `gpt-6-luna` at `max`.

Spawn exactly:

```text
agent_type: sol_advisor_luna_implementer
fork_turns: none
```

Do not attach per-spawn model or reasoning overrides. If the work reveals material judgment,
architecture sensitivity, context burden, high risk, or wide blast radius, stop and return that
evidence for Terra routing. A corrected Luna attempt is appropriate for a specification error but
is not a prerequisite for Terra.

## Terra / High higher-complexity implementation

Use for judgment-heavy, architecture-sensitive, context-heavy, high-risk, or wide-blast-radius
implementation, including risk revealed by a Luna result. The installed role pins
`gpt-5.6-terra` at `high`.

Spawn exactly:

```text
agent_type: sol_advisor_terra_implementer
fork_turns: none
```

Do not attach per-spawn model or reasoning overrides.

## Fresh Sol / High reviewer

Only for `audit` or `full`, after primary verification. The installed role pins
`gpt-6.1-sol` at `high` and requests `sandbox_mode = "read-only"`.

Spawn exactly:

```text
agent_type: sol_advisor_sol_reviewer
fork_turns: none
```

Do not attach per-spawn model or reasoning overrides. Observe the actual role, model, effort,
sandbox policy, and permission profile before accepting its verdict.

Prompt:

```text
ROLE
Act as the fresh final reviewer. Remain strictly read-only and do not implement fixes.

STATED GOAL
<requested outcome>

ACCUMULATED CHANGE SET
<allowed files plus complete diff, or explicit base/head revisions>

INTERFACES AND CONSTRAINTS
- <compatibility, repository rules, safety boundaries, excluded scope>

VERIFICATION EVIDENCE
- <command> -> <actual primary-session evidence>

REVIEW
Inspect correctness, completeness, regressions, scope discipline, interface preservation,
test adequacy, and material risk.

SOL REVIEW
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-based reason>
FINDINGS: <precise file references and required fixes, or none>
RESIDUAL RISK: <largest remaining risk, or none>
```

A reviewer never fixes its own findings. Any implementation correction invalidates the prior
verdict and requires primary re-verification plus a new fresh reviewer.

Use observed isolation, not requested isolation. If the host broadens the sandbox, proceed only
when hard isolation is not required, the prompt forbids mutation, and the primary captures exact
before/after repository and artifact state. If isolation is unobservable, hard isolation is
required, or any mutation occurs, reject the review.
