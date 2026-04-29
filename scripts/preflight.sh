#!/usr/bin/env bash
# Supply Chain Agent — preflight check (macOS / Linux / bash)
#
# Run from the repo root:
#   ./scripts/preflight.sh
#
# Verifies that the agent can launch successfully and reports which MCPs
# are configured vs. which will fail gracefully when invoked. Safe to run
# anytime — read-only checks, no state changes.
#
# Exit code: 0 if all critical checks pass, 1 if any critical check fails.
# Critical = op auth, vault access, Langfuse refs resolve, OTEL endpoint
# accepts the auth header. Optional MCPs missing creds is not critical.

set +e   # don't abort on first failed command — we want to report all checks

# Locate repo root (parent of scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
MCP_FILE="$REPO_ROOT/.mcp.json"

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CRITICAL_FAIL=0

ok()   { printf "  ${GREEN}[OK]${NC} %s\n" "$1"; }
fail() { printf "  ${RED}[FAIL]${NC} %s\n" "$1"; CRITICAL_FAIL=1; }
warn() { printf "  ${YELLOW}[!]${NC} %s\n" "$1"; }
info() { printf "  ${CYAN}[i]${NC} %s\n" "$1"; }

printf "\n${CYAN}================================================================${NC}\n"
printf "${CYAN} PRE-FLIGHT CHECK — Supply Chain Agent${NC}\n"
printf "${CYAN}================================================================${NC}\n\n"

# ---------------------------------------------------------------
# [1/5] op CLI installed and authenticated
# ---------------------------------------------------------------
echo "[1/5] 1Password CLI authentication"
if ! command -v op >/dev/null 2>&1; then
    fail "op CLI not found on PATH"
    info "Install: macOS 'brew install --cask 1password-cli', Linux see https://developer.1password.com/docs/cli/get-started"
