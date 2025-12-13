import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Item {
    id: tabRoot
    property var controller: null
    property var selectedStudent: null

    // 学生列表模型
    ListModel { id: studentListModel }
    // 历史记录模型
    ListModel { id: historyModel }

    // 初始化刷新
    Component.onCompleted: refresh()
    
    // 切换回此页面时自动刷新
    onVisibleChanged: if (visible) refresh()

    function refresh() {
        if (controller) controller.fetchPatients()
        if (selectedStudent) controller.fetchPatientHistory(selectedStudent.userId)
    }

    Connections {
        target: controller
        
        function onPatientListReceived(list) {
            studentListModel.clear()
            for(var i=0; i<list.length; i++) {
                studentListModel.append(list[i])
            }
        }
        
        function onPatientHistoryReceived(list) {
            historyModel.clear()
            for(var i=0; i<list.length; i++) {
                var item = list[i]
                
                var rawArr = item.surveyAnswers || []
                var objArr = []
                for (var j = 0; j < rawArr.length; j++) {
                    objArr.push({ "answerText": String(rawArr[j]) })
                }
                item.surveyAnswers = objArr

                item.report = item.report || ""
                item.reason = item.reason || ""
                
                historyModel.append(item)
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // 学生列表区
        Rectangle {
            SplitView.preferredWidth: 300
            SplitView.minimumWidth: 200
            SplitView.maximumWidth: 400
            color: Theme.background

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // 列表头
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: Theme.surface
                    border.color: Theme.divider
                    border.width: 1
                    
                    Label {
                        text: "预约学生列表"
                        color: Theme.textPrimary
                        font.bold: true
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                }

                ListView {
                    id: studentListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: studentListModel
                    
                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: 70
                        highlighted: ListView.isCurrentItem
                        
                        background: Rectangle {
                            color: parent.highlighted ? Theme.surfaceHighlight : (parent.hovered ? Theme.surfaceHighlight : "transparent")
                            Rectangle {
                                width: 4
                                height: parent.height
                                color: Theme.primary
                                visible: parent.parent.highlighted
                            }
                        }

                        contentItem: RowLayout {
                            spacing: 15
                            Rectangle {
                                width: 40; height: 40; radius: 20
                                color: Theme.primary
                                Text {
                                    text: model.realName ? model.realName.charAt(0) : "?"
                                    color: Theme.textPrimary
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }
                            
                            Column {
                                Text { 
                                    text: model.realName
                                    font.bold: true
                                    font.pixelSize: 16 
                                    color: Theme.textPrimary
                                }
                                Text { 
                                    text: "预约次数: " + model.appointmentCount
                                    font.pixelSize: 12
                                    color: Theme.textSecondary 
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: model.lastAppointmentDate || ""
                                font.pixelSize: 11
                                color: Theme.textPlaceholder
                            }
                        }
                        
                        onClicked: {
                            studentListView.currentIndex = index
                            tabRoot.selectedStudent = model
                            controller.fetchPatientHistory(model.userId)
                        }
                    }
                }
            }
        }

        // 详情与历史
        Rectangle {
            SplitView.fillWidth: true
            color: Theme.surface

            // 未选择时的提示
            ColumnLayout {
                anchors.centerIn: parent
                visible: !selectedStudent
                spacing: 10
                Text {
                    text: "请从左侧选择一名学生查看详细档案"
                    color: Theme.textPlaceholder
                    font.pixelSize: 16
                }
            }

            // 详情内容
            ColumnLayout {
                visible: !!selectedStudent
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // 顶部信息栏
                RowLayout {
                    Layout.fillWidth: true
                    Label { 
                        text: selectedStudent ? selectedStudent.realName : ""
                        font.bold: true
                        font.pixelSize: 24 
                        color: Theme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Label { 
                        text: "累计咨询: " + (selectedStudent ? selectedStudent.appointmentCount : 0) + " 次"
                        color: Theme.success
                        font.bold: true
                        font.pixelSize: 14
                    }
                }
                
                // 分割线
                Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }
                
                Label { 
                    text: "咨询历史记录" 
                    font.bold: true 
                    font.pixelSize: 16 
                    color: Theme.textSecondary 
                }

                Text {
                    visible: historyModel.count === 0
                    text: "暂无历史咨询记录"
                    color: Theme.textPlaceholder
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                }

                // 历史记录列表
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: historyModel
                    spacing: 15
                    visible: historyModel.count > 0

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: itemCol.implicitHeight + 30
                        color: Theme.background 
                        radius: 8
                        border.color: Theme.border
                        border.width: 1

                        ColumnLayout {
                            id: itemCol
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 8
                            
                            // 预约时间与状态
                            RowLayout {
                                Layout.fillWidth: true
                                Text { 
                                    text: model.appointmentDate + " (" + getTimeSlotStr(model.timeSlot) + ")"
                                    font.bold: true 
                                    font.pixelSize: 14
                                    color: Theme.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                Text { 
                                    text: getStatusStr(model.status)
                                    color: getStatusColor(model.status)
                                    font.bold: true
                                }
                            }
                            
                            Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                            // 咨询摘要
                            Text { 
                                text: "咨询摘要/标签: " + (model.reason || "无记录")
                                color: Theme.textSecondary
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }

                            // 详细报告
                            Text {
                                visible: model.report !== "" && model.report !== undefined
                                text: "详细报告: " + model.report
                                color: Theme.textSecondary
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                Layout.maximumHeight: 60 
                                elide: Text.ElideRight
                            }
                            
                            // 问卷回答区域
                            ColumnLayout {
                                visible: surveyAnswers && surveyAnswers.count > 0
                                Layout.fillWidth: true
                                Layout.topMargin: 5
                                spacing: 4
                                
                                Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider; Layout.bottomMargin: 4 }
                                
                                RowLayout {
                                    Text { 
                                        text: "问卷填写记录"; 
                                        font.bold: true; 
                                        font.pixelSize: 12; 
                                        color: Theme.primary 
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                Repeater {
                                    model: surveyAnswers
                                    delegate: RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 10
                                        Text { 
                                            text: "Q" + (index + 1) + ":"
                                            color: Theme.textPlaceholder
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        Text {
                                            text: answerText
                                            color: Theme.textPrimary
                                            font.pixelSize: 11
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !(surveyAnswers && surveyAnswers.count > 0)
                                text: "该次预约未填写问卷"
                                color: Theme.textPlaceholder
                                font.pixelSize: 11
                                font.italic: true
                                Layout.topMargin: 5
                            }
                        }
                    }
                }
            }
        }
    }
    
    function getStatusStr(s) {
        if(s===0) return "待确认"; 
        if(s===1) return "已确认"; 
        if(s===2) return "已完成"; 
        if(s===3) return "已取消"; 
        return "未知";
    }

    function getStatusColor(s) {
        if(s===0) return Theme.warning; 
        if(s===1) return Theme.success; 
        if(s===2) return Theme.primary; 
        return Theme.textPlaceholder;
    }
    
    function getTimeSlotStr(slot) {
        if (slot === undefined || slot === null || slot < 0) return "";
        var slots = ["08:30-09:30", "09:30-10:30", "10:30-11:30", "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"];
        return slots[slot] || "未知时段";
    }
}