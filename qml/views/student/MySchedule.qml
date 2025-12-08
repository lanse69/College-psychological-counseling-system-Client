import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

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
            text: "我的预约"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
    }

    StudentController {
        id: studentCtrl

        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                refreshSchedule()
            }
        }

        onScheduleReceived: function(schedule) {
            // 清空现有数据
            scheduleModel.clear()

            if (!schedule || !Array.isArray(schedule) || schedule.length === 0) {
                return
            }

            for (var i = 0; i < schedule.length; i++) {
                var item = schedule[i]
                
                // 转换时间槽为文本
                var timeSlotText = getTimeSlotString(item.timeSlot)
                // 转换状态为文本
                var statusText = getStatusString(item.status)

                scheduleModel.append({
                    "id": item.id,
                    "date": item.appointmentDate,
                    "timeSlot": item.timeSlot,
                    "timeSlotText": timeSlotText,
                    "status": item.status,
                    "statusText": statusText,
                    "doctorName": item.doctorName || "未知医生",
                    "reason": item.reason || "",
                    "report": item.report || ""
                })
            }
        }
    }

    ListModel { id: scheduleModel }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Label {
                text: "预约记录"
                font.bold: true
                font.pixelSize: 24
                color: "white"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 20
                Layout.topMargin: 15
                spacing: 15

                Button {
                    text: "刷新"
                    onClicked: refreshSchedule()
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40

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
                        border.color: "#64b5f6"
                        border.width: 1
                    }
                }
            }

            ListView {
                id: scheduleView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: scheduleModel
                clip: true

                ScrollBar.vertical: ScrollBar {}

                // 暂无数据提示
                Text {
                    anchors.centerIn: parent
                    text: "暂无预约记录"
                    color: "#999"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: scheduleModel.count === 0
                }

                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 150

                    contentItem: ColumnLayout {
                        spacing: 15

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Text {
                                text: "预约日期: " + (function() {
                                    // 确保日期格式为年月日
                                    var dateStr = model.date || ""
                                    if (dateStr.length === 10 && dateStr.includes('-')) { // YYYY-MM-DD格式
                                        return dateStr.replace('-', '年').replace('-', '月') + '日'
                                    } else if (dateStr.length === 8) { // YYYYMMDD格式
                                        return dateStr.substring(0, 4) + "年" +
                                               dateStr.substring(4, 6) + "月" +
                                               dateStr.substring(6, 8) + "日"
                                    }
                                    return dateStr
                                })()
                                color: "white"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.statusText
                                color: {
                                    if (model.status === 0) return "#FFA726"  // 待确认 - 橙色
                                    else if (model.status === 1) return "#4CAF50"  // 已确认 - 绿色
                                    else if (model.status === 2) return "#2196F3"  // 已完成 - 蓝色
                                    else return "#F44336"
                                }
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Text {
                            text: "时间: " + model.timeSlotText
                            color: "#ccc"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            Layout.topMargin: 5
                        }

                        Text {
                            text: "医生: " + model.doctorName
                            color: "#ccc"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            Layout.topMargin: 5
                        }

                        Text {
                            text: {
                                if (model.reason) {
                                    return "咨询原因: " + model.reason
                                } else {
                                    return ""
                                }
                            }
                            color: "#aaa"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Button {
                                text: "取消预约"
                                visible: model.status === 0 || model.status === 1  // 待确认或已确认时可取消
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 35

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#d32f2f" : "#f44336"
                                    radius: 4
                                    border.color: "#ff8a80"
                                    border.width: 1
                                }

                                onClicked: {
                                    cancelConfirmDialog.targetId = model.id
                                    cancelConfirmDialog.doctorName = model.doctorName
                                    cancelConfirmDialog.open()
                                }
                            }

                            Button {
                                text: "修改预约"
                                visible: model.status === 0  // 仅待确认时可修改
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 35

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#1976d2" : "#2196F3"
                                    radius: 4
                                    border.color: "#64b5f6"
                                    border.width: 1
                                }

                                onClicked: {
                                    appWindow.showToast("修改功能开发中...", false)
                                }
                            }

                            Button {
                                text: "查看报告"
                                visible: model.status === 2  // 仅已完成的可查看报告
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 35

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.down ? "#388e3c" : "#4CAF50"
                                    radius: 4
                                    border.color: "#81c784"
                                    border.width: 1
                                }

                                onClicked: {
                                    showReportDialog.model = model
                                    showReportDialog.open()
                                }
                            }
                        }
                    }

                    background: Rectangle {
                        color: {
                            if (parent.highlighted) {
                                return "#444"
                            } else if (parent.hovered) {
                                return "#3a3a3a"
                            } else {
                                return "#2b2b2b"
                            }
                        }
                        radius: 5
                        border.color: "#555"
                        border.width: 1
                    }

                    highlighted: ListView.isCurrentItem
                }
            }
        }
    }

    // 取消预约确认对话框
    Dialog {
        id: cancelConfirmDialog
        title: "取消预约"
        property int targetId: 0
        property string doctorName: ""
        anchors.centerIn: parent

        Label {
            text: "确定要取消与 " + cancelConfirmDialog.doctorName + " 的预约吗？\n此操作不可恢复。"
            color: "white"
            wrapMode: Text.Wrap
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: studentCtrl.cancelAppointment(cancelConfirmDialog.targetId)
    }

    // 查看报告对话框
    Dialog {
        id: showReportDialog
        title: "咨询报告"
        property var model: null
        anchors.centerIn: parent
        width: 500
        height: 400

        ScrollView {
            anchors.fill: parent

            ColumnLayout {
                width: parent.width - 40
                spacing: 15

                Label {
                    text: showReportDialog.model ? ("与 " + showReportDialog.model.doctorName + " 的咨询报告") : ""
                    font.bold: true
                    font.pixelSize: 18
                    color: "white"
                    Layout.fillWidth: true
                }

                Label {
                    text: "咨询日期: " + (showReportDialog.model ? (function() {
                        var dateStr = showReportDialog.model.date || ""
                        if (dateStr.length === 10 && dateStr.includes('-')) {
                            return dateStr.replace('-', '年').replace('-', '月') + '日'
                        } else if (dateStr.length === 8) {
                            return dateStr.substring(0, 4) + "年" +
                                   dateStr.substring(4, 6) + "月" +
                                   dateStr.substring(6, 8) + "日"
                        }
                        return dateStr
                    })() : "")
                    color: "#ccc"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Label {
                    text: "咨询时间: " + (showReportDialog.model ? showReportDialog.model.timeSlotText : "")
                    color: "#ccc"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: "#555"
                }

                Label {
                    text: "咨询报告内容："
                    font.bold: true
                    color: "white"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }

                TextArea {
                    id: reportContent
                    text: showReportDialog.model ? (showReportDialog.model.report || "暂无报告内容") : ""
                    readOnly: true
                    color: "#ccc"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        color: "#333"
                        radius: 4
                    }
                }

                Label {
                    text: showReportDialog.model ? (showReportDialog.model.resultTags ? ("结果标签: " + showReportDialog.model.resultTags) : "") : ""
                    color: "#4CAF50"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }
        }
    }

    function getTimeSlotString(slot) {
        const slots = [
            "08:30-09:30", 
            "09:30-10:30", 
            "10:30-11:30", 
            "14:30-15:30", 
            "15:30-16:30", 
            "16:30-17:30", 
            "17:30-18:30"
        ];
        return slots[slot] || "未知时段";
    }

    function getStatusString(status) {
        if (status === 0) return "待确认";
        if (status === 1) return "已确认";
        if (status === 2) return "已完成";
        if (status === 3) return "已取消";
        return "未知状态";
    }

    function refreshSchedule() {
        studentCtrl.fetchMySchedule()
    }

    Component.onCompleted: {
        refreshSchedule()
    }
}
