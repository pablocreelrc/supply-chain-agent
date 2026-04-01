"""Apply IB (Investment Banking) color coding and number formatting to an Excel workbook.

Usage:
    python scripts/ib_formatter.py <input.xlsx> <output.xlsx>

Applies:
    - Blue font (0,0,255) for hardcoded inputs
    - Black font (0,0,0) for formulas
    - Green font (0,128,0) for cross-sheet references
    - Parentheses for negatives
    - Consistent number formatting per references/excel-standards.md
"""

import argparse
import sys

try:
    from openpyxl import load_workbook
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side, numbers
except ImportError:
    print("Error: openpyxl is required. Install with: pip install openpyxl", file=sys.stderr)
    sys.exit(1)

# IB Color Constants (RGB hex)
BLUE_INPUT = "0000FF"
BLACK_FORMULA = "000000"
GREEN_CROSSSHEET = "008000"
WHITE_HEADER = "FFFFFF"
NAVY_HEADER_BG = "003366"
YELLOW_INPUT_BG = "FFFF00"
LIGHT_GRAY_BG = "D9D9D9"

# Standard IB number formats
FORMAT_THOUSANDS = '#,##0;(#,##0)'
FORMAT_CURRENCY_BODY = '#,##0;(#,##0)'
FORMAT_CURRENCY_TOTAL = '$#,##0;($#,##0)'
FORMAT_PERCENT = '0.0%'
FORMAT_DECIMAL_2 = '0.00'
FORMAT_DECIMAL_4 = '0.0000'


def apply_cell_formatting(cell, is_header=False, is_subheader=False):
    """Apply IB formatting to a single cell based on its content type."""
    if is_header:
        cell.font = Font(name="Calibri", size=10, bold=True, color=WHITE_HEADER)
        cell.fill = PatternFill(start_color=NAVY_HEADER_BG, end_color=NAVY_HEADER_BG, fill_type="solid")
        cell.border = Border(bottom=Side(style="thin"))
        return

    if is_subheader:
        cell.font = Font(name="Calibri", size=10, bold=True, color=BLACK_FORMULA)
        cell.fill = PatternFill(start_color=LIGHT_GRAY_BG, end_color=LIGHT_GRAY_BG, fill_type="solid")
        return

    is_formula = isinstance(cell.value, str) and cell.value.startswith("=")
    has_sheet_ref = is_formula and "!" in cell.value if is_formula else False

    if is_formula and has_sheet_ref:
        cell.font = Font(name="Calibri", size=10, color=GREEN_CROSSSHEET)
    elif is_formula:
        cell.font = Font(name="Calibri", size=10, color=BLACK_FORMULA)
    elif cell.value is not None:
        cell.font = Font(name="Calibri", size=10, color=BLUE_INPUT)
        cell.fill = PatternFill(start_color=YELLOW_INPUT_BG, end_color=YELLOW_INPUT_BG, fill_type="solid")


def apply_ib_formatting(input_path: str, output_path: str) -> None:
    """Apply IB formatting standards to all sheets in the workbook."""
    wb = load_workbook(input_path)

    for ws in wb.worksheets:
        # Format header row (row 1)
        for cell in ws[1]:
            apply_cell_formatting(cell, is_header=True)

        # Format data rows
        for row in ws.iter_rows(min_row=2):
            for cell in row:
                if cell.value is not None:
                    apply_cell_formatting(cell)

                # Right-align numeric columns
                if isinstance(cell.value, (int, float)):
                    cell.alignment = Alignment(horizontal="right")
                elif cell.column == 1:
                    cell.alignment = Alignment(horizontal="left")

        # Apply number formatting to numeric cells
        for row in ws.iter_rows(min_row=2):
            for cell in row:
                if isinstance(cell.value, (int, float)):
                    if abs(cell.value) >= 1:
                        cell.number_format = FORMAT_THOUSANDS
                    elif 0 < abs(cell.value) < 1:
                        cell.number_format = FORMAT_PERCENT

        # Freeze panes on header row
        ws.freeze_panes = "A2"

        # Turn off gridlines
        ws.sheet_view.showGridLines = False

    wb.save(output_path)
    print(f"IB formatting applied: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Apply IB formatting to Excel workbook")
    parser.add_argument("input", help="Path to the source .xlsx file")
    parser.add_argument("output", help="Path to save the formatted .xlsx file")
    args = parser.parse_args()

    apply_ib_formatting(args.input, args.output)


if __name__ == "__main__":
    main()
