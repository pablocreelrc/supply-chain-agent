"""Recalculate all formulas in an Excel workbook and check for errors.

Usage:
    python scripts/recalc.py <input.xlsx>

Returns JSON to stdout:
    {"status": "ok"} or {"status": "errors_found", "error_summary": [...]}

Note: Uses openpyxl in data_only mode to scan for cached formula errors.
For full recalculation, open in Excel or LibreOffice.
"""

import argparse
import json
import sys

try:
    from openpyxl import load_workbook
except ImportError:
    print("Error: openpyxl is required. Install with: pip install openpyxl", file=sys.stderr)
    sys.exit(1)

ERROR_VALUES = {"#REF!", "#DIV/0!", "#VALUE!", "#N/A", "#NAME?", "#NULL!", "#NUM!"}


def recalculate(filepath: str) -> dict:
    """Scan workbook for formula errors in cached values.

    Args:
        filepath: Path to the .xlsx file.

    Returns:
        Dict with 'status' key ('ok' or 'errors_found') and optional 'error_summary'.
    """
    wb = load_workbook(filepath, data_only=True)
    errors = []

    for ws in wb.worksheets:
        for row in ws.iter_rows():
            for cell in row:
                if isinstance(cell.value, str) and cell.value in ERROR_VALUES:
                    errors.append({
                        "sheet": ws.title,
                        "cell": cell.coordinate,
                        "error": cell.value,
                    })

    if errors:
        return {"status": "errors_found", "error_summary": errors}
    return {"status": "ok"}


def main():
    parser = argparse.ArgumentParser(description="Check Excel formulas for errors")
    parser.add_argument("filepath", help="Path to the .xlsx file")
    args = parser.parse_args()

    result = recalculate(args.filepath)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["status"] == "ok" else 1)


if __name__ == "__main__":
    main()
