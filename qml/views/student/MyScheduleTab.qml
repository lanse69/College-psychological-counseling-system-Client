import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

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
                item.pendingDate = item.pendingDate || ""
                item.pendingSlot = (item.pendingSlot !== undefined) ? item.pendingSlot : -1
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
        anchors.margins: 15
        spacing: 15

        // 顶部标题栏
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "我的预约记录"
                font.bold: true
                font.pixelSize: 22
                color: Theme.textPrimary 
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
                height: 150
                color: Theme.surface
                radius: 8
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 6

                    // 日期 + 状态
                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.date
                            font.bold: true
                            font.pixelSize: 16
                            color: Theme.textPrimary 
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: model.status === 4 ? "待确认修改" : getStatusStr(model.status)
                            color: model.status === 4 ? Theme.primary : getStatusColor(model.status)
                            font.bold: true
                        }
                    }
                    
                    // 详细信息
                    Text { 
                        text: "时间: " + getTimeSlotStr(model.timeSlot)
                        color: Theme.textSecondary 
                    }
                    Text { 
                        text: "医生: " + model.doctorName
                        color: Theme.textSecondary 
                    }

                    Rectangle {
                        visible: model.status === 4
                        Layout.fillWidth: true
                        height: 45
                        color: Theme.surfaceHighlight
                        radius: 4
                        border.color: Theme.primary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10
                            
                            Text {
                                text: "医生建议修改至:"
                                color: Theme.textSecondary
                                font.pixelSize: 12
                            }
                            
                            Text {
                                text: model.pendingDate + " " + getTimeSlotStr(model.pendingSlot)
                                color: Theme.primary
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }

                    // 分割线
                    Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                    // 操作按钮区
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Item { Layout.fillWidth: true } // 占位

                        // 同意修改
                        Button {
                            text: "同意修改"
                            visible: model.status === 4
                            highlighted: true
                            onClicked: controller.replyModification(model.id, true)
                        }

                        // 拒绝修改
                        Button {
                            text: "拒绝"
                            visible: model.status === 4
                            onClicked: controller.replyModification(model.id, false)
                        }

                        // 修改预约
                        // 仅待确认(0)或已确认(1)可修改
                        Button {
                            text: "修改时间"
                            visible: (model.status === 0 || model.status === 1) && model.status !== 4
                            onClicked: {
                                modifyDialog.targetId = model.id
                                modifyDialog.selectedDate = model.date // 原日期
                                modifyDialog.selectedSlot = model.timeSlot // 原时间
                                modifyDialog.open()
                            }
                        }

                        // 取消预约
                        // 仅待确认(0)或已确认(1)可取消
                        Button {
                            text: "取消"
                            visible: model.status === 0 || model.status === 1
                            onClicked: {
                                cancelDialog.targetId = model.id
                                cancelDialog.open()
                            }
                        }
                        
                        // 心理问卷
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

                        // 查看报告
                        Button {
                            text: "查看报告"
                            visible: model.status === 2 // 已完成
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

                        // 删除记录
                        Button {
                            text: "删除记录"
                            visible: model.status === 3 // 已取消
                            
                            contentItem: Text {
                                text: parent.text
                                color: Theme.error
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: "transparent"
                                border.color: Theme.error
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

    // 修改预约
    Dialog {
        id: modifyDialog
        title: "修改预约时间"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        property int targetId: 0
        property string selectedDate: ""
        property int selectedSlot: -1

        background: Rectangle {
            color: Theme.surface
            radius: 5
            border.color: Theme.border
        }

        contentItem: ColumnLayout {
            spacing: 15
            Label { 
                text: "请选择新的日期 (格式: YYYY-MM-DD)"
                color: Theme.textSecondary
            }
            
            TextField {
                id: dateField
                text: modifyDialog.selectedDate
                placeholderText: "YYYY-MM-DD"
                Layout.fillWidth: true
                color: Theme.textPrimary
                placeholderTextColor: Theme.textPlaceholder
                background: Rectangle {
                    color: Theme.inputBackground
                    border.color: Theme.border
                    radius: 4
                }
                onTextEdited: modifyDialog.selectedDate = text
            }

            Label { 
                text: "选择时间段:" 
                color: Theme.textSecondary
            }
            
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["08:30-09:30", "09:30-10:30", "10:30-11:30", 
                                "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"]
                    delegate: Button {
                        text: modelData
                        checkable: true
                        checked: modifyDialog.selectedSlot === index
                        highlighted: checked
                        onClicked: modifyDialog.selectedSlot = index
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.checked ? Theme.textInverted : Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.checked ? Theme.primary : "transparent"
                            border.color: parent.checked ? Theme.primary : Theme.border
                            radius: 4
                        }
                    }
                }
            }
        }
        
        onAccepted: {
            if (modifyDialog.selectedDate.length >= 8 && modifyDialog.selectedSlot >= 0) {
                // 调用 Controller 的修改接口
                controller.modifyAppointment(targetId, modifyDialog.selectedDate, modifyDialog.selectedSlot)
            } else {
                appWindow.showToast("请填写完整信息", true)
            }
        }
    }

    // 取消确认
    Dialog {
        id: cancelDialog
        property int targetId: 0
        title: "提示"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        width: 300
        standardButtons: Dialog.Yes | Dialog.No

        background: Rectangle { color: Theme.surface; radius: 5; border.color: Theme.border }
        
        contentItem: Text { 
            text: "确定要取消此预约吗？"
            color: Theme.textPrimary
            font.pixelSize: 16
            padding: 20
            wrapMode: Text.Wrap
        }
        onAccepted: controller.cancelAppointment(cancelDialog.targetId)
    }

    // 删除确认
    Dialog {
        id: confirmDeleteDialog
        property int targetId: 0
        title: "确认删除"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        standardButtons: Dialog.Yes | Dialog.No
        
        background: Rectangle { color: Theme.surface; radius: 5; border.color: Theme.border }
        
        contentItem: Text {
            text: "确定要彻底删除这条预约记录吗？"
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            padding: 20
        }
        
        onAccepted: {
            controller.deleteAppointment(confirmDeleteDialog.targetId)
        }
    }

    // 报告详情
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
            color: Theme.surface
            radius: 5
            border.color: Theme.border
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
                    color: Theme.textSecondary
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                Label { text: "评估标签"; font.bold: true; color: Theme.primary }
                Text {
                    text: reportDetailDialog.resultTags || "无标签"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                }

                Label { text: "详细报告/建议"; font.bold: true; color: Theme.primary }
                Text {
                    text: reportDetailDialog.reportContent || "医生暂未填写详细内容"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    lineHeight: 1.4
                    color: Theme.textPrimary
                }
            }
        }
    }

    // 状态文字
    function getStatusStr(s) {
        if(s===0) return "待确认"; if(s===1) return "已确认"; 
        if(s===2) return "已完成"; if(s===3) return "已取消"; return "未知";
    }

    // 状态颜色
    function getStatusColor(s) {
        if(s===0) return Theme.warning;
        if(s===1) return Theme.success;
        if(s===2) return Theme.primary;
        return Theme.textSecondary;
    }

    function getTimeSlotStr(slot) {
        if (slot === undefined || slot === null || slot < 0) return "未知时段";
        var slots = ["08:30-09:30", "09:30-10:30", "10:30-11:30", "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"];
        return slots[slot] || "未知时段";
    }
}