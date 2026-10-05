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

The primary task is expected to run on `gpt-6.1-sol` with `high` reasoning. The skill does not
change that model.

| Role type | Model | Effort | Operational use |
|---|---|---|---|
| `sol_advisor_luna_implementer` | `gpt-6-luna` | `max` | Delegate/full routine implementation |
| `sol_advisor_terra_implementer` | `gpt-5.6-terra` | `high` | Delegate/full higher-complexity implementation |
| `sol_advisor_sol_reviewer` | `gpt-6.1-sol` | `high` | Audit/full fresh review; requests read-only sandbox |
| `sol_advisor_luna_researcher` | `gpt-6-luna` | `high` | Bounded/focused read-only research; nested agents disabled |
| `sol_advisor_terra_researcher` | `gpt-5.6-terra` | `high` | Judgment-heavy read-only research; nested agents disabled |

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
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-implementation
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role terra-implementation
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role sol-review
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-research
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role terra-research
```

| Implementation/review route | Required companion checks |
|---|---|
| solo | None for implementation/review |
| delegate (Luna) | `--check --check-role luna-implementation` |
| delegate (Terra) | `--check --check-role terra-implementation` |
| audit | `--check --check-role sol-review` |
| full (Luna) | `--check --check-role luna-implementation --check-role sol-review` |
| full (Terra) | `--check --check-role terra-implementation --check-role sol-review` |

Research adds its own independent check:

| Research route | Required companion check |
|---|---|
| none / inline | None |
| luna | `--check --check-role luna-research` |
| terra | `--check --check-role terra-research` |
| split | one check per selected dedicated researcher role |

Unknown roles fail before mutation. Cache a successful check only for the current task. Missing,
conflicting, unavailable, or unobservable role/model/effort evidence stops that lane rather than
triggering a silent substitute.

## 0.7.0 capability-role migration

Haru fork 0.7.0 installed these obsolete role names:

- `sol-advisor-delegate-implementer.toml`
- `sol-advisor-escalation-implementer.toml`
- `sol-advisor-audit-reviewer.toml`

The 0.101.0 installer treats any of them as a migration hazard and stops before changing the
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

Accepted routing evidence is Luna / max for routine implementation, Terra / high for
higher-complexity implementation, GPT-6.1 Sol / high for audit/full review, Luna / high for bounded
research, and Terra / high for judgment-heavy research. If public and local evidence both exist,
they must agree. The inspector is evidence, not a model-selection fallback.

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
actual diff, confirm changed-file scope, rerun the requested checks, and evaluate required
artifact/runtime evidence. If evidence conflicts with the selected role/model/effort or shows an
unauthorized mutation, reject that auxiliary result and reroute only through an explicit valid lane.

## Maintainer verification

From the repository root:

```sh
sh plugins/sol-advisor/scripts/verify.sh
git diff --check
git status --short
git diff --stat
```

The verifier checks the 0.101.0 manifests, exact five-role set, implementation/research model and
effort pins, researcher read-only/nested-delegation constraints, root routing invariants,
progressive-disclosure ownership, reference reachability, installer fresh install,
0.100.0 -> 0.101.0 update behavior, 0.7.0 migration safety, JSON/TOML/YAML/shell syntax, and
implementation plus research runtime fixtures.
