// 1. Enable `devtools.debugger.remote-enabled`
// 2. Press C-S-A-i
// 3. Paste the below into the browser console
// 4. Run `hey reload @niri` to regenerate matugen templates (if needed)
// 5. Rerun `reloaduc` to reload chrome/userChrome.colors.css
globalThis.reloaduc = function (name = "userChrome.colors.css") {
  const sss = Cc["@mozilla.org/content/style-sheet-service;1"]
    .getService(Ci.nsIStyleSheetService);
  const path = PathUtils.join(PathUtils.profileDir, "chrome", name);
  const state = (globalThis._devSheets ??= {});
  const gen = (state[name] = (state[name] ?? 0) + 1);
  const uri = Services.io.newURI(`${PathUtils.toFileURI(path)}?${gen}`);
  sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
  const prev = state[`${name}:uri`];
  if (prev && sss.sheetRegistered(prev, sss.USER_SHEET))
    sss.unregisterSheet(prev, sss.USER_SHEET);
  state[`${name}:uri`] = uri;
  return `${name} reloaded (gen ${gen})`;
};

reloaduc();
