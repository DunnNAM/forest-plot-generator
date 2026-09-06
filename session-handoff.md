# Forest Plot Builder — Session Handoff

> **Last refreshed:** 2026-09-06 — FEAT-011 merged to `main`; a real git history purge
> and Connect Cloud publish also happened this window. This is a genuine handoff to a
> **new session** — read this whole file before doing anything else.
> **Purpose:** Session continuity — read at the start of a session, alongside `CLAUDE.md`.
> **Scope note:** `CLAUDE.md` is the standing context (architecture, conventions, file
> map). This document is the *current* state of play and what to pick up next. If the
> two disagree, `CLAUDE.md` wins on conventions and this file wins on status.

> **2026-09-06 — every commit hash on both `main` and `design/modal-progression-workflow`
> was rewritten, for real this time.** An earlier commit (CHG-040) sanitized
> `renv.lock`'s *current* content but deliberately left git history unrewritten (its
> own text says so) — that left a colleague's real full name and personal email
> address still recoverable from old commits on what is now a **public** repo. A
> follow-up pass used `git filter-branch` (a BFG-style history rewrite) to scrub both
> strings from every historical version of `renv.lock`/`manifest.json` on both
> branches, verified by scanning every blob in the object database directly (not just
> `git log`), then force-pushed both branches to `origin`. A GitHub Support ticket was
> also filed to purge the orphaned pre-rewrite objects, since force-pushing alone
> doesn't guarantee GitHub's servers drop them immediately — **check for a reply next
> session, see §3 item 1.** Every hash this document, `CLAUDE.md`, and
> `issues-register.md` cite was updated at the time of this rewrite — but if you're
> reading an older cached copy of any of these docs, or comparing against a note/link
> from before 2026-09-06, the hash it names no longer exists. Match by commit
> **subject line** (unchanged by the rewrite) instead, or ask rather than assume a
> stale hash is wrong content.

---

## 1. Project overview

Shiny app providing a GUI for publication-ready forest plots from regression output
(Poisson, Logistic, Cox PH). Wraps the companion package `forestHelperR`
(`regTabler()`, `forestPloter()`), which was stabilised in an earlier phase and is
**not** modified from this repo.

Version control: GitHub, `DunnNAM/forest-plot-generator` (**public** repo — see the
history-purge note above for why), single `main` branch, linear history (DEC-001).
The `design/modal-progression-workflow` branch that DEC-001 used to treat as "the one
active experimental branch" is **now merged and identical to `main`** (same commit,
`394ea5d` as of this writing) — it's still on `origin` but has nothing left to do; no
DEC has been raised on formally deleting it.

---

## 2. State of play

**Everything that was in flight is now either done or explicitly deferred.** In order:

| Phase | Outcome |
|---|---|
| Package stabilisation | Complete — 112 tests passing in `forestHelperR` |
| Code review / issue resolution | Complete — ISS-013 … ISS-027 resolved (CHG-007/008/009) |
| Test infrastructure (ISS-004) | Complete — `testthat` + `shinytest2` (CHG-014/015) |
| Font migration (DEC-003) | Complete — `extrafont` → `sysfonts`/`showtext` (CHG-016) |
| **DEC-004** file split | Complete — `server/` + `R/` split, no Shiny modules (CHG-018 … CHG-024) |
| **DEC-005** restyle | Complete — Steps 0-7 (CHG-029 … CHG-034, CHG-038) |
| **Connect Cloud publish** | Complete — `main` is published (confirmed by the user); ISS-036 fully resolved along the way (CHG-040) |
| **FEAT-011** (wizard + Data-drawer/navbar redesign) | **Merged to `main` 2026-09-06** — see below |
| **Git history purge** | Complete — see the top-of-file note |

The app's current layout is the DEC-005 bottom-rail + drawer design, now with **filled
pill navbar tabs** (CHG-055, replacing the original underline/divider design — see §7)
and a first-visit **setup wizard** (FEAT-011). Design rationale for the base restyle
lives in `restyle-implementation-plan.md` (historical — do not add new scope to it);
FEAT-011's own rationale is scattered across `app-changelog-decision-register.md`'s
CHG-041–058 (see that file's renumbering note — the branch used its own CHG-039–056
numbering before the merge, now shifted +2 to avoid colliding with `main`'s real
CHG-039/040) and `issues-register.md`'s FEAT-011 entry.

