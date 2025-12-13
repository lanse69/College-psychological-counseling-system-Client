import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Item {
    id: tabRoot
    property var controller: null

    function refresh() {
        if (controller) controller.fetchMyProfile()
    }

    // 监听个人信息变化
    Connections {
        target: controller
        function onMyProfileChanged() {
            var p = controller.myProfile
            nameField.text = p.realName || ""
            introField.text = p.intro || ""
            specField.text = p.spec || p.specializedField || ""
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: Math.min(parent.width * 0.8, 600)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 30
            spacing: 20

            Label {
                text: "个人工作台设置"
                font.bold: true
                font.pixelSize: 22
                Layout.alignment: Qt.AlignHCenter
            }

            // 功能入口区
            GridLayout {
                columns: 2
                rowSpacing: 15
                columnSpacing: 15
                Layout.fillWidth: true

                Button {
                    text: "排班管理"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    highlighted: true
                    onClicked: stackView.push("ScheduleMgr.qml")
                }

                Button {
                    text: "问卷管理"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    highlighted: true
                    onClicked: stackView.push("SurveyCreator.qml")
                }
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider; Layout.topMargin: 10; Layout.bottomMargin: 10 }

            Label { text: "基本资料修改"; font.bold: true; font.pixelSize: 16 }

            TextField {
                id: nameField
                placeholderText: "真实姓名"
                Layout.fillWidth: true
            }

            TextField {
                id: specField
                placeholderText: "擅长领域 (如: 抑郁症, 焦虑, 学业压力)"
                Layout.fillWidth: true
            }

            TextArea {
                id: introField
                placeholderText: "个人简介 (展示给预约学生)..."
                color: Theme.textSecondary
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                background: Rectangle { border.color: Theme.divider; radius: 4 }
            }

            TextField {
                id: passField
                placeholderText: "新密码 (留空则不修改)"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }

            Button {
                text: "保存个人信息"
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                onClicked: {
                    controller.updateMyProfile(nameField.text, passField.text, introField.text, specField.text)
                }
            }
        }
    }
}