# Supply Chain Agent — launcher (Windows / PowerShell)
#
# Usage from the repo root:
#   .\ops-agent.ps1
#
# Wraps the canonical launch command so employees never accidentally run
# plain `claude` (which silently fails to resolve `op://` references in
# .env and emits no OTEL telemetry to Langfuse — same failure class as
# the Marketing agent DARK pilot — memory: project_ai_agents_telemetry.md).

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $RepoRoot ".env"

function Write-Fail($msg) { Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Info($msg) { Write-Host "  [INFO] " -ForegroundColor Cyan -NoNewline; Write-Host $msg }

if (-not (Get-Command op -ErrorAction SilentlyContinue)) {
    Write-Fail "1Password CLI (op) not found on PATH"
    Write-Info "Install: winget install AgileBits.1Password.CLI, then restart this terminal"
    Write-Info "Then re-run: .\ops-agent.ps1"
    exit 1
}

if (-not $env:OP_SERVICE_ACCOUNT_TOKEN) {
    Write-Fail "OP_SERVICE_ACCOUNT_TOKEN not set in this shell"
    Write-Info "Set per ONBOARDING.md, then open a fresh PowerShell window"
    Write-Info "Without this, op:// references in .env will not resolve and OTEL goes dark"
    exit 1
}

if (-not (Test-Path $EnvFile)) {
    Write-Fail ".env file missing at $EnvFile"
    Write-Info "Run: cp .env.example .env  (then fill in USER_ID and TENANT per ONBOARDING.md)"
    exit 1
}

Push-Location $RepoRoot
try {
    & op run --env-file=.env -- claude @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
