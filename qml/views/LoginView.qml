import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: loginPage
    background: Rectangle { color: Theme.background }

    // 页面显示时自动清空密码和错误信息
    onVisibleChanged: {
        if (visible) {
            passField.text = ""
            statusLabel.text = ""
        }
    }

    header: Item {
        height: 50
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            
            Label {
                text: Theme.isDark ? "深色" : "浅色"
                color: Theme.textSecondary
            }
            Switch {
                checked: Theme.isDark
                onToggled: Theme.toggle()
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: 300

        Text {
            text: "高校心理咨询系统"
            font.pixelSize: 24
            font.bold: true
            color: Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: ipField
                text: "10.252.38.254"
                placeholderText: "服务端 IP 地址"
                Layout.fillWidth: true
                color: Theme.textPrimary
                placeholderTextColor: Theme.textPlaceholder
                background: Rectangle {
                    color: Theme.inputBackground
                    radius: 4
                    border.color: Theme.border
                }
            }
            Button {
                text: sessionCtrl.isConnected ? "已连接至服务器" : "未连接服务器"
                palette.button: sessionCtrl.isConnected ? "green" : "#d32f2f"
                onClicked: {
                    sessionCtrl.connectHost(ipField.text, 9999)
                }
            }
        }

        Label {
            text: sessionCtrl.isConnected ? "服务器连接正常" : "服务器未连接"
            color: sessionCtrl.isConnected ? Theme.success : Theme.error
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 12
        }

        // 用户名输入框
        TextField {
            id: userField
            placeholderText: "用户名"
            Layout.fillWidth: true
            selectByMouse: true
            color: Theme.textPrimary
            placeholderTextColor: Theme.textPlaceholder
            background: Rectangle {
                color: Theme.inputBackground
                radius: 4
                border.color: Theme.border
            }
            onAccepted: passField.forceActiveFocus()
        }

        // 密码输入框
        TextField {
            id: passField
            placeholderText: "密码"
            echoMode: TextInput.Password
            Layout.fillWidth: true
            selectByMouse: true
            color: Theme.textPrimary
            placeholderTextColor: Theme.textPlaceholder
            background: Rectangle {
                color: Theme.inputBackground
                radius: 4
                border.color: Theme.border
            }
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
            text: "登录"
            Layout.fillWidth: true
            highlighted: true
            enabled: sessionCtrl.isConnected
            onClicked: {
                sessionCtrl.login(userField.text, passField.text)
            }
        }

        Label {
            id: statusLabel
            color: Theme.error
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
