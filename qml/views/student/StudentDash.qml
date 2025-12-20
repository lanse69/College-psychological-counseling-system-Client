import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root
    background: Rectangle { color: Theme.background }

    header: ToolBar {
        height: 60
        topPadding: 10
        background: Rectangle { 
            color: Theme.surface 
            Rectangle { 
                width: parent.width; height: 1; 
                anchors.bottom: parent.bottom; color: Theme.divider 
            }
        }
        Label {
            text: "学生端 - " + sessionCtrl.currentUsername
            font.pixelSize: 18
            font.bold: true
            color: Theme.textPrimary
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 5
        }

        Switch {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            checked: Theme.isDark
            onToggled: Theme.toggle()
        }

        Button {
            text: "注销"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 5
            anchors.rightMargin: 10
            onClicked: root.StackView.view.pop()
        }
    }

    StudentController {
        id: studentCtrl
        
        // 全局错误处理
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 底部或顶部导航栏
        TabBar {
            id: bar
            Layout.fillWidth: true
            background: Rectangle { color: Theme.surface }

            component SkinTabButton: TabButton {
                id: tBtn
                
                contentItem: Text {
                    text: tBtn.text
                    font: tBtn.font
                    // 选中变色，未选中为次要文字色
                    color: tBtn.checked ? Theme.primary : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    // 选中时显示高亮背景，否则透明
                    color: tBtn.checked ? Theme.surfaceHighlight : "transparent"
                    // 底部指示条
                    Rectangle {
                        width: parent.width
                        height: 2
                        anchors.bottom: parent.bottom
                        color: Theme.primary
                        visible: tBtn.checked
                    }
                }
            }

            SkinTabButton { text: "医生列表" }
            SkinTabButton { text: "我的预约" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 医生列表页
            DoctorListTab {
                controller: studentCtrl
            }

            // 我的预约页
            MyScheduleTab {
                controller: studentCtrl
            }
        }
    }
}