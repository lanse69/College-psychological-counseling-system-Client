import QtQuick
import QtQuick.Controls
import PsyClient

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1024
    height: 768
    title: "高校心理咨询系统"

    SessionController {
        id: sessionCtrl

        onLoginSuccess: function(role) {
            // 根据角色推入不同的界面
            if (role === 3) { // Admin
                stackView.push("views/admin/AdminDash.qml")
            } else if (role === 2) { // Doctor
                stackView.push("views/doctor/DoctorDash.qml")
            } else { // Student
                stackView.push("views/student/StudentDash.qml")
            }
        }

        onLoginFailed: function(msg) {
            showToast(msg, true)
        }

        // 监听被踢信号
        onSessionKicked: function(reason) {
            showToast(reason, true)
            // 回到初始页 (LoginView)
            stackView.pop(null)
        }

        // 监听普通断线
        onConnectionStatusChanged: function(connected) {
            if (!connected) {
                // 不在登录页（depth > 1），则退回登录页
                if (stackView.depth > 1) {
                    showToast("与服务器断开连接", true)
                    stackView.pop(null)
                }
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        // 初始页面：登录页
        initialItem: "views/LoginView.qml"

        // 页面切换动画
        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        pushExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
        }
        popEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
        }
    }

    // 全局消息提示 (Toast)
    function showToast(msg, isError) {
        toast.show(msg, isError ? "red" : "green")
    }

    CToast {
        id: toast
    }
}
