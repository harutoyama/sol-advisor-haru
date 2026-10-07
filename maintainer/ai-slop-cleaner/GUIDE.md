# AI slop cleaner — maintainer guide

Adapted from `Yeachan-Heo/oh-my-claudecode` at commit `5281b19e0d64f8e6dc6767f2130299a88af2dc71`, after comparison with the repository-local versions in `sleep_epilepsy_prototype` and `sleep_staging_CRNN_EEG`.

Use this guide manually when Sol Advisor code works but has accumulated duplicate logic, dead paths, speculative flexibility, unnecessary wrappers, or weakly verified cleanup debt. It is for simplification, not feature delivery.

## Priority

1. Explicit task requirements.
2. Existing repository contracts and compatibility guarantees.
3. Observed behavior, tests, fixtures, and verifier evidence.
4. Deletion-first cleanup.

Line-count reduction is not the objective. Preserve behavior, compatibility, safety, and verification.

## Do not classify these as slop without evidence

- separation between repository-only files and `plugins/sol-advisor/` distribution content;
- explicit model pins, reasoning effort, and `fork_turns` contracts;
- fail-closed installer checks for modified, symlinked, unknown, or obsolete agent profiles;
- runtime-evidence inspection that distinguishes configured intent from actual runtime state;
- regression fixtures that lock routing or effort-gate behavior;
- compatibility profiles intentionally retained for older installations;
- duplicate metadata surfaces required by distinct plugin formats;
- validation in `plugins/sol-advisor/scripts/verify.sh`.

Simplify one of these only when the replacement preserves the same property with less conceptual overhead.

## Cleanup principles

- Prefer deletion over addition.
- Do not add a dependency solely to make cleanup easier.
- Reuse the existing canonical helper or policy instead of creating a second one.
- Treat one-implementation interfaces, one-caller layers, unused options, and pass-through wrappers as YAGNI candidates.
- Do not add factories, registries, plugin systems, or configuration points for hypothetical future consumers.
- Keep cleanup separate from unrelated feature work.

## Workflow

### 1. Bound the scope

Limit the pass to the requested files, diff, or subsystem. For a broad audit, separate independent smells instead of rewriting the repository in one pass.

### 2. Protect behavior first

Identify the contracts that must remain unchanged. Read the relevant verifier checks, fixtures, installer behavior, manifests, and documentation before editing.

If the intended behavior is unclear, define a concrete verification plan before cleanup.

### 3. Classify the slop

Check for:

- **dead code**: unreachable branches, stale flags, unused compatibility shims with no supported consumer;
- **duplication**: repeated routing rules, manifest values, validation, or profile lists that should have one canonical source;
- **needless abstraction**: wrappers or helpers that only forward arguments and add no contract;
- **speculative flexibility**: options, extension points, or policy layers without a current consumer;
- **boundary leak**: plugin-distribution concerns mixed with maintainer-only or runtime-only concerns;
- **weak verification**: cleanup that changes behavior without a focused regression check.

### 4. Simplify in deletion-first order

1. Delete clearly dead code.
2. Consolidate true duplication into the existing natural owner.
3. Inline single-use abstraction or pass-through layers when they are not compatibility boundaries.
4. Simplify names, control flow, and error handling.
5. Add or strengthen tests only where needed to protect behavior.

Do not invent a new architecture to remove old architecture.

### 5. Validate

Run the repository-standard verifier and any targeted checks relevant to the touched surface.

```sh
sh plugins/sol-advisor/scripts/verify.sh
```

For pull requests, also require the latest-head GitHub Actions run to be green and inspect the actual diff.

### 6. Report

State scope, simplifications, preserved boundaries, verification evidence, and any complexity that remains with its reason.

## Review-only mode

When asked only to review cleanup opportunities, do not edit. For each high-confidence finding, give the location, unnecessary complexity, simpler replacement, and evidence that behavior can be preserved.
