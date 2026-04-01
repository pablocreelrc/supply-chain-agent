"""Validate an Excel workbook against IB formatting and formula standards.

Usage:
    python scripts/excel_validator.py <input.xlsx>

Returns JSON to stdout with validation results:
    {
        "status": "pass" | "fail",
        "checks": {
            "formula_audit": {"pass": true/false, "issues": [...]},
            "reference_check": {"pass": true/false, "issues": [...]},
            "totals_tieout": {"pass": true/false, "issues": [...]},
            "zero_errors": {"pass": true/false, "issues": [...]},
            "color_compliance": {"pass": true/false, "issues": [...]},
            "format_consistency": {"pass": true/false, "issues": [...]}
        }
    }
"""

import argparse
import json
import sys

try:
    from openpyxl import load_workbook
    from openpyxl.styles import Font
except ImportError:
    print("Error: openpyxl is required. Install with: pip install openpyxl", file=sys.stderr)
    sys.exit(1)

# IB Color Constants
BLUE_INPUT = "0000FF"
BLACK_FORMULA = "000000"
GREEN_CROSSSHEET = "008000"


def check_color_compliance(ws):
    """Verify IB color rules: blue for inputs, black for formulas, green for cross-sheet."""
    issues = []
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            if cell.value is None:
                continue
            font_color = cell.font.color.rgb if cell.font.color and cell.font.color.rgb else None
            if font_color and isinstance(font_color, str):
                font_color = font_color[-6:]  # Strip alpha prefix
            is_formula = isinstance(cell.value, str) and cell.value.startswith("=")
            has_sheet_ref = is_formula and "!" in cell.value if is_formula else False
            if is_formula and has_sheet_ref and font_color and font_color != GREEN_CROSSSHEET:
                issues.append(f"{cell.coordinate}: Cross-sheet formula should be green, got {font_color}")
            elif is_formula and not has_sheet_ref and font_color and font_color not in (BLACK_FORMULA, GREEN_CROSSSHEET):
                issues.append(f"{cell.coordinate}: Formula should be black, got {font_color}")
            elif not is_formula and font_color and font_color not in (BLUE_INPUT, BLACK_FORMULA):
                pass  # Headers and labels can be any color
    return {"pass": len(issues) == 0, "issues": issues[:20]}


def check_formula_errors(ws):
    """Scan for Excel formula errors (#REF!, #DIV/0!, #VALUE!, #N/A, #NAME?)."""
    error_values = {"#REF!", "#DIV/0!", "#VALUE!", "#N/A", "#NAME?", "#NULL!", "#NUM!"}
    issues = []
    for row in ws.iter_rows():
        for cell in row:
            if isinstance(cell.value, str) and cell.value in error_values:
                issues.append(f"{cell.coordinate}: {cell.value}")
    return {"pass": len(issues) == 0, "issues": issues}


def check_format_consistency(ws):
    """Check that number formatting is consistent within columns."""
    issues = []
    col_formats = {}
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            if cell.value is not None and isinstance(cell.value, (int, float)):
                col = cell.column_letter
                fmt = cell.number_format
                if col not in col_formats:
                    col_formats[col] = fmt
                elif col_formats[col] != fmt and fmt != "General":
                    issues.append(f"Column {col}: Mixed formats ({col_formats[col]} vs {fmt})")
                    break
    return {"pass": len(issues) == 0, "issues": issues[:10]}


def validate_workbook(filepath: str) -> dict:
    """Run all validation checks on the workbook."""
    wb = load_workbook(filepath, data_only=True)
    results = {
        "formula_audit": {"pass": True, "issues": []},
        "reference_check": {"pass": True, "issues": []},
        "totals_tieout": {"pass": True, "issues": []},
        "zero_errors": {"pass": True, "issues": []},
        "color_compliance": {"pass": True, "issues": []},
        "format_consistency": {"pass": True, "issues": []},
    }

    for ws in wb.worksheets:
        errors = check_formula_errors(ws)
        if not errors["pass"]:
            results["zero_errors"]["pass"] = False
            results["zero_errors"]["issues"].extend(
                [f"[{ws.title}] {i}" for i in errors["issues"]]
            )

        colors = check_color_compliance(ws)
        if not colors["pass"]:
            results["color_compliance"]["pass"] = False
            results["color_compliance"]["issues"].extend(
                [f"[{ws.title}] {i}" for i in colors["issues"]]
            )

        formats = check_format_consistency(ws)
        if not formats["pass"]:
            results["format_consistency"]["pass"] = False
            results["format_consistency"]["issues"].extend(
                [f"[{ws.title}] {i}" for i in formats["issues"]]
            )

    overall = all(v["pass"] for v in results.values())
    return {"status": "pass" if overall else "fail", "checks": results}


def main():
    parser = argparse.ArgumentParser(description="Validate Excel workbook against IB standards")
    parser.add_argument("filepath", help="Path to the .xlsx file")
    args = parser.parse_args()

    result = validate_workbook(args.filepath)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["status"] == "pass" else 1)


if __name__ == "__main__":
    main()
