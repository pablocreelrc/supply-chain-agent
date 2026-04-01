"""Shortcut.ai API wrapper for generating polished Excel workbooks.

Usage:
    python scripts/shortcut_bridge.py "<prompt>" [--output output.xlsx]

Reads the Shortcut.ai API key from .env file (SHORTCUT_API_KEY).
Generates an Excel workbook, applies IB formatting, and validates.
"""

import argparse
import os
import subprocess
import sys

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # User must set SHORTCUT_API_KEY env var manually


def get_api_key() -> str:
    """Get Shortcut.ai API key from environment."""
    key = os.environ.get("SHORTCUT_API_KEY")
    if not key:
        print("Error: SHORTCUT_API_KEY not found. Set in .env or environment.", file=sys.stderr)
        sys.exit(1)
    return key


def generate_excel(prompt: str, output_path: str = "output.xlsx") -> str:
    """Generate an Excel workbook via Shortcut.ai API.

    Args:
        prompt: Description of the Excel workbook to generate.
        output_path: Path to save the generated .xlsx file.

    Returns:
        Path to the generated file.
    """
    api_key = get_api_key()

    # Build the IB-formatted prompt with standards embedded
    ib_prompt = f"""Create a professional Excel workbook with IB (Investment Banking) formatting:

{prompt}

Formatting requirements:
- Font: Calibri 10pt throughout
- Hardcoded inputs: blue font (0,0,255), yellow cell fill
- Formulas: black font (0,0,0), no fill
- Cross-sheet references: green font (0,128,0)
- Headers: bold, white font on dark navy background, bottom border
- Number formatting: commas for thousands, parentheses for negatives
- No $ symbol in body rows — only on first data row and totals row
- Assumptions tab as the last sheet with named ranges
- Freeze panes on header rows, gridlines off
"""

    # Call shortcut_excel.py (the global wrapper)
    try:
        result = subprocess.run(
            ["python", "shortcut_excel.py", "--prompt", ib_prompt, "--output", output_path],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(f"Shortcut.ai generation failed: {result.stderr}", file=sys.stderr)
            sys.exit(1)
    except FileNotFoundError:
        print("Error: shortcut_excel.py not found. Ensure it is in your PATH or current directory.", file=sys.stderr)
        sys.exit(1)

    # Apply IB formatting post-processing
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    formatter = os.path.join(scripts_dir, "ib_formatter.py")
    subprocess.run(["python", formatter, output_path, output_path], check=True)

    # Validate the output
    validator = os.path.join(scripts_dir, "excel_validator.py")
    validation = subprocess.run(["python", validator, output_path], capture_output=True, text=True)
    print(validation.stdout)

    return output_path


def main():
    parser = argparse.ArgumentParser(description="Generate Excel via Shortcut.ai with IB formatting")
    parser.add_argument("prompt", help="Description of the workbook to generate")
    parser.add_argument("--output", "-o", default="output.xlsx", help="Output file path")
    args = parser.parse_args()

    path = generate_excel(args.prompt, args.output)
    print(f"Generated: {path}")


if __name__ == "__main__":
    main()