**What FEAT-011 actually shipped**, briefly (full detail in the changelog entries
above): a soft-gated setup wizard (skippable, restartable via a new "Tour" rail item);
a titled-field/divider visual convention extended to every drawer panel except Export;
combined Variables estimate-column toggles into one radio group; the app now loads
with a working Simulated-data example already plotted; rail/status-chip clicks anchor
the main tab to whichever drawer is open; the Plot tab's card grows to the plot's full
height instead of an internal scrollbar; the Display panel was reshaped into a 3-group
50/25/25 layout with a configurable x-axis tick count and domain-scoped mirror-pairing;
the navbar was redesigned as filled pills (fixing ISS-042's navbar sub-issues, after an
earlier attempt — CHG-054 — landed none of its three intended fixes); the same pill
treatment reached the wizard's modal footers and the Export drawer, which was also
narrowed, centred, and given a single divider; a CSS audit's five low-risk quick fixes
were applied (z-index, an undeclared custom property, dead template CSS, overflow
scope). Along the way, one real pre-existing bug was found and fixed: `www/wizard.js`'s
first-visit detection listened for `"shiny:connected"` via `document.addEventListener`,
which can never catch an event Shiny fires through jQuery's `.trigger()` — the wizard
had silently never shown itself to a genuine first-time visitor since it was written
(ISS-038, fixed CHG-049).

**Still genuinely open from FEAT-011:** ISS-042's sub-issue 1 (Help page title still
not left-aligned — the navbar work never touched `R/ui_help.R`) and ISS-045 through
ISS-048 (an architecture review's findings: a wizard Step-2 modal styling gap;
widespread un-namespaced `pkg::fun()` calls; a couple of testability/DRY items) — none
of these are started. See §5.

**Also still open, unrelated to FEAT-011:** `README.md` (ISS-041) has been stale since
before DEC-004/DEC-005 — still describes the old sidebar+accordion layout and lists
resolved issues as current limitations. Deliberately not rewritten yet.

---

## 3. NEXT SESSION — things this session did NOT verify

**No code is half-finished and no test is red** (see §6) — this isn't a "finish the
work" handoff, it's a "check the work" one. Four things specifically:

