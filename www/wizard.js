// Setup wizard — first-visit detection + "seen" persistence
// (design/modal-progression-workflow experiment, FEAT-011).
// localStorage is scoped to this origin and wrapped in try/catch since some
// browser contexts (private windows, blocked site data) throw on access —
// in that case the tour just shows every visit, which is a safe fallback.
// Always sends wizard_should_show (true for a first visit, false for a
// returning one) rather than only sending it when true — the server needs
// the returning-user case too now, to default-open the Data drawer instead
// of landing with no drawer open (2026-09-04 follow-up, user request).
//
// Real, pre-existing bug found 2026-09-04 debugging the above (not a race,
// and not introduced this session — this is how the file looked as far back
// as CHG-039): the input never arrived server-side, in *any* session,
// confirmed via server-side trace, 100% of the time. Root cause, confirmed
// by reading the bundled shiny.min.js directly: Shiny fires "shiny:connected"
// via jQuery's `.trigger()` — `$(document).trigger({type: "shiny:connected",
// ...})` — which is jQuery's own event system, not a real DOM event. The
// native `document.addEventListener("shiny:connected", ...)` this file used
// to use can never see a jQuery-only trigger for a made-up event name like
// this one; it isn't a browser event `dispatchEvent` would fire, so no
// amount of "register the listener earlier" fixes it. Binding through
// jQuery itself (jQuery is guaranteed loaded before this script — it's the
// very first <script src> in <head>) is the actual fix; the
// Shiny.shinyapp.isConnected() load-time check stays as a fallback for the
// (now genuinely just a timing question) case where the connection already
// completed before this script ran.
function reportWizardVisit() {
  var seen = false;
  try { seen = localStorage.getItem("fpb_wizard_seen") === "1"; } catch (e) {}
  Shiny.setInputValue("wizard_should_show", !seen, { priority: "event" });
}

if (window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected && Shiny.shinyapp.isConnected()) {
  reportWizardVisit();
} else {
  jQuery(document).on("shiny:connected", reportWizardVisit);
}

Shiny.addCustomMessageHandler("wizard-seen", function (data) {
  try { localStorage.setItem("fpb_wizard_seen", "1"); } catch (e) {}
});
