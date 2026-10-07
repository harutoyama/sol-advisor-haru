---
name: orchestration
description: "Codex-native Luna-first routing: GPT-6.1 Sol / High owns architecture, decomposition, integration, and acceptance while model-pinned Luna roles handle routine exploration, implementation, testing, and research by default; Terra and fresh Sol review are exceptions for judgment-heavy or high-risk work."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, decomposition,
integration, escalation decisions, and final acceptance. Default routine execution volume to
model-pinned Luna roles; keep Sol focused on decisions and acceptance rather than repeating work
that a bounded child can perform.

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
research_rationale: <why inline/delegated research is or is not worth its context and coordination cost>
```

`fanout` is `0` for `none`/`inline`, normally `1` for `luna`, and `2..5` only for `split`.
Delegatability changes also require `ROUTE UPDATE`: for example a newly self-contained workstream,
removed state coupling after a frozen snapshot, a new independent source family, Luna-discovered
judgment conflict, or a second substantial independent workstream. Never silently change research
routes. Implementation/review escalation still requires newly observed risk.

## Select the implementation/review route

Use **Luna-first routing**. The question is not "is this task simple enough for Luna?"; the question
is "is there a concrete reason this execution step must stay with Sol or move to Terra?"

- `solo`: reserve for genuinely tiny/localized work where delegation overhead is larger than the
  work, coding-light planning, or execution that cannot yet be bounded because architecture,
  security policy, breaking-interface decisions, data migration policy, or materially ambiguous
  requirements are still unresolved. Sol resolves those decisions first.
- `delegate`: default for non-trivial repository execution after the parent has settled the
  direction. Use Luna roles as needed:
  - `sol_advisor_luna_explorer` for repository mapping, call/data-flow tracing, relevant
    tests/configuration, and implementation-boundary discovery;
  - `sol_advisor_luna_worker` as the default writer for bounded implementation, including its
    local edit -> verify -> repair loop;
  - `sol_advisor_luna_tester` for reproduction, targeted verification, and regression evidence.
- `delegate` -> Terra / High only when the implementation itself remains judgment-heavy after Sol
  has settled architecture: e.g. complex cross-cutting tradeoffs, unusually context-heavy logic, or
  a risk profile that a Luna worker explicitly surfaces as outside its bounded execution contract.
- `audit`: Sol-owned implementation followed by a fresh Sol / High reviewer. Use only when the
  implementation must remain in the primary because of architecture/security/breaking-change
  ownership and independent final scrutiny is materially warranted.
- `full`: delegated implementation plus a fresh Sol / High final review for broad or high-risk
  changes. The writer is Luna by default and Terra only under the exception above.

For non-trivial multi-file work or cross-component debugging, normally delegate at least one Luna
role. Exploration is preferred before implementation when the relevant path is not already known.
Testing is preferred after implementation when behavior or regression risk is non-trivial. Do not
spawn roles mechanically when they add no evidence.

Independent read-only exploration/research workstreams should run in parallel when useful. Serialize
dependent work such as explore -> architecture decision -> worker -> tester -> final review.
Never assign overlapping write ownership to multiple workers without explicit parent partitioning.

## Select the research route

Research is orthogonal to `mode`; `mode: solo` does not prohibit a researcher. Route research
**workstreams, not whole tasks**.

Use a light decision rule:

1. No substantive research -> `none`.
2. Tiny lookup or evidence that repeatedly depends on live primary mutation/state -> `inline`.
3. Substantive self-contained read-only repository, log, documentation, Web, API, dependency, or
   version-specific investigation -> **default `luna` / fanout 1**.
4. If gathered evidence requires scientific/methodological adjudication, architecture-sensitive
   causal synthesis, or complex root-cause judgment, Luna returns the evidence/conflict and the
   primary Sol owns that judgment. Do not route research to Terra.
5. Two or more genuinely independent substantial questions -> `split`, normally fanout 2 and at
   most 5, using independent Luna researchers.

Result dependency is not a reason to keep research inline: the parent may wait for a Luna report.
File count alone is not a reason to split. Overall task risk alone is not a reason to use Terra.

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
  selected by the current Luna-first route.
- The role TOMLs own model and reasoning-effort pins. Do not attach per-spawn model or effort
  overrides. Missing, conflicting, unavailable, or unobservable role/model/effort evidence stops
  that auxiliary lane; rerouting must be explicit.
- Explorer and researcher roles are read-only and cannot spawn nested subagents. Worker and tester
  roles also cannot spawn nested subagents. The primary alone owns fanout and integration.
- Preserve only delegated-work-relevant active constraints in child packets. Do not copy entire
  skill bodies, catalogs, or parent history.
- A delegated explorer/researcher owns its investigation scope until return. The primary may
  spot-check decisive or suspicious evidence but should not repeat the complete investigation.
- A Luna worker owns its assigned implementation surface. The primary inspects the actual final
  diff and acceptance-critical evidence; it should not reimplement the same change or blindly rerun
  every local worker check. Required user/repository acceptance checks still belong to the primary.
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
