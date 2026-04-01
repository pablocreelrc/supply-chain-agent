# IB Format Standards — Quick Reference

## Font & Colors (Excel)

| Element | Font | Color | Fill |
|---------|------|-------|------|
| Hardcoded inputs | Calibri 10pt | Blue (0,0,255) | Yellow |
| Formulas | Calibri 10pt | Black (0,0,0) | None |
| Cross-sheet links | Calibri 10pt | Green (0,128,0) | None |
| Headers | Calibri 10pt Bold | White (255,255,255) | Dark Navy |
| Sub-headers | Calibri 10pt Bold | Black (0,0,0) | Light Gray |

## Number Formatting

| Type | Format | Example |
|------|--------|---------|
| Integers | #,##0 | 1,250,000 |
| Decimals | #,##0.0 | 1,250,000.0 |
| Percentages | 0.0% | 12.5% |
| Negatives | Parentheses | (1,250,000) |
| Currency | $ on first and total rows only | $1,250,000 |
| Multiples | 0.0x | 8.5x |

## Layout (Excel)

- Column A: row labels, left-aligned
- Data columns: right-aligned
- Units row below headers (e.g., $M, %, x)
- Thin bottom borders between sections
- Double bottom border above totals
- Gridlines OFF
- Print area set
- Freeze panes on header row

## Document / Write-up Standards

- Font: Calibri or Times New Roman, 11pt body, 14pt title
- Structure: Executive summary up front, followed by detailed sections
- Tables: IB-style with thin borders, header row shaded, right-aligned numbers
- Page setup: 1" margins, professional header/footer with date and "Confidential"
- Figures in $M or $B with one decimal unless precision matters

## PDF Generation Rules

When generating PDFs with fpdf2 or similar:
1. Track Y position after every element — never assume fixed positions
2. After images, advance Y by image height + margin before more text
3. After `multi_cell()`, do NOT manually set Y to a hardcoded value
4. Check `get_y() > page_height - margin` before each new section
5. After generating, re-open with pypdf/fitz to verify no text overlap