elif [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    fail "OP_SERVICE_ACCOUNT_TOKEN not set in this shell"
    info "Add to ~/.zshrc or ~/.bashrc: export OP_SERVICE_ACCOUNT_TOKEN=\"ops_<your-token>\" — then source the file or open a new terminal"
else
    if op whoami 2>&1 | grep -q "SERVICE_ACCOUNT"; then
        ok "op CLI authenticated as SERVICE_ACCOUNT"
    else
        fail "op whoami did not return SERVICE_ACCOUNT (token invalid or revoked)"
    fi
fi

# ---------------------------------------------------------------
# [2/5] AI Agents vault accessible
# ---------------------------------------------------------------
echo ""
echo "[2/5] AI Agents vault accessible"
if [ "$CRITICAL_FAIL" -eq 0 ]; then
    if op vault list --format=json 2>/dev/null | grep -q '"name": *"AI Agents"'; then
        VAULT_ID=$(op vault list --format=json 2>/dev/null | grep -B1 '"name": *"AI Agents"' | grep '"id"' | head -1 | sed -E 's/.*"id": *"([^"]+)".*/\1/' | cut -c1-8)
        ok "AI Agents vault visible (id: ${VAULT_ID}...)"
    else
        fail "AI Agents vault NOT visible to this service account"
        info "Pablo: grant the service account Read access to AI Agents vault at ajolotelabs.1password.com"
    fi
else
    warn "Skipped — op auth failed above"
fi

# ---------------------------------------------------------------
# [3/5] Langfuse 1Password item — all 4 fields resolve
# ---------------------------------------------------------------
echo ""
echo "[3/5] Langfuse 1Password item — all 4 fields resolve"
if [ "$CRITICAL_FAIL" -eq 0 ]; then
    check_field() {
        local field="$1"
        local pattern="$2"
        local val
        val=$(op read "op://AI Agents/Langfuse/$field" 2>/dev/null)
        if [[ "$val" =~ $pattern ]]; then
            ok "$field — resolves with correct shape"
        else
            fail "$field — resolution failed or wrong shape"
        fi
    }
    check_field "auth_header" "^Authorization=Basic [A-Za-z0-9+/=]+$"
    check_field "public_key"  "^pk-lf-"
    check_field "secret_key"  "^sk-lf-"
    check_field "base_url"    "^https://"
else
    warn "Skipped — earlier checks failed"
fi

# ---------------------------------------------------------------
# [4/5] .env file shape
# ---------------------------------------------------------------
echo ""
echo "[4/5] Supply Chain Agent .env file shape"
if [ ! -f "$ENV_FILE" ]; then
    fail ".env file does not exist at $ENV_FILE"
    info "Run: cp .env.example .env  (then fill in USER_ID)"
else
    if grep -qE "^USER_ID=[a-zA-Z0-9_-]+$" "$ENV_FILE"; then
        ok "USER_ID set to a real handle"
    else
        fail "USER_ID is not set or is still a placeholder"
    fi
    if grep -qE "^USER_ID=<your-github-handle>" "$ENV_FILE"; then
        fail "USER_ID is still the placeholder '<your-github-handle>'"
    fi
    if grep -qE "^USER_ID=pablocreelrc$" "$ENV_FILE"; then
        fail "USER_ID is set to 'pablocreelrc' — that handle is reserved for Pablo's own machine. Set it to YOUR GitHub handle."
    fi
    if grep -qE "^TENANT=[a-zA-Z0-9_-]+$" "$ENV_FILE" && ! grep -qE "^TENANT=<your-company-slug>" "$ENV_FILE"; then
        ok "TENANT set to a real company/engagement slug (not placeholder)"
    else
        fail "TENANT not set or still a placeholder — required for per-customer rollup in Langfuse. Pablo provides the slug; common values: sacrificio, desclub, ajolote, internal."
    fi
    if grep -qE "^OTEL_EXPORTER_OTLP_HEADERS=op://AI Agents/Langfuse/auth_header$" "$ENV_FILE"; then
        ok "OTEL_EXPORTER_OTLP_HEADERS uses op:// reference"
    else
        fail "OTEL_EXPORTER_OTLP_HEADERS not set to expected op:// reference"
    fi
    if grep -qE "https://us\.cloud\.langfuse\.com/api/public/otel" "$ENV_FILE"; then
        ok "OTEL endpoint = US region"
    else
        fail "OTEL endpoint not pointing at us.cloud.langfuse.com"
    fi
    if grep -qE "^OTEL_TRACES_EXPORTER=otlp$" "$ENV_FILE"; then
        ok "OTEL_TRACES_EXPORTER=otlp set (traces export reliably)"
    else
        fail "OTEL_TRACES_EXPORTER=otlp missing — traces may not export. Copy the line from .env.example."
    fi
    if grep -qE "^OTEL_LOGS_EXPORTER=none$" "$ENV_FILE"; then
        ok "OTEL_LOGS_EXPORTER=none set (Langfuse doesn't accept OTLP logs)"
    else
        warn "OTEL_LOGS_EXPORTER not set to 'none' — Claude Code will repeatedly POST to a 404 endpoint at Langfuse"
    fi
    if grep -qE "^CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1$" "$ENV_FILE"; then
        ok "CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1 set (spans actually emitted)"
    else
        fail "CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1 missing — Claude Code will NOT emit spans, Langfuse Traces tab stays empty. Copy the line from .env.example."
    fi
    if grep -qE "^OTEL_METRIC_EXPORT_INTERVAL=[0-9]+$" "$ENV_FILE"; then
        ok "OTEL_METRIC_EXPORT_INTERVAL set (short sessions won't lose metrics)"
    else
        fail "OTEL_METRIC_EXPORT_INTERVAL missing — short /command sessions can drop metrics. Copy the line from .env.example."
    fi
fi

# ---------------------------------------------------------------
# [5/5] End-to-end OTEL pipeline
# ---------------------------------------------------------------
echo ""
echo "[5/5] End-to-end OTEL pipeline"
if [ "$CRITICAL_FAIL" -eq 0 ] && [ -f "$ENV_FILE" ]; then
    cd "$REPO_ROOT" || exit 1
    SMOKE_OUTPUT=$(op run --env-file=.env -- bash -c '
        HEADER="${OTEL_EXPORTER_OTLP_HEADERS#Authorization=}"
        curl -s -o /dev/null -w "%{http_code}" -X POST "$OTEL_EXPORTER_OTLP_ENDPOINT/v1/traces" \
             -H "Authorization: $HEADER" \
             -H "Content-Type: application/x-protobuf" \
             --data-binary @/dev/null
    ' 2>&1)
    if [[ "$SMOKE_OUTPUT" =~ ^(200|400)$ ]]; then
        ok "Langfuse OTEL endpoint returned $SMOKE_OUTPUT (auth accepted; 400 = empty body rejected = expected)"
    elif [[ "$SMOKE_OUTPUT" =~ ^(401|403)$ ]]; then
        fail "Langfuse rejected the auth header (HTTP $SMOKE_OUTPUT). The auth_header value in 1Password may be malformed."
    else
        fail "Unexpected response: $SMOKE_OUTPUT"
    fi
else
    warn "Skipped — earlier checks failed"
fi

# ---------------------------------------------------------------
# MCP status report (informational, not critical)
# ---------------------------------------------------------------
printf "\n${CYAN}================================================================${NC}\n"
printf "${CYAN} MCP servers registered in .mcp.json${NC}\n"
printf "${CYAN}================================================================${NC}\n"

if [ ! -f "$MCP_FILE" ]; then
    fail ".mcp.json not found"
elif ! command -v node >/dev/null 2>&1; then
    warn "node not found — skipping per-MCP env-var check (you'll see status when each MCP is invoked)"
else
    # Use node to parse .mcp.json and check env vars against .env
    node -e "
        const fs = require('fs');
        const path = require('path');
        const mcp = JSON.parse(fs.readFileSync('$MCP_FILE', 'utf8'));
        const envContent = fs.existsSync('$ENV_FILE') ? fs.readFileSync('$ENV_FILE', 'utf8') : '';
        const GREEN = '\x1b[0;32m', RED = '\x1b[0;31m', YELLOW = '\x1b[1;33m', NC = '\x1b[0m';
        for (const [name, cfg] of Object.entries(mcp.mcpServers)) {
            if (cfg.type === 'http') {
                console.log(\`  \${GREEN}[OK]\${NC} \${name}  (HTTP MCP — browser OAuth on first use)\`);
            } else if (cfg.env) {
                const missing = Object.keys(cfg.env).filter(v => !new RegExp('^' + v + '=', 'm').test(envContent));
                if (missing.length === 0) {
                    console.log(\`  \${GREEN}[OK]\${NC} \${name}  (env vars active in .env)\`);
                } else {
                    console.log(\`  \${YELLOW}[!]\${NC} \${name}  (will fail when invoked — missing: \${missing.join(', ')})\`);
                }
            } else {
                console.log(\`  \${GREEN}[OK]\${NC} \${name}  (no auth required)\`);
            }
        }
    "
fi

# ---------------------------------------------------------------
# Final status
# ---------------------------------------------------------------
printf "\n${CYAN}================================================================${NC}\n"
if [ "$CRITICAL_FAIL" -eq 1 ]; then
    printf "${RED} RESULT: NOT READY — critical checks failed (see above)${NC}\n"
    printf "${CYAN}================================================================${NC}\n\n"
    exit 1
else
    printf "${GREEN} RESULT: READY TO LAUNCH${NC}\n"
    printf "${CYAN}================================================================${NC}\n\n"
    printf "Launch with: ${CYAN}op run --env-file=.env -- claude${NC}\n"
    printf "Then in Claude Code: ${CYAN}/ai-agents-ops${NC}\n\n"
    exit 0
fi
