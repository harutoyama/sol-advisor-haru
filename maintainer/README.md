# Maintainer playbooks

This directory contains **maintainer-only** guidance for improving and reviewing Sol Advisor itself.

These files are deliberately outside `.agents/skills/` and `plugins/sol-advisor/skills/`. They are not part of the plugin distribution surface and must not be added to plugin manifests, installer inputs, default prompts, `AGENTS.md` auto-loading rules, or other automatic discovery paths.

Each playbook uses `GUIDE.md` rather than a Skill entrypoint on purpose. A maintainer may open a guide explicitly for repository-maintenance work; normal Sol Advisor tasks must not load these playbooks automatically.

## Playbooks

- `karpathy-coder/`: assumption management, simplicity, surgical diffs, and goal-driven verification.
- `ai-slop-cleaner/`: regression-safe, deletion-first cleanup of AI-generated overengineering.
- `improve-codebase-architecture/`: evidence-based identification of shallow modules and speculative seams.
- `ponytail-review/`: diff-only review focused narrowly on unnecessary complexity.
- `code-review-and-quality/`: final five-axis review for correctness, simplicity, architecture, security, and performance.

Third-party provenance and license mapping are recorded in `THIRD_PARTY.md`.
