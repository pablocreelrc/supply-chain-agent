# Tools — Supply Chain Agent

Canonical inventory of integrations available to the agent. **This file lists persistent operational state only — credentials, auth flows, MCP names, constraints, costs.** Individual capabilities (specific MCP tools or plugin skills) are NOT enumerated because they auto-discover on connection or session start.

## How this file is used

- **By the agent:** read at the start of any task to know what integrations are wired up.
- **By the user:** edited when you provision/deprovision an integration, change credentials, or update versions.
- **By config files:** every active integration here should also be wired in `.mcp.json` (MCPs), `.env` / `.env.example` (credentials), or installed as a Claude Code plugin.

If this file says an integration exists but the agent can't reach it, something's misconfigured. If an integration works but isn't listed, add it.

## Credential models

Two patterns coexist for tools in this file:

- **Shared via 1Password (`op://AI Agents/...`)** — for org-level shared accounts. Pablo provisions once; all employees consume read-only via the service account token. Used for paid data services and observability infrastructure.

- **BYO per-employee (raw value in local `.env`)** — for tools where each employee uses their own account. **Pablo does NOT provision or send these credentials.** Each employee creates their own account at the provider, generates their own credential, and pastes it into their own gitignored local `.env`. The credential never leaves the employee's machine.

**The classification is by tool nature, not preference:**
- If the agent acts as the org / consumes org data → shared via 1Password
- If the agent acts as the user / produces user-attributed work → BYO per-employee

## Graceful degradation when a tool isn't set up

The agent NEVER crashes or silently fails when a tool's credentials aren't configured. Before invoking any tool from this file, it checks:

1. **Is the credential present in the environment?** (resolved via `op run`, or set as a local env var by the employee)
2. **If not:** surface a clear message — "X isn't configured for this session. To enable, [point to the relevant section of `references/tools.md`]. Continuing without X for now." — and skip that capability gracefully.

Missing tools should reduce the agent's capability surface, not block its work entirely.

---

## Active integrations

### Data analysis & modeling

- **Python + pandas + numpy + scipy** — primary stack for any quantitative ops modeling (forecasting, simulation, optimization). Use `python` not `python3` on Windows. Standard imports: `import pandas as pd; import numpy as np; from scipy import optimize, stats`.
- **Jupyter / IPython** — for exploratory analysis. Save final notebooks alongside `clients/<slug>/models/` for handoff.
- **Excel** — final deliverable format for executive output. Use Shortcut.ai API via `shortcut_excel.py` for AI-generated models; use `openpyxl` to format existing data structures (per Pablo's global rule).

### QA & validation

- **Playwright** — cross-browser automation (Chromium, Firefox, WebKit). Use for scraping vendor portals, extracting structured data, validating dashboards.
  - MCP: `playwright` — no auth required.
- **chrome-devtools** — deep Chromium-specific access. Use for performance traces and network inspection of vendor portals.
  - MCP: `chrome-devtools` — no auth required.

### Research data

- **Context7** — current/live documentation for any library, framework, SDK, API, CLI tool, or cloud service.
  - MCP: `context7` — no auth required.
  - **Critical rule (always-on):** query Context7 EVERY TIME the agent works with a specific library, framework, SDK, API, or CLI — including well-known ones like pandas, scipy, NumPy. The agent's training data is months stale; Context7 returns the CURRENT docs. Skipping this introduces subtle bugs (deprecated methods, outdated config, removed flags). Treat Context7 as the first source of truth.

### Communication

- **Google Workspace** — Gmail drafts, Drive files, Calendar invites.
  - MCP: `google-workspace` — browser OAuth on first invocation.
  - Credentials: `op://AI Agents/Supply Chain Agent/google_client_id` + `google_client_secret` in `.env` (1Password vault item `Supply Chain Agent` must be populated by Pablo before this MCP works).

### Project management

- **Monday.com** — board / task tracking for client engagements and internal work.
  - MCP: `monday` — registered in `.mcp.json` using the official `@mondaydotcomorg/monday-api-mcp` package (npx, latest). Auto-loads when Claude Code opens this directory.
  - **Credential model: BYO (per-employee). Pablo does NOT send or provision this token.**
  - **Each employee provisions their own token:**
    1. Sign in at `monday.com` with their own account
    2. Click avatar (bottom-left) → Developers → My Access Tokens → Show
    3. Copy personal API token
    4. Paste into their local `.env` (gitignored) as a raw value: `MONDAY_TOKEN=<your-token>`. There's an entry for this in `.env.example` under the "BYO PER-EMPLOYEE" section, commented out by default.
  - The token never leaves the employee's machine. Pablo has no visibility into the boards.
  - If `MONDAY_TOKEN` isn't set, the MCP starts with empty credentials and fails gracefully when invoked.

---

## Optional integrations (commented out in `.env` until provisioned)

(none currently — populate as you add paid data services like SAP, Oracle, Snowflake connectors)

---

## Deprecated integrations

*(none currently)*

---

## How to add an integration

1. Add it to the appropriate section above with: name, integration type, auth method, credential path, cost/contract notes, any non-auto-discoverable constraints.
2. Wire credentials through 1Password (create or update the vault item) and reference via `op://...` in `.env.example`.
3. If MCP: register in `.mcp.json`.
4. If plugin: ensure it's installed in the user's Claude Code environment.
5. Update skills/workflows that should use it.

## How to remove an integration

1. Move its entry to the "Deprecated integrations" section with a one-line reason.
2. Remove from `.mcp.json` and `.env` references.
3. Audit skills/workflows that mention it and update them.
4. Rotate credentials at the provider, then delete from 1Password.
