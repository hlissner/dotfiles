import QtQuick

Rectangle {
  id: panel

  signal dismissRequested(var notification)
  signal actionRequested(var notification, var action)
  signal clearRequested()

  property var notificationServer
  property var unreadKeys: []
  property int revision: 0

  radius: 24
  color: "#ee080b12"
  border.color: "#66585b70"
  border.width: 1

  function notificationKey(notification) {
    return (notification.appName || "app") + ":" + notification.id;
  }

  function senderName(notification) {
    if (notification.appName && notification.appName.length > 0)
      return notification.appName;
    if (notification.desktopEntry && notification.desktopEntry.length > 0)
      return notification.desktopEntry;
    return "Application";
  }

  function isUnread(notification) {
    panel.revision;
    return panel.unreadKeys.indexOf(notificationKey(notification)) >= 0;
  }

  function groupCount(notification) {
    if (!panel.notificationServer)
      return 0;

    var sender = senderName(notification);
    var notifications = panel.notificationServer.trackedNotifications.values;
    var count = 0;

    for (var i = 0; i < notifications.length; i++) {
      if (senderName(notifications[i]) === sender)
        count += 1;
    }

    return count;
  }

  Column {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 12

    Row {
      width: parent.width
      height: 32
      spacing: 10

      Column {
        width: parent.width - clearButton.width - parent.spacing
        spacing: 2

        Text {
          width: parent.width
          text: "Notifications"
          color: "#cdd6f4"
          font.family: "JetBrains Mono"
          font.bold: true
          font.pixelSize: 14
        }

        Text {
          width: parent.width
          text: panel.notificationServer
            ? panel.notificationServer.trackedNotifications.values.length + " in current session"
            : "No notification server"
          color: "#a6adc8"
          font.family: "JetBrains Mono"
          font.pixelSize: 10
        }
      }

      Rectangle {
        id: clearButton
        width: 72
        height: 30
        radius: 12
        color: clearMouse.containsMouse ? "#44f38ba8" : "#1f1e1e2e"
        border.color: "#55f38ba8"
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "CLEAR"
          color: "#f38ba8"
          font.family: "JetBrains Mono"
          font.bold: true
          font.pixelSize: 10
        }

        MouseArea {
          id: clearMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: panel.clearRequested()
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: "#33585b70"
    }

    Text {
      width: parent.width
      visible: !panel.notificationServer || panel.notificationServer.trackedNotifications.values.length === 0
      text: "No notifications yet. New notifications will appear here for this Quickshell session."
      color: "#a6adc8"
      wrapMode: Text.WordWrap
      font.family: "JetBrains Mono"
      font.pixelSize: 11
    }

    Flickable {
      width: parent.width
      height: parent.height - y
      clip: true
      contentWidth: width
      contentHeight: notificationColumn.implicitHeight

      Column {
        id: notificationColumn
        width: parent.width
        spacing: 10

        Repeater {
          model: panel.notificationServer ? panel.notificationServer.trackedNotifications : []

          Rectangle {
            id: notificationCard
            required property var modelData
            property var notification: modelData
            property bool unread: panel.isUnread(notification)
            property int senderCount: panel.groupCount(notification)

            width: notificationColumn.width
            height: cardContent.implicitHeight + 22
            radius: 18
            color: unread ? "#22313f5f" : "#1f1e1e2e"
            border.color: unread ? "#6689b4fa" : "#33585b70"
            border.width: 1

            Column {
              id: cardContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 11
              spacing: 8

              Row {
                width: parent.width
                spacing: 8

                Rectangle {
                  width: 8
                  height: 8
                  radius: 4
                  color: notificationCard.unread ? "#89b4fa" : "#585b70"
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  width: parent.width - dismissButton.width - 24
                  text: panel.senderName(notificationCard.notification)
                    + (notificationCard.senderCount > 1 ? " (" + notificationCard.senderCount + ")" : "")
                  color: "#cdd6f4"
                  elide: Text.ElideRight
                  font.family: "JetBrains Mono"
                  font.bold: true
                  font.pixelSize: 11
                }

                Rectangle {
                  id: dismissButton
                  width: 28
                  height: 22
                  radius: 10
                  color: dismissMouse.containsMouse ? "#44f38ba8" : "#11111b"
                  border.color: "#44f38ba8"
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: "X"
                    color: "#f38ba8"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 10
                  }

                  MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.dismissRequested(notificationCard.notification)
                  }
                }
              }

              Text {
                width: parent.width
                text: notificationCard.notification.summary || "Notification"
                color: "#f5e0dc"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 12
              }

              Text {
                width: parent.width
                visible: notificationCard.notification.body && notificationCard.notification.body.length > 0
                text: notificationCard.notification.body || ""
                color: "#bac2de"
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.family: "JetBrains Mono"
                font.pixelSize: 10
              }

              Row {
                width: parent.width
                visible: notificationCard.notification.actions.length > 0
                spacing: 6

                Repeater {
                  model: notificationCard.notification.actions

                  Rectangle {
                    id: actionButton
                    required property var modelData
                    property var action: modelData

                    width: Math.min(actionText.implicitWidth + 18, notificationCard.width - 22)
                    height: 26
                    radius: 11
                    color: actionMouse.containsMouse ? "#4489b4fa" : "#11111b"
                    border.color: "#6689b4fa"
                    border.width: 1

                    Text {
                      id: actionText
                      anchors.centerIn: parent
                      width: parent.width - 12
                      text: actionButton.action.text || "Action"
                      color: "#89b4fa"
                      elide: Text.ElideRight
                      horizontalAlignment: Text.AlignHCenter
                      font.family: "JetBrains Mono"
                      font.bold: true
                      font.pixelSize: 10
                    }

                    MouseArea {
                      id: actionMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: panel.actionRequested(notificationCard.notification, actionButton.action)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
