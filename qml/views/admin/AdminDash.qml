import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    header: ToolBar {
        Label {
            text: "管理员控制台 - " + sessionCtrl.currentUsername
            font.pixelSize: 20
            anchors.centerIn: parent
        }
        Button {
            text: "注销"
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: stackView.pop()
        }
    }

    AdminController {
        id: adminCtrl
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                adminCtrl.fetchUserList()
                if (addUserComp) addUserComp.reset()
                if (manageUserComp) manageUserComp.reset()
            }
        }
        onUserListReceived: function(listData) {
            userListModel.clear()
            for (var i = 0; i < listData.length; i++) {
                userListModel.append(listData[i])
            }
        }
    }

    ListModel { id: userListModel }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: bar
            Layout.fillWidth: true
            TabButton { text: "添加用户" }
            TabButton { text: "用户管理" }
            TabButton { text: "数据统计" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 添加用户
            Item {
                id: addUserComp
                function reset() {
                    inUser.text="";
                    inPass.text="";
                    inRealName.text="";
                    inIntro.text="";
                    inSpec.text="";
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: parent.width // 确保不产生水平滚动条

                    ColumnLayout {
                        width: Math.min(parent.width * 0.7, 800)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 40
                        spacing: 20

                        Label {
                            text: "新增账号";
                            font.bold: true;
                            font.pixelSize: 22;
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // 表单区域
                        GridLayout {
                            columns: 2
                            columnSpacing: 15
                            rowSpacing: 15
                            Layout.fillWidth: true

                            Label {
                                text: "角色类型:";
                                color: "#ddd";
                                font.pixelSize: 16
                            }

                            ComboBox {
                                id: roleCombo
                                Layout.fillWidth: true
                                model: ["学生 (Student)", "医生 (Doctor)"]
                            }

                            Label {
                                text: "用户名:";
                                color: "#ddd";
                                font.pixelSize: 16
                            }

                            TextField {
                                id: inUser;
                                placeholderText: "登录账号";
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "密码:";
                                color: "#ddd";
                                font.pixelSize: 16
                            }

                            TextField {
                                id: inPass;
                                placeholderText: "初始密码";
                                echoMode: TextInput.Password;
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "真实姓名:";
                                color: "#ddd";
                                font.pixelSize: 16
                            }

                            TextField {
                                id: inRealName;
                                Layout.fillWidth: true
                            }
                        }

                        // 医生专用区域
                        ColumnLayout {
                            visible: roleCombo.currentIndex === 1
                            Layout.fillWidth: true
                            spacing: 10

                            // 分割线
                            Rectangle {
                                height: 1;
                                Layout.fillWidth: true;
                                color: "#555"
                            }

                            Label {
                                text: "医生详细资料";
                                font.bold: true;
                                color: "#ccc";
                                font.pixelSize: 16
                            }

                            TextField {
                                id: inSpec;
                                placeholderText: "擅长领域";
                                Layout.fillWidth: true
                            }

                            TextArea {
                                id: inIntro
                                placeholderText: "个人简介..."
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                wrapMode: Text.Wrap
                                color: "black"
                                background: Rectangle {
                                    color: "#f0f0f0";
                                    radius: 4
                                }
                            }
                        }

                        Button {
                            text: "确认添加"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            Layout.topMargin: 20
                            highlighted: true
                            onClicked: {
                                let r = roleCombo.currentIndex + 1
                                adminCtrl.addUser(inUser.text, inPass.text, r, inRealName.text, inIntro.text, inSpec.text)
                            }
                        }
                    }
                }
            }

            // 用户管理
            Item {
                id: manageUserComp

                function reset() {
                    targetIdField.text="";
                    modName.text="";
                    modPass.text="";
                    modIntro.text="";
                    modSpec.text=""
                }

                SplitView {
                    id: mainSplit
                    anchors.fill: parent
                    orientation: Qt.Horizontal

                    // 左侧：用户列表
                    Rectangle {
                        SplitView.preferredWidth: mainSplit.width * 0.3
                        SplitView.minimumWidth: 200
                        color: "#2b2b2b"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                text: "用户列表"
                                color: "#ddd"
                                font.bold: true
                                padding: 10
                                Layout.fillWidth: true
                                background: Rectangle { color: "#333" }
                            }

                            ListView {
                                id: userListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: userListModel

                                // 滚动条
                                ScrollBar.vertical: ScrollBar {}

                                delegate: ItemDelegate {
                                    width: ListView.view.width
                                    height: 50

                                    contentItem: RowLayout {
                                        spacing: 10
                                        Text {
                                            text: model.id
                                            color: "#888"
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 30
                                        }
                                        Column {
                                            Text {
                                                text: model.realName
                                                color: "white"
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                            Text {
                                                text: model.username + (model.role===1 ? " (学生)" : " (医生)")
                                                color: "#aaa"
                                                font.pixelSize: 12
                                            }
                                        }
                                    }

                                    background: Rectangle {
                                        color: parent.highlighted ? "#444" : (parent.hovered ? "#3a3a3a" : "transparent")
                                    }

                                    highlighted: ListView.isCurrentItem
                                    onClicked: {
                                        userListView.currentIndex = index
                                        targetIdField.text = model.id
                                        modName.text = model.realName
                                        if (model.role === 2) {
                                            modSpec.visible = true;
                                            modIntro.visible = true;
                                        } else {
                                            modSpec.visible = false;
                                            modIntro.visible = false;
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "刷新列表"
                                Layout.fillWidth: true
                                onClicked: adminCtrl.fetchUserList()
                            }
                        }
                    }

                    // 右侧：编辑区域
                    Rectangle {
                        SplitView.fillWidth: true
                        color: "#1e1e1e"

                        ScrollView {
                            anchors.fill: parent
                            contentWidth: parent.width

                            ColumnLayout {
                                width: Math.min(parent.width * 0.8, 600)
                                anchors.centerIn: parent
                                spacing: 20

                                Label {
                                    text: "编辑选中用户";
                                    font.bold: true;
                                    font.pixelSize: 20;
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    Label {
                                        text: "目标 ID:";
                                        color: "#ccc"
                                    }
                                    TextField {
                                        id: targetIdField
                                        readOnly: true
                                        placeholderText: "<- 请从左侧列表选择"
                                        Layout.fillWidth: true
                                        color: "black"
                                        background: Rectangle {
                                            color: "#ddd";
                                            radius: 4
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 1;
                                    Layout.fillWidth: true;
                                    color: "#444"
                                }

                                TextField {
                                    id: modName;
                                    placeholderText: "新真实姓名";
                                    Layout.fillWidth: true
                                }
                                TextField {
                                    id: modPass;
                                    placeholderText: "新密码 (留空不改)";
                                    echoMode: TextInput.Password;
                                    Layout.fillWidth: true
                                }

                                TextField {
                                    id: modSpec;
                                    visible: false;
                                    placeholderText: "新擅长领域 (仅医生)";
                                    Layout.fillWidth: true
                                }
                                TextArea {
                                    id: modIntro
                                    visible: false;
                                    placeholderText: "新简介 (仅医生)..."
                                    Layout.fillWidth: true;
                                    Layout.preferredHeight: 80
                                    color: "black"
                                    background: Rectangle {
                                        color: "#f0f0f0";
                                        radius: 4
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 20
                                    spacing: 20

                                    Button {
                                        text: "更新信息"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 45
                                        onClicked: {
                                            if(targetIdField.text === "") return
                                            adminCtrl.updateUserInfo(parseInt(targetIdField.text), modName.text, modPass.text, modIntro.text, modSpec.text)
                                        }
                                    }

                                    Button {
                                        id: btnDel
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 45

                                        contentItem: Text {
                                            text: "删除该用户"
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        background: Rectangle {
                                            color: btnDel.down ? "#b71c1c" : "#d32f2f"
                                            radius: 4
                                            border.color: "#ff8a80"
                                            border.width: 1
                                        }

                                        onClicked: {
                                            if(targetIdField.text === "") return
                                            deleteConfirmDialog.targetId = parseInt(targetIdField.text)
                                            deleteConfirmDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StatsView {}
        }
    }

    Dialog {
        id: deleteConfirmDialog
        title: "警告"
        property int targetId: 0
        anchors.centerIn: parent

        Label {
            text: "确定要彻底删除 ID: " + deleteConfirmDialog.targetId + " 吗？\n此操作不可恢复，且相关预约记录也会被清理。"
            color: "white"
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: adminCtrl.deleteUser(deleteConfirmDialog.targetId)
    }

    Component.onCompleted: {
        adminCtrl.fetchUserList()
    }
}
