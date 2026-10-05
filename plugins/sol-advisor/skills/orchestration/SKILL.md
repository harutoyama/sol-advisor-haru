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
`split`. A later read-only inspection may reveal materially more research volume or complexity than
expected. Before changing `none`/`inline` to `luna`, `terra`, or `split`, emit an explicit
`ROUTE UPDATE` with the observed reason. Implementation/review mode escalation still requires newly
observed risk. Never silently change a research route or silently downgrade a mode.

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
research auxiliary.

- `none`: no research is needed.
- `inline`: keep short lookups, few-file checks, strongly sequential investigation, or handoffs
  requiring most of the parent context in the primary.
- `luna`: use one bounded researcher for self-contained code/log/docs/Web investigation, multi-file
  inspection, or simple comparison where substantial raw evidence can be compressed into a short
  report.
- `terra`: use one judgment-heavy researcher for conflicting evidence, scientific or
  methodological judgment, architecture-sensitive investigation, or complex root-cause analysis.
- `split`: use only for at least two substantial independent workstreams. Default to one researcher;
  concurrent research fanout is capped at five. Do not micro-shard related lookups.

Before spawning, weigh task independence, expected raw-context volume, handoff cost, expected result
size, parallel speed or coverage benefit, and coordination overhead. More subagents are not
automatically more efficient.

## Cross-route invariants

- All auxiliary spawns use the exact selected Sol Advisor custom-agent profile and
  `fork_turns: none`. Never fall back to generic `explorer`, `worker`, `default`, another generic
  agent, or silent parent-model inheritance.
- The role TOMLs own model and reasoning-effort pins. Do not attach per-spawn model or effort
  overrides. Missing, conflicting, unavailable, or unobservable role/model/effort evidence stops
  that auxiliary lane; rerouting must be explicit.
- Researchers are read-only. The primary alone owns research fanout.
- Researchers must not spawn nested subagents.
- Auxiliary work must substitute for primary implementation, not duplicate it. The primary inspects
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
  section in [references/role-contracts.md](references/role-contracts.md). Also read the relevant
  task-scoped preflight/runtime-evidence sections in
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
