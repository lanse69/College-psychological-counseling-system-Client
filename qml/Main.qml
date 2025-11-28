import QtQuick
import QtQuick.Controls
import PsyClient 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1024
    height: 768
    title: "高校心理咨询系统"

    SessionController {
        id: sessionCtrl

        onLoginSuccess: function(role) {
            console.log("登录成功, 角色:", role)
            // 根据角色推入不同的界面
            if (role === 3) { // Admin
                stackView.push("views/admin/AdminDash.qml")
            } else if (role === 2) { // Doctor
                // stackView.push("views/doctor/DoctorDash.qml")
                showToast("医生界面开发中...", false)
            } else { // Student
                // stackView.push("views/student/StudentDash.qml")
                showToast("学生界面开发中...", false)
            }
        }

        onLoginFailed: function(msg) {
            showToast(msg, true)
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
