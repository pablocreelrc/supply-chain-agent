<!--
  Read CONTRIBUTING.md before opening this PR. A PR that skips sections will be closed.
  Every field is required unless marked optional.
-->

## Summary

<!-- 1-2 lines: what this PR changes and why it matters. -->

## What changed

<!-- Bullet list of concrete changes. Skill edits, new files, renamed triggers, etc. -->

-
-

## Why (user problem)

<!-- Describe the problem from the user's perspective, not the code's. What was the agent doing wrong or failing to do? -->

## Before / after

<!--
  For skill edits: paste a short before/after diff of behavior (not the skill body itself).
  For new skills: paste the trigger phrases you tested and the agent's response to each.
  For reference/workflow additions: describe the scenario that now works that didn't before.
-->

**Before:**
```
```

**After:**
```
```

## Langfuse trace ID (optional)

<!-- If this PR fixes a behavior you observed in the wild, paste the Langfuse trace ID so the reviewer can reproduce. -->

## Checklist

- [ ] Branch named per the CONTRIBUTING.md convention
- [ ] Trigger phrases tested in a Claude Code session
- [ ] `CATALOG.md` updated if a skill was added
- [ ] `.claude-plugin/marketplace.json` updated if a skill was added
- [ ] `examples/` updated if applicable
- [ ] No references to `.env`, API keys, or client-specific data in committed files
- [ ] `OTEL_LOG_*` debug flags NOT added to any committed file
- [ ] No force-pushes after review started
