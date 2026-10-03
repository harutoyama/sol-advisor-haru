# Native Codex role contracts

Sol Advisor uses capability-named custom agents. Model family names are not routing concepts.
The delegate profile is the only profile allowed to pin a concrete model. Escalation and audit
contain no concrete high-capability model slug; their spawns explicitly reuse the primary
session's resolved model and reasoning effort.

## Selective route

Before task tools:

```text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise task-specific rationale>
```

Solo is the default. A route changes only by escalation after newly observed risk is recorded.
Auxiliary work substitutes for primary work and must not duplicate it.

## Shared implementation packet

Every delegate or escalation prompt contains all five sections:

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
- `delegate`: spawn exactly one `sol_advisor_delegate_implementer`; primary verifies.
- `audit`: primary implements and verifies; spawn a fresh
  `sol_advisor_audit_reviewer` with explicit primary model/effort; reviewer does not implement.
- `full`: spawn one implementer, primary verifies, then spawn a fresh audit reviewer. Use
  `sol_advisor_delegate_implementer` only while implementation remains bounded; otherwise use
  `sol_advisor_escalation_implementer` with explicit primary model/effort.

## Delegate implementer

Use only for bounded, fully specified, low-risk, interface-stable work.

```text
agent_type: sol_advisor_delegate_implementer
fork_turns: none
```

Do not attach per-spawn model or reasoning overrides. The delegate custom-agent file owns the
single lightweight model pin. If the result reveals judgment-heavy, high-risk, context-heavy,
architecture-sensitive, or wide-blast-radius work, stop and escalate rather than stretching
the delegate contract.

## Escalation implementer

Use for judgment-heavy, high-risk, context-heavy, architecture-sensitive, or wide-blast-radius
implementation. Resolve the primary session's current model and effort first, then spawn:

```text
agent_type: sol_advisor_escalation_implementer
fork_turns: none
model: <primary-resolved-model>
reasoning_effort: <primary-resolved-effort>
```

The role TOML intentionally omits model and effort. Explicit spawn values are required because
user/project `agents.default_subagent_*` settings may otherwise reroute an omitted value.
If the primary values cannot be observed or the host cannot apply the explicit values, stop the
lane rather than substituting another capability.

## Fresh audit reviewer

Only for `audit` or `full`, after parent verification. Resolve the same primary values and
spawn:

```text
agent_type: sol_advisor_audit_reviewer
fork_turns: none
model: <primary-resolved-model>
reasoning_effort: <primary-resolved-effort>
```

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

AUDIT REVIEW
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-based reason>
FINDINGS: <precise file references and required fixes, or none>
RESIDUAL RISK: <largest remaining risk, or none>
```

The reviewer TOML requests read-only sandboxing. Runtime overrides may broaden the effective
sandbox, so use observed isolation, not requested isolation. Confirm the spawned model and
effort equal the primary values. Any fix invalidates the verdict and requires a new fresh audit.
