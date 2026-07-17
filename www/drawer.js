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
});
