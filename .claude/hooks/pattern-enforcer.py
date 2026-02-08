#!/usr/bin/env python3
"""
Pattern Enforcer Hook for Claude Code

This hook runs before Edit/Write operations to catch anti-patterns
and provide feedback to Claude before they're committed.

Exit codes:
- 0: Allow operation
- 2: Block operation (with feedback message to stdout)
"""

import json
import sys
import re
import os

def check_patterns(file_path: str, new_content: str) -> list[str]:
    """Check content for anti-patterns and return list of violations."""
    violations = []

    # Skip non-code files
    if not file_path.endswith(('.ts', '.tsx', '.sql')):
        return violations

    lines = new_content.split('\n')

    # === Server Action Checks ===
    if 'actions.ts' in file_path or 'actions/' in file_path:

        # Check for direct Supabase usage (should use repository)
        for i, line in enumerate(lines, 1):
            if re.search(r'supabase\s*\.\s*from\s*\(', line):
                if 'repository' not in file_path.lower():
                    violations.append(
                        f"Line {i}: Direct Supabase query in server action. "
                        f"Use repository function instead.\n"
                        f"  Found: {line.strip()}\n"
                        f"  Fix: Import from @/app/_shared/repositories/"
                    )

        # Check for missing revalidatePath after mutations
        has_mutation = any(
            re.search(r'\b(insert|update|delete)\b', line, re.IGNORECASE)
            for line in lines
        )
        has_revalidate = any('revalidatePath' in line for line in lines)

        if has_mutation and not has_revalidate:
            violations.append(
                "Missing revalidatePath() after mutation. "
                "Add revalidatePath('/path') after data changes to invalidate cache."
            )

    # === Repository Checks ===
    if '.repository.ts' in file_path:

        # Check for column picking (should use select *)
        for i, line in enumerate(lines, 1):
            # Match .select("field1, field2") but NOT .select("*") or .select(`*,...)
            if re.search(r'\.select\s*\(\s*["\'][^*]', line):
                if '(*)' not in line and '(`' not in line:
                    violations.append(
                        f"Line {i}: Column picking detected. Use select('*') instead.\n"
                        f"  Found: {line.strip()}\n"
                        f"  Fix: .select('*') for type safety"
                    )

    # === Component Checks ===
    if file_path.endswith('.tsx') and 'components' in file_path:

        # Check for hardcoded colors (should use CSS variables)
        color_patterns = [
            (r'bg-(blue|red|green|yellow|purple|pink|orange|gray|slate|zinc)-\d{2,3}', 'bg-primary/secondary/muted'),
            (r'text-(blue|red|green|yellow|purple|pink|orange|gray|slate|zinc)-\d{2,3}', 'text-primary/secondary/muted-foreground'),
            (r'border-(blue|red|green|yellow|purple|pink|orange|gray|slate|zinc)-\d{2,3}', 'border-primary/border'),
        ]

        for i, line in enumerate(lines, 1):
            for pattern, suggestion in color_patterns:
                if re.search(pattern, line):
                    match = re.search(pattern, line)
                    violations.append(
                        f"Line {i}: Hardcoded color '{match.group(0)}'. Use CSS variables.\n"
                        f"  Found: {line.strip()}\n"
                        f"  Fix: Use {suggestion} instead"
                    )

        # Check for raw HTML elements (should use shadcn)
        raw_elements = [
            (r'<button\s', '<Button> from @/components/ui/button'),
            (r'<input\s', '<Input> from @/components/ui/input'),
            (r'<textarea\s', '<Textarea> from @/components/ui/textarea'),
            (r'<select\s', '<Select> from @/components/ui/select'),
        ]

        for i, line in enumerate(lines, 1):
            for pattern, suggestion in raw_elements:
                if re.search(pattern, line, re.IGNORECASE):
                    violations.append(
                        f"Line {i}: Raw HTML element detected. Use shadcn/ui.\n"
                        f"  Found: {line.strip()}\n"
                        f"  Fix: Use {suggestion}"
                    )

    # === Protected Files ===
    protected_patterns = [
        (r'database\.types\.ts$', "database.types.ts is auto-generated. Run 'npm run db:types' instead."),
        (r'\.env', ".env files contain secrets. Don't edit directly."),
        (r'package-lock\.json$', "package-lock.json is auto-generated. Run npm install instead."),
    ]

    for pattern, message in protected_patterns:
        if re.search(pattern, file_path):
            violations.append(f"Protected file: {message}")

    return violations


def main():
    """Main hook entry point."""
    try:
        # Read input from stdin (JSON from Claude Code)
        input_data = json.load(sys.stdin)

        tool_input = input_data.get('tool_input', {})
        file_path = tool_input.get('file_path', '')

        # For Edit tool, we check new_string
        # For Write tool, we check content
        new_content = tool_input.get('new_string', '') or tool_input.get('content', '')

        if not file_path or not new_content:
            sys.exit(0)  # Allow if we can't determine what's being edited

        # Check for violations
        violations = check_patterns(file_path, new_content)

        if violations:
            # Output feedback and block the operation
            print("⛔ Pattern Violations Detected\n")
            print(f"File: {file_path}\n")
            for i, violation in enumerate(violations, 1):
                print(f"{i}. {violation}\n")
            print("\nPlease fix these issues before proceeding.")
            print("See .claude/skills/ for pattern documentation.")
            sys.exit(2)  # Block with feedback

        sys.exit(0)  # Allow operation

    except json.JSONDecodeError:
        # If we can't parse input, allow the operation
        sys.exit(0)
    except Exception as e:
        # Log error but allow operation to not block development
        print(f"Hook error (allowing operation): {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
