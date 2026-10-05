---
name: orchestration
description: "Codex-native selective routing: Sol owns architecture and acceptance; model-pinned auxiliaries handle implementation, focused research, and selected fresh review only when their context/parallelism benefit exceeds coordination cost."
---

# Sol Advisor Orchestration

Act as the architect and primary owner. Own the user's intent, architecture, route choice,
decomposition, complete worker specifications, parent verification, escalation decisions, and
final acceptance.

This root file is the canonical owner of route selection and cross-route invariants. Keep it in
context whenever the skill triggers. Load supporting references only when the selected route or
an operational task requires their detailed contracts.

## Primary session and route declaration

Run the primary Codex session on `gpt-6.1-sol` with `high` reasoning. The skill cannot change the
primary model. Verify model/effort from runtime metadata when available. Before using any auxiliary
lane, stop if observed metadata conflicts; if those fields are unavailable, ask the user to confirm
GPT-6.1 Sol / High.

Before the first task tool call, emit:

```text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
research: none | inline | luna | terra | split
fanout: 0 | 1 | 2 | 3 | 4 | 5
risk: <concise task-specific rationale>
research_rationale: <why inline/delegated research is or is not worth its context and coordination cost>
```

`fanout` is `0` for `none`/`inline`, normally `1` for `luna`/`terra`, and `2..5` only for
`split`. Research routing may change when delegatability changes, not only when volume or complexity
grows. If inline work reveals a self-contained workstream, a frozen snapshot removes state coupling,
a new independent source family appears, Luna finds judgment-heavy conflict, or a second substantial
independent workstream appears, emit an explicit `ROUTE UPDATE` before rerouting. Implementation/review
mode escalation still requires newly observed risk. Never silently change a research route or silently
downgrade a mode.

## Select the implementation/review route

Do not use `solo` as a catch-all merely because delegation is optional.

- `solo`: use when implementation/review delegation is unnecessary: very small changes, work where
  delegation overhead dominates, architecture/planning/requirement resolution, coding-light work,
  or work plainly simpler in the primary.
- `delegate` -> Luna / Max: prefer when requirements are resolved and the primary can provide a
  bounded, fully specified, interface-stable, low-risk implementation contract.
- `delegate` -> Terra / High: use for judgment-heavy, architecture-sensitive, context-heavy,
  high-risk, or wide-blast-radius implementation, including complexity newly revealed by Luna.
- `audit`: primary implements and verifies, then a fresh Sol / High reviewer inspects the complete
  accumulated change set.
- `full`: broad or high-risk exception. One selected implementer executes the settled
  specification, the primary verifies, then a fresh Sol / High reviewer reviews.

Resolve unclear requirements in the primary before delegation. Do not default unresolved coding to
`solo` merely to avoid deciding the contract.

## Select the research route

Research is orthogonal to `mode`. `mode: solo` prohibits implementation/review auxiliaries, not a
research auxiliary. **Route research workstreams, not whole tasks.** Overall workflow sequencing is not
itself an inline reason.

A **result dependency** means the primary must wait for the research report before its next decision.
That is fan-in and remains delegatable. An **execution-state dependency** means useful research repeatedly
depends on primary-owned mutation, live system state, intervening primary judgment, or the result of
stop/resume/restart-like operations; keep that workstream inline.

Use this decision procedure in order:

1. **Need:** no substantive research -> `none`.
2. **Extract workstreams:** identify coherent units by evidence question, source family, and state
   ownership before choosing a route.
3. **Read-only gate:** if a workstream cannot complete without mutation -> primary `inline`.
4. **State-coupling gate:** execution-state coupling -> `inline`; result dependency alone does not.
5. **Packet test:** delegate only if QUESTION, SCOPE, minimal CONTEXT, EVIDENCE REQUIREMENTS,
   STOP CONDITIONS, and RETURN can make the workstream self-contained.
6. **Compression/scale test:** substantial code, logs, docs, or search evidence that can be compressed
   into a much shorter report creates delegation value.
7. **Payoff test:** require material benefit from at least one of context isolation/raw-context
   compression, latency, coverage, or fresh context. Parallelism is not required.
8. **Coordination-cost test:** if packet creation, preflight, report integration, and spot verification
   cost more than the work itself, keep it `inline`.