1. **Check for a reply on the GitHub Support ticket** about purging the orphaned
   pre-history-purge commit objects (the ones containing the colleague's real
   name/email, no longer reachable from any branch but not yet garbage-collected by
   GitHub). If they've confirmed the purge, note it in `app-changelog-decision-
   register.md`; if not, no action needed yet, just don't assume it's done.
2. **Do a live visual check of the merged FEAT-011 UI end-to-end.** Most of FEAT-011's
   individual pieces were verified in isolation (either via served HTML/CSS text with
   no browser tool, or via the user's own live checks turn-by-turn) — nobody has
   looked at the *whole* merged app running together yet. Specifically worth eyeballing:
   the wizard's first-visit flow, the navbar pills across both tabs, the Export
   drawer's new layout, and — per item 3 below — the Help page title alignment.
   **The Chrome browser extension is gone from this session, on purpose — do not try
   to reconnect it** (see the `no-chrome-extension-user-inspects-visually` memory).
   The user does the visual checking and directs fixes turn by turn; this is the
   standing process now, not a one-off workaround (see §7's CHG-055 entry for why).
3. **ISS-042 sub-issue 1 (Help page title left-alignment) is still open** — confirmed
   not touched by any FEAT-011 commit. Worth a quick check next time the Help tab is
   open. The original hypothesis (an `R/ui_help.R` class rename needing a full R
   restart, not just a browser refresh, to actually take effect) was never confirmed
   or ruled out — restart R fully before concluding it's still broken.
4. **Confirm Connect Cloud's auto-deploy actually picked up today's push.** The
   handoff before this merge listed "turn on auto-deploy" as not-yet-confirmed
   end-to-end; if it's on, the FEAT-011 merge should already be live — check the
   deployed app matches what's in `main` now, not a stale pre-merge build.

Housekeeping, not urgent: `.git/rebase-merge/` is an empty leftover directory from
this session's rebase — the sandbox this session ran in couldn't delete it
(`.git` internals are protected), so `git status` may still say "You are currently
rebasing" even though `HEAD` is a normal branch ref pointing at the right commit. A
plain `rm -rf .git/rebase-merge` (or the PowerShell equivalent) clears it; harmless
either way.

Beyond those four, the open queue in §5 (README refresh, R 4.5.2 migration, the
internal `styling` package, the architecture-review findings) is genuinely just a
backlog — pick whatever seems most useful, or ask the user.

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

**Verification gate:** the baseline is **48 assertions / 23 blocks** and
**9 assertions / 6 blocks**, all passing under R 4.3.3 (see §6, reverified 2026-09-06
post-merge). Re-run both under 4.5.2 and compare before snapshotting.

---

## 5. Open queue

Beyond §3 (things to check) and §4 (the migration), this is a backlog — no mandated
order:

| ID | Sev | What | Note |
|---|---|---|---|
| **ISS-042** | Low | Sub-issue 1 only: Help page title left-alignment | Navbar sub-issues (2, 3) resolved — CHG-055. Sub-issue 1 never touched; see §3. |
| **ISS-041** | Medium | `README.md` describes the pre-restyle app (sidebar/accordion, no tests, no renv) | User-facing and actively misleading, not just incomplete. Deliberately not fixed yet — worth its own pass. |
| **ISS-045** | Low-Medium | Wizard Step 2 modal missing `.wizard-modal-footer`/`.btn-wizard-skip` wrapper classes | Visible regression mid-wizard-flow: modal shrinks, buttons lose flex parity. Fix mirrors `wizardWelcomeModal()` exactly — see `issues-register.md`. |
| **ISS-046** | Medium | Widespread un-namespaced `pkg::fun()` calls across `ui.R`/`R/ui_*.R`/`server/*.R` | Direct contradiction of `CLAUDE.md`'s own convention. Large surface area — do deliberately, one file/topic at a time, verifying tests after each. |
| **ISS-047** | Low/Medium | `xticks_default()`/`make_log_range()` are pure math but live inside `server/observers.R` | Extract to `R/helpers.R`; add unit tests. |
| **ISS-048** | Low | Estimate-label `case_when()` in `server/preview.R` duplicates `get_est_type()` in `R/helpers.R` | Replace with a call to the existing helper. |
| **ISS-049–054** | Low/Note | Remaining architecture/CSS audit findings — doc-only, not started | Data panel field-wrapper inconsistency, unannotated `server.R` file-order dependency, redundant reactive dereferencing, redundant `isTruthy()`-in-`req()`, unbundled `'JetBrains Mono'` font reference, two divergent "cream" colour tokens. Full detail in `issues-register.md`. |
| **ISS-043** | — (feature) | Add internal `styling` package as a dependency (colour palettes, fonts) | Doc-only, not started. Same deployability question ISS-036 was — whatever internal-package-hosting approach gets chosen should probably cover this too. |
| **ISS-028** | Medium | Age group levels not in clinical sort order | Highest-severity pre-existing item and the only one affecting output correctness — but it lives in `forestHelperR`, so it needs a session in *that* repo. Explicitly out of scope per plan §10. |
| **ISS-029** | Low | OS system fonts absent from selector after `sysfonts` migration | |
| **ISS-030** | Low | `"Source Sans Pro"` renamed on Google Fonts; silently absent | |
| **ISS-039** | Low | x-axis tick generation always splits evenly either side of 1 | Doesn't suit a skewed distribution. Deferred future-development note, not an immediate ask. |
| **ISS-040** | Low | Variables rail badge can briefly flash a stale "hidden" count on load | Cosmetic, self-corrects. User explicitly asked this be logged rather than fixed now. |
| Follow-up | — | Confirm with Helen whether she's comfortable with her real name/masked-email on the now-public `forestHelperR` repo | Currently credited as `Helen ***` / `H*.*@health.qld.gov.au` pending her confirmation. Not resolved by the history purge — that removed the *leaked, unmasked* version from history; the masked attribution question is separate and still open. |
| PDEC-005 | — | Move `forestHelperR` to its own repo? | Already effectively actioned by the Connect Cloud publish work (CHG-040) — worth formally closing this pending decision rather than leaving it open. |
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

Both suites were re-run against the merged `main` on 2026-09-06: **48/48 unit
assertions, 9/9 integration assertions, both green.** (One integration run hit a
transient Chromote startup timeout on 4/6 blocks — a clean re-run passed all 6/9; if
you see the same thing, it's very likely a resource/timing fluke, not a regression —
retry once before treating it as real.)

Until the R 4.5.2 migration lands, run under **R 4.3.x**
(`C:\Program Files\R\R-4.3.3\bin\`) — R 4.5.2 has no populated library.

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
- **Stale docs have bitten this project three times now.** The restyle plan claimed
  "nothing implemented" for four months after it shipped; a later handoff described a
  phase three phases out of date; and this file itself spent a while describing a
  merge that was still mid-conflict-resolution. If you finish a phase, update
  `CLAUDE.md` §Current phase and this file in the same commit.
- **`rsconnect::writeManifest()` calls `renv::snapshot()` internally, in *both* its
  lockfile-based and library-based dependency-resolution modes** — this isn't
  documented up front and the two failure modes look unrelated until you trace them.
  The default (lockfile) mode aborts on any library/lockfile drift at all; a
  library-based mode still internally re-snapshots the local library and its
  pre-flight validation aborts outright on any package with an "unknown" source — this
  is what surfaced ISS-036 as a real Connect Cloud deploy blocker, not just an R 4.5.2
  migration issue. Neither failure has a documented flag to skip validation; the fix
  that worked was giving `forestHelperR` a real resolvable source (a public GitHub
  repo, CHG-040), not fighting the validator.
- **A negation in a parent `.gitignore` cannot re-include a file inside a directory
  a *closer* (more specific) `.gitignore` already excludes.** `renv/.gitignore`
  excludes `cellar/` outright; a negation added to the *root* `.gitignore` silently did
  nothing (`git check-ignore -v` still showed it ignored) — the un-ignore has to live
  inside `renv/.gitignore` itself, as a line after the exclusion it's overriding.
- **`conditionalPanel()` renders `display: contents` when shown**, not `block`. It
  promotes its children into the parent's flex/grid layout for *sizing* purposes, but
  CSS structural selectors (`:first-child`, `:not(:first-child)`, `.parent > *`) still
  only see the un-promoted DOM tree — they silently match nothing on a promoted child.
  Found building the Data drawer's field dividers (FEAT-011).
- **A background dev-server restart on this Windows setup doesn't reliably kill the
  previous `Rscript.exe`.** Stopping a background task and starting a new
  `shiny::runApp()` task can leave the old R process running and orphaned. Check
  `tasklist //FI "IMAGENAME eq Rscript.exe"` periodically if you've been restarting a
  lot, and `taskkill //PID <pid> //F` anything not the one actually listening on the
  port in use (`netstat -ano | grep :<port>` identifies it).
- **A restart is not always necessary.** `www/*.css` and `www/*.js` are served fresh
  from disk on every browser request — only `ui.R`/`R/*.R`/`server/*.R` changes need
  the R process restarted. A CSS-only edit just needs the browser refreshed (bump the
  stylesheet's `?v=` cache-buster in `ui.R` if the browser might have it cached).
- **Shiny fires `"shiny:connected"` via jQuery's `.trigger()`, not a native DOM event.**
  `document.addEventListener("shiny:connected", ...)` can never catch it — confirmed by
  reading the bundled `shiny.min.js` directly. Any client-side "run once Shiny connects"
  code needs `jQuery(document).on("shiny:connected", ...)` instead. This is what ISS-038
  turned out to be, and it had been silently broken since CHG-041 (the wizard's
  original commit) — worth checking any other `addEventListener("shiny:...", ...)`
  call in the codebase for the same mistake if one ever gets added.
- **A plain `observe()` re-fires on the very first reactive flush too**, not just on
  later changes — including when the reactive value it reads is already valid from
  app-start defaults. This bit the wizard's auto-advance observer once Simulated data
  (with a valid response/predictor selection) became the default: it fired almost
  instantly instead of waiting for the user to do something. `bindEvent(..., ignoreInit
  = TRUE)` on the actual inputs that should trigger it is the fix — see CHG-050.
- **htmltools' pretty-printer inserts whitespace between a tag call's separate
  arguments**, and between *inline* elements (unlike block-level ones) that collapses to
  a visible stray space in the browser. `p("...", strong("X"), ", ", strong("Y"), ...)`
  can render as "X , Y" instead of "X, Y". Building the sentence as one `HTML()` string
  sidesteps it — see CHG-050 / `R/ui_wizard.R`.
- **A CSS descendant selector matches a nested `.drawer-field-block` too, not just a
  direct row item.** `.drawer-row-divided .drawer-field-block--divided` (the divider
  rule) matches *any* descendant with that class, regardless of nesting depth — a field
  nested inside another field's own content picks up the row-level divider padding
  meant for actual row items, visibly shifting it right of its siblings. Fix is always
  `first = TRUE` on a nested `drawerFieldUI()`/`drawerGroupUI()` call, not just on
  top-level row items — see CHG-052.
- **`bslib::navset_card_tab()`'s fill behaviour can't be turned off via its own
  arguments — its outer `card()` call is hardcoded inside `bslib` with no `fill`
  passthrough** (confirmed by reading the `bslib` 0.8.0 source directly:
  `bslib:::navset_card` calls `card(height = height, full_screen = full_screen, ...)`).
  `page_navbar(fillable = FALSE)` only turns off *page*-level fill context; the card
  keeps sizing itself via its own resize JS regardless. Overriding in CSS
  (`height: auto !important` etc., which *does* beat an inline style even one JS keeps
  rewriting — a real spec exception) was the practical fix, not reimplementing the
  component against `bslib`'s undocumented internals — see CHG-051 / `www/style.css`.
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
  see CHG-051.
- **`shinyWidgets::noUiSliderInput()`'s handle *count* is fixed at creation** —
  `updateNoUiSliderInput()` only repositions/reconfigures existing handles (confirmed
  via the package's own formals and example app), it can't add or remove them. Changing
  how many handles a multi-value slider has means rebuilding it via `renderUI()` (same
  pattern as the Data panel's file table / Order panel's sortable list — remember
  `outputOptions(..., suspendWhenHidden = FALSE)` for it) — see CHG-052.
- **CSS/layout reasoning verified only against stylesheet text, without an actual
  rendered screenshot, is not reliable enough to report as "verified."** An earlier
  navbar/Help-tab styling attempt (CHG-054) made three changes with detailed reasoning
  about flexbox `align-items`, absolute-positioning offsets, and class scoping — all
  internally consistent on paper, checked via `curl` for served HTML/CSS and balanced
  braces, but no Chrome browser extension was available that session so none of it was
  actually seen rendered. The user's own live check immediately after found none of the
  three fixes landed, and one regressed (ISS-042). **Resolution that actually worked
  (CHG-055, same day):** the user removed the Chrome extension from the session
  entirely and instead checked each CSS round live in their own browser, directing the
  next fix — i.e. the fix wasn't "get Claude a working browser tool", it was "the
  human does the visual verification and Claude iterates on direction." This is now
  the standing process — see the `no-chrome-extension-user-inspects-visually` memory —
  not a one-off workaround.
- **bslib's `page_navbar()` does not emit plain Bootstrap 5 navbar markup.** It uses
  Bootstrap-3-style compatibility structure: `.navbar-brand` renders as a `<span>`
  nested inside a `.navbar-header` wrapper div (which also holds the mobile toggle
  button), and `.navbar-header` — not `.navbar-brand` — is the actual flex child of
  `.container-fluid`. Any CSS assuming `.navbar-brand` is a direct flex sibling of
  `.navbar-collapse` (the natural assumption from reading plain Bootstrap 5 docs) will
  silently target the wrong element for flex alignment. Found (CHG-055) by fetching the
  served HTML directly (`curl http://127.0.0.1:<port>/`) after a `margin-bottom` change
  on `.navbar-brand` visibly had no effect — worth doing this check early for any
  navbar-brand-position CSS in this app, rather than assuming standard markup.
- **Bootstrap 5.3's `.nav-underline` utility class is present by default on bslib's
  generated tab `<ul>`** (`page_navbar()`'s tabs render as `<ul class="nav navbar-nav
  nav-underline" ...>`), and its own rule
  `.navbar .nav-underline :where(ul.nav.navbar-nav > li)>a` — specificity 0-2-1 — set
  `padding-bottom`/`margin-bottom` intended to make *its own* underline style hug the
  navbar's border. This silently overrides a plain `.navbar-nav .nav-link` selector
  (specificity 0-2-0) **regardless of which stylesheet loads last** — a same-property
  override that isn't about `!important` or edit order, just a higher-specificity
  selector nobody wrote deliberately for this app. Found (CHG-055) by fetching
  `bootstrap.min.css` directly and diffing it against what our own `.nav-link` rule
  declared — this is what made every previous attempt at aligning the active-tab
  underline fail regardless of how the offset math was tuned. Worth checking for on any
  future `.nav-link`/tab-styling work in this app; the eventual fix was to stop
  fighting it (switch to filled pill tabs, which don't need underline-precision
  alignment at all) rather than out-specificity it.
- **A merge/rebase that spans many commits touching the same doc files repeatedly is
  its own kind of slog — plan for it.** Rebasing FEAT-011's 18 commits onto `main`'s 3
  Connect Cloud commits hit a doc-file conflict (`app-changelog-decision-register.md`,
  `issues-register.md`, `session-handoff.md`) at nearly every step, because both sides
  had been updating these same running logs independently. Resolving it required a
  genuine numbering-collision fix (the branch's own CHG-039–056 vs. `main`'s real
  CHG-039/040) applied consistently across every subsequent conflict, not just once.
  If a long-lived branch and `main` both maintain these registers, expect this same
  slog on the next big merge — there's no shortcut besides doing it carefully.

---

## 8. Conventions reminder

Full list in `CLAUDE.md`. The two most often missed:

- **Update `app-changelog-decision-register.md` for every change** — every code change
  gets a CHG entry; decisions get a DEC entry; issues get an ISS/FEAT entry.
- **Explicit `package::function()` notation everywhere.** (Currently violated
  widely — see ISS-046.)

---
