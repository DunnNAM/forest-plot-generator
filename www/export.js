// Forest Plot Builder — client-side clipboard copy for the Export drawer's
// "Copy R code" button (CHG-061). `clipr::write_clip()` writes to the OS
// clipboard of the machine running the R process — on a local session that's
// the user's own machine, so it worked, but on Connect Cloud the R process
// runs in a headless container with no clipboard device at all, and even if
// it had one, it would be the *server's* clipboard, never the visiting
// browser's. It was reporting "clipboard unavailable on this server" for
// every Connect Cloud user. The actual copy has to happen in the browser via
// the Clipboard API instead — `server/export.R` now sends the generated code
// string over as a custom message rather than trying to copy it itself, and
// this handler does the real copy client-side, reporting success/failure
// back to Shiny so the existing notification observer can react either way.
Shiny.addCustomMessageHandler("copy-r-code", function (code) {
  function notifyResult(status, message) {
    Shiny.setInputValue(
      "copy_r_code_result",
      { status: status, message: message || null, nonce: Math.random() },
      { priority: "event" }
    );
  }

  // navigator.clipboard.writeText requires a secure context (HTTPS or
  // localhost) — true for Connect Cloud and for a local dev session, but
  // guarded with a fallback (a hidden textarea + document.execCommand) for
  // any older/non-secure-context browser rather than failing outright.
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(code).then(
      function () { notifyResult("success"); },
      function (err) { notifyResult("error", String(err)); }
    );
    return;
  }

  try {
    var textarea = document.createElement("textarea");
    textarea.value = code;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    document.body.appendChild(textarea);
    textarea.select();
    var ok = document.execCommand("copy");
    document.body.removeChild(textarea);
    notifyResult(ok ? "success" : "error", ok ? null : "execCommand('copy') returned false");
  } catch (err) {
    notifyResult("error", String(err));
  }
});
