# INSTALL.md — install runbook (read by Claude Code, not by humans)

**This file is read and executed by Claude Code.** When the user opens Claude Code inside a freshly cloned `supply-chain-agent` repo and says any of:

- "install this agent"
- "set this up"
- "I cloned this repo, walk me through the install"
- "configure this agent"
- "let's get this working"

…you (Claude Code) follow these steps in order. Do not skip steps. If a step fails, stop and ask the user before proceeding.

## The install gate (read this first)

This install is a **gate**. The agent cannot run real work until install completes. Three enforcement rules:

1. **Secrets never touch `.env`.** Every credential in `.env` is a 1Password reference (`op://...`). The `.env` file in this repo is not a place to paste secrets — it is a manifest that tells the 1Password CLI which vault items to fetch at launch time. If a user starts pasting raw API keys into `.env`, stop them and explain.
2. **Required references must resolve.** Steps 2 (1Password CLI access) and 3 (Langfuse reference resolves) MUST succeed. If `op run` can't fetch the Langfuse `auth_header`, the agent can't emit telemetry and the install fails.
3. **Optional credential sets are all-or-nothing per set.** For each optional set in Step 6, either ALL fields are populated in the vault item OR you COMMENT OUT the corresponding lines in `.env`. Empty vault fields cause MCP servers to start with empty creds and fail in obscure ways.

If a required step fails, tell the user: "I can't finish install without this. Get vault access from Pablo, then we'll continue. Re-run install when ready."

---

## Step 0 — Confirm you're in the right place

Before doing anything, run:

```bash
ls CLAUDE.md commands/ai-agents-ops.md .env.example
```

All three must exist. If any is missing, the user is in the wrong directory or cloned the wrong repo. Stop and tell them.

## Step 1 — Verify the 1Password CLI is installed

The whole credential model depends on `op` (the 1Password CLI). Check:

```bash
op --version
```

If the user gets `command not found`, install per platform:

- **macOS:** `brew install --cask 1password-cli`
- **Windows:** `winget install AgileBits.1Password.CLI`  *(note: the package ID is `AgileBits.1Password.CLI`, not `1Password.CLI`)*
- **Linux:** follow https://developer.1password.com/docs/cli/get-started

After install, the user must restart their terminal so `op` lands on PATH. Stop the install and have them confirm `op --version` returns a version before continuing.

## Step 1.5 — Set up the service account token

The user receives a service account token (`ops_...`) from Pablo via 1Password message. The token must live in their environment so every shell sees it.

**macOS / Linux** — append to `~/.zshrc` (zsh, default on modern macOS) or `~/.bashrc`:
```bash
export OP_SERVICE_ACCOUNT_TOKEN="ops_..."
```
Then `source ~/.zshrc` or open a new terminal.

**Windows (PowerShell)** — store as a user environment variable:
```powershell
setx OP_SERVICE_ACCOUNT_TOKEN "ops_..."
```
The user must close and reopen their PowerShell window — `setx` writes the value but doesn't update the current shell.

**Verify:**
```bash
op whoami
```
Should print the account URL and `User Type: SERVICE_ACCOUNT`. If it errors, the env var isn't set in this shell, the token is malformed, or the user is in the same shell instance that ran `setx` (which won't see the new value — open a fresh terminal).

## Step 2 — Verify access to the `AI Agents` vault

The agent's secrets live in a 1Password vault named `AI Agents` that Pablo shares with you. Verify access:

```bash
op vault list | grep -i "AI Agents"
```

If the vault is missing, tell the user: "You don't have access to the `AI Agents` vault yet. Ping Pablo to share it, then re-run install." Stop the install.

If the vault is listed, verify the required `Langfuse` item exists:

```bash
op item get "Langfuse" --vault "AI Agents" --fields auth_header > /dev/null && echo "Langfuse OK"
```

- Echoes `Langfuse OK` → continue.
- Errors or no output → Pablo hasn't created the shared Langfuse item yet. Stop and tell the user to ping Pablo.

The `Supply Chain Agent` 1Password item is OPTIONAL. It's only required when the user wants to enable Google Workspace. The corresponding `op://` references in `.env` are commented out by default; uncomment them in Step 6 only if Pablo has populated the corresponding fields on the per-agent vault item.

