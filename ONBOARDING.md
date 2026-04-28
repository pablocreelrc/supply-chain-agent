# Onboarding — Supply Chain Agent

Welcome. This agent is a Claude Code plugin you run locally on your machine. Everything you produce stays on your machine; Pablo sees only behavioral telemetry (which skills you invoked, which MCP calls succeeded) via Langfuse, never your prompt content.

The install itself is driven by Claude Code — you tell Claude "install this agent" and it walks you through the rest. This page just lists what you need before you start, and what to do when something breaks.

## Prerequisites

- **Claude Code** installed and authenticated: https://claude.com/claude-code (any working Claude Code setup — your own Claude.ai subscription, a Teams seat, etc.)
- **git** on your PATH, plus a GitHub account.
- **1Password CLI (`op`)** — install per platform: macOS `brew install --cask 1password-cli`, Windows `winget install AgileBits.1Password.CLI`, Linux see https://developer.1password.com/docs/cli/get-started.
- **A 1Password service account token** (`ops_...`) — Pablo sends this via 1Password share after you accept the GitHub invite. The token gives the `op` CLI read access to the `AI Agents` vault, where the agent's secrets live.
- **`uv`** installed (Python package manager, used by the Google Workspace MCP). Install: https://docs.astral.sh/uv/getting-started/installation/. Skip if you don't plan to enable Google Workspace.
- **Python 3.11+** with `pandas`, `numpy`, `scipy` for quantitative modeling work. The agent assumes `python` (not `python3`) on Windows.

If you've never used git or Claude Code: read the respective docs first, then come back. This page assumes both are familiar.

## Onboarding flow

### 1. Accept the GitHub invite

Pablo sends the invite to the email on your GitHub account. Accept from your email or from `github.com/notifications`. You'll land in `pablocreelrc/supply-chain-agent` with Write access.

### 2. Set up your 1Password service account token

Pablo sends you a service account token (`ops_...`) via 1Password share after the GitHub invite. Set it as an environment variable so every shell sees it.

**macOS / Linux** — append to `~/.zshrc` (or `~/.bashrc`):
```bash
export OP_SERVICE_ACCOUNT_TOKEN="ops_..."
```
Then `source ~/.zshrc` or open a fresh terminal.

**Windows (PowerShell)**:
```powershell
setx OP_SERVICE_ACCOUNT_TOKEN "ops_..."
```
Close and reopen your PowerShell window — `setx` doesn't update the current shell.

Verify: `op whoami` should print your account URL and `User Type: SERVICE_ACCOUNT`. If it errors, the token is wrong or you're in the same shell that ran `setx`.

### 3. Clone the repo

```
git clone git@github.com:pablocreelrc/supply-chain-agent.git
cd supply-chain-agent
```

Or HTTPS if you haven't set up SSH:

```
git clone https://github.com/pablocreelrc/supply-chain-agent.git
cd supply-chain-agent
```

### 4. Run the install

From inside the repo directory:

```
claude
```

Then in the Claude Code session, type:

```
install this agent
```

Claude reads `INSTALL.md` and walks you through:
- Verifying `op` CLI is installed and your service account token works
- Verifying you have read access to the `AI Agents` vault and the `Langfuse` item exists
- Creating your `.env` from the template (the template uses `op://` references, so no secret values get pasted into files)
- Confirming your GitHub handle (becomes `user.id` on every trace)
- Validating end-to-end that `op run` resolves the Langfuse reference and the OTEL endpoint accepts the auth header
- Copying the `/ai-agents-ops` slash command into your global Claude Code commands
- Setting up the launch alias so you run the agent via `op run --env-file=.env -- claude` (or the alias) — never plain `claude` from this folder

This is interactive. Read what Claude tells you and follow along. If a step fails, Claude tells you why and stops the install.

### 5. Start working

Once install reports success, **launch the agent**:

```
op run --env-file=.env -- claude
```

(or the alias the install set up — typically `claude-ops`). Then run `/ai-agents-ops` in the Claude Code session. The agent activates as VP of Operations / COO and routes your request to the right skill.

Try something real, like: "Build an operational baseline for a mid-market beverage distributor" or "Run a safety stock + reorder-point analysis for a 200-SKU portfolio with mixed lead times."

**Important:** if you run plain `claude` (without `op run`), the `op://` references in `.env` won't resolve — Claude Code starts but OTEL traces silently don't reach Langfuse, and any MCP that needs a credential will fail. Always use the `op run` form (or the alias).

## Verify your first trace landed

Pablo will tell you the Langfuse dashboard URL once you're set up. Within ~30 seconds of your first real prompt, a trace tagged `service.name=ai-agent-ops` and `user.id=<your-handle>` should appear in the Traces view.

If it doesn't:
1. Confirm you launched via `op run --env-file=.env -- claude` (or the alias), NOT plain `claude` — the OTEL env vars only get injected by `op run`.
2. Re-run the install (`install this agent` again) — it'll re-validate the OTEL endpoint and tell you what failed.
3. Confirm `op whoami` still returns `SERVICE_ACCOUNT` — if your token expired or got rotated, traces stop landing silently.
4. If still nothing, ping Pablo with the session timestamp.

## When something in the agent is wrong

**The contract:** if a skill fails you, a prompt is confusing, or a reference is wrong — fix it via PR. Don't file an issue, don't DM gripes. Fix it or stay silent.

Read `CONTRIBUTING.md` for branch naming, PR structure, and review flow.

If you're not sure whether to edit an existing skill or author a new one — that's the call Pablo or the AI lead wants to weigh in on. Start a short PR description draft with your proposal first, then ping for alignment.

## Tools the agent can reach for

The repo ships with a project-scope `.mcp.json` that auto-installs 5 MCP servers when you open Claude Code in this directory:

| MCP | What it does | First-run auth |
|---|---|---|
| **google-workspace** | Gmail drafts, Drive files, Calendar invites | OAuth (browser) |
| **playwright** | Browser automation, scrape vendor portals, validate dashboards | none |
| **chrome-devtools** | Performance traces and network inspection | none |
| **context7** | Library + framework documentation lookup | none |
| **monday** | Monday.com boards / task tracking | personal API token (BYO, raw value in `.env`) |

By default, only the Langfuse references are active in `.env`. The Google Workspace credential set is commented out — uncomment it once Pablo provisions the fields on the `Supply Chain Agent` 1Password item. Monday is BYO: paste your own personal API token into `.env` to enable it.

If a skill needs an MCP that isn't here yet, the contribution path is: open a PR adding the server to `.mcp.json` and updating this table.

## Privacy note

Langfuse traces capture: session start/stop, tool names, durations, token counts, API cost, error events, model IDs. They do NOT capture: your prompt text, tool input/output bodies, file contents, or the bodies of skills you invoke. This is enforced by Claude Code's default redaction and will not change without an explicit spec revision.

## Questions

Ping Pablo. Keep the thread short — everything doc-worthy lands here, in `INSTALL.md`, or in `CONTRIBUTING.md`.
