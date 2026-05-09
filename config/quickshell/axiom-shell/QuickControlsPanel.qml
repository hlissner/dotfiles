import Quickshell.Io
import QtQuick
import QtQuick.Controls

Rectangle {
  id: root

  signal closeRequested()
  signal statusRequested(string text)

  property bool opened: false
  property string initialSection: "audio"
  property string section: initialSection
  property var snapshot: ({})

  color: "#ee080b12"
  radius: 22
  border.color: "#66f9e2af"
  border.width: 1

  function refresh() {
    statusProcess.command = ["axiom-control-helper", "status"];
    statusProcess.running = true;
  }

  function runHelper(args, label) {
    root.statusRequested(label);
    actionRunner.command = ["axiom-control-helper"].concat(args);
    actionRunner.startDetached();
    refreshTimer.restart();
  }

  function runStatic(command, label) {
    root.statusRequested(label);
    actionRunner.command = command;
    actionRunner.startDetached();
    refreshTimer.restart();
  }

  function textAt(path, fallback) {
    var cur = root.snapshot;
    for (var i = 0; i < path.length; i++) {
      if (cur === undefined || cur === null || cur[path[i]] === undefined || cur[path[i]] === null)
        return fallback;
      cur = cur[path[i]];
    }
    if (Array.isArray(cur))
      return cur.length > 0 ? cur.join(", ") : fallback;
    if (typeof cur === "boolean")
      return cur ? "on" : "off";
    return String(cur);
  }

  onOpenedChanged: if (opened) { section = initialSection; refresh(); }
  onInitialSectionChanged: if (opened) section = initialSection

  Process {
    id: statusProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.snapshot = JSON.parse(this.text); }
        catch (e) { root.snapshot = { "error": "Status unavailable" }; }
      }
    }
  }

  Process { id: actionRunner }

  Timer {
    id: refreshTimer
    interval: 450
    repeat: false
    onTriggered: root.refresh()
  }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    Row {
      width: parent.width
      spacing: 8
      Text {
        width: parent.width - 92
        text: "Quick controls"
        color: "#f9e2af"
        font.family: "JetBrains Mono"
        font.pixelSize: 20
        font.bold: true
      }
      Button { text: "↻"; onClicked: root.refresh() }
      Button { text: "×"; onClicked: root.closeRequested() }
    }

    Flow {
      width: parent.width
      spacing: 6
      Repeater {
        model: [
          { "id": "audio", "label": "Audio" },
          { "id": "network", "label": "Network" },
          { "id": "bluetooth", "label": "Bluetooth" },
          { "id": "media", "label": "Media" },
          { "id": "session", "label": "Session" },
          { "id": "actions", "label": "Actions" }
        ]
        Button {
          required property var modelData
          text: modelData.label
          checked: root.section === modelData.id
          onClicked: root.section = modelData.id
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: "#33585b70" }

    Flickable {
      width: parent.width
      height: parent.height - y
      contentWidth: width
      contentHeight: contentColumn.height
      clip: true

      Column {
        id: contentColumn
        width: parent.width
        spacing: 14

        Column {
          visible: root.section === "audio"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Audio"; subtitle: "PipeWire/Pulse via pamixer" }
          StatusLine { label: "Output"; value: root.textAt(["audio", "output", "label"], "unavailable") }
          StatusLine { label: "Input"; value: root.textAt(["audio", "input", "label"], "unavailable") }
          Flow { width: parent.width; spacing: 8
            Button { text: "Vol -"; onClicked: root.runHelper(["audio", "output-volume", "-10"], "Volume down") }
            Button { text: "Vol +"; onClicked: root.runHelper(["audio", "output-volume", "+10"], "Volume up") }
            Button { text: "Mute"; onClicked: root.runHelper(["audio", "output-volume", "mute"], "Output mute") }
            Button { text: "Mic mute"; onClicked: root.runHelper(["audio", "input-volume", "mute"], "Mic mute") }
            Button { text: "Open pavucontrol"; onClicked: root.runStatic(["pavucontrol"], "pavucontrol") }
          }
        }

        Column {
          visible: root.section === "network"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Network"; subtitle: "Status and NetworkManager fallback" }
          StatusLine { label: "State"; value: root.textAt(["network", "state"], "unavailable") }
          StatusLine { label: "Primary"; value: root.textAt(["network", "primary"], "No active connection") }
          Flow { width: parent.width; spacing: 8
            Button { text: "Wi-Fi toggle"; onClicked: root.runHelper(["network", "wifi-toggle"], "Wi-Fi toggle") }
            Button { text: "Open network editor"; onClicked: root.runStatic(["nm-connection-editor"], "Network editor") }
          }
        }

        Column {
          visible: root.section === "bluetooth"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Bluetooth"; subtitle: "Controller status and Blueman fallback" }
          StatusLine { label: "Powered"; value: root.textAt(["bluetooth", "powered"], "unavailable") }
          StatusLine { label: "Connected"; value: root.textAt(["bluetooth", "connected"], "No devices") }
          Flow { width: parent.width; spacing: 8
            Button { text: "Power toggle"; onClicked: root.runHelper(["bluetooth", "power-toggle"], "Bluetooth power") }
            Button { text: "Open blueman"; onClicked: root.runStatic(["blueman-manager"], "Blueman") }
          }
        }

        Column {
          visible: root.section === "media"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Media"; subtitle: "MPRIS via playerctl" }
          StatusLine { label: "Player"; value: root.textAt(["media", "player"], "No active player") }
          StatusLine { label: "Track"; value: root.textAt(["media", "summary"], "No active player") }
          StatusLine { label: "State"; value: root.textAt(["media", "status"], "unknown") }
          Flow { width: parent.width; spacing: 8
            Button { text: "Prev"; onClicked: root.runHelper(["media", "previous"], "Previous") }
            Button { text: "Play/Pause"; onClicked: root.runHelper(["media", "play-pause"], "Play/Pause") }
            Button { text: "Next"; onClicked: root.runHelper(["media", "next"], "Next") }
            Button { text: "-5s"; onClicked: root.runHelper(["media", "seek-back"], "Seek back") }
            Button { text: "+5s"; onClicked: root.runHelper(["media", "seek-forward"], "Seek forward") }
          }
        }

        Column {
          visible: root.section === "session"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Session / power"; subtitle: "Safe direct actions and wlogout fallback" }
          Flow { width: parent.width; spacing: 8
            Button { text: "Lock"; onClicked: root.runHelper(["session", "lock"], "Lock") }
            Button { text: "Display off"; onClicked: root.runHelper(["session", "dpms-off"], "Display off") }
            Button { text: "Open wlogout"; onClicked: root.runHelper(["session", "wlogout"], "wlogout") }
          }
        }

        Column {
          visible: root.section === "actions"
          width: parent.width
          spacing: 10
          SectionHeader { title: "Basic actions"; subtitle: "Static local commands" }
          Flow { width: parent.width; spacing: 8
            Button { text: "Guide"; onClicked: root.runStatic(["xdg-open", Qt.resolvedUrl("../../axiom-desktop/guide.md").toString().replace("file://", "")], "Guide") }
            Button { text: "Terminal"; onClicked: root.runStatic(["uwsm", "app", "--", "foot"], "Terminal") }
            Button { text: "Files"; onClicked: root.runStatic(["uwsm", "app", "--", "thunar"], "Files") }
            Button { text: "Screenshot"; onClicked: root.runStatic(["hey", ".screenshot", "--swappy"], "Screenshot") }
            Button { text: "Record"; onClicked: root.runStatic(["hey", ".screencast"], "Record") }
            Button { text: "Launcher"; onClicked: root.runStatic(["fuzzel"], "Fuzzel") }
          }
        }
      }
    }
  }

  component SectionHeader: Column {
    property string title: ""
    property string subtitle: ""
    width: parent.width
    spacing: 3
    Text { text: title; color: "#cdd6f4"; font.family: "JetBrains Mono"; font.pixelSize: 17; font.bold: true }
    Text { text: subtitle; width: parent.width; wrapMode: Text.WordWrap; color: "#a6adc8"; font.family: "JetBrains Mono"; font.pixelSize: 11 }
  }

  component StatusLine: Row {
    property string label: ""
    property string value: ""
    width: parent.width
    spacing: 8
    Text { text: label + ":"; width: 92; color: "#bac2de"; font.family: "JetBrains Mono"; font.pixelSize: 12 }
    Text { text: value; width: parent.width - 100; color: "#cdd6f4"; wrapMode: Text.WordWrap; font.family: "JetBrains Mono"; font.pixelSize: 12 }
  }
}