## Step 3 — Create `.env` from the template

If `.env` does not exist, copy it:

```bash
cp .env.example .env
```

If `.env` already exists, read it and skip to Step 4 only for variables that are still placeholders (e.g. `USER_ID=<your-github-handle>`). Never overwrite a variable that's already populated.

## Step 4 — Prompt for the user's GitHub handle (REQUIRED)

Ask:

> What's your GitHub handle? (no `@` prefix). This becomes `user.id` on every Langfuse trace so Pablo can tell your sessions apart from his.

Use Edit to replace the `USER_ID=<your-github-handle>` line in `.env` with their value. Do not append, do not duplicate.

## Step 5 — Validate the Langfuse reference resolves and works

This is the install's main correctness check: does `op run` resolve the Langfuse reference, and does Langfuse accept the resolved auth header?

**Note on the header format:** the `OTEL_EXPORTER_OTLP_HEADERS` env var follows OTEL spec format (`Header=Value`), which is *not* what curl's `-H` flag expects (HTTP wire format `Header: Value`). The smoke tests below convert before passing to curl; the actual Claude Code OTEL SDK does this conversion internally.

**macOS / Linux:**

```bash
op run --env-file=.env -- bash -c 'HDR="${OTEL_EXPORTER_OTLP_HEADERS#Authorization=}"; curl -s -o /dev/null -w "%{http_code}\n" -X POST "$OTEL_EXPORTER_OTLP_ENDPOINT/v1/traces" -H "Authorization: $HDR" -H "Content-Type: application/x-protobuf" --data-binary @/dev/null'
```

**Windows (PowerShell):**

```powershell
op run --env-file=.env -- powershell -NoProfile -Command "$h = $env:OTEL_EXPORTER_OTLP_HEADERS -replace '^Authorization=', ''; curl.exe -s -o NUL -w '%{http_code}' -X POST `"$($env:OTEL_EXPORTER_OTLP_ENDPOINT)/v1/traces`" -H `"Authorization: $h`" -H 'Content-Type: application/x-protobuf' --data-binary '@NUL'"
```

Expected output:

- `200` or `400` → header resolved correctly and Langfuse accepted it. Continue. (`200` means the request was processed; `400` means Langfuse rejected the empty body but the auth was valid — both prove the credentials work.)
- `401` or `403` → reference resolved but the auth header value in 1Password is wrong, or the Langfuse keys are for a different region than `OTEL_EXPORTER_OTLP_ENDPOINT` points to. Ping Pablo to update the `auth_header` field on the `Langfuse` vault item or fix the endpoint URL in `.env`.
- `op` error like "could not resolve reference" → the field name in 1Password doesn't match what `.env` expects. The `.env` references `op://AI Agents/Langfuse/auth_header` — the field MUST be named exactly `auth_header`. Ping Pablo.

On Windows where the user's default shell is PowerShell, use the equivalent at the bottom of this file.

## Step 6 — Optional credential set: Google Workspace

The agent has one optional credential set. **Pablo's rule: either populate the full set in 1Password, or COMMENT OUT the corresponding `.env` lines.** Empty 1Password fields cause MCPs to start with empty creds and fail in obscure ways.

> Gmail drafts, Drive files, Calendar invites. Reads from your own Google account on first call (browser OAuth). Setup requires a Google Cloud Console project: enable Gmail / Drive / Calendar APIs, create an OAuth Desktop client, and store Client ID + Client Secret on the vault item. Skipping just disables the google-workspace MCP.

Ask the user, verbatim:

> Do you have Google Workspace credentials, AND has Pablo populated them on the `Supply Chain Agent` vault item? Reply **yes** to keep these references active, **no** to comment them out for now (you can re-enable later by un-commenting).

Variables: `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`.
Vault fields: `google_client_id`, `google_client_secret`.

If **yes** → use Edit to remove the leading `#` from the two GOOGLE_OAUTH lines. Then run a resolve check:

```bash
op run --env-file=.env -- bash -c 'echo "$GOOGLE_OAUTH_CLIENT_ID"'
```

