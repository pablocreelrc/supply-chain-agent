# Supply Chain Agent

A Claude Code AI agent that operates as a **VP of Operations / Chief Operating Officer**. From a company brief, it builds an operational baseline, runs supply chain optimization, inventory and demand planning, capacity and throughput analysis, and ships decision-grade quantitative recommendations to executives — all routed automatically based on the brief.

## Quick start

This is a Claude Code plugin, not a standalone app. Setup is documented in two files; read them in order.

1. **`ONBOARDING.md`** — what you need installed before you start: Claude Code, git, the 1Password CLI (`op`), and a service account token Pablo sends via 1Password share.
2. **`INSTALL.md`** — the runbook Claude Code itself executes when you say "install this agent" inside the cloned repo. It walks through verifying `op` auth, creating `.env` from the template, validating the Langfuse pipeline end-to-end, and copying the slash command into your global Claude Code commands directory.

After install completes, run the agent with:

```bash
op run --env-file=.env -- claude
```

Then in Claude Code, run `/ai-agents-ops` to activate. **Never run plain `claude` from this folder** — without `op run`, the `op://` references in `.env` don't resolve and OTEL telemetry silently breaks.

## What the agent does

Full persona is in `CLAUDE.md` (auto-loaded when working in this directory). Four pillars:

- **A. Supply chain optimization** — network design (DC placement, lane optimization, multi-echelon inventory), routing, sourcing strategy, supplier rationalization, make-vs-buy, total landed cost
- **B. Inventory & demand planning** — demand forecasting (statistical + judgmental), safety stock, reorder-point models, ABC/XYZ classification, slow-mover analysis, S&OP cadence
- **C. Capacity & throughput** — capacity planning across labor, equipment, storage; bottleneck analysis (TOC), takt-time, line-balancing, queueing analysis
- **D. Operational baseline & intelligence** — full operational baseline from available data (mandatory first step for any new client; produces `clients/<slug>/baseline/` as the source of knowledge for every downstream skill)

Every deliverable is decision-grade, quantified, and presentable to executives or shippable to operations teams. There is no closed list of artifacts — the agent infers scope from the brief.

## Skills, workflows, and tools

Three files together describe everything the agent has access to:

- **`CATALOG.md`** — canonical inventory of skills and workflows. Skills auto-match on their frontmatter triggers; workflows chain skills for multi-step deliverables.
- **`references/tools.md`** — canonical inventory of tool integrations (Python data stack, Playwright, chrome-devtools, Context7, Google Workspace, Monday). Documents the two credential models (shared via 1Password vs BYO per-employee) and the graceful-degradation pattern when a tool isn't configured.
- **`.claude-plugin/marketplace.json`** — Claude Code plugin manifest. Generated from skill frontmatters; do not edit by hand.

## Observability

Every session emits OpenTelemetry traces to a shared Langfuse project (US region) tagged with the user's `USER_ID` (their GitHub handle) and `service.name=ai-agent-ops`. Captured: session lifecycle, tool names + durations, token counts, API costs, error events, model IDs. **Not captured:** prompt text, tool I/O bodies, file contents — all redacted by Claude Code default.

Credentials are 1Password references resolved at launch by `op run`. No secret values touch disk.

## Project structure

```
Supply Chain Agent/
├── README.md                       # You are here
├── CLAUDE.md                       # Agent persona + behavioral rules (auto-loaded)
├── ONBOARDING.md                   # Pre-install checklist for the user
├── INSTALL.md                      # Install runbook (Claude Code executes this)
├── CONTRIBUTING.md                 # PR-or-silence contract for contributors
├── CATALOG.md                      # Skill + workflow inventory
├── .env.example                    # op:// reference template (committed)
├── .env                            # Local copy with USER_ID etc. (gitignored)
├── .mcp.json                       # MCP server config (auto-loads in this dir)
├── .claude-plugin/marketplace.json # Plugin manifest (generated from skill frontmatters)
├── .github/                        # CODEOWNERS, PR template
├── commands/ai-agents-ops.md       # Slash command (thin persona activator)
├── skills/                         # Skill submodules: Supply-Chain-Pro, Business-Analytics-Pro
├── workflows/                      # Multi-step pipelines (created as needed)
├── references/                     # Domain knowledge + tools.md inventory
├── clients/                        # Per-client state (created on the fly, gitignored)
├── examples/                       # Before/after artifacts (organic, via PRs)
└── output/                         # Final deliverables (gitignored)
```

## Client files are created on the fly

No client files are pre-scaffolded. When a client comes up, the agent:

1. Runs the operational-baseline skill (mandatory first step) — produces `clients/<slug>/baseline/` with the process map, throughput by node, inventory turns, fill rate, on-time-in-full, cost-to-serve, and sector benchmarks.
2. Creates `clients/<slug>/profile.md` for additional info beyond what the baseline captures (stated goals, deadlines, contacts, contractual constraints).
3. Downstream work lives co-located: `clients/<slug>/models/` for spreadsheets / Python / R analysis, `clients/<slug>/decks/` for executive output.

All downstream skills (network design, safety-stock optimization, capacity modeling, S&OP design) READ FROM `clients/<slug>/baseline/` instead of guessing — so every recommendation is grounded in real operational data and quantified tradeoffs.

## Contributing

Read `CONTRIBUTING.md` first. The contract is **fix it or stay silent** — ship a PR, don't file issues, don't DM gripes about agent behavior. Every employee with repo access is expected to contribute fixes back rather than complain.
