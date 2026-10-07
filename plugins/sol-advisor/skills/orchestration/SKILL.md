---
name: orchestration
description: "Codex-native Sol-led routing: GPT-6.1 Sol owns architecture, integration, and acceptance; bounded Luna roles are preferred for substantial independently assignable workstreams; Terra and fresh Sol review remain explicit exceptions."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, decomposition,
integration, escalation decisions, and final acceptance. Prefer Luna for any substantial bounded
workstream that can be instructed independently; keep tiny/localized, strongly live-state-coupled,
or unresolved judgment work in Sol. Parent integration and acceptance do not make delegation
additive. Do not run the same investigation or implementation in both parent and child.

This root file is the canonical owner of route selection and cross-route invariants. Keep it in
context whenever the skill triggers. Load supporting references only when the selected route or
an operational task requires their detailed contracts.

## Primary effort gate and route declaration

Start the primary Codex task on `gpt-6.1-sol` / `high` by default. The skill does not change the
primary model or reasoning effort inside an active task/session. Before the first task tool call,
classify the whole task once using only the user's request and already-available context; do not
inspect the repository, research external sources, spawn auxiliaries, or begin implementation first.

Emit:

```text
PRIMARY EFFORT
primary_effort: medium-recommended | high
effort_rationale: <concise task-specific reason>
```

Choose `medium-recommended` only when all material conditions are true: requirements and interfaces
are sufficiently resolved; architecture is stable; root-cause analysis is absent or bounded; blast
radius is contained; changes are reversible; security, privacy, data-loss, migration, and production
risk are low; failure/retry cost is modest; and final acceptance is routine. Ordinary planning,
routine verification, normal code review, multi-step tool use, or a typical bounded implementation
does not by itself justify staying on High.

Keep `high` when any material condition applies: architecture or requirement ambiguity that needs
judgment; complex root-cause analysis with multiple plausible layers; wide or cross-system blast
radius; irreversible, security-sensitive, privacy-sensitive, data-loss, migration, or production
risk; expensive failure/retry or rollback; or acceptance whose error cost is materially high. When
uncertain because the missing information itself is consequential, keep High.

If the gate says `medium-recommended` and runtime metadata does not already confirm
`gpt-6.1-sol` / `medium`, return only a short instruction to restart this same task with GPT-6.1
Sol / Medium and invoke Sol Advisor again. Stop before task tools. Do not attempt an in-session
effort update. If the gate says `high`, require GPT-6.1 Sol / High before task tools. On a fresh
Medium task, rerun the gate; proceed only when it again says `medium-recommended`. Verify
model/effort from runtime metadata when available; if required fields are unavailable, ask the user
to confirm the required primary configuration. Any observed mismatch is fail-closed.

After the required primary configuration is confirmed, emit:

```text
SELECTIVE ROUTE
primary_effort: medium | high
mode: solo | delegate | audit | full
research: none | inline | luna | split
fanout: 0 | 1 | 2 | 3 | 4 | 5
risk: <concise task-specific rationale>
research_rationale: <why this research route matches scope, independence, and live-state coupling>
```

`fanout` is `0` for `none`/`inline`, normally `1` for one delegated workstream, and `2` only when two substantial workstreams are genuinely independent. `3..5` is exceptional and requires an explicit reason each added child cannot be bundled or deferred.
Delegatability changes also require `ROUTE UPDATE`: for example a newly self-contained workstream,
removed state coupling after a frozen snapshot, a new independent source family, Luna-discovered
judgment conflict, or a second substantial independent workstream. Never silently change research
routes. Implementation/review escalation still requires newly observed risk.

## Select the implementation/review route

Use **Sol-led bounded delegation**. Prefer Luna whenever a substantial bounded workstream can be
instructed independently with a clear objective, ownership, stop conditions, and acceptance
evidence. Parent integration, actual-diff inspection, and acceptance-critical verification are not
delegation contraindications. Keep work in Sol when it is tiny/localized, strongly live-state
coupled, or cannot yet be bounded because architecture, security, interface, migration, or material
requirements remain unresolved. Do not choose `solo` merely because it seems faster or delegation
has overhead when a substantial bounded workstream exists.

- `solo`: use for tiny/localized work, strongly sequential or live-state-coupled execution, and
  work that cannot yet be bounded because architecture, security policy, breaking-interface
  decisions, migration policy, or materially ambiguous requirements remain unresolved.
- `delegate`: prefer the matching Luna role for a substantial bounded workstream that can be
  independently instructed. Choose only the role that owns that distinct workstream:
  - `sol_advisor_luna_explorer` for repository mapping, call/data-flow tracing, relevant
    tests/configuration, and implementation-boundary discovery;
  - `sol_advisor_luna_worker` for bounded implementation with its local
    `edit -> verify -> repair` loop;
  - `sol_advisor_luna_tester` for reproduction, targeted verification, and regression evidence.
- `delegate` -> Terra / High only when the implementation itself remains judgment-heavy after Sol
  has settled architecture: e.g. complex cross-cutting tradeoffs, unusually context-heavy logic, or
  a risk profile that a Luna worker explicitly surfaces as outside its bounded execution contract.
- `audit`: Sol-owned implementation followed by a fresh Sol / High reviewer. Use only when the
  implementation must remain in the primary because of architecture/security/breaking-change
  ownership and independent final scrutiny is materially warranted.
