# Architecture review — restyle readiness audit

| Field | Detail |
|---|---|
| **Date** | 2026-06-10 |
| **Type** | Architecture / readiness audit (pre-restyle) |
| **Git ref** | `9e0ca4e` (local `main`, **5 commits ahead of `origin/main`**, nothing to pull) |
| **Working tree** | **Dirty** — `server.R` modified, `server/plot.R` untracked (DEC-004 Step 5 / CHG-022 pending smoke test + commit); `Rplots.pdf` and `.claude/settings.json` modified |
| **Scope** | `global.R`, `ui.R`, `server.R`, `R/helpers.R` (skimmed), `R/ui_plot_options.R`, `server/upload.R`, `server/regression.R`, `server/preview.R` (skimmed), `server/plot.R`, `www/styles.css`, both registers |
| **Purpose** | Establish the current state before the bottom-rail/drawer restyle (see `restyle-implementation-plan.md` at project root) and record findings that affect or precede it |

---

## 1. Remote sync state

✅ Checked `origin/main` (fetched 2026-06-10). The remote has **no commits the
local machine lacks**. Local `main` is 5 commits ahead (CHG-014 → DEC-004
Step 4) and has uncommitted Step 5 work. **The remote is stale, not the local
copy.** Push after Step 5 commits.

## 2. DEC-004 file-split state

✅ Steps 1–4 committed and consistent with `handover-dec004-file-split.md`.

⚠️ **Step 5 (CHG-022) is in limbo** — `server/plot.R` exists and is sourced by
`server.R`, tests reported passing, but the smoke test and commit are pending.
The working tree has been in this state since the last session. Any restyle
work must not begin on top of this; complete/commit Step 5 first.

🔲 Steps 6 (export → `server/export.R`) and 7 (misc observers →
`server/observers.R`) not started — the remaining ~165 lines of `server.R`
are exactly that scope. The restyle plan depends on Step 6 in particular
(export handlers must be in their own file before the Export drawer rework).

## 3. Findings

### F-1 ❌ `Rplots.pdf` is a tracked build artifact

`Rplots.pdf` is committed and shows as modified on every run (headless plot
device output). It will churn in every commit and bloat history.
**Candidate ISS-032:** `git rm --cached Rplots.pdf`, add to `.gitignore`.

### F-2 ⚠️ `output$forest` assigned inside an `observe()` (`server/plot.R` §e)

```r
observe({
  req(forest_plot_object())
  output$forest <- renderPlot({ ... }, width = dims()[1]*72*1.5, ...)
})
```

Registering an output inside an observer is a known anti-pattern: the
`renderPlot` is re-registered on every invalidation. It works because
`width`/`height` need reactive values, but `renderPlot()` accepts
**functions** for `width`/`height`, which is the supported idiom:

```r
output$forest <- renderPlot({ forest_plot_object() },
  width  = function() dims()[1]*72*1.5,
  height = function() dims()[2]*72*1.5,
  res = 72*1.5)
```

**Candidate ISS-033.** Low urgency, but worth folding into the Step 5/CHG-022
commit window or a follow-up CHG, since `server/plot.R` is already open.

### F-3 ⚠️ Unqualified base/foreign calls — convention drift

CLAUDE.md requires explicit `package::function()` notation. Found:

- `server.R` download handlers call `ggsave()` unqualified — and **`ggplot2`
  is not loaded in `global.R`** at all. It currently works only because a
  dependency attaches it (likely `forestHelperR`/`forestploter` Depends).
  On a refactor of those packages this breaks silently at export time —
  same failure class as resolved ISS-013/ISS-014.
- `server/regression.R`: `glm()`, `as.formula()` unqualified (`stats::`).

**Candidate ISS-034:** qualify as `ggplot2::ggsave()`, `stats::glm()`,
`stats::as.formula()`; decide whether `library(ggplot2)` belongs in
`global.R`. Also confirm SVG export device: `ggsave(device = "svg")` needs
`svglite` or `grDevices::svg` — verify which is in `renv.lock`.

### F-4 ℹ️ Stylesheet link has no cache-busting

`ui.R` links `styles.css` plainly; the MDT template appends
`?v=<timestamp>`. Browsers cache aggressively during iterative CSS work.
Fold into the restyle (no separate ISS needed).

### F-5 ℹ️ Inline styles in `ui.R` export-button block

The four export buttons use `div(style="display:inline-block; ...")`
wrappers — this is the proximate cause of **ISS-031** (fourth button wraps
with no spacing). The restyle plan resolves ISS-031 and supersedes the
*location* proposed in FEAT-009 (sidebar accordion) with an Export drawer,
while keeping FEAT-009's interaction design (format radio + single download
button; separate copy/download buttons for code).

### F-6 ✅ Input ID surface is restyle-friendly

All ~45 input IDs live in flat `ui.R` / `R/ui_plot_options.R` definitions
(no modules, per DEC-004). `conditionalPanel()` conditions reference inputs
that will remain in the DOM under a CSS show/hide drawer approach. The
shinytest2 tests target input IDs, not layout containers, so a restyle that
**preserves every input ID** should keep all 7 integration tests valid.

### F-7 ✅ Server logic is layout-agnostic

`server/upload.R`, `regression.R`, `preview.R`, `plot.R` reference no layout
containers — only input/output IDs. The DEC-004 split means the restyle is
almost entirely a `ui.R` + `R/` + `www/` change. This was verified by
reading each file, not assumed.

## 4. Candidate register entries proposed

| Candidate | Type | Summary |
|---|---|---|
| ISS-032 | Issue (Low) | `Rplots.pdf` tracked build artifact — untrack + gitignore |
| ISS-033 | Issue (Low) | `output$forest` registered inside `observe()`; use function-valued `width`/`height` |
| ISS-034 | Issue (Medium) | `ggsave()` unqualified and `ggplot2` undeclared in `global.R`; `glm()`/`as.formula()` unqualified |
| DEC-005 | Decision | Adopt MDT theme + bottom rail/drawer layout — see `restyle-implementation-plan.md` |

These become official only when added to the registers with the next free IDs.

---

*Report is a read-only artefact — resolve findings in code/registers and note
outcomes in the next review.*
