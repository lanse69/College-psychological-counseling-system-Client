import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: loginPage
    background: Rectangle { color: "#f0f2f5" }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: 300

        Text {
            text: "PsySystem Login"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: userField
            placeholderText: "Username"
            Layout.fillWidth: true
        }

        TextField {
            id: passField
            placeholderText: "Password"
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        Button {
            text: "Login"
            Layout.fillWidth: true
            highlighted: true
            onClicked: {
                sessionCtrl.connectHost("10.252.69.250", 9999);
                sessionCtrl.login(userField.text, passField.text);
            }
        }

        Label {
            id: statusLabel
            color: "red"
            visible: text !== ""
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Connections {
        target: sessionCtrl
        function onLoginFailed(msg) {
            statusLabel.text = msg
        }
    }
}