# Ponytail review — maintainer guide

Adapted from `DietrichGebert/ponytail` at commit `e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156`, after comparison with the versions in `sleep_epilepsy_prototype` and `sleep_staging_CRNN_EEG`.

Review a diff only for **unnecessary complexity**. This pass does not replace correctness, security, or full final review, and it does not apply fixes.

## Finding format

Prefer one concise finding per line:

`<file>:L<start>-L<end>: <tag> <problem>. <replacement>.`

If line numbers are uncertain, name the function, section, or file instead of inventing numbers.

Tags:

- `delete:` dead code or unused behavior;
- `stdlib:` custom logic replaceable by the language standard library;
- `native:` logic replaceable by functionality already present in the repository/tooling;
- `yagni:` one-use abstraction, unused option, one-caller layer, or speculative extension point;
- `shrink:` control flow or transformation that can be expressed more directly;
- `dedupe:` repeated logic that should use an existing canonical implementation.

## Exclusions

Do not flag something merely because it adds lines when it is carrying a current contract, including fail-closed installer protections, runtime-evidence checks, documented compatibility profiles, routing regression fixtures, distinct plugin metadata required by supported formats, explicit model/effort/`fork_turns` pins, or separation of root maintainer material from plugin-distributed content.

A simplification finding against one of these needs a concrete alternative that preserves the same guarantee.

## Review rules

- Prioritize complexity introduced by the diff.
- Do not invent future requirements.
- "Reusable someday" does not justify a new abstraction.
- One implementation is a YAGNI signal unless the seam is an actual compatibility or trust boundary.
- Do not recommend a new dependency to save a few lines.
- Do not delete tests, assertions, safety checks, or explanatory comments merely to reduce size.
- Keep correctness/security/performance findings out of this pass; hand them to the full review instead.

## Examples

`plugins/sol-advisor/scripts/foo.py:build_roles: yagni: wrapper has one caller and only forwards the role list. Inline it into the canonical owner.`

`plugins/sol-advisor/scripts/verify.sh:dedupe: role-name validation duplicates the existing canonical loop. Reuse the existing list.`

## Ending

If findings exist, an estimated net deletion may be reported as a secondary signal. Never prioritize it over compatibility, safety, or clarity.

If the diff is already appropriately lean, conclude with `Lean already.`.
