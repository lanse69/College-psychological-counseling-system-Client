import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page


    header: ToolBar {
        background: Rectangle {
            color: "#ffffff"  // 白色
        }

        Button {
            text: "注销"
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            Layout.preferredWidth: 70
            background: Rectangle {
                color: "#4CAF50"
                radius: 4
            }
            contentItem: Label {
                text: "注销"
                color: "white"
                font.pixelSize: 12
            }
            onClicked: stackView.pop()
        }
    }

    DoctorController {
        id: doctorCtrl

        onOperationResult: function(success, msg) {
            if (success) {
                doctorCtrl.fetchAppointments()
            } else {
                appWindow.showToast(msg, true)
            }
        }

        onReportSubmitted: function() {
            doctorCtrl.fetchAppointments()
        }

        onPatientListReceived: function(patients) {
            // 清空现有数据
            patientListModel.clear()

            // 转换数据格式
            for (var i = 0; i < patients.length; i++) {
                var patient = patients[i]
                var patientData = {
                    "patientId": patient.userId,
                    "patientName": patient.realName || "未知预约学生",
                    "totalAppointments": patient.appointmentCount || 0,
                    "completedAppointments": Math.floor((patient.appointmentCount || 0) * 0.8), // 估算完成数
                    "lastAppointment": patient.lastAppointmentDate || "无记录",
                    "status": patient.appointmentCount > 3 ? "治疗中" : "活跃",
                    "notes": "来自服务端数据的预约学生记录",
                    "hidden": false
                }
                patientListModel.append(patientData)
            }

            // 应用搜索筛选
            filterPatients()
        }

        // 预约筛选功能
        function filterAppointments() {
            var filterText = statusFilter.currentText || "全部"

            for (var i = 0; i < appointmentListModel.count; i++) {
                var item = appointmentListModel.get(i)
                var shouldShow = false

                if (filterText === "全部") {
                    shouldShow = (item.status === 0 || item.status === 1) // 只显示待确认和已确认
                } else if (filterText === "待确认" && item.status === 0) {
                    shouldShow = true
                } else if (filterText === "已确认" && item.status === 1) {
                    shouldShow = true
                } else if (filterText === "已完成" && item.status === 2) {
                    shouldShow = true
                } else if (filterText === "已取消" && item.status === 3) {
                    shouldShow = true
                }

                appointmentListModel.setProperty(i, "hidden", !shouldShow)
            }
        }

        // 预约学生筛选功能
        function filterPatients() {
            var searchText = (patientSearchField.text || "").toLowerCase()

            for (var i = 0; i < patientListModel.count; i++) {
                var item = patientListModel.get(i)
                var shouldShow = true

                if (searchText.length > 0) {
                    var patientName = (item.patientName || "").toLowerCase()
                    shouldShow = patientName.indexOf(searchText) !== -1
                }

                patientListModel.setProperty(i, "hidden", !shouldShow)
            }
        }

    }

    ListModel { id: patientListModel }

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: "#f5f5f5"
        visible: true

        Component.onCompleted: {
            doctorCtrl.fetchAppointments()
            doctorCtrl.fetchPatients()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            Layout.margins: 0

            TabBar {
                id: bar
                Layout.fillWidth: true

                TabButton {
                    text: "预约管理"
                }

                TabButton {
                    text: "预约学生管理"
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: bar.currentIndex

                // 预约管理
                Item {
                    Rectangle {
                        anchors.fill: parent
                        color: "#f5f5f5"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                text: "预约管理"
                                font.bold: true
                                font.pixelSize: 24
                                color: "#333333"
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 20
                            }

                            // 状态筛选
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 20
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                spacing: 10

                                Label {
                                    text: "筛选:"
                                    color: "#333333"
                                }

                                ComboBox {
                                    id: statusFilter
                                    model: [ "全部", "待确认", "已确认", "已完成", "已取消"]
                                    currentIndex: 0
                                    onActivated: {
                                        doctorCtrl.appointmentModel.applyFilter(currentText)
                                    }
                                }

                                Button {
                                    text: "刷新"
                                    background: Rectangle {
                                        color: "#2196F3"
                                        radius: 4
                                    }
                                    contentItem: Label {
                                        text: "刷新"
                                        color: "white"
                                        font.pixelSize: 14
                                    }
                                    onClicked: doctorCtrl.fetchAppointments()
                                }
                            }

                            // 预约列表
                            ListView {
                                id: appointmentView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                Layout.topMargin: 20
                                Layout.bottomMargin: 20
                                clip: true

                                ScrollBar.vertical: ScrollBar {}

                                model: doctorCtrl.appointmentModel

                                onCountChanged: {
                                }

                                delegate: Rectangle {
                                    id: appointmentDelegate
                                    width: ListView.view.width - 20
                                    height: visible ? 170 : 0
                                    color: "#ffffff"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                    border.width: 1
                                    anchors.margins: 5

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 8

                                        Text {
                                            text: model.studentName + " - " + model.statusText
                                            color: "#333333"
                                            font.bold: true
                                            font.pixelSize: 16
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: model.appointmentDate + " " + model.timeSlotText
                                            color: "#666666"
                                            font.pixelSize: 14
                                            Layout.fillWidth: true
                                        }

                                        // 操作按钮区域
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 10

                                            // 待确认状态的按钮
                                            visible: model.status === 0

                                            Button {
                                                text: "接受预约"
                                                Layout.preferredWidth: 80
                                                background: Rectangle {
                                                    color: "#4CAF50"
                                                    radius: 4
                                                }
                                                contentItem: Label {
                                                    text: "接受预约"
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    doctorCtrl.confirmAppointment(model.id)
                                                }
                                            }

                                            Button {
                                                text: "拒绝预约"
                                                Layout.preferredWidth: 80
                                                background: Rectangle {
                                                    color: "#f44336"
                                                    radius: 4
                                                }
                                                contentItem: Label {
                                                    text: "拒绝预约"
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    rejectConfirmDialog.targetId = model.id
                                                    rejectConfirmDialog.patientName = model.studentName || "未知预约学生"
                                                    rejectConfirmDialog.open()
                                                }
                                            }
                                        }

                                        // 已确认状态的按钮
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 10
                                            visible: model.status === 1  // 只对状态为1（已确认）的预约显示

                                            Button {
                                                text: "完成咨询"
                                                Layout.preferredWidth: 80
                                                background: Rectangle {
                                                    color: "#2196F3"
                                                    radius: 4
                                                }
                                                contentItem: Label {
                                                    text: "完成咨询"
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    // 跳转到报告编写页面
                                                    stackView.push("ReportWrite.qml", {
                                                        appointmentId: model.id,
                                                        patientName: model.studentName || "未知预约学生"
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 预约学生管理
                Item {
                    Rectangle {
                        anchors.fill: parent
                        color: "#f5f5f5"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                text: "预约学生管理"
                                font.bold: true
                                font.pixelSize: 24
                                color: "#333333"
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 20
                            }

                            // 搜索和操作栏
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 20
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                spacing: 10

                                TextField {
                                    id: patientSearchField
                                    placeholderText: "搜索预约学生姓名..."
                                    Layout.fillWidth: true
                                    color: "#333333"
                                    font.pixelSize: 14
                                    background: Rectangle {
                                        color: "#ffffff"
                                        border.color: "#cccccc"
                                        border.width: 1
                                        radius: 4
                                    }
                                    placeholderTextColor: "#999999"
                                    onTextChanged: {
                                        doctorCtrl.filterPatients()
                                    }
                                }

                                Button {
                                    text: "刷新"
                                    Layout.preferredWidth: 60
                                    background: Rectangle {
                                        color: "#2196F3"
                                        radius: 4
                                    }
                                    contentItem: Label {
                                        text: "刷新"
                                        color: "white"
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: doctorCtrl.fetchPatients()
                                }


                            }

                            // 预约学生列表状态提示
                            Label {
                                id: patientStatusLabel
                                text: "正在加载预约学生数据..."
                                color: "#ccc"
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 40
                                visible: patientListModel.count === 0
                            }

                            // 预约学生列表
                            ListView {
                                id: patientListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                Layout.topMargin: 20
                                Layout.bottomMargin: 20
                                clip: true

                                ScrollBar.vertical: ScrollBar {}

                                model: patientListModel

                                onCountChanged: {
                                    if (count > 0) {
                                        patientStatusLabel.visible = false
                                    } else {
                                        patientStatusLabel.visible = true
                                        patientStatusLabel.text = "没有预约学生"
                                    }
                                }

                                delegate: Rectangle {
                                    id: patientDelegate
                                    width: ListView.view.width - 20
                                    height: visible ? 110 : 0
                                    visible: !model.hidden
                                    color: "#ffffff"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                    border.width: 1
                                    anchors.margins: 5

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 8

                                        Text {
                                            text: model.patientName || "未知预约学生"
                                            color: "#333333"
                                            font.bold: true
                                            font.pixelSize: 16
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "状态: " + (model.status || "活跃")
                                            color: "#666666"
                                            font.pixelSize: 14
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "预约次数: " + (model.totalAppointments || 0)
                                            color: "#666666"
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 拒绝预约确认对话框
    Dialog {
        id: rejectConfirmDialog
        title: "拒绝预约"
        property int targetId: 0
        property string patientName: ""
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 400)
        height: 160
        background: Rectangle {
            color: "#ffffff"
            radius: 8
        }

        contentItem: Label {
            text: "确定要拒绝与 " + rejectConfirmDialog.patientName + " 的预约吗？"
            color: "#333333"
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14  // 减小字体避免溢出
            padding: 20
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width - 40  // 留出内边距
        }

        footer: Row {
            spacing: 15
            anchors.right: parent.right
            anchors.rightMargin: 20
            padding: 20

            Button {
                text: "确定"
                background: Rectangle {
                    color: "#f44336"
                    radius: 4
                }
                contentItem: Label {
                    text: "确定"
                    color: "white"
                    font.pixelSize: 14
                }
                onClicked: {
                    doctorCtrl.rejectAppointment(rejectConfirmDialog.targetId)
                    rejectConfirmDialog.close()
                }
            }

            Button {
                text: "取消"
                background: Rectangle {
                    color: "#9e9e9e"
                    radius: 4
                }
                contentItem: Label {
                    text: "取消"
                    color: "white"
                    font.pixelSize: 14
                }
                onClicked: rejectConfirmDialog.close()
            }
        }
    }
}