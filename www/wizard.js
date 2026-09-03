// Setup wizard — first-visit detection + "seen" persistence
// (design/modal-progression-workflow experiment, FEAT-011).
// localStorage is scoped to this origin and wrapped in try/catch since some
// browser contexts (private windows, blocked site data) throw on access —
// in that case the tour just shows every visit, which is a safe fallback.
document.addEventListener("shiny:connected", function () {
  var seen = false;
  try { seen = localStorage.getItem("fpb_wizard_seen") === "1"; } catch (e) {}
  if (!seen) {
    Shiny.setInputValue("wizard_should_show", true, { priority: "event" });
  }
});

Shiny.addCustomMessageHandler("wizard-seen", function (data) {
  try { localStorage.setItem("fpb_wizard_seen", "1"); } catch (e) {}
});
