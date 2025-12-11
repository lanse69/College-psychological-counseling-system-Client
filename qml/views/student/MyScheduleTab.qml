import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: tabRoot
    property var controller: null

    ListModel { id: scheduleModel }

    Component.onCompleted: refresh()
    // 当 Tab 变为可见时刷新
    onVisibleChanged: if (visible) refresh()

    function refresh() {
        if (controller) controller.fetchMySchedule()
    }

    // 监听 Controller 信号
    Connections {
        target: controller
        function onScheduleReceived(schedule) {
            scheduleModel.clear()
            for (var i = 0; i < schedule.length; i++) {
                var item = schedule[i]
                item.date = item.appointmentDate || item.date || "日期未知"
                item.doctorName = item.doctorName || "未知医生"
                item.status = (item.status !== undefined) ? item.status : 0
                item.timeSlot = (item.timeSlot !== undefined) ? item.timeSlot : -1
                item.report = item.report || ""
                item.resultTags = item.resultTags || ""
                scheduleModel.append(item)
            }
        }
        // 操作成功后自动刷新
        function onOperationResult(success, msg) {
            if (success && tabRoot.visible) refresh()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "我的预约记录"
                font.bold: true
                font.pixelSize: 22
                color: "white"
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "刷新"
                onClicked: refresh()
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: scheduleModel
            spacing: 10

            delegate: Rectangle {
                width: ListView.view.width
                height: 140
                color: "white"
                radius: 8
                border.color: "#ddd"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.date
                            font.bold: true; font.pixelSize: 16; color: "#333" 
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: getStatusStr(model.status)
                            color: getStatusColor(model.status)
                            font.bold: true
                        }
                    }
                    
                    Text { 
                        text: "时间: " + getTimeSlotStr(model.timeSlot)
                        color: "#555" 
                    }
                    Text { 
                        text: "医生: " + model.doctorName
                        color: "#555" 
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Item { Layout.fillWidth: true } // 占位，把按钮挤到右边

                        // 只有待确认(0)或已确认(1)可取消
                        Button {
                            text: "取消预约"
                            visible: model.status === 0 || model.status === 1
                            onClicked: {
                                cancelDialog.targetId = model.id
                                cancelDialog.open()
                            }
                        }
                        
                        // 只有待确认(0)或已确认(1)可填写问卷
                        Button {
                            text: "心理问卷"
                            visible: model.status === 0 || model.status === 1
                            highlighted: true
                            onClicked: {
                                stackView.push("SurveyFill.qml", {
                                    "currentAppointment": {
                                        "id": model.id,
                                        "doctorName": model.doctorName,
                                        "date": model.date
                                    }
                                })
                            }
                        }

                        // "查看报告" 按钮
                        Button {
                            text: "查看报告"
                            visible: model.status === 2
                            highlighted: true
                            onClicked: {
                                if (model.report !== "" || model.resultTags !== "") {
                                    reportDetailDialog.reportContent = model.report
                                    reportDetailDialog.resultTags = model.resultTags
                                    reportDetailDialog.doctorName = model.doctorName
                                    reportDetailDialog.open()
                                } else {
                                    if (typeof appWindow !== "undefined") {
                                        appWindow.showToast("医生还暂未填写报告内容", true)
                                    }
                                }
                            }
                        }

                        // 删除记录按钮
                        Button {
                            text: "删除记录"
                            visible: model.status === 3
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: "#d32f2f"
                                radius: 4
                            }
                            
                            onClicked: {
                                confirmDeleteDialog.targetId = model.id
                                confirmDeleteDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: cancelDialog
        property int targetId: 0
        title: "提示"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        width: 300
        standardButtons: Dialog.Yes | Dialog.No
        background: Rectangle { color: "white"; radius: 5 }
        contentItem: Text { 
            text: "确定要取消此预约吗？"
            color: "black" 
            font.pixelSize: 16
            padding: 20
        }
        onAccepted: controller.cancelAppointment(cancelDialog.targetId)
    }

    Dialog {
        id: reportDetailDialog
        title: "咨询结果报告"
        width: Math.min(tabRoot.width * 0.9, 500)
        height: 400

        x: (tabRoot.width - width) / 2
        y: (tabRoot.height - height) / 2

        modal: true
        standardButtons: Dialog.Ok

        property string reportContent: ""
        property string resultTags: ""
        property string doctorName: ""
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ccc"
        }

        contentItem: ScrollView {
            id: bgScrollView
            contentWidth: availableWidth
            clip: true
            
            ColumnLayout {
                width: reportDetailDialog.availableWidth
                spacing: 15
                Label {
                    text: "医生: " + reportDetailDialog.doctorName
                    font.bold: true
                    color: "#555"
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#ddd" }

                Label { text: "评估标签"; font.bold: true; color: "#1976D2" }
                Text {
                    text: reportDetailDialog.resultTags || "无标签"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    color: "#333"
                }

                Label { text: "详细报告/建议"; font.bold: true; color: "#1976D2" }
                Text {
                    text: reportDetailDialog.reportContent || "医生暂未填写详细内容"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    lineHeight: 1.4
                    color: "#333"
                }
            }
        }
    }

    Dialog {
        id: confirmDeleteDialog
        property int targetId: 0
        title: "确认删除"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        standardButtons: Dialog.Yes | Dialog.No
        
        background: Rectangle {
            color: "white"
            radius: 5
        }
        
        contentItem: Text {
            text: "确定要彻底删除这条预约记录吗？"
            color: "#333"
            wrapMode: Text.Wrap
            padding: 20
        }
        
        onAccepted: {
            controller.deleteAppointment(confirmDeleteDialog.targetId)
        }
    }

    function getStatusStr(s) {
        if(s===0) return "待确认"; if(s===1) return "已确认"; 
        if(s===2) return "已完成"; if(s===3) return "已取消"; return "未知";
    }

    function getStatusColor(s) {
        if(s===0) return "#FF9800"; if(s===1) return "#4CAF50"; 
        if(s===2) return "#2196F3"; return "#9E9E9E";
    }

    function getTimeSlotStr(slot) {
        if (slot === undefined || slot === null || slot < 0) return "未知时段";
        var slots = ["08:30-09:30", "09:30-10:30", "10:30-11:30", "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"];
        return slots[slot] || "未知时段";
    }
}