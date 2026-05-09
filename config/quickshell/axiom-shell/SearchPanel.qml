import Quickshell.Io
import QtQuick
import QtQuick.Controls

Rectangle {
  id: root

  signal closeRequested()
  signal statusRequested(string text)

  property bool opened: false
  property string query: ""
  property var apps: []
  property var emoji: []
  property var clipboardItems: []
  property bool clipboardEnabled: true
  property string calcResult: ""
  property var results: []
  property var actions: [
    { "id": "guide", "provider": "action", "title": "Open Axiom guide", "subtitle": "Local desktop guide", "keywords": "help guide docs nix axiom", "command": ["xdg-open", Qt.resolvedUrl("../../axiom-desktop/guide.md").toString().replace("file://", "")] },
    { "id": "terminal", "provider": "action", "title": "Open terminal", "subtitle": "foot", "keywords": "terminal shell foot", "command": ["uwsm", "app", "--", "foot"] },
    { "id": "files", "provider": "action", "title": "Open files", "subtitle": "thunar", "keywords": "files folder thunar", "command": ["uwsm", "app", "--", "thunar"] },
    { "id": "browser", "provider": "action", "title": "Open browser", "subtitle": "zen-beta", "keywords": "browser web zen", "command": ["uwsm", "app", "--", "zen-beta"] },
    { "id": "power", "provider": "action", "title": "Power menu", "subtitle": "wlogout", "keywords": "power logout shutdown reboot", "command": ["wlogout"] },
    { "id": "fallback", "provider": "action", "title": "Open fallback launcher", "subtitle": "Fuzzel direct fallback", "keywords": "launcher fallback fuzzel apps", "command": ["fuzzel"] },
    { "id": "clear-clipboard", "provider": "clipboard", "title": "Clear clipboard history", "subtitle": "Wipe stored Axiom clipboard entries", "keywords": "clipboard clear history privacy", "helper": ["axiom-search-helper", "clipboard", "clear"], "refreshClipboard": true }
  ]

  color: "#ee080b12"
  radius: 22
  border.color: "#66cdd6f4"
  border.width: 1

  function open() {
    queryInput.forceActiveFocus();
    loadClipboard();
    rebuild();
  }

  function close() {
    root.query = "";
    queryInput.text = "";
    root.closeRequested();
  }

  function loadClipboard() {
    clipboardProcess.command = ["axiom-search-helper", "clipboard", "list"];
    clipboardProcess.running = true;
  }

  function matches(item, needle) {
    if (needle.length === 0)
      return item.provider === "action";
    var haystack = (item.title + " " + item.subtitle + " " + (item.keywords || "")).toLowerCase();
    return haystack.indexOf(needle) >= 0;
  }

  function rebuild() {
    var needle = root.query.trim().toLowerCase();
    var built = [];
    var i;
    if (root.calcResult.length > 0)
      built.push({ "provider": "calc", "title": root.calcResult, "subtitle": "Calculator result - Enter copies", "text": root.calcResult });
    if (root.query.trim().length > 0)
      built.push({ "provider": "web", "title": "Search web for \"" + root.query.trim() + "\"", "subtitle": "DuckDuckGo", "query": root.query.trim() });
    for (i = 0; i < root.actions.length; i++) {
      if (root.actions[i].id === "clear-clipboard" && !root.clipboardEnabled)
        continue;
      if (matches(root.actions[i], needle)) built.push(root.actions[i]);
    }
    for (i = 0; i < root.apps.length && built.length < 80; i++)
      if (matches(root.apps[i], needle)) built.push(root.apps[i]);
    for (i = 0; i < root.emoji.length && built.length < 100; i++)
      if (matches(root.emoji[i], needle)) built.push(root.emoji[i]);
    if (root.clipboardEnabled) {
      for (i = 0; i < root.clipboardItems.length && built.length < 120; i++) {
        var text = root.clipboardItems[i].text || "";
        var item = { "id": root.clipboardItems[i].id, "provider": "clipboard", "title": text.replace(/\n/g, " ").slice(0, 80), "subtitle": "Clipboard history", "keywords": text };
        if (matches(item, needle)) built.push(item);
      }
    }
    root.results = built;
  }

  function activate(item) {
    if (!item)
      return;
    root.statusRequested(item.title || "Search action");
    if (item.provider === "app") {
      runner.command = ["axiom-search-helper", "apps", "launch", item.id];
    } else if (item.provider === "calc" || item.provider === "emoji") {
      runner.command = ["axiom-search-helper", "copy-text", item.text || item.title];
    } else if (item.provider === "clipboard" && item.id === "clear-clipboard") {
      runner.command = item.helper;
    } else if (item.provider === "clipboard") {
      runner.command = ["axiom-search-helper", "clipboard", "copy", item.id];
    } else if (item.provider === "web") {
      runner.command = ["uwsm", "app", "--", "xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(item.query).replace(/%20/g, "+")];
    } else {
      runner.command = item.command;
    }
    runner.startDetached();
    if (item.refreshClipboard)
      loadClipboard();
    close();
  }

  Process {
    id: appsProcess
    command: ["axiom-search-helper", "apps", "list"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.apps = JSON.parse(this.text); } catch (e) { root.apps = []; }
        root.rebuild();
      }
    }
  }

  Process {
    id: emojiProcess
    command: ["axiom-search-helper", "emoji", "list"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.emoji = JSON.parse(this.text); } catch (e) { root.emoji = []; }
        root.rebuild();
      }
    }
  }

  Process {
    id: clipboardProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text);
          root.clipboardEnabled = parsed.enabled;
          root.clipboardItems = parsed.items || [];
        } catch (e) {
          root.clipboardItems = [];
        }
        root.rebuild();
      }
    }
  }

  Process {
    id: calcProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text);
          root.calcResult = parsed.ok ? parsed.result : "";
        } catch (e) {
          root.calcResult = "";
        }
        root.rebuild();
      }
    }
  }

  Process { id: runner }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    TextInput {
      id: queryInput
      width: parent.width
      height: 42
      color: "#cdd6f4"
      selectionColor: "#585b70"
      selectedTextColor: "#ffffff"
      font.family: "JetBrains Mono"
      font.pixelSize: 18
      focus: root.opened
      text: root.query
      onTextChanged: {
        root.query = text;
        if (root.query.trim().length > 0) {
          calcProcess.command = ["axiom-search-helper", "calc", root.query];
          calcProcess.running = true;
        } else {
          root.calcResult = "";
        }
        root.rebuild();
      }
      Keys.onEscapePressed: root.close()
      Keys.onReturnPressed: root.activate(resultsList.currentItem ? resultsList.currentItem.item : root.results[0])
      Keys.onDownPressed: resultsList.currentIndex = Math.min(resultsList.currentIndex + 1, root.results.length - 1)
      Keys.onUpPressed: resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0)

      Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        z: -1
        radius: 14
        color: "#1f1e1e2e"
        border.color: "#66585b70"
        border.width: 1
      }
    }

    ListView {
      id: resultsList
      width: parent.width
      height: parent.height - queryInput.height - 28
      clip: true
      model: root.results
      currentIndex: -1
      onCountChanged: currentIndex = count > 0 ? Math.min(Math.max(currentIndex, 0), count - 1) : -1
      spacing: 6

      delegate: Rectangle {
        id: resultRow
        required property var modelData
        required property int index
        property var item: modelData
        property bool current: ListView.isCurrentItem
        width: resultsList.width
        height: 58
        radius: 14
        color: resultRow.current ? "#89b4fa" : mouse.containsMouse ? "#33454a5f" : "#141e1e2e"
        border.color: resultRow.current ? "#ffffffff" : "#33585b70"
        border.width: 1

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: 12
          spacing: 4
          Text {
            width: parent.width
            text: modelData.title
            color: resultRow.current ? "#11111b" : "#cdd6f4"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 13
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: modelData.provider.toUpperCase() + " · " + (modelData.subtitle || "")
            color: resultRow.current ? "#313244" : "#a6adc8"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          onEntered: resultsList.currentIndex = index
          onClicked: root.activate(modelData)
        }
      }
    }
  }
}
