import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    header: ToolBar {
        height: 60
        topPadding: 10
        background: Rectangle { color: Theme.surface }
        Label {
            text: "系统管理后台 - " + sessionCtrl.currentUsername
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
            anchors.rightMargin: 10
            onClicked: root.StackView.view.pop()
        }
    }

    // 全局管理员控制器
    AdminController {
        id: adminCtrl

        // 统一处理操作结果反馈
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            
            // 如果操作成功，刷新当前页面数据
            if (success) {
                if (bar.currentIndex === 0) userTab.refresh()
                if (bar.currentIndex === 1) statsTab.refresh()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: bar
            Layout.fillWidth: true
            
            TabButton { text: "用户与权限管理" }
            TabButton { text: "数据统计报表" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 用户管理
            UserMgmtTab {
                id: userTab
                controller: adminCtrl
            }

            // 统计报表
            StatsTab {
                id: statsTab
                controller: adminCtrl
            }
        }
    }
}