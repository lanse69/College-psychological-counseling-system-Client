import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Item {
    id: tabRoot
    property var controller: null

    property bool isEditMode: false
    property int currentUserId: -1

    ListModel { id: userListModel }

    Component.onCompleted: refresh()

    function refresh() {
        if (controller) controller.fetchUserList()
    }

    Connections {
        target: controller
        function onUserListReceived(list) {
            userListModel.clear()
            for (var i = 0; i < list.length; i++) {
                userListModel.append(list[i])
            }
        }

        function onOperationResult(success, msg) {
            if (success) {
                switchToCreateMode()
                refresh()
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // 左侧：用户列表区
        Rectangle {
            SplitView.preferredWidth: 300
            SplitView.minimumWidth: 250
            color: Theme.surface

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 顶部操作栏
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    Label { 
                        text: "用户列表";
                        color: Theme.textPrimary
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "刷新"
                        onClicked: refresh()
                    }
                    Button {
                        text: "+ 新增"
                        highlighted: true
                        onClicked: switchToCreateMode()
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: userListModel
                    
                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: 60
                        highlighted: ListView.isCurrentItem

                        background: Rectangle {
                            color: parent.highlighted ? Theme.surfaceHighlight : (parent.hovered ? Theme.surfaceHighlight : "transparent")
                        }

                        contentItem: RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 36; height: 36; radius: 18
                                color: model.role === 2 ? Theme.doctorColor : (model.role === 1 ? Theme.studentColor : Theme.adminColor)
                                Text { 
                                    text: model.role === 2 ? "医" : (model.role === 1 ? "学" : "管")
                                    color: Theme.textPrimary
                                    anchors.centerIn: parent
                                    font.bold: true
                                }
                            }
                            
                            Column {
                                Text { 
                                    text: model.realName
                                    color: Theme.textPrimary
                                    font.bold: true
                                }
                                Row {
                                    spacing: 5
                                    Text { 
                                        text: model.gender ? model.gender : "未设置"
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                    Text { 
                                        text: " | " + model.username
                                        color: Theme.textSecondary
                                        font.pixelSize: 12 
                                    }
                                }
                            }
                        }

                        onClicked: {
                            listView.currentIndex = index
                            switchToEditMode(model)
                        }
                    }
                }
            }
        }

        // 编辑/新增表单区
        Rectangle {
            SplitView.fillWidth: true
            color: Theme.surface

            ScrollView {
                anchors.fill: parent
                clip: true
                contentWidth: parent.width

                ColumnLayout {
                    width: Math.min(parent.width * 0.8, 500)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 40
                    spacing: 20
                    Layout.bottomMargin: 50

                    Label {
                        text: isEditMode ? "编辑用户资料" : "创建新用户"
                        font.bold: true
                        font.pixelSize: 22
                        color: Theme.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // 角色选择
                    Label { text: "账户角色"; color: Theme.textPrimary }
                    ComboBox {
                        id: roleCombo
                        Layout.fillWidth: true
                        model: ["学生 (Student)", "医生 (Doctor)", "管理员 (Admin)"]
                        enabled: !isEditMode
                    }

                    // 登录账号
                    Label { text: "登录用户名"; color: Theme.textPrimary }
                    TextField {
                        id: userField
                        Layout.fillWidth: true
                        placeholderText: "用于登录的唯一账号"
                        readOnly: isEditMode
                        color: readOnly ? Theme.textPrimary : Theme.textSecondary
                        background: Rectangle { color: parent.readOnly ? Theme.background : Theme.inputBackground; border.color: Theme.border }
                    }

                    // 真实姓名
                    Label { text: "真实姓名"; color: Theme.textPrimary }
                    TextField {
                        id: nameField
                        Layout.fillWidth: true
                        placeholderText: "用户真实姓名"
                    }

                    // 性别选择
                    Label { text: "性别"; color: Theme.textPrimary }
                    RowLayout {
                        spacing: 20
                        RadioButton {
                            id: maleRadio
                            text: "男"
                            checked: true
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.textPrimary
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: parent.indicator.width + parent.spacing
                            }
                        }
                        
                        RadioButton {
                            id: femaleRadio
                            text: "女"
                            
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.textPrimary
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: parent.indicator.width + parent.spacing
                            }
                        }
                    }

                    // 密码
                    Label { text: isEditMode ? "重置密码 (留空则不修改)" : "初始密码"; color: Theme.textPrimary }
                    TextField {
                        id: passField
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: isEditMode ? "******" : "必填"
                    }

                    // 医生专属字段
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: roleCombo.currentIndex === 1 // 选中医生时显示
                        spacing: 10

                        Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider; Layout.margins: 10 }
                        Label { text: "医生专业信息"; color: Theme.doctorColor; font.bold: true }

                        TextField {
                            id: specField
                            Layout.fillWidth: true
                            placeholderText: "擅长领域 (如: 抑郁症, 焦虑)"
                        }
                        
                        TextArea {
                            id: introField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            placeholderText: "医生个人简介..."
                            color: Theme.textSecondary
                            background: Rectangle { border.color: Theme.border; radius: 4 }
                        }
                    }

                    // 操作按钮
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        spacing: 20

                        Button {
                            text: isEditMode ? "保存修改" : "立即创建"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            highlighted: true
                            onClicked: submitForm()
                        }

                        // 删除按钮 (仅编辑模式显示)
                        Button {
                            text: "删除此用户"
                            visible: isEditMode
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 45
                            
                            contentItem: Text { 
                                text: parent.text; color: Theme.textPrimary; 
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                            }
                            background: Rectangle { color: Theme.error; radius: 4 }
                            
                            onClicked: {
                                confirmDeleteDialog.open()
                            }
                        }
                    }
                    Item { Layout.preferredHeight: 40; Layout.fillWidth: true }
                }
            }
        }
    }

    function switchToCreateMode() {
        isEditMode = false
        currentUserId = -1
        listView.currentIndex = -1 // 取消列表选中
        
        // 清空表单
        userField.text = ""
        nameField.text = ""
        passField.text = ""
        specField.text = ""
        introField.text = ""
        roleCombo.currentIndex = 0
        maleRadio.checked = true
    }

    function switchToEditMode(userData) {
        isEditMode = true
        currentUserId = userData.id
        
        userField.text = userData.username
        nameField.text = userData.realName
        passField.text = "" // 密码不回显
        if (userData.gender === "女") {
            femaleRadio.checked = true
        } else {
            maleRadio.checked = true
        }
        
        // 角色映射: role 1->index 0, 2->1, 3->2
        var r = userData.role
        if (r >= 1 && r <= 3) roleCombo.currentIndex = r - 1
    }

    function submitForm() {
        // 基础校验
        if (userField.text === "" || nameField.text === "") {
            appWindow.showToast("用户名和姓名不能为空", true)
            return
        }

        var role = roleCombo.currentIndex + 1 // 1:Student, 2:Doctor
        var genderStr = maleRadio.checked ? "男" : "女"

        if (isEditMode) {
            // 更新
            controller.updateUserInfo(currentUserId, nameField.text, genderStr, passField.text, introField.text, specField.text)
        } else {
            // 新增
            if (passField.text === "") {
                appWindow.showToast("创建用户必须设置初始密码", true)
                return
            }
            controller.addUser(userField.text, passField.text, role, nameField.text, genderStr, introField.text, specField.text)
        }
    }
    
    Dialog {
        id: confirmDeleteDialog
        title: "警告"
        anchors.centerIn: parent
        width: 300
        standardButtons: Dialog.Yes | Dialog.No
        background: Rectangle { color: Theme.surface; radius: 5 }
        contentItem: Text { 
            text: "确定要永久删除该用户吗？\n此操作不可恢复。" 
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            padding: 20
        }
        onAccepted: {
            controller.deleteUser(currentUserId)
        }
    }
}
