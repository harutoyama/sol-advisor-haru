# Maintainer playbook provenance

The files under `maintainer/` are manual repository-maintenance material. They are intentionally outside the Sol Advisor plugin distribution and are not automatic Agent Skills.

Source repositories were compared at these snapshots:

- `harutoyama/sleep_epilepsy_prototype` main: `f3dad68d439132351c202b9da6c638420a8f2643`
- `harutoyama/sleep_staging_CRNN_EEG` main: `7b4d581324a3e433127176ec484319316bd72b56`

Their `THIRD_PARTY_SKILLS.md` records were used to recover the pinned upstream source and license for each playbook.

| playbook | pinned upstream | upstream path | license | Sol Advisor adaptation |
| --- | --- | --- | --- | --- |
| karpathy-coder | `alirezarezvani/claude-skills@19392f7a08264ed00486a251f5b2098321771f94` | `engineering/karpathy-coder/skills/karpathy-coder/` | MIT | Retains the four principles and useful references. Removes installed Skill frontmatter and all assumptions that upstream scripts, slash commands, reviewer agents, or hooks exist. Adds Sol Advisor maintenance calibration. |
| ai-slop-cleaner | `Yeachan-Heo/oh-my-claudecode@5281b19e0d64f8e6dc6767f2130299a88af2dc71` | `skills/ai-slop-cleaner/SKILL.md` | MIT | Retains regression-safe, deletion-first cleanup. Removes OMC/Ralph/UI workflow and EEG/research-runtime specifics; protects Sol Advisor distribution, installer, runtime-evidence, routing, and compatibility boundaries instead. |
| improve-codebase-architecture | `mattpocock/skills@c55ee46073ed923f86ce59a5eb3b6d895095d1b7` | `skills/engineering/improve-codebase-architecture/SKILL.md` | MIT | Retains module depth, deletion test, locality/leverage, and evidence-based candidate ranking. Removes HTML/Tailwind/Mermaid output, automatic Skill calls, and CONTEXT/ADR mutation. |
| ponytail-review | `DietrichGebert/ponytail@e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156` | `skills/ponytail-review/SKILL.md` | MIT | Retains narrow diff-only overengineering review. Replaces research-data exclusions with Sol Advisor compatibility/distribution/safety exclusions. |
| code-review-and-quality | `addyosmani/agent-skills@c004a74784a08295d52749b04cda634125b9a581` | `skills/code-review-and-quality/SKILL.md` | MIT | Retains the five-axis final review and severity model. Removes web/SQL/UI and research-harness specifics; adapts checks to plugin distribution, routing, agent profiles, installer safety, provenance, and latest-head CI. |

## Karpathy references

The three files in `maintainer/karpathy-coder/references/` are derived from the version vendored by `sleep_epilepsy_prototype`, which records the same pinned `alirezarezvani/claude-skills` upstream. `anti-patterns.md` and `karpathy-principles.md` are kept without repository-specific rewrites. `enforcement-patterns.md` carries a short local warning because its upstream installation/hook examples are reference material only and must not be wired into Sol Advisor automatically.

## License files

Exact upstream MIT license texts at the pinned commits are retained under `maintainer/licenses/`:

- `alirezarezvani-claude-skills-MIT.txt`
- `yeachan-heo-oh-my-claudecode-MIT.txt`
- `mattpocock-skills-MIT.txt`
- `dietrichgebert-ponytail-MIT.txt`
- `addyosmani-agent-skills-MIT.txt`

No upstream executable scripts, hooks, slash commands, reviewer agents, or automatic loaders are included.
