# Contributing

## The contract

Fix it or stay silent. If a skill fails you, a prompt confuses you, or a reference is wrong, your only channels are:

- **Ship a PR** that fixes the skill, adds a new one, or improves the workflow.
- **Propose a new skill** via a PR draft when the fix is a taxonomy question, not a code edit. Pablo and the AI lead weigh in before you invest.

No GitHub Issues. No feedback forms. No Slack DMs about agent behavior. The repo grows through code, not complaints.

## What to contribute

| Contribution | Where it lands | Review path |
|---|---|---|
| Skill edit (existing `.md` in `skills/`) | `skills/<name>.md` | AI lead reviews, Pablo merges |
| New skill | `skills/<new-name>.md` + `CATALOG.md` + `.claude-plugin/marketplace.json` | AI lead reviews, Pablo merges (taxonomy call, so propose first) |
| Workflow (pipeline chaining existing skills) | `workflows/<name>.md` | AI lead reviews, Pablo merges |
| Reference file (domain knowledge) | `references/<name>.md` | AI lead reviews, Pablo merges |
| Example output (before/after artifact) | `examples/<client-or-topic>/` | Either reviews, low-stakes |
| Agent persona / routing (CLAUDE.md) | `CLAUDE.md` | Pablo only |
| Infra (`.github/`, `.env.example`, `ONBOARDING.md`, this file) | Same | Pablo only |

## Branching

One branch per unit of work:

- Skill fix: `skill/<name>/<short-desc>` — e.g. `skill/safety-stock/fix-lognormal-edge-case`
- New skill: `feat/skill-<new-name>` — e.g. `feat/skill-multi-echelon-inventory`
- Workflow: `feat/workflow-<name>`
- Reference: `feat/ref-<name>`
- Anything else: `chore/<short-desc>`

Never commit directly to `main`. Branch protection blocks it anyway.

## PR flow

1. Push your branch, open a PR using the template.
2. Fill every section. A PR that says "fix stuff" gets closed.
3. Include a Langfuse trace ID if you're fixing behavior you observed in the wild.
4. Wait for review. AI lead reviews skills/workflows/references; Pablo merges.
5. When requested changes arrive, push more commits to the same branch (don't force-push).
6. Once approved and merged, delete your branch. Skills update on next clone or pull.

## Skill authoring

Follow the methodology in `../../Project Obsidian/design/flow-authoring-methodology.md` when creating anything reusable. Short version:

- Brainstorm first, don't code first.
- If the work deserves a spec, write one in `Project Obsidian/docs/superpowers/specs/` before the skill.
- The skill body stays under ~500 lines. Split references out, don't inline.
- Frontmatter: `name` + `description`. The description is how Claude Code routes — put 3+ trigger phrases in it.
- After merge, capture gotchas discovered in-use back into the skill's "Known Gotchas" section.

When in doubt about taxonomy — "should this be a new skill, or a branch on an existing one?" — open a PR draft with your proposal and tag Pablo before writing the body. A 5-minute alignment saves a rewrite.

## What NOT to do

- Don't add feature flags, TODO placeholders, or "for now" workarounds to skills. Fix it completely or don't touch it.
- Don't reference our internal clients, employees, or projects by name in skill bodies. Skills are client-agnostic library code; client context lives in `clients/<name>/`, which is generated at runtime and gitignored.
- Don't commit `.env`. It's gitignored — confirm with `git status` before every push.
- Don't enable `OTEL_LOG_USER_PROMPTS=1`, `OTEL_LOG_TOOL_DETAILS=1`, or `OTEL_LOG_TOOL_CONTENT=1` in `.env.example` or any committed file. These are debugging-only flags, set locally and never shared.

## When in doubt

Read an existing skill for tone and structure before authoring a new one. The Supply-Chain-Pro and Business-Analytics-Pro submodules under `skills/` contain the strongest references — see their respective `CATALOG.md` files for the full skill inventory.
