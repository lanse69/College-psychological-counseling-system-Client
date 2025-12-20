import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    background: Rectangle { color: Theme.background}

    header: ToolBar {
        height: 60
        topPadding: 10
        background: Rectangle { color: Theme.background }
        Label {
            text: "医生工作台 - " + sessionCtrl.currentUsername
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

    // 全局医生控制器，传给子页面使用
    DoctorController {
        id: doctorCtrl

        // 全局操作反馈
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                refreshCurrentTab()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: bar
            Layout.fillWidth: true
            
            TabButton { text: "预约处理" }
            TabButton { text: "预约学生档案" }
            TabButton { text: "个人中心" }
        }

        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 预约管理
            AppointmentMgmtTab {
                id: appointmentTab
                controller: doctorCtrl
            }

            // 学生档案管理
            StudentMgmtTab {
                id: studentTab
                controller: doctorCtrl
            }

            // 个人中心 (含排班和问卷入口)
            ProfileTab {
                id: profileTab
                controller: doctorCtrl
            }
        }
    }
    
    // 切换 Tab 时刷新数据
    function refreshCurrentTab() {
        if (bar.currentIndex === 0) appointmentTab.refresh()
        else if (bar.currentIndex === 1) studentTab.refresh()
        else if (bar.currentIndex === 2) profileTab.refresh()
    }
    
    // 监听 Tab 切换事件
    Connections {
        target: bar
        function onCurrentIndexChanged() {
            refreshCurrentTab()
        }
    }
}