# Forest Plot Builder — Session Handoff

> **Last refreshed:** 2026-09-06 (CHG-039/040, Connect Cloud publish prep; merged with
> `design/modal-progression-workflow`'s own handoff refresh through CHG-058 — see
> `app-changelog-decision-register.md`'s renumbering note for why the branch's own
> CHG-039..056 became CHG-041..058 in the merge)
> **Purpose:** Session continuity — read at the start of a session, alongside `CLAUDE.md`.
> **Scope note:** `CLAUDE.md` is the standing context (architecture, conventions, file
> map). This document is the *current* state of play and what to pick up next. If the
> two disagree, `CLAUDE.md` wins on conventions and this file wins on status.

---

## 1. Project overview

Shiny app providing a GUI for publication-ready forest plots from regression output
(Poisson, Logistic, Cox PH). Wraps the companion package `forestHelperR`
(`regTabler()`, `forestPloter()`), which was stabilised in an earlier phase and is
**not** modified from this repo.

Version control: GitHub, `DunnNAM/forest-plot-generator` (private repo), single `main`
branch, linear history (DEC-001) — plus one active experimental branch, see below.

**Also worth knowing:** an experimental branch, `design/modal-progression-workflow`
(FEAT-011, a first-visit setup wizard + Data drawer visual redesign), diverged from
`main` at CHG-038 (2026-09-04) and is still in progress as of this writing — not
merged, no DEC raised on whether to adopt it. It's on a separate publish/merge track
from the Connect Cloud work below; see that branch's own commits and `issues-register.md`
(FEAT-011, ISS-042, ISS-044..048) for its state.

---

## 2. State of play

**All planned programmes of work on `main`'s application code are complete.** There is
no in-flight migration or half-finished refactor in the app itself. The one piece of
live work right now is deployment prep (see §3), not a code change. See §1 above for
the `design/modal-progression-workflow` branch's own, separate status; ISS-038 (a real
pre-existing first-visit-trigger bug the branch found and fixed) is detailed in
`issues-register.md`.

**Also worth knowing:** `README.md` (both on this branch and on `main`) is
significantly stale — untouched since before DEC-004/DEC-005, still describing the
old sidebar+accordion layout and listing resolved issues (no tests, no renv lockfile)
as current limitations. Raised as **ISS-041**, deliberately not rewritten yet —
flagged for its own pass rather than folded into unrelated UI work.

| Phase | Outcome |
|---|---|
| Package stabilisation | Complete — 112 tests passing in `forestHelperR` |
| Code review / issue resolution | Complete — ISS-013 … ISS-027 resolved (CHG-007/008/009) |
| Test infrastructure (ISS-004) | Complete — `testthat` + `shinytest2` (CHG-014/015) |
| Font migration (DEC-003) | Complete — `extrafont` → `sysfonts`/`showtext` (CHG-016) |
| **DEC-004** file split | Complete — `server/` + `R/` split, no Shiny modules (CHG-018 … CHG-024) |
| **DEC-005** restyle | **Complete** — Steps 0-7 (CHG-029 … CHG-034, CHG-038). Step 7 / FEAT-010 shipped 2026-09-04 |

The app's current layout is the DEC-005 bottom-rail + drawer design. The design
rationale lives in `restyle-implementation-plan.md` (a historical record — do not add
new scope to it) and its companion audit in
`reviews/architecture/2026-06-10_restyle-readiness-review.md`.

---

## 3. NEXT SESSION — Connect Cloud publish, in progress (started 2026-09-06)

**This is the live piece of work right now**, ahead of the R 4.5.2 migration below.
Goal: publish `main` to Posit Connect Cloud via its GitHub-integrated deploy, turn on
auto-deploy on push, then merge `design/modal-progression-workflow` into `main` as a
git-workflow exercise.

**Done so far:**
- **CHG-039 (interim, superseded):** `manifest.json` generated with `forestHelperR`
  resolved via a committed `renv/cellar/` tarball. **First real deploy attempt from
  `main` failed** with `Package forestHelperR has invalid package source Cellar.` —
  Connect Cloud does its own server-side dependency resolution against the cloned
  repo's `manifest.json`/`renv.lock`, and `"Cellar"` is a reference to *this
  machine's* directory, meaningless to its build servers. Confirms ISS-036 needed a
  real fix, not a local workaround.
