import QtQuick
import QtQuick.Controls
import PsyClient

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "PsyClient"

    SessionController {
        id: sessionCtrl
        // 监听信号
        onLoginSuccess: function(role) {
            console.log("Login success logic here, role:", role)

            // 根据角色跳转不同页面 
            // 这里先用简单的 Text 占位，后续替换为具体 Dash 页面
            if (role === 3) { // Admin
                 stackView.push(adminComponent)
            } else if (role === 2) { // Doctor
                 stackView.push(doctorComponent)
            } else { // Student
                 stackView.push(studentComponent)
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: LoginView {}
    }

    // --- 临时占位页面组件 ---
    Component {
        id: adminComponent
        Page {
            header: Label { text: "Admin Dashboard"; font.pixelSize: 20; padding: 10 }
            Label { anchors.centerIn: parent; text: "Welcome Administrator!" }
        }
    }
    
    Component {
        id: doctorComponent
        Page {
            header: Label { text: "Doctor Dashboard"; font.pixelSize: 20; padding: 10 }
            Label { anchors.centerIn: parent; text: "Welcome Doctor!" }
        }
    }

    Component {
        id: studentComponent
        Page {
            header: Label { text: "Student Dashboard"; font.pixelSize: 20; padding: 10 }
            Label { anchors.centerIn: parent; text: "Welcome Student!" }
        }
    }
}