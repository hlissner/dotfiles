import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: root

  property var workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9]
  property var launchers: [
    { "label": "ZEN", "hint": "Browser", "command": "uwsm app -- zen-beta || zen-beta" },
    { "label": "TERM", "hint": "Terminal", "command": "uwsm app -- foot || foot" },
    { "label": "FILES", "hint": "Files", "command": "uwsm app -- thunar $HOME || thunar $HOME" },
    { "label": "CHAT", "hint": "Vesktop", "command": "uwsm app -- vesktop || vesktop" },
    { "label": "GAME", "hint": "Steam", "command": "uwsm app -- steam || steam" },
    { "label": "HELP", "hint": "Guide", "command": "xdg-open $HOME/.config/axiom-desktop/guide.md" }
  ]
  property var controls: [
    { "label": "APP", "hint": "Launcher", "command": "fuzzel" },
    { "label": "WIFI", "hint": "Network", "command": "nm-connection-editor" },
    { "label": "BT", "hint": "Bluetooth", "command": "blueman-manager" },
    { "label": "VOL", "hint": "Audio", "command": "pavucontrol" },
    { "label": "SHOT", "hint": "Screenshot", "command": "hey .screenshot --swappy" },
    { "label": "REC", "hint": "Record", "command": "hey .screencast" },
    { "label": "LOCK", "hint": "Lock", "command": "hey .lock" },
    { "label": "PWR", "hint": "Power", "command": "wlogout" }
  ]
  property string statusText: "Ready"
  property int notificationCount: 0

  function run(command, label) {
    statusText = label;
    launcher.command = ["sh", "-lc", command];
    launcher.startDetached();
  }

  Process {
    id: launcher
  }

  NotificationServer {
    id: notifications
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: true
    onNotification: function(notification) {
      notification.tracked = true;
      root.notificationCount += 1;
      root.statusText = notification.summary || "Notification";
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData
      implicitWidth: 76
      exclusiveZone: 88
      anchors {
        left: true
        top: true
        bottom: true
      }
      margins {
        left: 12
        top: 12
        bottom: 12
      }

      Rectangle {
        id: dock
        anchors.fill: parent
        radius: 22
        color: "#dd080b12"
        border.color: "#66cdd6f4"
        border.width: 1

        Column {
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 10
          spacing: 8

          DockButton {
            label: "NIX"
            hint: "Axiom desktop guide"
            accent: "#89b4fa"
            onClicked: root.run("xdg-open $HOME/.config/axiom-desktop/guide.md", "Guide")
          }

          Rectangle {
            width: parent.width
            height: 1
            color: "#33585b70"
          }

          Repeater {
            model: root.workspaces
            DockButton {
              required property var modelData
              label: modelData.toString()
              hint: "Workspace " + modelData
              compact: true
              active: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id == modelData
              onClicked: Hyprland.dispatch("workspace " + modelData)
            }
          }
        }

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: 10
          spacing: 8

          Rectangle {
            width: parent.width
            height: 1
            color: "#33585b70"
          }

          Repeater {
            model: root.launchers
            DockButton {
              required property var modelData
              label: modelData.label
              hint: modelData.hint
              compact: true
              onClicked: root.run(modelData.command, modelData.hint)
            }
          }
        }

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 10
          spacing: 8

          DockButton {
            label: root.notificationCount > 0 ? "N" + root.notificationCount : "NOTE"
            hint: root.notificationCount > 0 ? root.statusText : "Notifications"
            accent: root.notificationCount > 0 ? "#f38ba8" : "#a6e3a1"
            onClicked: {
              root.notificationCount = 0;
              root.statusText = "Notifications cleared";
            }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(clock.date, "hh\nmm")
            color: "#cdd6f4"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            lineHeight: 0.9
          }

          Repeater {
            model: root.controls
            DockButton {
              required property var modelData
              label: modelData.label
              hint: modelData.hint
              compact: true
              onClicked: root.run(modelData.command, modelData.hint)
            }
          }
        }
      }
    }
  }
}
