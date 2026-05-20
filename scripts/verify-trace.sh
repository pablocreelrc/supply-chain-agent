#!/usr/bin/env bash
# verify-trace.sh — destination-verified first-trace gate.
#
# Config looking correct is NOT proof telemetry works. This queries Langfuse
# DIRECTLY and exits 0 only if a trace tagged with THIS operator's
# service.name + user.id actually landed in the last N minutes.
#
# Run AFTER your first real agent prompt:
#   op run --env-file=.env -- ./scripts/verify-trace.sh
#
# Generic by design: reads OTEL_SERVICE_NAME + USER_ID from the env, so the
# same script works unchanged for every ai-agents-* agent. Copy as-is.
#
# Exit: 0 = a trace for you landed. 1 = nothing found / misconfig (the
# silent-failure this gate exists to catch).

set -euo pipefail

WINDOW_MIN="${1:-15}"

# langfuse-cli reads LANGFUSE_HOST; our .env supplies LANGFUSE_BASE_URL.
export LANGFUSE_HOST="${LANGFUSE_HOST:-${LANGFUSE_BASE_URL:-}}"

missing=0
for v in LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_HOST OTEL_SERVICE_NAME USER_ID; do
  if [ -z "${!v:-}" ]; then echo "  [FAIL] $v not set — launch via 'op run --env-file=.env -- ./scripts/verify-trace.sh'"; missing=1; fi
done
[ "$missing" -eq 1 ] && exit 1

SINCE="$(date -u -d "${WINDOW_MIN} minutes ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -v-"${WINDOW_MIN}"M +%Y-%m-%dT%H:%M:%SZ)"

# Server-side datetime filter only (nested resourceAttributes are NOT filterable
# server-side in langfuse-cli). The operator/agent match is done client-side
# against metadata.resourceAttributes, where Claude Code puts OTEL resource attrs.
FILTER='[{"type":"datetime","column":"timestamp","operator":">=","value":"'"${SINCE}"'"}]'

echo "Querying Langfuse for service.name=${OTEL_SERVICE_NAME} user.id=${USER_ID} since ${SINCE} ..."

COUNT="$(npx -y langfuse-cli api traces list --limit 100 --fields core,io --filter "${FILTER}" 2>/dev/null \
  | python -c '
import sys, json
svc, uid = sys.argv[1], sys.argv[2]
try:
    data = json.load(sys.stdin).get("data", [])
except Exception:
    print("ERR"); sys.exit(0)
n = 0
for t in data:
    ra = (t.get("metadata") or {}).get("resourceAttributes") or {}
    if ra.get("service.name") == svc and ra.get("user.id") == uid:
        n += 1
print(n)
' "${OTEL_SERVICE_NAME}" "${USER_ID}" 2>/dev/null | tr -d '[:space:]' || echo ERR)"

if [ "$COUNT" != "ERR" ] && [ -n "$COUNT" ] && [ "$COUNT" -ge 1 ] 2>/dev/null; then
  echo "  [OK] ${COUNT} trace(s) for you landed in Langfuse. Telemetry is live."
  exit 0
fi

echo "  [FAIL] ZERO traces for service.name=${OTEL_SERVICE_NAME} user.id=${USER_ID} in the last ${WINDOW_MIN} min."
echo "         (Checked the ${WINDOW_MIN}-min window; widen with: ./scripts/verify-trace.sh 60)"
echo "         This is the silent failure. Checklist:"
echo "         1. Did you launch via 'op run --env-file=.env -- claude' (NOT plain 'claude')?"
echo "         2. Did you actually send one real prompt to the agent first?"
echo "         3. 'op whoami' still returns SERVICE_ACCOUNT?"
echo "         4. Re-run 'install this agent' to re-validate the OTEL endpoint."
[ "$COUNT" = "ERR" ] && echo "         (Note: langfuse-cli returned no parseable data — check LANGFUSE_* creds resolved.)"
exit 1