9. **Model/fanout:** use Luna / High for objective bounded evidence gathering; use Terra / High only
   when the delegated workstream itself needs conflicting-evidence adjudication, scientific or
   methodological judgment, architecture-sensitive causal analysis, or complex root-cause synthesis.
   One delegated workstream -> `luna` or `terra`, `fanout: 1`. Two or more -> `split` only
   when they are genuinely independent and splitting has material marginal benefit.

Route semantics:

- `none`: no substantive research.
- `inline`: tiny lookup, one or two targeted reads, small log check, non-self-contained handoff,
  execution-state-coupled work, or coordination overhead greater than delegation benefit.
- `luna`: exactly one delegated Luna research workstream. Primary-owned live/state-coupled research
  may coexist in the same task.
- `terra`: exactly one delegated judgment-heavy Terra research workstream. Primary-owned research
  may coexist; overall task risk alone does not justify Terra.
- `split`: two to five delegated research workstreams. The soft default is two. For every third or
  later researcher, require a distinct workstream, a reason it cannot be bundled into an existing
  researcher, and material marginal coverage or latency benefit. File count alone never justifies split.

Representative S8 case: live production state, process control, mutation decisions, and final judgment
remain primary-owned, while one bundled repository + frozen-log + successful-path trace is a bounded
Luna workstream. That is `research: luna`, `fanout: 1` even though the primary waits for the report.
Initial split or Terra is unnecessary unless new evidence justifies an explicit route update.

## Cross-route invariants

- All auxiliary spawns use the exact selected Sol Advisor custom-agent profile and
  `fork_turns: none`. Never fall back to generic `explorer`, `worker`, `default`, another generic
  agent, or silent parent-model inheritance.
- The role TOMLs own model and reasoning-effort pins. Do not attach per-spawn model or effort
  overrides. Missing, conflicting, unavailable, or unobservable role/model/effort evidence stops
  that auxiliary lane; rerouting must be explicit.
- Researchers are read-only. The primary alone owns research fanout.
- Researchers must not spawn nested subagents.
- A delegated research workstream has exclusive investigation ownership. The primary must not repeat
  the same full investigation; it may spot-check decisive, suspicious, or acceptance-critical evidence
  before using the report. Verification is not duplicate full investigation.
- Auxiliary implementation must substitute for primary implementation, not duplicate it. The primary inspects
  the complete actual diff, confirms changed-file scope, reruns required checks, evaluates
  artifact/runtime evidence, and decides acceptance. Verification evidence is required before
  completion.
- A Luna result may justify Terra only when it reveals newly observed complexity, risk,
  architectural sensitivity, context burden, or wider blast radius. A corrected Luna retry is
  appropriate for a specification error but is not required before Terra escalation.
- `audit` and `full` use a new fresh Sol reviewer only after primary verification. The reviewer is
  read-only by contract, returns `ship`, `fix-first`, or `rethink`, and never fixes its own findings.
  Any implementation change invalidates the prior verdict and requires primary re-verification plus
  a new fresh review.
- Reviewer acceptance uses observed sandbox/permission evidence, not the requested sandbox alone.

## Load supporting references only when needed

For an ordinary `solo + inline` task, do not read either supporting reference; this root contract is
sufficient unless the task itself concerns Sol Advisor installation, migration, maintenance, or
runtime evidence.

- When spawning a researcher, read only the shared research packet and the selected researcher
  section in [references/role-contracts.md](references/role-contracts.md). Also read only researcher
  isolation plus the relevant task-scoped preflight/runtime-evidence sections in
  [references/operations.md](references/operations.md).
- When `delegate` or `full` selects an implementer, read only the shared implementation contract and
  the selected implementer section in
  [references/role-contracts.md](references/role-contracts.md), plus the relevant preflight/runtime
  evidence sections in [references/operations.md](references/operations.md).
- When `audit` or `full` selects review, read the fresh reviewer contract in
  [references/role-contracts.md](references/role-contracts.md) and the reviewer isolation plus
  preflight/runtime-evidence sections in [references/operations.md](references/operations.md).
- For installation, migration, release, manifest, or maintainer work, read only the applicable
  sections of [references/operations.md](references/operations.md).

Do not load unrelated role or operations sections merely because they exist.
