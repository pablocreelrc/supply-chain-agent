#!/usr/bin/env bash
# Supply Chain Agent — launcher (macOS / Linux / bash)
#
# Usage from the repo root:
#   ./ops-agent.sh
#
# Wraps the canonical launch command so employees never accidentally run
# plain `claude` (which silently fails to resolve `op://` references in
# .env and emits no OTEL telemetry to Langfuse — same failure class as
# the Marketing agent DARK pilot — memory: project_ai_agents_telemetry.md).
#
# Forwards all arguments to claude.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$REPO_ROOT/.env"

RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

fail() { printf "  ${RED}[FAIL]${NC} %s\n" "$1"; }
info() { printf "  ${CYAN}[INFO]${NC} %s\n" "$1"; }

if ! command -v op >/dev/null 2>&1; then
    fail "1Password CLI (op) not found on PATH"
    info "Install: macOS 'brew install --cask 1password-cli'; Linux see https://developer.1password.com/docs/cli/get-started"
    info "Then re-run: ./ops-agent.sh"
    exit 1
fi

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    fail "OP_SERVICE_ACCOUNT_TOKEN not set in this shell"
    info "Set per ONBOARDING.md, then source your shell profile or open a fresh terminal"
    info "Without this, op:// references in .env will not resolve and OTEL goes dark"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    fail ".env file missing at $ENV_FILE"
    info "Run: cp .env.example .env  (then fill in USER_ID and TENANT per ONBOARDING.md)"
    exit 1
fi

cd "$REPO_ROOT"
exec op run --env-file=.env -- claude "$@"
