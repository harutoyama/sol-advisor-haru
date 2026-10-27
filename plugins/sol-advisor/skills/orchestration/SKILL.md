---
name: orchestration
description: "Codex-native Sol-led orchestration using the user-selected primary model and effort; bounded Luna workstreams, fail-closed child verification, and direct judgment-based Terra or high-risk-only fresh Sol review."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, decomposition,
integration, routing, and final acceptance. Route independently bounded, well-specified routine
work to Luna / Max; route judgment-heavy implementation or research directly to Terra 6.1 / High
when complexity is evident at intake. Keep unresolved architecture, policy, integration, and
acceptance decisions with the primary. Do not duplicate delegated work.

This root file is the canonical owner of route selection and cross-route invariants. Keep it in
context whenever the skill triggers. Load supporting references only when the selected route or
an operational task requires their detailed contracts.

## Start immediately; route internally

Use the primary model and reasoning effort already selected by the user. Start the requested
work without a primary model/effort gate: do not ask for configuration confirmation,
wait for primary runtime metadata, request a Medium/High restart, or block task tools over
a primary configuration mismatch. Never change the user's primary settings as a prerequisite.

Assess scope, uncertainty, reversibility, security/privacy/data-loss/migration/production impact,
retry cost, and acceptance risk to choose delegation and verification depth—not to prescribe the
primary model or effort. Keep `mode: solo | delegate | audit | full`,
`research: none | inline | luna | terra | split`, `fanout: 0..5`, and task-specific risk
internally. Do not emit routine primary-effort or routing-status blocks, or pause for a
routing checkpoint. Explain only a material change of approach,
newly observed risk/conflict, required approval, or a consequential escalation. Re-evaluate
routing when evidence changes, without repeating an unchanged declaration.

`fanout` is 0 for none/inline, normally 1 for one bounded lane, and 2 only when
workstreams are materially independent. 3–5 is exceptional and needs distinct ownership
and marginal value for every additional child.

## Select the implementation/review route

Use **Sol-led judgment-based delegation**. First assess the judgment required by each
independent workstream and its risk. Select Luna / Max for clear, bounded routine tasks.
Select Terra 6.1 / High **directly** when implementation requires complex tradeoffs, difficult
root-cause analysis, scientific or methodological judgment, or evaluation of contradictory
evidence. Do not require a Luna attempt before Terra if difficulty is clear at intake.
File count and task size alone are not routing criteria. The primary retains final
architecture, interface, security, migration, integration, and acceptance decisions.

- `solo`: tiny/localized work, strongly sequential or live-state-coupled operations, or
  work whose parent-owned design and security decisions cannot yet be settled.
- `delegate`: select a role by judgment complexity and specific ownership:
  - `sol_advisor_luna_explorer` for bounded repository mapping, call/data-flow tracing,
    test/config lookup, and evidence collection;
  - `sol_advisor_luna_worker` for well-specified routine implementation within settled
    interfaces, including multi-file but straightforward changes;
  - `sol_advisor_luna_tester` for targeted tests, reproduction, and regression evidence;
  - `sol_advisor_terra_implementer` for judgment-heavy implementation, complex causal
    debugging, demanding design tradeoffs within a settled architecture, and high-risk logic.
    Choose it at intake when the complexity is already known, or explicitly reroute newly
    identified judgment-heavy scope after a Luna report.
- `audit`: primary-owned implementation with fresh Sol / High final review only under
  the existing high-risk independent-review condition.
- `full`: delegated implementation with a fresh Sol / High final review when the
  existing broad/high-risk review condition warrants it. The implementation worker is
  selected independently by judgment, not by the review decision.

Do not choose `solo` merely because it seems faster or delegation has overhead when a
substantial bounded workstream exists. Parent integration, actual-diff inspection, and
acceptance-critical verification are not delegation contraindications.

Do not mechanically chain explorer -> worker -> tester. Use only stages that own a distinct bounded
workstream. Use the Luna tester for bounded independent verification rather than inventing a
separate Luna review lane.

Independent read-only exploration/research workstreams may run in parallel when useful. Serialize
dependent work such as explore -> architecture decision -> worker -> tester -> final review.
Never assign overlapping write ownership to multiple workers without explicit parent partitioning.

## Select the research route

Research is orthogonal to `mode`; `mode: solo` does not prohibit a researcher. Route
research **workstreams, not whole tasks**, according to required judgment.

