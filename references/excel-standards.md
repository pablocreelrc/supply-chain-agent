# Excel Standards (IB Format)

All Excel output produced by Business-Analytics-Pro skills follows Investment Banking formatting standards via Shortcut.ai API (`shortcut_excel.py`).

## Font & Color Rules

| Element | Font | Color | Fill |
|---------|------|-------|------|
| Hardcoded inputs | Calibri 10pt | Blue (0,0,255) | Yellow |
| Formulas / calculations | Calibri 10pt | Black (0,0,0) | None |
| Cross-sheet links | Calibri 10pt | Green (0,128,0) | None |
| Headers | Calibri 10pt Bold | White (255,255,255) | Dark blue / navy |
| Sub-headers | Calibri 10pt Bold | Black | Light gray |

## Number Formatting

| Type | Format Code | Example |
|------|-------------|---------|
| Thousands | `#,##0` | 1,234 |
| Currency (body) | `#,##0;(#,##0)` | 1,234 / (1,234) |
| Currency (first/total row) | `$#,##0;($#,##0)` | $1,234 |
| Percentages | `0.0%` | 45.3% |
| Negatives | Parentheses | (1,234) not -1,234 |

See `references/analytics-format-codes.md` for domain-specific formats.

## Layout Rules

- **Column A:** Row labels, left-aligned
- **Data columns:** Right-aligned
- **Units row:** Show units (e.g., $M, %, x) below or beside headers
- **Borders:** Thin bottom between sections, double bottom above totals
- **Gridlines:** Off
- **Print area:** Set
- **Freeze panes:** On header rows and label columns
- **No merged cells** in data ranges

## Tab Structure

- Analysis-specific tabs first (vary by skill)
- **Assumptions tab always last** — all hardcoded values live here
- Blue font + yellow background on key assumption cells
- Define named ranges for anything referenced by other tabs
