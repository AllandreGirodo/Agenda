---
name: camel-case-checker
description: '**WORKFLOW SKILL** — Verify and enforce camelCase naming convention for field names and variables in Dart code. Automatically corrects non-compliant names by converting them to camelCase and updating all usages. USE FOR: ensuring consistent naming conventions in Flutter/Dart projects. DO NOT USE FOR: other languages, manual reviews, or when auto-correction is not desired.'
---

# Camel Case Checker

This skill checks all Dart files in the workspace for variable and field declarations that do not follow camelCase naming convention (starting with lowercase letter, no underscores, alphanumeric only). For each violation, it converts the name to camelCase (e.g., `user_name` to `userName`, `UserName` to `userName`) and updates all usages of that variable/field in the codebase.

## Workflow Steps

1. **Search for declarations**: Use grep to find all variable and field declarations in `.dart` files. Pattern: `\b(var|final|const|dynamic|String|int|double|bool|List|Map|Set)\s+(\w+)\s*[;=]`

2. **Extract names**: For each match, extract the variable name (second capture group).

3. **Check camelCase**: Verify if the name matches `^[a-z][a-zA-Z0-9]*$`. If yes, skip. If no, proceed to correction.

4. **Compute new name**: Convert to camelCase:
   - Split by underscores, capitalize each part except first, join.
   - If starts with uppercase, lowercase the first letter.

5. **Find all usages**: Use `vscode_listCodeUsages` to find all references to the symbol.

6. **Replace all occurrences**: For each usage location, use `replace_string_in_file` to update the name.

7. **Report changes**: List all variables corrected and files modified.

## Notes

- This assumes simple conversions; complex cases may need manual review.
- Back up the codebase before running, as this modifies files.
- Only applies to Dart files.

## Example Usage

/camel-case-checker

This will scan and fix all non-camelCase variables in the project.