1. No substantive research -> `none`.
2. Tiny lookup or evidence tightly coupled to live primary mutation/state -> `inline`.
3. Bounded fact gathering, literature search, repository/log tracing, and ordinary
   evidence collation -> `luna` / fanout 1, even for substantial research scopes.
4. Scientific or methodological validation, ambiguous causal interpretation, and weighing
   conflicting sources requiring nontrivial judgment -> `terra` / fanout 1. Choose Terra
   6.1 / High directly when this is clear at intake. Terra synthesizes evidence and
   recommendations; the primary retains final scientific, architectural, and acceptance
   decisions.
5. `split` for genuinely independent substantial questions. Select Luna or Terra per
   child based on each question's judgment complexity; normally fanout 2, with 3–5
   exceptional and justified for distinct independent workstreams.

File count, task size, parent synthesis, or handoff overhead alone cannot determine
Luna versus Terra. A Luna report may trigger an explicit Terra reroute if it uncovers
judgment beyond the original bounded scope; a Luna trial is not a prerequisite.

Each research packet remains self-contained and bounded. Prefer authoritative evidence,
return compact synthesized findings, and avoid large file or log dumps. The primary
spot-checks decisive or suspicious evidence instead of repeating delegated work.

## Cross-route invariants

- All auxiliary spawns use the exact selected Sol Advisor custom-agent profile and
  `fork_turns: none`. The current routing profiles are `sol_advisor_luna_explorer`,
  `sol_advisor_luna_worker`, `sol_advisor_luna_tester`,
  `sol_advisor_luna_researcher`, `sol_advisor_terra_researcher`,
  `sol_advisor_terra_implementer`, and `sol_advisor_sol_reviewer`.
  `sol_advisor_luna_implementer` remains installed only for backward compatibility.
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
- Reuse resolved findings for the same question while evidence, inputs, code, environment, and
  execution conditions are unchanged. Reopen for new counterevidence, changed premises, or
  acceptance gaps; do not introduce persistent tracking.
- Normal active auxiliary fanout is `0-1`. Use `2` only for genuinely independent substantial
  surfaces. Fanout `3+` is exceptional and requires explicit marginal-value justification.
- Each child is one-shot: spawn -> report -> terminate. Use at most one follow-up to the same child,
  only for a concrete missing fact or clarification; otherwise integrate, reroute, or finish.
- Complete the user's requested endpoint, not merely the first patch, passing test, or child
  report. Continue through requested PR/CI/merge, but never perform unrequested actions or
  cross an approval boundary. If blocked, report the unmet endpoint and reason.
- Before any new spawn, reserve enough primary capacity for integration, actual-diff/evidence
  inspection, acceptance-critical verification, and the final response. If that completion reserve
  is doubtful, stop spawning and converge from existing evidence.
- A Luna worker or tester should stop rather than self-expand when it encounters unresolved
  architecture, security-sensitive design, breaking API/schema changes, dependency additions, data
  migration policy, cross-owner conflicts, or materially ambiguous requirements.
- Terra can be selected at intake for identified judgment-heavy work. A Luna result may
  justify rerouting only newly discovered complex scope; do not require a Luna trial.
  Terra is not selected merely because the task spans multiple files.
- Fresh Sol review is a high-risk final gate, not a routine stage. When used, spawn a new reviewer
  only after primary integration/verification. The reviewer is read-only by contract, returns
  `ship`, `fix-first`, or `rethink`, and never fixes its own findings. Any implementation
  change invalidates the prior verdict.
- Reviewer and read-only-role acceptance uses observed sandbox/permission evidence, not requested
  configuration alone.

## Load supporting references only when needed

Keep progressive disclosure. Read only the detailed contract for a role that the selected route
actually uses.

- For Luna exploration, worker implementation, Luna testing, Luna/Terra research,
  Terra implementation, or fresh Sol review, read the corresponding section in
  [references/role-contracts.md](references/role-contracts.md) plus only the relevant task-scoped
  preflight/runtime-evidence or isolation section in
  [references/operations.md](references/operations.md).
- For installation, migration, release, manifest, or maintainer work, read only the applicable
  sections of [references/operations.md](references/operations.md).
- For a truly trivial `solo + inline` task with no auxiliary lane, this root contract is
  sufficient.

Do not load unrelated role or operations sections merely because they exist.
