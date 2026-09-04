# Reviews — Forest Plot Builder

Ongoing record of architectural audits and bug-hunting reviews for the project.
Each review is a point-in-time snapshot checking the codebase against the
decisions in `app-changelog-decision-register.md`, the conventions in
`CLAUDE.md`, and the open items in `issues-register.md`.

Modelled on the same convention used in `mdt-activity-dashboard/reviews/`.

## Folder structure

```
reviews/
  README.md                          ← this file
  architecture/                      ← decision-register / readiness audits
    YYYY-MM-DD_<topic>.md
  bugs/                              ← targeted bug-hunt / code-review reports
    YYYY-MM-DD_<topic>.md
```

## Conventions

- **File naming:** `YYYY-MM-DD_<short-topic>.md`. One file per review session.
- **Reports are read-only artefacts.** Never edit a past review to "fix" a
  finding — resolve the finding in code/registers and note it in the *next*
  review. The history of what was found and when is the point.
- **Findings feed the registers, not the other way round.** A review proposes
  candidate `ISS-NNN` / `DEC-NNN` / `CHG-NNN` entries; they only become
  official when added to `issues-register.md` /
  `app-changelog-decision-register.md` (check for duplicates and use the next
  free ID, per CLAUDE.md).
- **Each report should carry:** date, scope (files audited), git ref
  (`git rev-parse --short HEAD`), and whether the working tree was dirty.
- **Severity legend used in reports:**
  - ❌ Violation / bug — contradicts an Active decision or is a defect
  - ⚠️ Drift / risk — works today but diverges from a decision or convention
  - ℹ️ Note — minor, cosmetic, or informational
  - ✅ Compliant — explicitly verified, not just unexamined

## How to run a review

- Architecture / readiness audit: audit `global.R`, `ui.R`, `server.R`,
  `R/`, `server/` against both registers and CLAUDE.md conventions. Save the
  output to `reviews/architecture/`.
- Bug-focused review: run `/code-review` at the desired effort level and save
  notable findings to `reviews/bugs/`.

## Review index

| Date | Type | File | Headline |
|---|---|---|---|
| 2026-09-04 | CSS / Styling | [architecture/2026-09-04_css-stylesheet-audit.md](architecture/2026-09-04_css-stylesheet-audit.md) | Stylesheet inspection & conflict audit: wizard modal Step 2 width/button styling discrepancy; drawer scrim z-index inversion (98 vs 1027); ~65 lines of dead template CSS; flexbox min-width conflict on Display drawer. |
| 2026-09-04 | Architecture | [architecture/2026-09-04_architecture-code-review.md](architecture/2026-09-04_architecture-code-review.md) | Function-based architecture audit (DEC-004): 48/48 unit and 9/9 integration tests green; candidate ISS-033 resolved; F-5 un-namespaced `pkg::fun()` drift across UI/server; F-6 pure math helpers in `server/observers.R`; F-7 duplicated estimate label logic in `server/preview.R`. |
| 2026-06-10 | Architecture | [architecture/2026-06-10_restyle-readiness-review.md](architecture/2026-06-10_restyle-readiness-review.md) | Restyle readiness: DEC-004 Steps 5–7 incomplete and unpushed; `Rplots.pdf` tracked artifact; `output$forest` inside `observe()`; unqualified `ggsave()`/`glm()` convention drift. Companion plan: `restyle-implementation-plan.md` |
