import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    header: ToolBar {
        height: 60
        topPadding: 10
        background: Rectangle { color: "#333" }
        Label {
            text: "学生端 - " + sessionCtrl.currentUsername
            font.pixelSize: 18
            font.bold: true
            color: "white"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 5
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

    // 全局唯一的 StudentController 实例，供子页面使用
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
            
            TabButton { text: "医生" }
            TabButton { text: "我的预约" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 医生列表页
            DoctorListTab {
                controller: studentCtrl // 将 controller 传进去
            }

            // 我的预约页
            MyScheduleTab {
                controller: studentCtrl
            }
        }
    }
}