- `full`: delegated implementation plus a fresh Sol / High final review for broad or high-risk
  changes. The writer is Luna by default and Terra only under the exception above.

Do not mechanically chain explorer -> worker -> tester. Use only stages that own a distinct bounded
workstream. Use the Luna tester for bounded independent verification rather than inventing a
separate Luna review lane.

Independent read-only exploration/research workstreams may run in parallel when useful. Serialize
dependent work such as explore -> architecture decision -> worker -> tester -> final review.
Never assign overlapping write ownership to multiple workers without explicit parent partitioning.

## Select the research route

Research is orthogonal to `mode`; `mode: solo` does not prohibit a researcher. Route research
**workstreams, not whole tasks**.

1. No substantive research -> `none`.
2. Tiny lookup or evidence that repeatedly depends on live primary mutation/state -> `inline`.
3. Prefer `luna` / fanout 1 for any substantive, self-contained, read-only workstream. Parent
   synthesis, result dependency, or handoff overhead alone is not a reason to keep such research
   inline.
4. If gathered evidence requires scientific/methodological adjudication, architecture-sensitive
   causal synthesis, or complex root-cause judgment, Luna returns the evidence/conflict and the
   primary Sol owns that judgment. Do not route research to Terra.
5. Use `split` for two genuinely independent substantial questions. Fanout 3..5 is exceptional and
   requires distinct scope plus material marginal benefit for every additional researcher.

Result dependency is not a reason to keep research inline: the parent may wait for a Luna report.
File count or task size alone is not a delegation reason.

Every delegated research packet remains self-contained and bounded. Prefer authoritative sources,
return compact evidence, and avoid sending large raw logs or whole files back to the parent.
The primary spot-checks decisive or suspicious evidence instead of repeating the entire delegated
investigation.

## Cross-route invariants

- All auxiliary spawns use the exact selected Sol Advisor custom-agent profile and
  `fork_turns: none`. The current routing profiles are `sol_advisor_luna_explorer`,
  `sol_advisor_luna_worker`, `sol_advisor_luna_tester`,
  `sol_advisor_luna_researcher`, `sol_advisor_terra_implementer`, and
  `sol_advisor_sol_reviewer`. `sol_advisor_luna_implementer` and
  `sol_advisor_terra_researcher` remain installed only for backward compatibility and are not
  selected by the current route.
- The role TOMLs own model and reasoning-effort pins. Do not attach per-spawn model or effort
  overrides. Missing, conflicting, unavailable, or unobservable role/model/effort evidence stops
  that auxiliary lane; rerouting must be explicit.
- Explorer and researcher roles are read-only and cannot spawn nested subagents. Worker and tester
  roles also cannot spawn nested subagents. The primary alone owns fanout and integration.
- Preserve only delegated-work-relevant active constraints in child packets. Do not copy entire
  skill bodies, catalogs, or parent history.
- Delegation is substitution, not addition. Once a scope is assigned, the primary does not perform
  the same investigation or implementation in parallel or repeat it after return except for narrow
  acceptance-critical spot-checks. Primary integration, actual-diff inspection, and
  acceptance-critical verification are not duplicate execution. Reuse the child's compact evidence.
- Normal active auxiliary fanout is `0-1`. Use `2` only for genuinely independent substantial
  surfaces. Fanout `3+` is exceptional and requires explicit marginal-value justification.
- Each child is one-shot: spawn -> report -> terminate. Use at most one follow-up to the same child,
  only for a concrete missing fact or clarification; otherwise integrate, reroute, or finish.
- Before any new spawn, reserve enough primary capacity for integration, actual-diff/evidence
  inspection, acceptance-critical verification, and the final response. If that completion reserve
  is doubtful, stop spawning and converge from existing evidence.
- A Luna worker or tester should stop rather than self-expand when it encounters unresolved
  architecture, security-sensitive design, breaking API/schema changes, dependency additions, data
  migration policy, cross-owner conflicts, or materially ambiguous requirements.
- A Luna result may justify Terra only when it returns concrete evidence that the bounded execution
  contract is insufficient. Terra is an exception, not the default for merely multi-file work.
- Fresh Sol review is a high-risk final gate, not a routine stage. When used, spawn a new reviewer
  only after primary integration/verification. The reviewer is read-only by contract, returns
  `ship`, `fix-first`, or `rethink`, and never fixes its own findings. Any implementation
  change invalidates the prior verdict.
- Reviewer and read-only-role acceptance uses observed sandbox/permission evidence, not requested
  configuration alone.

## Load supporting references only when needed

Keep progressive disclosure. Read only the detailed contract for a role that the selected route
actually uses.

- For Luna exploration, worker implementation, Luna testing, Luna research, Terra implementation,
  or fresh Sol review, read the corresponding section in
  [references/role-contracts.md](references/role-contracts.md) plus only the relevant task-scoped
  preflight/runtime-evidence or isolation section in
  [references/operations.md](references/operations.md).
- For installation, migration, release, manifest, or maintainer work, read only the applicable
  sections of [references/operations.md](references/operations.md).
- For a truly trivial `solo + inline` task with no auxiliary lane, this root contract is
  sufficient.

Do not load unrelated role or operations sections merely because they exist.
