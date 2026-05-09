import QtQuick

Rectangle {
  id: root

  property string kind: ""
  property string label: ""
  property int value: 0
  property string detail: ""
  property int serial: 0

  visible: false
  opacity: visible ? 1 : 0
  radius: 22
  color: "#ee080b12"
  border.color: "#66cdd6f4"
  border.width: 1

  onSerialChanged: {
    if (serial <= 0)
      return;
    visible = true;
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: 1400
    repeat: false
    onTriggered: root.visible = false
  }

  Column {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 9

    Row {
      width: parent.width
      spacing: 10
      Text {
        text: root.kind === "brightness" ? "BRI" : (root.kind === "media" ? "MED" : (root.kind === "mic" ? "MIC" : "VOL"))
        color: "#89b4fa"
        font.family: "JetBrains Mono"
        font.pixelSize: 16
        font.bold: true
      }
      Text {
        width: parent.width - 58
        text: root.label
        color: "#cdd6f4"
        elide: Text.ElideRight
        font.family: "JetBrains Mono"
        font.pixelSize: 15
      }
    }

    Rectangle {
      width: parent.width
      height: 12
      radius: 6
      color: "#313244"
      Rectangle {
        width: Math.max(8, parent.width * Math.max(0, Math.min(100, root.value)) / 100)
        height: parent.height
        radius: 6
        color: root.kind === "brightness" ? "#f9e2af" : (root.kind === "media" ? "#a6e3a1" : "#89b4fa")
      }
    }

    Text {
      width: parent.width
      text: root.detail.length > 0 ? root.detail : (root.value + "%")
      color: "#a6adc8"
      elide: Text.ElideRight
      font.family: "JetBrains Mono"
      font.pixelSize: 11
    }
  }
}
