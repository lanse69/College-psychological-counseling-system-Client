import QtQuick
import QtQuick.Controls
import PsyClient

Rectangle {
    id: root
    width: msgLbl.width + 40
    height: 40
    radius: 5
    color: Theme.surface
    opacity: 0
    anchors.centerIn: parent
    anchors.verticalCenterOffset: parent.height / 3
    z: 100

    property alias text: msgLbl.text

    Text {
        id: msgLbl
        anchors.centerIn: parent
        color: Theme.textPrimary
        font.pixelSize: 14
    }

    function show(message, colorCode) {
        root.text = message
        if (colorCode === "red") {
            root.color = Theme.error
        } else if (colorCode === "green") {
            root.color = Theme.success
        } else {
            root.color = Theme.surfaceHighlight
        }
        anim.restart()
    }

    SequentialAnimation {
        id: anim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 200 }
        PauseAnimation { duration: 2000 }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 500 }
    }
}
