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
research: none | inline | luna | terra | split
fanout: 0 | 1 | 2 | 3 | 4 | 5
risk: <concise task-specific rationale>
research_rationale: <why this research lane is worth its context/coordination cost>
```

`mode` controls implementation/review only; research is orthogonal, so `solo` may still use a
researcher. Do not treat `solo` as the automatic answer to every coding task. Use it for very small changes,
delegation-overhead cases, architecture/planning/requirement resolution, coding-light work, or
work plainly simpler in the primary. Prefer Luna / Max when routine implementation is bounded,
fully specified, interface-stable, and low-risk. Use Terra / High for materially harder or
higher-risk implementation. A route may only escalate after newly observed risk is recorded;
never silently downgrade.

Confirm GPT-6.1 Sol / High in the primary session before using auxiliaries. Preflight only the
roles selected by the route.

## Research routing contract

Research defaults to the primary unless delegation has a clear payoff. Evaluate task independence,
expected raw-context volume, handoff cost, result size, parallel speed/coverage benefit, and
coordination overhead. More subagents are not automatically more efficient.

- `none`: no research is needed.
- `inline`: primary performs the lookup/inspection directly. Prefer this for short or strongly
  sequential investigation, few-file checks, or handoffs that require most of the parent context.
- `luna`: exactly one `sol_advisor_luna_researcher` for bounded, self-contained, evidence-heavy
  exploration that can return a compact summary.
- `terra`: exactly one `sol_advisor_terra_researcher` for conflict resolution, methodological or
  scientific judgment, architecture-sensitive investigation, or complex root-cause analysis.
- `split`: two to five substantial independent research workstreams. Bundle related small lookups;
  do not micro-shard one question per agent.

The primary alone owns fanout. Researchers may not spawn subagents. Every research spawn names one
of the dedicated researcher profiles and uses `fork_turns: none`.

Never use the generic `explorer`, `worker`, `default`, or silent parent-model inheritance as a
research fallback. If a dedicated profile is unavailable or routing evidence conflicts, stop the
lane. The primary may explicitly route-update to another dedicated lane or `inline`, but may not
silently substitute.

After an initial read-only inspection, an unexpectedly large or complex investigation may justify
an explicit `ROUTE UPDATE` from `none`/`inline` to `luna`, `terra`, or `split`. State the observed
reason before spawning. Silent research-route changes are forbidden.

## Shared research packet

Every researcher receives a self-contained packet with these semantic sections:

```text
QUESTION
<precise question>

SCOPE
<allowed files/systems/sources/hypotheses>

CONTEXT
<minimal facts needed; never the whole parent conversation>

EVIDENCE REQUIREMENTS
<required citations, file/line refs, commands, authoritative sources, or observations>

STOP CONDITIONS
<when to stop and return partial/blocked instead of broadening scope or implementing>

RETURN
RESEARCH REPORT
STATUS: complete | partial | blocked
QUESTION: <restated question>
FINDINGS: <short synthesis>
EVIDENCE: <compact supporting evidence>
CONFLICTS: <contradictory evidence or none>
GAPS: <unknowns or none>
```

Do not return raw file contents, long search logs, or unnecessary tool traces.

## Luna / High bounded research

Use for focused code exploration, log investigation, documentation/Web lookup, multi-file
inspection, or simple comparison. The installed role pins `gpt-6-luna` at `high`, requests
`sandbox_mode = "read-only"`, and disables multi-agent tools.

Spawn exactly:

```text
agent_type: sol_advisor_luna_researcher
fork_turns: none
```

Read only. Do not implement, mutate, commit, or spawn nested subagents. If the investigation
requires material methodology/architecture judgment or conflict resolution, stop with evidence so
the primary can explicitly route-update to Terra.

## Terra / High judgment-heavy research

Use for multiple-evidence conflict resolution, scientific/methodological judgment,
architecture-sensitive investigation, or complex root-cause analysis. The installed role pins
`gpt-5.6-terra` at `high`, requests `sandbox_mode = "read-only"`, and disables multi-agent tools.

Spawn exactly:

```text
agent_type: sol_advisor_terra_researcher
fork_turns: none
```

Read only. Do not implement, mutate, commit, or spawn nested subagents.

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

- `solo`: primary implements and verifies; no implementation/review auxiliary. A research auxiliary
  is still allowed when selected by the independent research route.
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
