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
  property bool notificationPanelOpen: false
  property var unreadNotificationKeys: []
  property int notificationRevision: 0
  property int notificationCount: notifications.trackedNotifications.values.length
  property int unreadNotificationCount: computeUnreadNotificationCount(notificationRevision, notificationCount)

  function run(command, label) {
    statusText = label;
    launcher.command = ["sh", "-lc", command];
    launcher.startDetached();
  }

  function notificationKey(notification) {
    return (notification.appName || "app") + ":" + notification.id;
  }

  function markNotificationUnread(notification) {
    var key = notificationKey(notification);
    if (unreadNotificationKeys.indexOf(key) >= 0)
      return;

    var keys = unreadNotificationKeys.slice();
    keys.push(key);
    unreadNotificationKeys = keys;
    notificationRevision += 1;
  }

  function dropUnreadNotification(notification) {
    var key = notificationKey(notification);
    if (unreadNotificationKeys.indexOf(key) < 0)
      return;

    unreadNotificationKeys = unreadNotificationKeys.filter(function(candidate) {
      return candidate !== key;
    });
    notificationRevision += 1;
  }

  function markAllNotificationsSeen() {
    if (unreadNotificationKeys.length === 0)
      return;

    unreadNotificationKeys = [];
    statusText = "Notifications seen";
    notificationRevision += 1;
  }

  function computeUnreadNotificationCount(revision, count) {
    var active = notifications.trackedNotifications.values;
    var total = 0;

    for (var i = 0; i < active.length; i++) {
      if (unreadNotificationKeys.indexOf(notificationKey(active[i])) >= 0)
        total += 1;
    }

    return total;
  }

  function toggleNotificationPanel() {
    notificationPanelOpen = !notificationPanelOpen;

    if (notificationPanelOpen)
      markAllNotificationsSeen();
  }

  function dismissNotification(notification) {
    dropUnreadNotification(notification);
    notification.dismiss();
    statusText = "Notification dismissed";
    notificationRevision += 1;
  }

  function invokeNotificationAction(notification, action) {
    dropUnreadNotification(notification);
    statusText = action.text || "Notification action";
    action.invoke();
    notificationRevision += 1;
  }

  function clearNotifications() {
    var active = notifications.trackedNotifications.values;

    for (var i = active.length - 1; i >= 0; i--)
      active[i].dismiss();

    unreadNotificationKeys = [];
    statusText = "Notifications cleared";
    notificationRevision += 1;
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
      if (!root.notificationPanelOpen)
        root.markNotificationUnread(notification);
      root.statusText = notification.summary || "Notification";
      root.notificationRevision += 1;
    }
  }

  Connections {
    target: notifications.trackedNotifications

    function onObjectRemovedPost(notification, index) {
      root.dropUnreadNotification(notification);
      root.notificationRevision += 1;
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
            label: root.unreadNotificationCount > 0 ? "N" + root.unreadNotificationCount : "NOTE"
            hint: root.notificationCount > 0
              ? root.unreadNotificationCount + " unread / " + root.notificationCount + " total"
              : "Notifications"
            active: root.notificationPanelOpen
            accent: root.unreadNotificationCount > 0 ? "#f38ba8" : "#a6e3a1"
            onClicked: root.toggleNotificationPanel()
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: notificationPanelWindow
      required property var modelData
      visible: root.notificationPanelOpen
      screen: modelData
      implicitWidth: 380
      exclusiveZone: 0
      anchors {
        left: true
        top: true
        bottom: true
      }
      margins {
        left: 100
        top: 12
        bottom: 12
      }

      NotificationPanel {
        anchors.fill: parent
        notificationServer: notifications
        unreadKeys: root.unreadNotificationKeys
        revision: root.notificationRevision
        onDismissRequested: function(notification) {
          root.dismissNotification(notification);
        }
        onActionRequested: function(notification, action) {
          root.invokeNotificationAction(notification, action);
        }
        onClearRequested: root.clearNotifications()
      }
    }
  }
}
