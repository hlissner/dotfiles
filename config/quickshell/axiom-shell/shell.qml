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
    { "label": "GAME", "hint": "Steam", "command": "uwsm app -- steam || steam" }
  ]
  property var controls: [
    { "label": "APP", "hint": "Search", "action": "search" },
    { "label": "WIFI", "hint": "Network", "action": "quickControls", "section": "network" },
    { "label": "BT", "hint": "Bluetooth", "action": "quickControls", "section": "bluetooth" },
    { "label": "VOL", "hint": "Audio", "action": "quickControls", "section": "audio" },
    { "label": "SHOT", "hint": "Screenshot", "command": "hey .screenshot --swappy" },
    { "label": "REC", "hint": "Record", "command": "hey .screencast" },
    { "label": "LOCK", "hint": "Lock", "command": "hey .lock" },
    { "label": "PWR", "hint": "Power", "action": "quickControls", "section": "session" }
  ]
  property string statusText: "Ready"
  property bool searchPanelOpen: false
  property bool notificationPanelOpen: false
  property bool quickControlsOpen: false
  property string quickControlsSection: "audio"
  property string osdKind: ""
  property string osdLabel: ""
  property int osdValue: 0
  property string osdDetail: ""
  property int osdSerial: 0
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

    if (notificationPanelOpen) {
      searchPanelOpen = false;
      quickControlsOpen = false;
      markAllNotificationsSeen();
    }
  }

  function openSearchPanel() {
    searchPanelOpen = true;
    notificationPanelOpen = false;
    quickControlsOpen = false;
  }

  function toggleSearchPanel() {
    searchPanelOpen = !searchPanelOpen;

    if (searchPanelOpen)
      notificationPanelOpen = false;
    if (searchPanelOpen)
      quickControlsOpen = false;
  }

  function openQuickControls(section) {
    quickControlsSection = section || "audio";
    quickControlsOpen = true;
    searchPanelOpen = false;
    notificationPanelOpen = false;
    statusText = "Quick controls";
  }

  function toggleQuickControls(section) {
    if (quickControlsOpen && quickControlsSection === section) {
      quickControlsOpen = false;
      statusText = "Ready";
      return;
    }

    openQuickControls(section);
  }

  function showOsd(kind, label, value, detail) {
    osdKind = kind || "osd";
    osdLabel = label || "";
    osdValue = Math.max(0, Math.min(100, parseInt(value || 0)));
    osdDetail = detail || "";
    osdSerial += 1;
  }

  function activateControl(control) {
    if (control.action === "search") {
      toggleSearchPanel();
      statusText = searchPanelOpen ? "Search" : "Ready";
      return;
    }

    if (control.action === "quickControls") {
      toggleQuickControls(control.section || "audio");
      return;
    }

    run(control.command, control.hint);
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

  IpcHandler {
    target: "axiom"

    function toggleSearch() {
      root.toggleSearchPanel();
    }

    function openSearch() {
      root.openSearchPanel();
    }

    function openQuickControls(section) {
      root.openQuickControls(section || "audio");
    }

    function toggleQuickControls(section) {
      root.toggleQuickControls(section || "audio");
    }

    function showOsd(kind, label, value, detail) {
      root.showOsd(kind, label, value, detail);
    }
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
              active: (modelData.action === "search" && root.searchPanelOpen) || (modelData.action === "quickControls" && root.quickControlsOpen && root.quickControlsSection === modelData.section)
              accent: modelData.action === "search" ? "#89b4fa" : (modelData.action === "quickControls" ? "#f9e2af" : "#cba6f7")
              onClicked: root.activateControl(modelData)
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: searchPanelWindow
      required property var modelData
      visible: root.searchPanelOpen
      screen: modelData
      implicitWidth: 540
      implicitHeight: 620
      exclusiveZone: 0
      anchors {
        left: true
        top: true
      }
      margins {
        left: 100
        top: 48
      }

      SearchPanel {
        id: searchPanel
        anchors.fill: parent
        opened: root.searchPanelOpen
        onCloseRequested: root.searchPanelOpen = false
        onStatusRequested: function(text) {
          root.statusText = text;
        }

        onOpenedChanged: {
          if (opened)
            open();
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: quickControlsPanelWindow
      required property var modelData
      visible: root.quickControlsOpen
      screen: modelData
      implicitWidth: 430
      implicitHeight: 710
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

      QuickControlsPanel {
        anchors.fill: parent
        opened: root.quickControlsOpen
        initialSection: root.quickControlsSection
        onCloseRequested: root.quickControlsOpen = false
        onStatusRequested: function(text) { root.statusText = text; }
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: osdWindow
      required property var modelData
      visible: osdOverlay.visible
      screen: modelData
      implicitWidth: 360
      implicitHeight: 96
      exclusiveZone: 0
      anchors {
        top: true
        right: true
      }
      margins {
        top: 38
        right: 38
      }

      OsdOverlay {
        id: osdOverlay
        anchors.fill: parent
        kind: root.osdKind
        label: root.osdLabel
        value: root.osdValue
        detail: root.osdDetail
        serial: root.osdSerial
      }
    }
  }
}
