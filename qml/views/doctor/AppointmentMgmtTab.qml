import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: tabRoot
    property var controller: null

    Component.onCompleted: {
        if (controller) {
            controller.fetchAppointments()
        }
    }

    Connections {
        target: controller
        function onSurveyContentReceived(data) {
            surveyDetailDialog.surveyTitle = data.title || "问卷详情"
            surveyDetailDialog.questions = data.questions || []
            surveyDetailDialog.answers = data.existingAnswers || []
            surveyDetailDialog.open()
        }
    }

    onVisibleChanged: {
        if (visible && controller) controller.fetchAppointments()
    }

    function refresh() {
        if (controller) controller.fetchAppointments()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        RowLayout {
            Label { text: "预约申请列表"; font.bold: true; font.pixelSize: 20 }
            Item { Layout.fillWidth: true }
            Button { text: "刷新列表"; onClicked: refresh() }
        }

        // 状态筛选器
        ComboBox {
            id: filterCombo
            Layout.fillWidth: true
            model: ["全部状态", "待确认", "已确认", "已完成", "已取消"]
            onActivated: {
                if (controller && controller.appointmentModel) {
                    controller.appointmentModel.applyFilter(currentText === "全部状态" ? "全部" : currentText)
                }
            }
        }

        ListView {
            id: apptList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            
            model: controller ? controller.appointmentModel : null

            delegate: Rectangle {
                width: ListView.view.width
                height: 140
                color: "white"
                radius: 8
                border.color: "#ddd"
                
                visible: true 

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.studentName || "未知学生"
                            font.bold: true
                            font.pixelSize: 18
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: model.statusText
                            font.bold: true
                            color: getStatusColor(model.status)
                        }
                    }

                    Text { 
                        text: "时间: " + model.appointmentDate + " " + model.timeSlotText 
                        color: "#555"
                    }
                    Text { 
                        text: "备注: " + (model.reason || "无")
                        color: "#888"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                    // 操作按钮区
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Item { Layout.fillWidth: true }

                        Text {
                            visible: model.status === 2 || model.status === 3
                            text: model.status === 2 ? "咨询已归档" : "预约已失效"
                            color: "#aaa"
                        }

                        // 状态 0: 待确认 -> 显示 接受/拒绝
                        Button {
                            text: "拒绝"
                            visible: model.status === 0
                            onClicked: {
                                rejectDialog.targetId = model.id
                                rejectDialog.studentName = model.studentName
                                rejectDialog.open()
                            }
                            background: Rectangle { color: "#ffebee"; radius: 4; border.color: "#ef5350" }
                            contentItem: Text { text: "拒绝"; color: "#d32f2f"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }

                        Button {
                            text: "接受预约"
                            visible: model.status === 0
                            highlighted: true
                            onClicked: controller.confirmAppointment(model.id)
                        }

                        Button {
                            text: "查看问卷"
                            // 状态 1(已确认) 2(已完成) 时显示
                            visible: model.status === 1 || model.status === 2
                            onClicked: {
                                controller.fetchAppointmentSurvey(model.id)
                            }
                        }

                        // 状态 1: 已确认 -> 显示 完成咨询
                        Button {
                            text: "填写报告并完成"
                            visible: model.status === 1
                            highlighted: true
                            onClicked: {
                                // 跳转到写报告页面
                                stackView.push("ReportWrite.qml", {
                                    "appointmentId": model.id,
                                    "studentName": model.studentName
                                })
                            }
                        }

                        // 删除记录按钮
                        Button {
                            text: "删除记录"
                            visible: model.status === 3
                            
                            contentItem: Text {
                                text: parent.text
                                color: "#d32f2f"
                            }
                            background: Rectangle {
                                color: "transparent"
                                border.color: "#d32f2f"
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
        id: rejectDialog
        property int targetId: 0
        property string studentName: ""
        title: "拒绝确认"
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No
        Text { text: "确定要拒绝 " + rejectDialog.studentName + " 的预约吗？" }
        onAccepted: controller.rejectAppointment(rejectDialog.targetId)
    }

    Dialog {
        id: confirmDeleteDialog
        property int targetId: 0
        title: "确认删除"
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No
        
        Text { text: "确定要移除这条已取消的记录吗？"; color: "white"}
        
        onAccepted: {
            controller.deleteAppointment(confirmDeleteDialog.targetId)
        }
    }

    Dialog {
        id: surveyDetailDialog
        title: "学生问卷填写情况"
        width: 600
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Close
        
        property string surveyTitle: ""
        property var questions: []
        property var answers: []

        contentItem: ColumnLayout {
            Label {
                text: surveyDetailDialog.surveyTitle
                font.bold: true; font.pixelSize: 18
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle { height: 1; Layout.fillWidth: true; color: "#ccc" }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Repeater {
                        model: surveyDetailDialog.questions
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            // 题目
                            Text {
                                text: (index + 1) + ". " + modelData.question
                                font.bold: true
                                color: "#c2c9c2ff"
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            
                            // 学生的回答
                            Text {
                                property string ans: (surveyDetailDialog.answers.length > index) 
                                                     ? surveyDetailDialog.answers[index] 
                                                     : "未作答"
                                text: "回答: " + ans
                                color: "#1976D2"
                                font.pixelSize: 14
                                Layout.leftMargin: 20
                            }
                        }
                    }
                    
                    Label {
                        visible: surveyDetailDialog.questions.length === 0
                        text: "该学生暂未填写问卷"
                        color: "#888"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    function getStatusColor(s) {
        if(s===0) return "#FF9800"; if(s===1) return "#4CAF50"; 
        if(s===2) return "#2196F3"; return "#9E9E9E";
    }
}