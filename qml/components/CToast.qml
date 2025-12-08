import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: msgLbl.width + 40
    height: 40
    radius: 5
    color: "#333333"
    opacity: 0
    anchors.centerIn: parent
    anchors.verticalCenterOffset: parent.height / 3
    z: 100

    property alias text: msgLbl.text

    Text {
        id: msgLbl
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 14
    }

    function show(message, colorCode) {
        root.text = message
        if (colorCode === "red") {
            root.color = "#dd3333"
        } else if (colorCode === "green") {
            root.color = "#33aa33"
        } else {
            root.color = "#333333"
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
