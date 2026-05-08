import QtQuick

Rectangle {
  id: button

  signal clicked()

  property string label: ""
  property string hint: ""
  property string accent: "#cba6f7"
  property bool active: false
  property bool compact: false

  width: parent ? parent.width : 56
  height: compact ? 30 : 42
  radius: compact ? 12 : 16
  color: active ? accent : mouse.containsMouse ? "#33454a5f" : "#1f1e1e2e"
  border.color: active ? "#ffffffff" : "#33585b70"
  border.width: 1

  Text {
    anchors.centerIn: parent
    width: parent.width - 8
    text: button.label
    color: button.active ? "#11111b" : "#cdd6f4"
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    font.family: "JetBrains Mono"
    font.bold: true
    font.pixelSize: button.compact ? 8 : 10
  }

  Text {
    anchors.left: parent.right
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    visible: mouse.containsMouse && button.hint.length > 0
    text: button.hint
    color: "#cdd6f4"
    font.family: "JetBrains Mono"
    font.pixelSize: 11

    Rectangle {
      anchors.fill: parent
      anchors.margins: -8
      z: -1
      radius: 10
      color: "#ee11111b"
      border.color: "#66585b70"
      border.width: 1
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: button.clicked()
  }
}
