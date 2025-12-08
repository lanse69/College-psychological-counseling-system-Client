import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

import "../../components"

Page {
    id: root

    header: ToolBar {
        Button {
            text: "返回"
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: stackView.pop()
        }
        Label {
            text: "预约学生管理"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
    }

    DoctorController {
        id: doctorCtrl

        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
        }

        onPatientListReceived: function(patients) {
            patientListModel.clear()
            for (var i = 0; i < patients.length; i++) {
                var patient = patients[i]
                patientListModel.append({
                    patientId: patient.userId,
                    patientName: patient.realName,
                    totalAppointments: patient.appointmentCount || 0,
                    completedAppointments: patient.appointmentCount || 0, 
                    lastAppointment: patient.lastAppointmentDate || "无记录",
                    status: patient.appointmentCount > 3 ? "治疗中" : "活跃",
                    notes: "点击查看详情...",
                    hidden: false
                })
            }
        }

        onPatientHistoryReceived: function(historyList) {
            historyModel.clear()
            
            for (var i = 0; i < historyList.length; i++) {
                var item = historyList[i]
                historyModel.append({
                    "id": item.id,
                    "date": item.appointmentDate,
                    "timeSlot": item.timeSlot,
                    "timeText": getTimeSlotString(item.timeSlot), 
                    "status": item.status,
                    "statusText": getStatusString(item.status),
                    "reason": item.reason || "无",
                    "notes": item.report || (item.status === 2 ? "待填写报告" : "无咨询报告")
                })
            }
        }

        function filterLocal(text) {
            var searchText = text.toLowerCase()
            for(var i = 0; i < patientListModel.count; i++) {
                var item = patientListModel.get(i)
                var match = item.patientName.toLowerCase().indexOf(searchText) !== -1
                patientListModel.setProperty(i, "hidden", !match)
            }
        }

        Component.onCompleted: {
            doctorCtrl.fetchPatients()
        }
    }

    ListModel { id: patientListModel }
    ListModel { id: historyModel }

    property var selectedPatient: null
    property bool showPatientDetails: false // 控制 SplitView 显示

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        // 显示详情 (SplitView 模式)
        SplitView {
            anchors.fill: parent
            orientation: Qt.Horizontal
            visible: showPatientDetails

            // 左侧：预约学生列表
            PatientList {
                SplitView.preferredWidth: parent.width * 0.4
                SplitView.minimumWidth: 250
                
                patientModel: patientListModel
                showToggleButton: false // SplitView模式下不需要切换按钮
                
                onRefreshClicked: doctorCtrl.fetchPatients()
                onSearchTextChanged: (text) => doctorCtrl.filterLocal(text)
                
                onPatientSelected: function(patientData, index) {
                    root.selectPatient(patientData)
                }
            }

            // 右侧：预约学生详情
            Rectangle {
                SplitView.fillWidth: true
                color: "#1e1e1e"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        width: parent.width - 40
                        spacing: 20

                        Button {
                            text: "关闭详情"
                            Layout.alignment: Qt.AlignRight
                            onClicked: showPatientDetails = false
                            background: Rectangle { color: "#444"; radius: 4 }
                            contentItem: Text { text: parent.text; color: "white"; anchors.centerIn: parent }
                        }

                        // 预约学生基本信息
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            color: "#2b2b2b"
                            radius: 10
                            border.color: "#555"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 10

                                Label {
                                    text: selectedPatient ? selectedPatient.patientName : ""
                                    font.bold: true
                                    font.pixelSize: 24
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 20
                                    Label { text: "总预约: " + (selectedPatient ? selectedPatient.totalAppointments : 0); color: "#ccc"; font.pixelSize: 14 }
                                    Label { text: "状态: " + (selectedPatient ? selectedPatient.status : ""); color: "#4CAF50"; font.pixelSize: 14 }
                                }
                                Label {
                                    text: "最后咨询: " + (selectedPatient ? selectedPatient.lastAppointment : "无记录")
                                    color: "#ccc"; font.pixelSize: 14
                                }
                            }
                        }

                        // 预约学生备注
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                            color: "#2b2b2b"
                            radius: 10
                            border.color: "#555"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Label {
                                    text: "预约学生备注"
                                    font.bold: true
                                    font.pixelSize: 18
                                    color: "white"
                                }

                                TextArea {
                                    id: notesField
                                    text: selectedPatient ? selectedPatient.notes : ""
                                    placeholderText: "预约学生的基本情况、问题描述、治疗进展等..."
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    wrapMode: Text.Wrap
                                    color: "black"
                                    background: Rectangle {
                                        color: "#f0f0f0"
                                        radius: 4
                                    }
                                    readOnly: true
                                }

                                Button {
                                    text: "编辑备注"
                                    Layout.alignment: Qt.AlignRight
                                    highlighted: true
                                    visible: selectedPatient !== null

                                    onClicked: {
                                        if (notesField.readOnly) {
                                            notesField.readOnly = false
                                            editNotesButton.text = "保存"
                                        } else {
                                            // 保存备注逻辑
                                            notesField.readOnly = true
                                            editNotesButton.text = "编辑备注"
                                            appWindow.showToast("备注已保存", false)
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: parent.down ? "#1976d2" : "#2196F3"
                                        radius: 4
                                    }
                                }

                                Button {
                                    id: editNotesButton
                                    text: "编辑备注"
                                    Layout.alignment: Qt.AlignRight
                                    highlighted: true
                                    visible: false
                                }
                            }
                        }

                        // 预约历史
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            color: "#2b2b2b"
                            radius: 10
                            border.color: "#555"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Label {
                                    text: "预约历史"
                                    font.bold: true
                                    font.pixelSize: 18
                                    color: "white"
                                }

                                Label {
                                    visible: historyModel.count === 0
                                    text: "暂无预约历史记录"
                                    color: "#666"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    ScrollBar.vertical: ScrollBar {}

                                    model: historyModel

                                    delegate: ItemDelegate {
                                        width: ListView.view.width
                                        height: 80

                                        contentItem: ColumnLayout {
                                            spacing: 5

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Text {
                                                    text: model.date + " " + model.timeText
                                                    color: "white"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: model.statusText
                                                    color: model.status === 2 ? "#4CAF50" : "#FFA726"
                                                    font.pixelSize: 12
                                                }
                                            }

                                            Text {
                                                text: "咨询原因: " + model.reason
                                                color: "#ccc"
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: "报告/备注: " + model.notes
                                                color: "#aaa"
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                            }
                                        }

                                        background: Rectangle {
                                            color: parent.hovered ? "#3a3a3a" : "transparent"
                                            radius: 5
                                        }

                                        onClicked: {
                                            if (model.status === 2) {
                                                // 查看已完成的报告
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 操作按钮
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20
                            Layout.topMargin: 20

                            Button {
                                text: "发送消息"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                visible: selectedPatient !== null

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#388e3c" : "#4CAF50"
                                    radius: 4
                                }

                                onClicked: {
                                    appWindow.showToast("消息功能开发中...", false)
                                }
                            }

                            Button {
                                text: "创建新预约"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                visible: selectedPatient !== null

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#1976d2" : "#2196F3"
                                    radius: 4
                                }

                                onClicked: {
                                    appWindow.showToast("预约功能开发中...", false)
                                }
                            }

                            Button {
                                text: "生成报告"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                visible: selectedPatient !== null

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#7b1fa2" : "#9C27B0"
                                    radius: 4
                                }

                                onClicked: {
                                    appWindow.showToast("报告生成功能开发中...", false)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 不显示详情
        PatientList {
            anchors.fill: parent
            visible: !showPatientDetails
            
            patientModel: patientListModel
            showToggleButton: true // 显示"显示详情"按钮
            isDetailsVisible: showPatientDetails
            
            onRefreshClicked: doctorCtrl.fetchPatients()
            onSearchTextChanged: (text) => doctorCtrl.filterLocal(text)
            
            onPatientSelected: function(patientData, index) {
               showPatientDetails = true
               root.selectPatient(patientData)
            }
            
            onToggleDetailsClicked: showPatientDetails = !showPatientDetails
        }
    }
    // 统一处理选中逻辑
    function selectPatient(patientData) {
        selectedPatient = patientData
        if (patientData && patientData.patientId) {
            historyModel.clear() // 先清空，等待网络回调
            doctorCtrl.fetchPatientHistory(patientData.patientId)
        }
    }

    // 状态转换
    function getStatusString(status) {
        if (status === 0) return "待确认";
        if (status === 1) return "已确认";
        if (status === 2) return "已完成";
        if (status === 3) return "已取消";
        return "未知";
    }

    // 时间段转换
    function getTimeSlotString(slot) {
        const slots = [
            "08:30-09:30", "09:30-10:30", "10:30-11:30",
            "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"
        ];
        return slots[slot] || "未知时段";
    }
}
