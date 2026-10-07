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
research: none | inline | luna | terra | split
fanout: 0 | 1 | 2 | 3 | 4 | 5
risk: <concise task-specific rationale>
research_rationale: <why inline/delegated research is or is not worth its context and coordination cost>
```

`fanout` is `0` for `none`/`inline`, normally `1` for `luna`/`terra`, and `2..5` only for `split`.
Delegatability changes also require `ROUTE UPDATE`: for example a newly self-contained workstream,
removed state coupling after a frozen snapshot, a new independent source family, Luna-discovered
judgment conflict, or a second substantial independent workstream. Never silently change research
routes. Implementation/review escalation still requires newly observed risk.

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

Research is orthogonal to `mode`; `mode: solo` does not prohibit a researcher. **Route research
workstreams, not whole tasks.** Overall sequencing alone is not an inline reason.

- **result dependency**: primary waits for the report -> fan-in; still delegatable.
- **execution-state dependency**: useful research repeatedly needs primary mutation, live state,
  intervening judgment, or operation results -> `inline`.

Decide in order:

0. **Need:** no substantive research -> `none`.
1. **Extract:** coherent workstreams by evidence question, source family, and state ownership.
2. **Read-only:** mutation required -> `inline`.
3. **State coupling:** execution-state coupling -> `inline`; result dependency alone is not.
4. **Packet:** QUESTION, SCOPE, minimal CONTEXT, EVIDENCE REQUIREMENTS, STOP CONDITIONS, and RETURN
   must make the workstream self-contained.
5. **Compression:** substantial raw evidence compressible to a short report favors delegation.
6. **Payoff:** require material context isolation/raw-context compression, latency, coverage, or
   fresh-context benefit. Parallelism is not required.
7. **Cost:** if packet/preflight/integration/spot-verification cost dominates -> `inline`.
8. **Model:** Luna / Max for bounded objective gathering; Terra / High only when that delegated
   workstream itself needs evidence adjudication, scientific/methodological judgment,
   architecture-sensitive causal analysis, or complex root-cause synthesis.
9. **Fanout:** one delegated workstream -> `luna` or `terra`, `fanout: 1`; use `split` only for
   genuinely independent workstreams with material marginal benefit.

Semantics: `none` = no research; `inline` = tiny/targeted, non-self-contained, state-coupled, or
coordination-dominated work; `luna` = exactly one bounded delegated workstream; `terra` = exactly
one judgment-heavy delegated workstream. Luna/Terra may coexist with primary-owned live/state-coupled
research; overall task risk alone does not justify Terra. `split` = 2-5 delegated workstreams, soft
default 2. Each third-or-later researcher needs distinct scope, a reason bundling is inferior, and
material marginal coverage/latency benefit. File count alone never justifies split.

S8 regression: primary owns live production/control/mutation decisions; one bundled repository +
frozen-log + successful-path trace routes to Luna / 1. Waiting for it is result dependency.

## Cross-route invariants

- All auxiliary spawns use the exact selected Sol Advisor custom-agent profile and
  `fork_turns: none`. Never fall back to generic `explorer`, `worker`, `default`, another generic
  agent, or silent parent-model inheritance.
- The role TOMLs own model and reasoning-effort pins. Do not attach per-spawn model or effort
  overrides. Missing, conflicting, unavailable, or unobservable role/model/effort evidence stops
  that auxiliary lane; rerouting must be explicit.
- Researchers are read-only. The primary alone owns research fanout.
- Researchers must not spawn nested subagents.
- When delegated research must obey active cross-cutting execution constraints already applicable
  in the primary, preserve only the delegated-work-relevant subset as a compact constraint capsule
  in its research packet. Do not copy entire skill bodies, the available-skill catalog, or parent
  history.
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
