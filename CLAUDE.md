# Forest Plot Builder — Claude Code Context

## Project
Shiny app generating publication-ready forest plots. Wraps the `forestHelperR`
package (already stabilised, 112 tests passing).

## Key files
- `global.R` — package loads, global objects
- `server.R` — all reactive logic
- `ui.R` — layout and inputs
- `app-changelog-decision-register.md` — decisions and changes log (update this for every change)
- `issues-register.md` — open issues register

## Current phase
App code review and issue resolution. Working through three batches:
- Batch 1: namespace qualifiers + undeclared packages (ISS-013, 014, 015)
- Batch 2: UI label corrections (ISS-017, 018, 019, 027)
- Batch 3: dead code removal + reactive tidying (ISS-022, 023, 024, 025, 016/026)

## Conventions
- Always use explicit package::function() notation
- Update the changelog register for every code change made
- Do not guess — if unsure, ask before editing
- Prefer req() over is.null() guards in reactives
- All documentation in .md format

## Do not modify
- forestHelperR package files (separate repo)
- renv.lock (if present)