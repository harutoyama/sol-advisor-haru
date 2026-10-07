# Native operations

This page owns Sol Advisor's operational details: canonical packaging, exact model/effort pins,
task-scoped preflight, runtime evidence, sandbox interpretation, migration, and maintainer
verification. Route selection is owned by [`SKILL.md`](../SKILL.md); auxiliary prompt/return
contracts are owned by [`role-contracts.md`](role-contracts.md).

## Canonical plugin layout

The portable Agent Plugins manifest at `plugins/sol-advisor/plugin.json` is canonical.
`plugins/sol-advisor/.codex-plugin/plugin.json` remains as the Codex compatibility manifest.
The repo marketplace at `.agents/plugins/marketplace.json` points to `./plugins/sol-advisor`.

## Role pins and primary evidence

The primary task starts on `gpt-6.1-sol` / `high` by default. Before task tools, the root skill
performs its primary-effort gate. A `medium-recommended` decision may proceed only in a fresh
`gpt-6.1-sol` / `medium` task; a `high` decision requires `gpt-6.1-sol` / `high`. Runtime
metadata must match the gate before work starts. Missing or conflicting evidence is fail-closed.

Do not implement the gate by changing reasoning effort inside an active task/session. Current Codex
code has step-scoped reasoning-effort machinery on supported surfaces, but this workflow
intentionally treats primary effort as a task-start decision so one task has one primary effort and
one auditable runtime contract. The gate therefore redirects to a fresh task when the current
effort does not match.

| Role type | Model | Effort | Operational use |
|---|---|---|---|
| `sol_advisor_luna_explorer` | `gpt-6-luna` | `max` | Read-only repository exploration; nested agents disabled |
| `sol_advisor_luna_worker` | `gpt-6-luna` | `max` | Default routine implementation with local edit/verify/repair; nested agents disabled |
| `sol_advisor_luna_tester` | `gpt-6-luna` | `max` | Targeted verification and regression evidence; nested agents disabled |
| `sol_advisor_luna_implementer` | `gpt-6-luna` | `max` | Legacy 0.102.x implementation compatibility profile |
| `sol_advisor_terra_implementer` | `gpt-5.6-terra` | `high` | Judgment-heavy implementation exception |
| `sol_advisor_sol_reviewer` | `gpt-6.1-sol` | `high` | High-risk fresh final review; requests read-only sandbox |
| `sol_advisor_luna_researcher` | `gpt-6-luna` | `max` | Default substantive read-only research; nested agents disabled |
| `sol_advisor_terra_researcher` | `gpt-5.6-terra` | `high` | Legacy 0.102.x research compatibility profile |

Each custom-agent TOML pins its own model and reasoning effort. Do not attach per-spawn model or
reasoning overrides. Codex configuration can define `agents.default_subagent_model` and
`agents.default_subagent_reasoning_effort`. Explicit spawn values take precedence over those
defaults. This workflow uses role-pinned TOMLs and requires observed runtime evidence to match those
pins. If an explicit spawn override is present, it must match the role pin exactly; otherwise stop
the lane.

## Install and task-scoped preflight

Install or verify all shipped profiles:

```sh
sh plugins/sol-advisor/scripts/install-agents.sh
sh plugins/sol-advisor/scripts/install-agents.sh --check
```

Preflight only roles selected by the declared route. Selective checks are:

```sh
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-exploration
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-worker
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-testing
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role terra-implementation
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role sol-review
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-research
# legacy compatibility only:
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role terra-research
```

| Execution/review need | Required companion checks |
|---|---|
| trivial solo | None |
| Luna exploration | `--check --check-role luna-exploration` |
| Luna worker | `--check --check-role luna-worker` |
| Luna tester | `--check --check-role luna-testing` |
| Terra implementation exception | `--check --check-role terra-implementation` |
| high-risk fresh review | `--check --check-role sol-review` |
| legacy 0.102.x Luna implementation compatibility | `--check --check-role luna-implementation` |

Research adds its own independent check:

| Research route | Required companion check |
|---|---|
| none / inline | None |
| luna | `--check --check-role luna-research` |
| split | one `--check --check-role luna-research` check; fanout uses the same pinned Luna role |

Unknown roles fail before mutation. Cache a successful check only for the current task. Missing,
conflicting, unavailable, or unobservable role/model/effort evidence stops that lane rather than
triggering a silent substitute.

## 0.7.0 capability-role migration

