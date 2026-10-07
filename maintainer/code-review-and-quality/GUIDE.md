# Code review and quality — maintainer guide

Adapted from `addyosmani/agent-skills` at commit `c004a74784a08295d52749b04cda634125b9a581`, after comparison with the repository-local versions in `sleep_epilepsy_prototype` and `sleep_staging_CRNN_EEG`.

Use this as the final maintainer review before merging a non-trivial Sol Advisor change. Passing tests are necessary but not sufficient. Review is read-only unless a separate fix pass is requested.

## Review order

### 1. Context

Confirm the task and intended scope, read the relevant plugin manifests, orchestration contract, agent profiles, scripts, fixtures, and tests, and check for unrelated changes.

### 2. Correctness

- Does implementation match requested behavior and documented routing/install contracts?
- Are boundary cases and failure paths handled where they matter?
- Do tests and fixtures verify behavior rather than implementation details?
- Are unexecuted checks clearly marked as unexecuted?
- If model, effort, role, or compatibility semantics changed, are all affected contracts updated consistently?

### 3. Readability and simplicity

Check direct control flow, repository-consistent naming, dead code, pass-through wrappers, one-use abstractions, speculative options, and whether a refactor actually reduces concepts rather than relocating them.

### 4. Architecture

- Respect repository-only versus `plugins/sol-advisor/` distribution boundaries.
- Keep orchestration policy, agent profiles, installer logic, runtime inspection, and verification in their natural owners.
- Avoid feature-specific logic leaking into general helpers.
- Avoid drift between duplicate role/routing declarations when a canonical source is appropriate.
- Require a real current consumer for new abstractions.

### 5. Security and operational safety

- No secrets, tokens, credentials, private paths, or unintended environment data in commits/logs.
- Installer changes remain fail-closed around modified files, symlinks, unknown conflicts, and destructive replacement.
- Shell/path handling is quoted and bounded.
- GitHub Actions use least required permissions and avoid unsafe secret exposure.
- External dependencies or copied material retain source and license provenance.

### 6. Performance

Check for repeated expensive process work, unnecessary runtime/network probes, unbounded scans, and optimization-driven complexity without measured need.

### 7. Verification

At minimum:

```sh
sh plugins/sol-advisor/scripts/verify.sh
```

For a pull request, verify GitHub Actions completed successfully for the **latest head SHA**, then confirm the head did not move after the successful run. Inspect the diff and confirm maintainer-only changes did not enter the plugin distribution tree unless explicitly requested.

## Finding severity

- **Critical**: security exposure, destructive installer behavior, broken distribution, or clearly incorrect routing/runtime behavior.
- **Required**: correctness, architecture, compatibility, provenance, or verification issue that must be fixed before merge.
- **Optional**: useful improvement that does not block this merge.
- **Nit**: cosmetic/editorial issue.

## Merge verdict

Recommend merge only when Critical findings are 0, Required findings are 0 or resolved, scope is clean, provenance/license obligations are satisfied, latest-head CI is green, and the diff matches the requested distribution boundary.
