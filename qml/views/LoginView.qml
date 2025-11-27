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

        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: ipField
                text: "10.252.69.250" // 默认 IP
                placeholderText: "Server IP"
                Layout.fillWidth: true
            }
            Button {
                text: sessionCtrl.isConnected ? "已连接" : "连接"
                palette.button: sessionCtrl.isConnected ? "lightgreen" : undefined
                onClicked: {
                    sessionCtrl.connectHost(ipField.text, 9999)
                }
            }
        }

        Label {
            text: sessionCtrl.isConnected ? "服务器连接正常" : "服务器未连接"
            color: sessionCtrl.isConnected ? "green" : "red"
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 12
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
            enabled: sessionCtrl.isConnected
            onClicked: {
                sessionCtrl.login(userField.text, passField.text);
            }
        }

        Label {
            id: statusLabel
            color: "red"
            visible: text !== ""
            Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 300
        }
    }

    Connections {
        target: sessionCtrl
        function onLoginFailed(msg) {
            statusLabel.text = msg
        }
        function onConnectionStatusChanged(connected) {
            if (connected) {
                statusLabel.text = ""
            } else {
                statusLabel.text = "服务器断开连接"
            }
        }
    }

    Component.onCompleted: {
        sessionCtrl.connectHost(ipField.text, 9999)
    }
}
