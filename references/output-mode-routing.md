# Output Mode Routing

Shared logic referenced by every skill in Business-Analytics-Pro.

## Detection Rules

1. Scan the user's message for mode signals (see table below)
2. If multiple signals conflict, prefer the most specific one
3. If no signal detected, ask: "Want me to build this in Excel, run it in Python, or just walk through the concepts?"

| Priority | Signal Keywords | Mode |
|----------|----------------|------|
| 1 (highest) | "both", "build and run", "Excel and Python" | Both |
| 2 | "Excel", "spreadsheet", "model", "workbook", "Shortcut" | Excel |
| 2 | "Python", "script", "run", "simulate", "compute", "calculate" | Python |
| 3 | "explain", "walk me through", "how", "teach", "what is" | Teach |
| 4 (default) | No signal | Ask user |

## Mode Behaviors

### Excel Mode
- Use Shortcut.ai API (`shortcut_excel.py`) to create a professional IB-formatted workbook
- Follow `references/excel-standards.md` for all formatting
- Assumptions tab always last, named ranges for key inputs
- All hardcoded inputs: blue font, yellow fill
- All formulas: black font
- Cross-sheet references: green font

### Python Mode
- Write a self-contained Python script using standard libraries
- Include inline comments explaining the methodology
- Print key results to console
- Generate matplotlib charts where visualization adds value
- Use `python` (not `python3`) on Windows

### Both Mode
- Python computes results first
- Shortcut.ai formats results into a professional Excel workbook
- The Excel workbook contains both the raw data and formatted output
- Not applicable for skills that are inherently single-mode (note in SKILL.md)

### Teach Mode
- Claude explains the framework, math, and business context
- Use formulas in code blocks for clarity
- Walk through the logic step by step
- No code output, no file creation
