---
name: function-comments-simple
description: 'Write short, clear English line comments for functions. Use during feature execution or other coding tasks to keep comment quality and style consistent.'
argument-hint: 'Provide file(s) or function(s), and whether to apply minimal mode, standard mode, or auto mode.'
user-invocable: true
---

# Function Comments Simple

## Outcome
Apply clear function comments efficiently during edits, following the canonical policy in `.github/instructions/global-style-consistency.instructions.md`.

## When to Use
- During feature implementation by Feature Executor.
- During any coding task that modifies function logic.
- Add or improve comments only where clarity gains are meaningful.

## Canonical Rules Source
- Use `.github/instructions/global-style-consistency.instructions.md` as the single source of truth for:
   - English-only comments
   - Plain line comments
   - Minimal vs standard mode behavior
   - Scope defaults and comment recheck requirements

## Modes
- Minimal mode:
   - Use for obvious/simple functions.
- Standard mode:
   - Use for complex functions.
- Auto mode (default):
   - Minimal mode for obvious/simple functions.
   - Standard mode for complex functions.

## Procedure
1. Identify target functions and read nearby code for context.
2. Decide if a comment is needed:
   - Needed: business rule, side effect, non-obvious flow, or important assumption.
   - Not needed: obvious getter/setter or trivial wrapper.
3. Select mode:
    - Minimal mode for obvious/simple functions.
    - Standard mode for complex functions.
4. Write or revise comments using the global instruction rules.
5. Re-read comments with this check:
   - Can a new teammate understand the function in under 10 seconds?
   - Is every sentence necessary?

## Quick Patterns
- Good: "Calculates monthly spending from expense transactions only."
- Good: "Validates pocket balance from latest DB state before saving."
- Avoid: "This function loops through list and adds numbers."
- Avoid: "Helper method for processing data in many different cases and situations."

## Completion Checks
- Comments are added only where they improve understanding.
- No duplicate or redundant comments remain.
- Global instruction policy is followed for touched scope.
