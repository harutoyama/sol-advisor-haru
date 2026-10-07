# Improve codebase architecture — maintainer guide

Adapted from `mattpocock/skills` at commit `c55ee46073ed923f86ce59a5eb3b6d895095d1b7`, after comparison with the versions in `sleep_epilepsy_prototype` and `sleep_staging_CRNN_EEG`.

The goal is to find architecture that makes Sol Advisor harder to understand or change and to reduce that friction. Do not invent a new architecture merely to run an architecture review.

## Vocabulary

- **module**: an implementation unit with a coherent responsibility;
- **interface**: what a caller must understand to use that module;
- **depth**: useful complexity hidden behind a small interface;
- **shallow module**: an interface almost as complex as its implementation;
- **seam**: a boundary separating implementations or responsibilities;
- **adapter**: a layer translating an external form into the repository's form;
- **locality**: how closely information needed for one concept is kept together;
- **leverage**: how much useful behavior a small interface provides.

### Deletion test

For a suspicious layer, ask: if it disappears, does complexity become concentrated in a more natural owner, or merely move elsewhere? The former is evidence that the layer may be shallow.

### Hypothetical seam rule

An interface, adapter, factory, or registry with one implementation and no current evidence of a second is speculative by default. "We may need another later" is not enough.

## Intentional Sol Advisor boundaries

Treat these as deliberate until evidence shows otherwise:

- root marketplace/repository metadata versus the `plugins/sol-advisor/` installable surface;
- orchestration policy documents versus custom-agent TOML profiles;
- installer mutation logic versus `--check`/runtime inspection;
- current role contracts versus compatibility-only profiles;
- primary routing policy versus regression fixtures that lock that policy;
- plugin manifest compatibility surfaces required by different plugin loaders;
- maintainer-only material under `maintainer/` versus distributed plugin content.

Do not collapse these merely because they create multiple files.

## Use when

- one concept requires bouncing through many files;
- wrappers, registries, adapters, or policy layers have accumulated;
- the same rule is expressed in multiple places with drift risk;
- AI-generated changes have produced architecture drift;
- a subsystem has become hard to verify or modify safely.

For a single diff focused only on excess complexity, use the narrower `ponytail-review` guide. For cleanup implementation, use the deletion-first workflow in `ai-slop-cleaner`.

## Process

### 1. Scope before scanning

Prefer recently changing or explicitly named areas. Do not redesign dormant code in anticipation of hypothetical future work.

### 2. Explore for friction

Look for shallow modules, pass-through wrappers, one-implementation abstractions, configuration or extension points without consumers, duplicated validation or routing policy, poor locality, and mixed distribution/runtime/maintenance responsibilities.

Apply the deletion test to each candidate.

### 3. Require current evidence

Base candidates on repository evidence: call sites, fixtures, manifests, tests, installer behavior, commit history, or actual supported compatibility requirements.

### 4. Report candidates before broad refactoring

For each candidate, record **Files**, **Current friction**, **Why shallow or speculative**, **Deletion/deepening proposal**, **Contracts to preserve**, **Expected benefit**, and **Evidence strength** (Strong / Worth exploring / Speculative).

Only Strong candidates should be default implementation targets. For Speculative candidates, explain why not changing them now is preferable.

## Anti-overengineering rules

- Do not add a reporting framework, diagram stack, or visualization dependency for the audit.
- Do not auto-edit unrelated documentation, ADRs, or agent instructions.
- Do not assume another Skill or sub-agent must exist.
- Do not create a second implementation to justify an abstraction.
- Do not judge architecture by file count, class count, or line count alone.
