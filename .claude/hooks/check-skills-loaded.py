#!/usr/bin/env python
"""
Supply Chain Agent — SessionStart hook: submodule visibility check.

Runs at Claude Code SessionStart. Verifies the two skill submodules
(Supply-Chain-Pro, Business-Analytics-Pro) are populated. A plain
`git clone` (without --recurse-submodules) leaves skills/ empty and
the agent starts with ZERO skills loaded — same silent-failure class
as a DARK telemetry config (memory: project_ai_agents_telemetry.md).

Read-only. Never blocks. Exits 0 even on failure. Errors land in
.claude/hooks/skills-check-errors.log so they don't disappear silently
but never disrupt session start.
"""
from __future__ import annotations

import sys
import traceback
from datetime import datetime, timezone
from pathlib import Path

HOOK_DIR = Path(__file__).resolve().parent
REPO_ROOT = HOOK_DIR.parent.parent
ERROR_LOG = HOOK_DIR / "skills-check-errors.log"

AGENT_NAME = "Supply Chain Agent"
SUBMODULES = [
    ("Supply-Chain-Pro", "skills/Supply-Chain-Pro/CATALOG.md"),
    ("Business-Analytics-Pro", "skills/Business-Analytics-Pro/CATALOG.md"),
]

RED = "\033[0;31m"
YELLOW = "\033[1;33m"
GREEN = "\033[0;32m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"


def log_error(context: str, exc: BaseException) -> None:
    try:
        ERROR_LOG.parent.mkdir(parents=True, exist_ok=True)
        with ERROR_LOG.open("a", encoding="utf-8") as f:
            ts = datetime.now(timezone.utc).isoformat()
            f.write(f"[{ts}] {context}: {type(exc).__name__}: {exc}\n")
            f.write(traceback.format_exc())
            f.write("\n")
    except Exception:
        pass


def main() -> int:
    try:
        missing: list[str] = []
        for name, marker in SUBMODULES:
            if not (REPO_ROOT / marker).exists():
                missing.append(name)

        if not missing:
            sys.stderr.write(
                f"{GREEN}[OK]{NC} {AGENT_NAME}: all {len(SUBMODULES)} skill submodules populated.\n"
            )
            return 0

        bar = "=" * 70
        sys.stderr.write(f"\n{RED}{BOLD}{bar}{NC}\n")
        sys.stderr.write(
            f"{RED}{BOLD} {AGENT_NAME}: SKILL SUBMODULES MISSING — agent will load with 0 skills{NC}\n"
        )
        sys.stderr.write(f"{RED}{BOLD}{bar}{NC}\n\n")
        for name in missing:
            sys.stderr.write(f"  {RED}[MISSING]{NC} skills/{name}/ is empty or absent\n")
        sys.stderr.write(
            f"\n{YELLOW}Fix from the repo root:{NC}\n"
            f"  {CYAN}git submodule update --init --recursive{NC}\n\n"
            f"Then close + reopen Claude Code so the plugin loader re-scans skills/.\n"
            f"Background: a plain `git clone` (without --recurse-submodules) leaves\n"
            f"skills/ empty and the .claude-plugin/marketplace.json registers zero\n"
            f"skills — silently. This hook is here so that failure mode is visible.\n\n"
        )
        return 0
    except Exception as exc:
        log_error("skills-check main", exc)
        return 0


if __name__ == "__main__":
    sys.exit(main())
