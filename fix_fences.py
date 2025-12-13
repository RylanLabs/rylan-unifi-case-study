#!/usr/bin/env python3
"""Fix MD031 violations by ensuring exactly one blank line before/after fences."""

import re
import sys
from pathlib import Path


def fix_fences(content: str) -> str:
    """Add blank lines before/after fenced code blocks, removing excess blanks."""
    lines = content.split("\n")
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if current line is fence start (``` or ```lang)
        if re.match(r"^```\w*$", line):
            # Ensure exactly 1 blank before fence (if not at start)
            if result and result[-1].strip() != "":
                result.append("")
            elif result and len(result) >= 2 and result[-1] == "" and result[-2] == "":
                # Remove extra blank
                result.pop()

            result.append(line)
            i += 1

            # Copy fence content until closing ```
            while i < len(lines) and lines[i].strip() != "```":
                result.append(lines[i])
                i += 1

            # Add closing fence
            if i < len(lines):
                result.append(lines[i])
                i += 1

            # Ensure exactly 1 blank after fence (if not at end)
            if i < len(lines) and lines[i].strip() != "":
                result.append("")
            # Skip existing blanks
            while i < len(lines) and lines[i].strip() == "":
                i += 1
                break
        else:
            result.append(line)
            i += 1

    return "\n".join(result)


def main():
    if len(sys.argv) < 2:
        print("Usage: fix-fences.py <file1.md> [file2.md ...]")
        sys.exit(1)

    for filepath in sys.argv[1:]:
        path = Path(filepath)
        if not path.exists():
            print(f"Skip {filepath}: not found")
            continue

        content = path.read_text()
        fixed = fix_fences(content)

        if fixed != content:
            path.write_text(fixed)
            print(f"Fixed {filepath}")
        else:
            print(f"No changes for {filepath}")


if __name__ == "__main__":
    main()