Haru fork 0.7.0 installed these obsolete role names:

- `sol-advisor-delegate-implementer.toml`
- `sol-advisor-escalation-implementer.toml`
- `sol-advisor-audit-reviewer.toml`

The 0.103.0 installer treats any of them as a migration hazard and stops before changing the
destination. It never deletes them automatically. It reports whether each file is the exact known
0.7.0 regular file or a modified/unknown/unsafe file.

Known unmodified 0.7.0 SHA-256 values:

- delegate: `1594d2ac0fa527301b92afaf635a14a4e89b640d20f8673b6406d87298bc31c5`
- escalation: `85a257f74155ea717c4591acb3c24667d1498d5fbc3244029fda6290f7f080af`
- audit: `b11c1c8a9773cfbcb62fa855f7723bbf5fc9df4cf91a5c9dc2be2a01b898f597`

Only an exact known regular non-symlink file is safe for the operator to remove without further
content review. A different digest, symlink, non-regular file, or unreadable file must be inspected
manually.

## Runtime routing evidence

Public spawn/details metadata is authoritative when available. If it omits routing fields, use the
local inspector for the exact native thread:

```sh
skill_dir=<directory-containing-SKILL.md>
runtime_inspector="$skill_dir/../../scripts/inspect-agent-runtime.sh"
sh "$runtime_inspector" <native-subagent-thread-id>
```

Accepted routing evidence is Luna / max for explorer, worker, tester, and substantive bounded
research; Terra / high only for judgment-heavy implementation exceptions; and GPT-6.1 Sol / high
for fresh high-risk review. The legacy Luna implementer remains Luna / max and the legacy Terra
researcher remains Terra / high when explicitly used for compatibility. If public and local evidence both exist,
they must agree. The inspector is evidence, not a model-selection fallback.

## Explorer and researcher isolation

The explorer and researcher TOMLs request `sandbox_mode = "read-only"`, but requested configuration is not
proof of effective isolation. Check public runtime metadata or the local runtime inspector for the
actual child sandbox before trusting a read-only-role result.

- observed read-only sandbox: proceed;
- broader observed sandbox: proceed only when hard isolation is not required, the delegated read-only prompt
  still forbids all mutation, and the primary captures relevant before/after repository and artifact
  state;
- hard read-only required but sandbox unobservable or broadened: stop that read-only lane;
- any observed filesystem, repository, external-system, MCP, or app mutation: reject the result.

Filesystem sandboxing and external-tool permissions are separate controls. A read-only filesystem
sandbox does not prove that an MCP/app tool cannot mutate remote state, and tool annotations such as
read-only hints are not an authorization boundary. Read-only roles therefore remain prohibited from
external-system mutation regardless of filesystem sandbox state.

Do not invent undocumented role-local tool-allowlist TOML fields. Keep the current explorer/researcher TOMLs
unless a current OpenAI specification documents a role-local control whose effective behavior can
also be verified at runtime.

## Reviewer isolation

The reviewer TOML requests `sandbox_mode = "read-only"`. Runtime policy can still broaden the
effective child sandbox:

- observed read-only: proceed;
- broader observed sandbox: proceed only when hard isolation is not required, the prompt forbids
  mutation, and the primary captures exact before/after repository and artifact state;
- unobservable isolation, required hard isolation, or any mutation: stop and reject the review.

Never claim enforced read-only isolation from the TOML alone.

## Acceptance evidence

Auxiliary reports never replace direct primary inspection. Before acceptance, inspect the complete
actual diff, confirm changed-file scope, rerun required acceptance-critical checks, and evaluate
required artifact/runtime evidence. Do not mechanically replay every child-local check when its
compact evidence is sufficient and the check is not part of final acceptance. If evidence conflicts with the selected role/model/effort or shows an
unauthorized mutation, reject that auxiliary result and reroute only through an explicit valid lane.

## Maintainer verification

From the repository root:

```sh
sh plugins/sol-advisor/scripts/verify.sh
git diff --check
git status --short
git diff --stat
```

The verifier checks the 0.103.0 manifests, exact eight-role set, Luna-first explorer/worker/tester
pins and contracts, Terra/Sol exception lanes, research routing, read-only-role isolation and
external-mutation constraints, root/reference ownership,
regression fixtures, installer fresh install, 0.102.2 -> current update behavior, 0.7.0 migration
safety, JSON/TOML/YAML/shell syntax, and worker plus research runtime fixtures.