- **CHG-040 (real fix): `forestHelperR` published to `github.com/DunnNAM/forestHelperR`
  (new repo, public).** Sanitized before publishing (full source-tree scan found only
  the maintainer's personal email — no Gitea/internal references elsewhere);
  reattributed rather than stripped, at the user's direction: original author
  credited with a masked identity (`Helen ***` / `H*.*@health.qld.gov.au`) pending
  her own confirmation, Nathan Dunn added as maintainer with a real contact.
  `renv.lock`'s `forestHelperR` entry updated to a real `"Source": "GitHub"` record
  — **the scoped `renv.lock` override the user explicitly authorized**, DEC-006-style
  but for this deploy blocker. `manifest.json` regenerated via the *default*
  lockfile-based path this time (no workaround needed) — 138/138 packages match,
  including `svglite`/`systemfonts`/`textshaping` (the ISS-035-pattern gap from
  CHG-039, resolved automatically this time). **ISS-036 is now fully resolved.**
- **Repo visibility:** tried Connect Cloud's GitHub App flow with `main` private
  first, per plan — confirmed **Connect Cloud's free tier only lists public repos**
  in its repository picker regardless of GitHub App permissions (public repos showed,
  private ones didn't, even with access correctly granted and the right GitHub
  account). `main` was made public as a result. `forestHelperR` was made public too,
  for the same reason (Connect Cloud's build step needs to fetch it).
- **Two real, live privacy exposures found and fixed along the way** (not hypothetical
  — both were actually live on GitHub for a window): (1) CHG-039's cellar commit put
  the *original, unsanitized* tarball on the now-public `main` — removed from the
  current tree, **git history on `main` deliberately left unrewritten** (the
  unmerged `design/modal-progression-workflow` branch would need rebasing onto any
  rewritten history — a bigger, separate decision, not made this session); (2) the
  first `forestHelperR` publish commit's own message quoted the real email while
  describing its removal — fixed via amend + force-push, safe only because that repo
  had exactly one commit and nothing depended on it yet.
- Verified throughout: 48/48 unit + 9/9 integration assertions pass.

**Not yet done — pick up here:**
1. Push this session's commits to `origin/main` (manifest/renv.lock/register updates,
   cellar-tarball removal, README attribution).
2. Retry the Connect Cloud deploy from `main` — should now find the repo (public) and
   resolve `forestHelperR` correctly (real GitHub source, no more "Cellar" error).
   This is the next real test; not yet confirmed end-to-end successful as of this
   writing.
3. Once deployed, turn on auto-deploy on push to `main`.
4. Merge `design/modal-progression-workflow` into `main` (decided: merge as-is, not
   cherry-picked, as a git-workflow exercise — see §1).
5. **Follow up with Helen** on whether she's comfortable with her real name/email on
   the now-public `forestHelperR` repo — currently masked pending that confirmation.
6. Separately flagged, not yet started: the user wants to add an internal `styling`
   package (colour palettes, fonts) as a future dependency, same deployability
   category `forestHelperR` was in — logged as **ISS-043** (doc-only).
7. Worth a deliberate look later, not urgent: whether to fully purge `main`'s git
   history of the leaked tarball (see point 3 under "Done so far" above) — deferred,
   not decided against, just not done today.

---

## 4. R 4.5.2 migration (manual, planned 2026-09-04) — still open, not this session's focus

An automated attempt on 2026-09-03 failed; see CHG-037 for the full record. Read this
before retrying so you don't repeat it.

**Current position:** the project runs on **R 4.3.x**. `renv.lock` pins R 4.3.1, and
`renv/library/R-4.3/` is fully populated — the app and both test files work there today.
`renv/library/windows/R-4.5/` is empty apart from renv itself. Nothing is half-migrated.

**What blocked the automated attempt:**

1. ~~**`forestHelperR` has no resolvable source (ISS-036).**~~ **Resolved 2026-09-06,
   CHG-040** — `renv.lock` now records a real `"Source": "GitHub"` entry
   (`github.com/DunnNAM/forestHelperR`). `renv::restore()` should no longer fail on
   this package specifically; not yet re-verified against an actual 4.5.2 restore
   attempt, so treat as likely-fixed rather than confirmed until retried.
2. **A compiled-package cascade.** `renv::restore()` aborted with 12 failures — `DT`,
   `broom`, `colourpicker`, `forestHelperR`, `forestploter`, `ggplot2`, `gridExtra`,
   `stringi`, `stringr`, `svglite`, `textshaping`, `tidyr`. `stringi` compiles from
   source (it builds the whole ICU library) and most of the rest depend on it directly
   or via `stringr`; `textshaping`/`svglite` are the other compiled group. The exact
   `stringi` failure was not captured — **capture the full install log when retrying**,
   do not pipe it through `tail`.

**Toolchain:** Rtools45 is installed (`C:\rtools45`) and was being used correctly — the
build log references it, so the toolchain was not the blocker. **Rtools43 was removed**
by the winget upgrade, so R 4.3.x no longer has a matching toolchain. The existing
R-4.3 library is already built so the app still *runs* there, but compiling new source
packages under 4.3.x needs Rtools43 reinstalled from CRAN.

**Lockfile:** per **DEC-006**, running `renv::snapshot()` to record R 4.5.2 is
authorised for this migration, overriding the standing "do not modify `renv.lock`"
convention. Snapshot **only after** the suite is green under 4.5.2 — a lockfile
recording a broken environment is worse than a stale one. Rollback is
`git checkout renv.lock`.

**Verification gate:** the pre-migration baseline is **48 assertions / 23 blocks** and
**9 assertions / 6 blocks**, all passing under R 4.3.3 (see §6). Re-run both under 4.5.2
and compare before snapshotting.

---

## 5. Open queue

Beyond the two live items above (§3 Connect Cloud, §4 migration), this is a backlog:

| ID | Sev | What | Note |
|---|---|---|---|
| **ISS-036** | — | ~~`forestHelperR` recorded as `Source: "unknown"` in `renv.lock`~~ | ✅ Resolved (CHG-040) — published to `github.com/DunnNAM/forestHelperR`, `renv.lock` now records a real `"Source": "GitHub"`. `renv::restore()` should now fully succeed, unblocking the R 4.5.2 migration's own prerequisite too — not yet re-verified on 4.5.2 itself. |
| **ISS-043** | — (feature) | Add internal `styling` package as a dependency (colour palettes, fonts) | Doc-only, not started. Same deployability question as ISS-036 — whatever eventually fixes ISS-036 properly should probably cover this too. |
| **ISS-028** | Medium | Age group levels not in clinical sort order | Highest-severity pre-existing item and the only one affecting output correctness — but it lives in `forestHelperR`, so it needs a session in *that* repo. Explicitly out of scope per plan §10. |
| **ISS-029** | Low | OS system fonts absent from selector after `sysfonts` migration | |
| **ISS-030** | Low | `"Source Sans Pro"` renamed on Google Fonts; silently absent | |
| **ISS-041** | Medium | `README.md` describes the pre-restyle app (sidebar/accordion, no tests, no renv) | User-facing and actively misleading, not just incomplete. Deliberately not fixed yet — worth its own pass. |
| **ISS-039** | Low | x-axis tick generation always splits evenly either side of 1 | Doesn't suit a skewed distribution. Deferred future-development note from the user, not an immediate ask. |
| **ISS-040** | Low | Variables rail badge can briefly flash a stale "hidden" count on load | Cosmetic, self-corrects. User explicitly asked this be logged rather than fixed now. |
| **FEAT-011** | — | Decide whether `design/modal-progression-workflow` gets merged/adopted | Merged to `main` (2026-09-06, rebase — see `app-changelog-decision-register.md`'s renumbering note). |
| PDEC-005 | — | Move `forestHelperR` to its own repo? | Deferred — gated on publication/hosting being scoped. Note ISS-036 may force this conversation earlier, and now has a concrete Connect Cloud reason to as well. |
| PDEC-006 | — | Declare package deps vs. document manual install | Deferred to a future package maintenance cycle |

---

## 6. Running the app and the tests

```r
shiny::runApp()
```

```r
testthat::test_file("tests/testthat/test-helpers.R")     # 23 blocks / 48 assertions
testthat::test_file("tests/testthat/test-shiny-app.R")   # 6 blocks / 9 assertions
```

**`NOT_CRAN=true` is required for the integration tests (ISS-037).** `shinytest2`'s
`AppDriver$new()` calls `skip_on_cran()` internally. Without it all 6 blocks skip
silently *and the run still exits 0* — it reads as a pass. `devtools::test()` and the
RStudio runner set it for you; a bare `Rscript -e ...` does not:

```sh
NOT_CRAN=true Rscript -e 'testthat::test_file("tests/testthat/test-shiny-app.R")'
```

Until the migration lands, run under **R 4.3.x** (`C:\Program Files\R\R-4.3.3\bin\`) —
R 4.5.2 has no populated library.

---

## 7. Traps worth knowing

- **Hidden drawer panels suspend their outputs.** Panels are `display:none` by default,
  so Shiny suspends anything inside them — including `downloadButton`s, which render as
  `disabled` with an empty `href`. Anything live in a hidden panel needs
  `outputOptions(output, "<id>", suspendWhenHidden = FALSE)` in `server/drawers.R`.
  This bit both the export buttons and the data/UI outputs during DEC-005 (CHG-033).
- **Drawer panels are static, not `renderUI`.** Every input ID is in the DOM from app
  start; the active panel is chosen by toggling a CSS class. This is deliberate — see
  DEC-005 — and is why the shinytest2 suite survived the restyle nearly unmodified.
- **A green-looking test run may be a skipped one.** See ISS-037 above.
- **Stale docs have bitten this project twice.** The restyle plan claimed "nothing
  implemented" for four months after it shipped, and this handoff described a phase
  three phases out of date. If you finish a phase, update `CLAUDE.md` §Current phase
  and this file in the same commit.
- **`rsconnect::writeManifest()` calls `renv::snapshot()` internally, in *both* its
  lockfile-based and library-based dependency-resolution modes** — this isn't
  documented up front and the two failure modes look unrelated until you trace them.
  The default (lockfile) mode aborts on any library/lockfile drift at all (found
  2026-09-06: a trivial `codetools` version mismatch was enough); `dependencyResolution
  = "library"` mode still internally re-snapshots the local library and its pre-flight
  validation aborts outright on any package with an "unknown" source — this is what
  actually surfaced ISS-036 as a real deploy blocker, not just an R 4.5.2 migration
  issue. Neither failure has a documented flag to skip validation; the fix that worked
  was giving the installed package a resolvable source via `renv/cellar/` +
  `renv::install()` (see CHG-039), not fighting the validator.
- **A negation in a parent `.gitignore` cannot re-include a file inside a directory
  a *closer* (more specific) `.gitignore` already excludes.** `renv/.gitignore`
  excludes `cellar/` outright; adding `!renv/cellar/forestHelperR_0.2.0.tar.gz` to the
  *root* `.gitignore` silently did nothing (`git check-ignore -v` still showed it
  ignored) — the un-ignore had to be added inside `renv/.gitignore` itself, as a line
  after the exclusion it's overriding. Found 2026-09-06 committing the ISS-036
  cellar workaround.
- **`conditionalPanel()` renders `display: contents` when shown**, not `block`. It
  promotes its children into the parent's flex/grid layout for *sizing* purposes, but
  CSS structural selectors (`:first-child`, `:not(:first-child)`, `.parent > *`) still
  only see the un-promoted DOM tree — they silently match nothing on a promoted child.
  Found 2026-09-04 (design/modal-progression-workflow, `www/style.css` has the full
  writeup) building the Data drawer's field dividers.
- **A background dev-server restart on this Windows setup doesn't reliably kill the
  previous `Rscript.exe`.** Stopping a background task and starting a new
  `shiny::runApp()` task can leave the old R process running and orphaned (found
  2026-09-04 — three stray processes, one at 200+ MB, accumulated over a session of
  restarts). Check `tasklist //FI "IMAGENAME eq Rscript.exe"` periodically if you've
  been restarting a lot, and `taskkill //PID <pid> //F` anything not the one actually
  listening on the port in use (`netstat -ano | grep :<port>` identifies it).
- **A restart is not always necessary.** `www/*.css` and `www/*.js` are served fresh
  from disk on every browser request — only `ui.R`/`R/*.R`/`server/*.R` changes need
  the R process restarted. A CSS-only edit just needs the browser refreshed (bump the
  stylesheet's `?v=` cache-buster in `ui.R` if the browser might have it cached).
- **Shiny fires `"shiny:connected"` via jQuery's `.trigger()`, not a native DOM event.**
  `document.addEventListener("shiny:connected", ...)` can never catch it — confirmed by
  reading the bundled `shiny.min.js` directly. Any client-side "run once Shiny connects"
  code needs `jQuery(document).on("shiny:connected", ...)` instead. This is what ISS-038
  turned out to be, and it had been silently broken since CHG-039 — worth checking any
  other `addEventListener("shiny:...", ...)` call in the codebase for the same mistake
  if one ever gets added.
- **A plain `observe()` re-fires on the very first reactive flush too**, not just on
  later changes — including when the reactive value it reads is already valid from
  app-start defaults. This bit the wizard's auto-advance observer once Simulated data
  (with a valid response/predictor selection) became the default: it fired almost
  instantly instead of waiting for the user to do something. `bindEvent(..., ignoreInit
  = TRUE)` on the actual inputs that should trigger it is the fix — see CHG-048.
- **htmltools' pretty-printer inserts whitespace between a tag call's separate
  arguments**, and between *inline* elements (unlike block-level ones) that collapses to
  a visible stray space in the browser. `p("...", strong("X"), ", ", strong("Y"), ...)`
  can render as "X , Y" instead of "X, Y". Building the sentence as one `HTML()` string
  sidesteps it — see CHG-048 / `R/ui_wizard.R`.
- **A CSS descendant selector matches a nested `.drawer-field-block` too, not just a
  direct row item.** `.drawer-row-divided .drawer-field-block--divided` (the divider
  rule) matches *any* descendant with that class, regardless of nesting depth — a field
  nested inside another field's own content (e.g. a sub-field added to an existing
  titled field) picks up the row-level divider padding meant for actual row items,
  visibly shifting it right of its siblings. Fix is always `first = TRUE` on a nested
  `drawerFieldUI()`/`drawerGroupUI()` call, not just on top-level row items — found
  2026-09-04 (CHG-050) when "Number of decimal places" landed inside Variables'
  Estimate Column Formatting field without it.
- **`bslib::navset_card_tab()`'s fill behaviour can't be turned off via its own
  arguments — its outer `card()` call is hardcoded inside `bslib` with no `fill`
  passthrough** (confirmed by reading the `bslib` 0.8.0 source directly:
  `bslib:::navset_card` calls `card(height = height, full_screen = full_screen, ...)`).
  `page_navbar(fillable = FALSE)` only turns off *page*-level fill context; the card
  keeps sizing itself via its own resize JS regardless. Overriding in CSS
  (`height: auto !important` etc., which *does* beat an inline style even one JS keeps
  rewriting — a real spec exception) was the practical fix, not reimplementing the
  component against `bslib`'s undocumented internals — see CHG-049 / `www/style.css`.
- **`plotOutput()`'s `height` argument only accepts a fixed CSS length — passing
  `"auto"` breaks Shiny's own client-side plot-resize JS.** The rendered `<img>` came
  back with a literal `height="[object Object]"` HTML attribute (confirmed by
  inspecting the tag directly) instead of erroring visibly. A CSS override on the
  container achieves the same effect safely. Separately: the `<img>` itself only ever
  carries `width="100%"` with no CSS `style` at all, so it always stretches to fill the
  container's current width — if the server renders the bitmap at a fixed pixel
  resolution (unrelated to display size, as `server/plot.R`'s `dims()`-based sizing
  does here), widening the container stretches a fixed-resolution image over more
  screen space, reading as "zoomed in, blurry" rather than an actual quality
  regression. `width: auto; max-width: 100%` (shrink-only, never stretch) is the fix —
  see CHG-049.
- **`shinyWidgets::noUiSliderInput()`'s handle *count* is fixed at creation** —
  `updateNoUiSliderInput()` only repositions/reconfigures existing handles (confirmed
  via the package's own formals and example app), it can't add or remove them. Changing
  how many handles a multi-value slider has means rebuilding it via `renderUI()` (same
  pattern as the Data panel's file table / Order panel's sortable list — remember
  `outputOptions(..., suspendWhenHidden = FALSE)` for it) — see CHG-050.

---

## 8. Conventions reminder

Full list in `CLAUDE.md`. The two most often missed:

- **Update `app-changelog-decision-register.md` for every change** — every code change
  gets a CHG entry; decisions get a DEC entry; issues get an ISS/FEAT entry.
- **Explicit `package::function()` notation everywhere.**

---
