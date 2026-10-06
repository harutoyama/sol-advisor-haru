# Native Codex role contracts

This file owns the detailed prompt, execution, and return contracts for auxiliaries after the root
[`SKILL.md`](../SKILL.md) has selected a route. It does not choose or reinterpret the route.
For task-scoped preflight, runtime evidence, sandbox interpretation, migration, and maintainer
procedures, use [`operations.md`](operations.md).

Read only the sections named by the root progressive-disclosure rules.

## Shared research packet

Every researcher receives a self-contained packet instead of the parent conversation:

```text
QUESTION
<One precise question the researcher must answer.>

SCOPE
- <allowed files, systems, sources, or hypotheses>

CONTEXT
- <only the minimal facts needed to work independently>

ACTIVE CROSS-CUTTING CONSTRAINTS
- <compact delegated-work-relevant constraints active for this task, or none>

EVIDENCE REQUIREMENTS
- <what counts as evidence: file/line refs, commands, authoritative docs, reproducible observations>

STOP CONDITIONS
- <conditions that should return partial/blocked rather than broaden scope or implement>

RETURN
RESEARCH REPORT
STATUS: complete | partial | blocked
QUESTION: <restated question>
FINDINGS: <short synthesized findings>
EVIDENCE: <compact citations, file refs, commands, or observations>
CONFLICTS: <contradictory evidence or none>
GAPS: <unknowns, blocked areas, or none>
```

The constraint capsule is generic. Include only constraints the user explicitly invoked or loaded,
or that clearly govern task execution, and only the delegated-work-relevant subset. Do not depend
on a particular skill name or path, copy complete skill bodies, copy the available-skill catalog,
or copy parent history. An empty capsule is valid when no cross-cutting constraint applies.

### Researcher evidence retrieval invariant

- Budget total model-visible tool output across the workstream; per-command caps do not make
  aggregate output bounded.
- For unknown or potentially large sources, start with size/count/status, an index/summary, or
  filters. Then read only relevant files, symbols, or ranges and expand only when needed.
- Parallel tool execution is allowed, but never concatenate multiple raw results into one large
  model-visible payload.
- When bulky raw evidence must be retained, keep it in the source or an artifact when possible and
  return a summary plus precise evidence references rather than the raw body.
- If a tool reports truncation, narrow/filter the scope and retrieve again. Do not use truncation
  as the normal retrieval strategy.
- Preserve provenance and scientific evidence needed to support findings; compression must not
  erase the evidence trail.
- Keep the final return within the compact `RESEARCH REPORT` contract above.

Researchers are read-only: no implementation, mutation, formatting, fixes, commits, pushes, PR
actions, or nested delegation. Return synthesized evidence, not raw file contents, long search
logs, or unnecessary tool traces.

The delegated workstream is researcher-owned until its report returns. The primary may continue
separate live/state-coupled research, but it must not investigate the same delegated scope in
parallel or repeat the full investigation afterward. Before relying on a report, the primary may
spot-check or reproduce decisive, suspicious, or acceptance-critical evidence. That verification
is deliberately narrower than duplicate full investigation.

## Luna bounded researcher

When the root selects the bounded research lane, spawn:

```text
agent_type: sol_advisor_luna_researcher
fork_turns: none
```

The installed profile is `sol_advisor_luna_researcher`, pinned to `gpt-6-luna` / `max`. Stay inside
the supplied research packet. If the investigation requires material scientific, methodological,
architectural, or
conflict-resolution judgment beyond the bounded scope, stop and return the evidence and gap so the
primary can explicitly route-update.

## Terra judgment-heavy researcher

When the root selects the judgment-heavy research lane, spawn:

```text
agent_type: sol_advisor_terra_researcher
fork_turns: none
```

The installed profile is `sol_advisor_terra_researcher`. Stay inside the supplied research packet.
Resolve conflicting evidence explicitly and distinguish observation from inference. The return
must clearly separate OBSERVATIONS, INFERENCES, CONFLICTS, ALTERNATIVES, and GAPS (either inside
FINDINGS or as labeled subsections). Return partial/blocked when the question cannot be answered
inside scope.

## Shared implementation contract

Every Luna or Terra implementer prompt contains all five sections:

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

Worker reports are claims. The primary inspects the actual diff and reruns verification before
acceptance.

## Luna routine implementer

When the root selects Luna implementation, spawn:

```text
agent_type: sol_advisor_luna_implementer
fork_turns: none
```

The installed profile is `sol_advisor_luna_implementer`. Execute only the settled implementation
contract. If work proves judgment-heavy, architecture-sensitive, context-heavy, high-risk, or wide
in blast radius, stop and return that evidence for explicit Terra routing. A corrected Luna retry
is appropriate for a specification error but is not a prerequisite for Terra escalation.

## Terra higher-complexity implementer

When the root selects Terra implementation, spawn:

```text
agent_type: sol_advisor_terra_implementer
fork_turns: none
```

The installed profile is `sol_advisor_terra_implementer`. Execute only the settled implementation
contract and surface unresolved architecture or scope conflicts instead of silently broadening the
task.

## Fresh Sol reviewer

Only after primary verification for `audit` or `full`, spawn a new:

```text
agent_type: sol_advisor_sol_reviewer
fork_turns: none
```

The installed profile is `sol_advisor_sol_reviewer`. It remains read-only and never implements its
own findings. Use this prompt contract:

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
verdict and requires primary re-verification plus a new fresh reviewer. Accept the verdict only
under the observed isolation rules in `operations.md`.
