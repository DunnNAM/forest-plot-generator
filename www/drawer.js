// Forest Plot Builder — drawer open/close handler (DEC-005)
// Adapted from mdt-activity-dashboard/themed-template/www/drawer.js. The custom-message
// contract is unchanged (drawer-open with open + key); this version additionally shows
// the active drawer panel / hides its siblings, and dispatches a resize event so
// sliders and DataTables initialised while hidden recompute their width.
Shiny.addCustomMessageHandler("drawer-open", function(data) {
  var drawer = document.getElementById(data.drawerId);
  var scrim  = document.getElementById(data.scrimId);
  if (drawer) drawer.classList.toggle("open", data.open);
  if (scrim)  scrim.classList.toggle("active", data.open);

  document.querySelectorAll(".rail-item[data-key]").forEach(function(el) {
    el.classList.toggle("active", data.open && el.dataset.key === data.key);
  });

  // show the active panel, hide siblings
  document.querySelectorAll(".drawer-panel").forEach(function(el) {
    el.classList.toggle("active", data.open && el.dataset.key === data.key);
  });

  // let sliders / DT / plots recompute their width now they're visible
  if (data.open) window.dispatchEvent(new Event("resize"));

  updateDrawerNavButtons(data.open ? data.key : null);
});

// FEAT-012 — Back/Next drawer-navigation buttons. Only Data through Order form
// a linear sequence (Export is a terminal action panel, not a step in the
// guided flow, so it gets neither button — same reasoning as Tour never being
// part of the sequence). Data (first) shows Next only; Order (last) shows Back
// only; both hidden entirely when no drawer is open, or when the open drawer
// (Export) isn't part of the sequence at all.
var DRAWER_NAV_SEQUENCE = ["data", "variables", "display", "text", "order"];

function updateDrawerNavButtons(activeKey) {
  var idx = DRAWER_NAV_SEQUENCE.indexOf(activeKey);
  setDrawerNavButton("drawer-nav-back", idx > 0 ? DRAWER_NAV_SEQUENCE[idx - 1] : null);
  setDrawerNavButton(
    "drawer-nav-next",
    idx !== -1 && idx < DRAWER_NAV_SEQUENCE.length - 1 ? DRAWER_NAV_SEQUENCE[idx + 1] : null
  );
}

function setDrawerNavButton(id, targetKey) {
  var btn = document.getElementById(id);
  if (!btn) return;
  // position:absolute (see www/style.css .drawer-nav-btn) takes these out of
  // flow entirely, so toggling `hidden` never reflows the drawer's own
  // content underneath — no need for a reserved-space/visibility-hidden
  // approach here.
  btn.hidden = targetKey === null;
  btn.disabled = targetKey === null;
  btn.dataset.targetKey = targetKey || "";
}

// Reuses the exact same input the rail buttons themselves fire
// (server/drawers.R's observeEvent(input$rail_key, ...)) — Back/Next are just
// another way to request a given drawer key, not a separate navigation
// concept the server needs to know about.
function drawerNavClick(btn) {
  var key = btn.dataset.targetKey;
  if (key) Shiny.setInputValue("rail_key", key, { priority: "event" });
  // Blurred immediately, not left focused (2026-09-06 user report): this
  // button stays in the DOM across every drawer switch (only its
  // disabled/hidden state and target key change, see setDrawerNavButton()
  // above), unlike a real Shiny actionButton() whose click typically re-
  // renders something and naturally drops focus. Without this, Bootstrap's
  // own `.btn:focus` box-shadow ring stayed visible indefinitely after a
  // click, on a button now representing a different drawer than the one
  // actually clicked.
  btn.blur();
}