If it echoes empty, the field doesn't exist yet on the vault item — fall through to **no**.

If **no** → leave the lines commented out. The google-workspace MCP will start with empty creds and fail gracefully when invoked.

## Step 6.5 — BYO Monday.com token (per-employee)

Monday.com uses a Bring-Your-Own credential model — Pablo does not provision this token. Each employee provisions their own.

Ask the user, verbatim:

> Do you want to enable Monday.com integration? You'll need to generate your own personal API token (Pablo doesn't provide this). Reply **yes** to walk through provisioning, **no** to skip for now.

If **yes**, walk them through:

1. Sign in at `monday.com` with their own account.
2. Click avatar (bottom-left) → Developers → My Access Tokens → Show.
3. Copy the personal API token.
4. Use Edit to uncomment the `MONDAY_TOKEN=` line in `.env` and paste the raw token (NOT an op:// reference — this is a BYO credential).

If **no** → leave the line commented out. The monday MCP will start with empty creds and fail gracefully when invoked.

## Step 7 — MCPs auto-load from `.mcp.json`

The repo ships with a project-scope `.mcp.json` declaring 5 MCP servers: `google-workspace`, `playwright`, `chrome-devtools`, `context7`, `monday`. Claude Code picks these up automatically when the user opens this directory; no manual `claude mcp add` is required.

`google-workspace` requires browser-based OAuth on first invocation; `monday` reads `MONDAY_TOKEN` from the process environment at launch. The other three (`playwright`, `chrome-devtools`, `context7`) require no auth.

Mention to the user, verbatim:

> The agent's MCP servers are pre-configured. Google Workspace will prompt you to authenticate in a browser the first time a skill uses it — this is expected. Monday uses the personal token you pasted into `.env` (or fails gracefully if you skipped that step).

You can verify the MCP set inside Claude Code (after Step 9) by running:

```
/mcp
```

You should see all 5 servers. If any show `✗ Failed to connect`, that's a problem with that specific MCP's runtime (e.g., `npx` package down, network issue) and is fixable separately.

## Step 8 — Install the slash command

Copy the slash command file into the user's global Claude Code commands directory so `/ai-agents-ops` is available from any session, not just this repo.

Bash / Git Bash / WSL / macOS:
```bash
mkdir -p ~/.claude/commands
cp commands/ai-agents-ops.md ~/.claude/commands/
```

PowerShell (Windows):
```powershell
New-Item -ItemType Directory -Path $HOME/.claude/commands -Force | Out-Null
Copy-Item commands/ai-agents-ops.md $HOME/.claude/commands/
```

Confirm the copy worked:
```bash
ls ~/.claude/commands/ai-agents-ops.md
```

If missing, the copy failed silently — re-run with explicit error reporting.

## Step 8.5 — Run the preflight check

Before suggesting launch, run the preflight script to verify the entire pipeline is healthy. This catches misconfiguration BEFORE the user discovers it mid-session (when an MCP fails because env vars aren't set; an MCP fix would otherwise require restarting Claude Code).

**macOS / Linux:**
```bash
./scripts/preflight.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\preflight.ps1
```

The script verifies (read-only, no state changes):
1. `op` CLI installed and authenticated as SERVICE_ACCOUNT
2. `AI Agents` vault accessible
3. Langfuse 1Password item — all 4 fields (`auth_header`, `public_key`, `secret_key`, `base_url`) resolve with correct shapes
4. `.env` file shape (USER_ID set, OTEL header uses `op://` reference, US region endpoint)
5. End-to-end OTEL pipeline — `op run` resolves the Langfuse reference, the OTEL endpoint accepts the auth header (HTTP 200 or 400)

Then it lists every MCP in `.mcp.json` and reports which ones are configured vs. which will fail gracefully when invoked (missing env vars). Optional MCPs missing creds is NOT a failure — the agent runs in degraded mode for those tools.

**Pass criteria:** the script prints `RESULT: READY TO LAUNCH` and exits with code 0.

**If the script prints `RESULT: NOT READY`:** stop the install. Read the failed checks, fix them, re-run the script. Do not advance to Step 9 until the script passes.

This script is also runnable anytime as a standalone status check — when an employee adds new credentials (e.g., pastes their Monday token in `.env`), they re-run the script to confirm the new config landed correctly. No need to launch Claude Code to test.

## Step 9 — Set up the launch alias

The agent must be launched via `op run` so secrets resolve. Without the alias, users will run plain `claude` and the OTEL/MCP env vars will be empty — telemetry silently breaks and the user won't know.

Suggest adding this alias to the user's shell rc file. Bash / Zsh:

```bash
alias claude-ops='op run --env-file="$(pwd)/.env" -- claude'
```

PowerShell (add to `$PROFILE`):

```powershell
function Invoke-ClaudeOps { op run --env-file="$PWD\.env" -- claude @args }
Set-Alias claude-ops Invoke-ClaudeOps
```

The alias resolves `.env` from the current working directory, so it Just Works as long as the user is `cd`'d into the agent repo when they run it.

Tell the user, verbatim:

> Add this alias to your shell rc file so you don't have to remember the launch command. From now on, `cd` into this repo and run `claude-ops` instead of `claude`. Plain `claude` will skip the secret resolution and your traces won't reach Langfuse.

## Step 10 — Confirm success and tell the user how to start

Print, verbatim:

> Install complete. To use the agent:
> 1. `cd` into this repo
> 2. Run `claude-ops` (or `op run --env-file=.env -- claude` if you skipped the alias)
> 3. Inside Claude Code, run `/ai-agents-ops` to start the agent
>
> Your traces will land in Pablo's Langfuse dashboard tagged with your GitHub handle.
>
> The 5 MCP servers in `.mcp.json` (Google Workspace, Playwright, chrome-devtools, Context7, Monday) auto-loaded when Claude Code started. Google Workspace will prompt for browser sign-in on first use; Monday uses your personal token from `.env` (or fails gracefully if you skipped that step).

End the install conversation here. Do not start doing real work in the same turn — wait for the user's next message.

---

## What this runbook does NOT do

- Does NOT modify `~/.claude/settings.json` or any other global Claude Code config beyond copying the slash command
- Does NOT commit anything to git
- Does NOT touch `.gitignore`
- Does NOT pull, push, or otherwise interact with GitHub
- Does NOT write the user's secrets anywhere on disk — they live in 1Password and are streamed into Claude Code's process environment by `op run`

If the user asks for any of the above, tell them it's out of scope for this runbook and refer to ONBOARDING.md.

## Troubleshooting cheats

- **"`op run` says could not resolve reference"** → the field name on the 1Password item doesn't match what `.env` expects. Check exact spelling — `op://AI Agents/Langfuse/auth_header` requires a field literally named `auth_header` on the `Langfuse` item in the `AI Agents` vault. 1Password field names are case-sensitive.
- **"Langfuse curl returned 401"** → the `auth_header` field value in 1Password is malformed. Common mistakes: stored only the base64 string and dropped the `Authorization=Basic ` prefix; stored with extra whitespace; stored with quotes around it. Should be exactly `Authorization=Basic <base64>` with no quotes, no trailing newline.
- **"`op run` works but Claude Code says env var is empty"** → the user launched plain `claude`, not `op run -- claude`. Tell them to use the `claude-ops` alias from Step 9.
- **"Slash command doesn't show up after Step 8"** → check that `~/.claude/commands/ai-agents-ops.md` actually exists. If yes, the user may need to restart their Claude Code session to pick it up.
- **"User says they don't have a 1Password vault item yet"** → stop the install. Tell the user to ping Pablo for vault access, then re-run install once they have it.
- **"`op whoami` returns 'no account configured'"** → `OP_SERVICE_ACCOUNT_TOKEN` env var isn't set in the current shell. On Windows, this commonly means the user ran `setx` but is still in the same shell that created the value — open a fresh PowerShell window. On macOS/Linux, run `source ~/.zshrc` (or `~/.bashrc`) or open a new terminal.
- **"`op` returns auth errors after the env var is confirmed set"** → the token is malformed (missing `ops_` prefix, copy-paste truncation) or has been rotated. Ping Pablo for a fresh token.
