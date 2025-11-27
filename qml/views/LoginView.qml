import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: loginPage
    background: Rectangle { color: "#f0f2f5" }

    // 页面显示时自动清空密码和错误信息
    onVisibleChanged: {
        if (visible) {
            passField.text = ""
            statusLabel.text = ""
            // 页面出现时自动聚焦到用户名框
            userField.forceActiveFocus()
        }
    }

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
                text: "10.252.69.250" // 默认IP
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

        // 用户名输入框
        TextField {
            id: userField
            placeholderText: "Username"
            Layout.fillWidth: true
            selectByMouse: true

            onAccepted: passField.forceActiveFocus()
        }

        // 密码输入框
        TextField {
            id: passField
            placeholderText: "Password"
            echoMode: TextInput.Password
            Layout.fillWidth: true
            selectByMouse: true

            onAccepted: {
                if (sessionCtrl.isConnected) {
                    sessionCtrl.login(userField.text, passField.text)
                } else {
                    statusLabel.text = "请先连接服务器"
                }
            }
        }

        Button {
            id: loginBtn
            text: "Login"
            Layout.fillWidth: true
            highlighted: true
            enabled: sessionCtrl.isConnected
            onClicked: {
                sessionCtrl.login(userField.text, passField.text)
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

    // 自动连接
    Component.onCompleted: {
        sessionCtrl.connectHost(ipField.text, 9999)
    }
}
