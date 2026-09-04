# CSS Stylesheet Audit — Conflict & Quality Review

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Type** | Stylesheet Inspection & Conflict Audit |
| **Git ref** | `2edee25` (branch `design/modal-progression-workflow`) |
| **Working tree** | Uncommitted review artefacts (`reviews/README.md`, `.agy-context.md`, prior architecture review) |
| **Scope** | `www/style.css` (1,014 lines) cross-referenced against `ui.R`, `R/ui_*.R`, `server/drawers.R`, and `www/*.js` |
| **Purpose** | Identify contradictory rules, layout conflicts, specificity traps, and orphaned CSS to inform a comprehensive cleanup pass |

---

## 1. Executive Summary

A deep audit of [`www/style.css`](file:///C:/Users/namdu/OneDrive/Documents/ShinyStuff/Sandbox/forest-plot-generator/www/style.css) was conducted to evaluate styling coherence, layout robustness, and rule conflicts. 

The stylesheet is generally well-documented with rich contextual commentary from recent design iterations (DEC-005, FEAT-010, FEAT-011). However, rapid feature development and template porting have introduced several **concrete layout conflicts**, **stacking order bugs**, **approximately 65 lines of dead template CSS**, and **missing token declarations**.

---

## 2. Functional Contradictions & Layout Conflicts

### 2.1 ❌ Wizard Step 2 Modal Layout Inconsistency
* **Location:** `www/style.css:941–981` vs `R/ui_wizard.R:78–91`
* **Mechanism:**
  - In `www/style.css`, the modal widening (`max-width: 650px`) and equal-width button flexbox distribution (`flex: 1 1 0; min-width: 0;`) are scoped via `:has(.wizard-modal-footer)`.
  - In `R/ui_wizard.R`, `wizardWelcomeModal()` wraps its footer in `<div class="wizard-modal-footer">`.
  - However, `wizardVariablesModal()` uses a bare `tagList()` without the `.wizard-modal-footer` class, and omits the `.btn-wizard-skip` class on its skip button:
    ```r
    footer = tagList(
      actionButton("wizard_skip", "Skip wizard"),
      actionButton("wizard_finish", "Finish setup", class = "btn-primary")
    )
    ```
* **Consequence:**
  When the wizard auto-advances from Step 1 to Step 2, the modal dialog visibly shrinks from 650px down to Bootstrap's default 500px, button widths lose flex parity, and the "Skip wizard" button reverts to Bootstrap's standard grey button rather than the maroon pill.
* **Remediation:** Wrap `wizardVariablesModal()`'s footer in `div(class = "wizard-modal-footer", ...)` and add `class = "btn-wizard-skip"` to `wizard_skip`.

---

### 2.2 ❌ Scrim Z-Index Inversion & Stacking Vulnerability
* **Location:** `www/style.css:373`
* **Mechanism:**
  The stacking layers are currently declared as:
  ```css
  .navbar        { z-index: 1030; }
  .filter-rail   { z-index: 1029; }
  .filter-drawer { z-index: 1028; }
  .drawer-scrim  { z-index: 98;   }  /* <-- Inverted */
  ```
* **Consequence:**
  The scrim is intended to dim the page content while sitting directly underneath the drawer (`1028`). Setting it to `98` places it far below standard Bootstrap 5 components (`$zindex-dropdown: 1000`) and Selectize.js dropdown menus (`z-index: 1000`). If a dropdown menu or floating widget is active or positioned on the page, it will render **in front of** the dimmed backdrop scrim when the drawer opens.
* **Remediation:** Update `.drawer-scrim` to `z-index: 1027;`.

---

### 2.3 ⚠️ Display Drawer Flexbox Breakpoint Conflict (`min-width: 220px` vs `25%` width)
* **Location:** `www/style.css:471` vs `R/ui_plot_options.R:431–477`
* **Mechanism:**
  - `www/style.css:471` declares:
    ```css
    .drawer-row-divided .drawer-field-block {
      flex: 1 1 220px;
      min-width: 220px;
      ...
    }
    ```
  - `displayPanelUI()` assigns the three drawer groups widths of `50%`, `25%`, and `25%` via inline styles (`flex: 0 0 25%; max-width: 25%;`).
* **Consequence:**
  In CSS Flexbox, `min-width` overrides both `flex-basis` and `max-width`. On drawer containers narrower than 880px:
  `25% < 220px` → Groups 2 and 3 are forced to 220px minimum width.
  Total width needed = `400px + 220px + 220px = 840px > 800px`.
  Because `.drawer-row-divided` has `flex-wrap: wrap`, Group 3 ("Spacing & layout") wraps onto a new row. When wrapped, the vertical dividing rules (sized to full line height) break their intended visual alignment.
* **Remediation:** Allow group subfields to specify a lower `min-width` or set `min-width: 0` when explicit percentage widths are assigned.

---

## 3. Dead & Orphaned CSS Rules (~65 lines)

The following selectors target classes that are **never rendered or referenced** in any `.R`, `.js`, or HTML file in the project:

| Unused Selector Block | Lines | Notes |
|---|---|---|
| `.drawer-btn`, `.drawer-btn:hover`, `.drawer-btn.primary`, `.drawer-btn.primary:hover`, `.drawer-btn.block`, `.drawer-btn:focus-visible` | 799–822 | Leftover from earlier template; Export buttons use `.export-section .btn` |
| `.drawer-search` and child elements (`input`, `.shiny-input-container`) | 714–736 | No search input exists in any drawer panel |
| `.drawer-count` | 705–712 | Unused badge component |
| `.drawer-section-label` | 738–745 | Unused section header |
| `.chips-right` | 846–850 | Unused status-chip layout helper |
| `.filter-chip.add` | 870 | Unused template button style |
| `.filter-chips:has(.filter-chip.active)` & `.filter-chip.active` | 869, 879–883 | Neither server (`server/drawers.R`) nor client (`drawer.js`) ever applies `.active` to chips; the magenta left border never activates |

---

## 4. Specificity Traps & Brittle Overrides

### 4.1 Card Overflow Suppression on Review Data Tab
* **Location:** `www/style.css:241–248`
* **Rule:**
  ```css
  .content-area .bslib-card,
  .content-area .bslib-card .card-body,
  .content-area .bslib-card .tab-pane,
  .content-area .bslib-card .shiny-plot-output {
    height: auto !important;
    max-height: none !important;
    overflow: visible !important;
  }
  ```
* **Concern:** This rule was introduced to prevent the Forest Plot image from being trapped inside an inner scrollbox. However, setting `overflow: visible !important` globally across `.content-area .bslib-card .card-body` and `.tab-pane` also strips horizontal overflow containment from the `Review data` tab's `DT::dataTableOutput`. Very wide tables can spill outside the card border rather than scrolling internally.
* **Remediation:** Scope `overflow: visible !important` to the Plot tab specifically (e.g. `#main_tabs .tab-pane[data-value="Plot"]`), preserving standard overflow handling on the data review card.

### 4.2 Fragmented Button Definitions in Export Section
* **Location:** `www/style.css:637–672`
* `.export-section .btn` is split across three separate rule blocks:
  - Lines 637–642: `border-radius`, `padding-left/right`
  - Lines 651–655: `background`, `border-color`, `color`
  - Lines 669–672: `min-width`, `text-align`
* **Remediation:** Consolidate into a single coherent `.export-section .btn` rule block.

---

## 5. Token & Variable Inconsistencies

1. **Undeclared Custom Property `--page-accent`:**
   - `--page-accent` is referenced 13 times as `var(--page-accent, #426175)`, but is never declared on `:root`.
   - Meanwhile, `#426175` is hardcoded across ~18 other selectors.
   - **Fix:** Add to `:root`:
     ```css
     :root {
       --page-accent: #426175;
     }
     ```
2. **Missing Font Reference (`JetBrains Mono`):**
   - Line 346: `font-family: 'JetBrains Mono', monospace;` for `.rail-badge`.
   - `JetBrains Mono` is not bundled or loaded in the app; browsers silently fall back to generic system `monospace`.
3. **Divergent Cream Color Tokens:**
   - `#f7f4ec` (page body bg, navbar active pill text, theme default).
   - `#f3eedb` (rail text color, active rail button bg).
   - Standardize or document the deliberate two-tone cream palette.

---

## 6. Action Plan & Candidate Register Entries

- **Candidate ISS-046:** Fix wizard modal layout discontinuity (`wizardVariablesModal` missing `.wizard-modal-footer` and button styling).
- **Candidate ISS-047:** Correct `.drawer-scrim` z-index from `98` to `1027`.
- **Candidate CHG-059:** CSS cleanup pass:
  1. Remove ~65 lines of dead template CSS (`.drawer-btn*`, `.drawer-search`, `.drawer-count`, `.drawer-section-label`, unused chip states).
  2. Declare `:root { --page-accent: #426175; }` and consolidate `.export-section .btn` declarations.
  3. Scope card overflow override to the Plot tab specifically.
