# Karpathy Coder — maintainer guide

Adapted from `alirezarezvani/claude-skills` at commit `19392f7a08264ed00486a251f5b2098321771f94`, after comparison with the versions in `sleep_epilepsy_prototype` and `sleep_staging_CRNN_EEG`.

This is a manual maintainer playbook, not an installed Skill. Upstream scripts, slash commands, reviewer agents, and hooks are intentionally not vendored.

## Four principles

### 1. Think before coding

Do not silently choose among plausible interpretations.

- State material assumptions.
- Surface conflicting requirements or repository evidence.
- Prefer the simpler interpretation when it fully satisfies the task.
- Ask only when ambiguity blocks a safe decision; otherwise resolve bounded details from repository evidence.

### 2. Simplicity first

Implement the minimum structure required by the current task.

- Do not add features beyond the request.
- Do not add abstractions for one use case.
- Do not create configurability without a current consumer.
- Do not add defensive branches for impossible states unless a contract requires them.
- Prefer existing repository mechanisms over parallel ones.

The test is whether a senior maintainer would need fewer concepts to understand the result.

### 3. Surgical changes

Every changed line should trace to the maintenance goal.

- Do not reformat or rename adjacent code without need.
- Do not refactor unrelated files while touching a nearby issue.
- Match existing conventions unless the task is explicitly to change them.
- Remove dead imports or helpers introduced by the current change.
- Mention unrelated cleanup opportunities instead of folding them into the diff.

For Sol Advisor, do not casually alter routing policy, model pins, compatibility profiles, installer behavior, runtime-evidence checks, plugin metadata, or distribution layout when the requested change does not require it.

### 4. Goal-driven execution

Translate work into concrete acceptance checks before editing.

| Instead of | Define |
| --- | --- |
| "simplify the installer" | preserve fail-closed conflict handling and make the targeted case pass |
| "change routing" | name the routing invariant and regression fixture that must change |
| "update plugin metadata" | identify every manifest/version surface that must remain consistent |
| "refactor verifier" | run the same verifier before and after and preserve required checks |

For multi-step work, keep a short `step -> verification` plan and loop until the relevant checks pass.

## Sol Advisor calibration

Do not mistake deliberate boundaries for overengineering. Before simplifying, identify why each boundary exists:

- repository root versus `plugins/sol-advisor/` distribution surface;
- orchestration Skill versus custom-agent profiles;
- installer/check mode versus runtime inspection;
- current roles versus explicitly retained compatibility profiles;
- runtime evidence and fail-closed behavior versus convenience;
- duplicated plugin metadata required by supported plugin formats.

A boundary is removable only when the same compatibility or safety property remains demonstrably preserved.

## References

- `references/karpathy-principles.md`: source context and when to relax each principle.
- `references/anti-patterns.md`: before/after examples.
- `references/enforcement-patterns.md`: upstream enforcement ideas for reference only; do not install them automatically in this repository.

## When to relax

Use judgment for trivial, unambiguous edits. Broader changes are appropriate when the task explicitly requests a refactor, architecture change, or compatibility migration. The principles constrain accidental scope growth; they do not override the requested scope.
