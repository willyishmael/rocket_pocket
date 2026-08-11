---
description: "Use when editing Flutter code in this repository to enforce MVVM boundaries, reusable widget checks, concise English line comments, and consistent code style."
applyTo: "lib/**/*.dart, test/**/*.dart"
---

# Global Style Consistency Rules

## Architecture
- Keep strict MVVM boundaries:
  - UI in screens/widgets.
  - State and UI logic in viewmodels.
  - Data access in services/repositories.
  - No business logic inside widgets.

## Widget Reuse
- Before creating a new widget, search existing widgets and shared UI components first.
- If a new widget can be reused across screens, make it reusable from the start.
- If a widget is intentionally local-only, keep it small and document why reuse is not needed.

## Code Style Consistency
- Match naming, structure, and formatting patterns already used in nearby files.
- Prefer minimal, focused diffs and avoid unrelated refactors.
- Keep functions small and single-purpose where practical.

## Function Comments
- Comments must be in English.
- Use plain line comments only.
- Use minimal mode for obvious/simple functions:
  - Add comment only when it prevents confusion.
  - Keep one short line.
- Use standard mode for complex functions:
  - Explain non-obvious logic, assumptions, side effects, or important constraints.
  - Keep to one to three short lines.

## Comment Recheck Requirement
- If editing a function:
  - Recheck comments for that function and related nearby comments in the same file.
- If editing a whole file:
  - Recheck comments for all functions in that file.
- Remove stale, redundant, or misleading comments.

## Completion Criteria
- MVVM boundaries remain intact.
- Existing widgets were checked before adding new widgets.
- Naming and style are consistent with the project.
- Function comments follow English line-comment rules and are rechecked for touched scope.
