import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    header: ToolBar {
        Label {
            text: "学生端 - " + sessionCtrl.currentUsername
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

    StudentController {
        id: studentCtrl

        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
        }

        onDoctorListReceived: function(doctors) {
            doctorListModel.clear()
            for (var i = 0; i < doctors.length; i++) {
                doctorListModel.append(doctors[i])
            }
        }

        onDoctorDetailReceived: function(doctor) {
        }

        onScheduleReceived: function(schedule) {
            // 清空现有数据
            myScheduleModel.clear()

            if (!schedule || !Array.isArray(schedule)) return

            for (var i = 0; i < schedule.length; i++) {
                var item = schedule[i]

                myScheduleModel.append({
                    "id": item.id,
                    "date": item.appointmentDate,
                    "timeSlot": item.timeSlot,
                    "timeSlotText": getTimeSlotString(item.timeSlot),
                    "status": item.status,
                    "statusText": getStatusString(item.status),
                    "doctorName": item.doctorName || "未知医生",
                    "reason": item.reason || "",
                    "report": item.report || ""
                })
            }
        }
    }

    ListModel { id: doctorListModel }
    ListModel { id: myScheduleModel }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: bar
            Layout.fillWidth: true

            TabButton {
                text: "医生列表"
            }

            TabButton {
                text: "我的预约"
                onClicked: {
                    stackView.push("MySchedule.qml")
                }
            }

            TabButton { text: "心理测评" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex

            // 医生列表
            Item {
                Rectangle {
                    anchors.fill: parent
                    color: "#1e1e1e"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            text: "心理咨询师"
                            font.bold: true
                            font.pixelSize: 24
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                        }

                        ListView {
                            id: doctorListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: doctorListModel
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            delegate: ItemDelegate {
                                width: ListView.view.width
                                height: 80

                                contentItem: ColumnLayout {
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: model.realName || "医生姓名"
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 18
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "可预约"
                                            color: "#4CAF50"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Text {
                                        text: model.specializedField || "专业领域待补充"
                                        color: "#ccc"
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.intro || "简介待补充"
                                        color: "#aaa"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                    }
                                }

                                background: Rectangle {
                                    color: {
                                        if (parent.highlighted) {
                                            return "#444"
                                        } else if (parent.hovered) {
                                            return "#3a3a3a"
                                        } else {
                                            return "transparent"
                                        }
                                    }
                                    radius: 5
                                    border.color: "#555"
                                    border.width: 1
                                }

                                highlighted: ListView.isCurrentItem
                                onClicked: {
                                    doctorListView.currentIndex = index
                                    stackView.push("DoctorDetail.qml", {selectedDoctor: model})
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    studentCtrl.fetchDoctorList()
                }
            }

            // 我的预约
            Item {
                Rectangle {
                    anchors.fill: parent
                    color: "#1e1e1e"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            text: "我的预约"
                            font.bold: true
                            font.pixelSize: 24
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                        }

                        ListView {
                            id: myScheduleView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: myScheduleModel
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            delegate: ItemDelegate {
                                width: ListView.view.width
                                height: 130 // 增加高度以避免重叠

                                contentItem: ColumnLayout {
                                    spacing: 12 // 增加间距

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12 // 增加间距

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
                                                if (model.status === 1) {
                                                    return "#4CAF50"
                                                } else if (model.status === 2) {
                                                    return "#FF9800"
                                                } else {
                                                    return "#ccc"
                                                }
                                            }
                                            font.pixelSize: 12
                                        }
                                    }

                                    Text {
                                        text: "时间: " + model.timeSlotText
                                        color: "#ccc"
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                        Layout.topMargin: 5 // 增加上边距
                                    }

                                    Text {
                                        text: "医生: " + model.doctorName
                                        color: "#ccc"
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                        Layout.topMargin: 5 // 增加上边距
                                    }
                                }

                                background: Rectangle {
                                    color: {
                                        if (parent.highlighted) {
                                            return "#444"
                                        } else if (parent.hovered) {
                                            return "#3a3a3a"
                                        } else {
                                            return "transparent"
                                        }
                                    }
                                    radius: 5
                                    border.color: "#555"
                                    border.width: 1
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    studentCtrl.fetchMySchedule()
                }
            }

            // 心理测评
            Item {
                Rectangle {
                    anchors.fill: parent
                    color: "#1e1e1e"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            text: "心理测评"
                            font.bold: true
                            font.pixelSize: 24
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                width: Math.min(parent.width * 0.8, 600)
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 20
                                spacing: 20

                                Label {
                                    text: "心理状态自评量表 (SDS)"
                                    font.bold: true
                                    font.pixelSize: 18
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Label {
                                    text: "请根据您最近两周的感受选择最符合的选项："
                                    color: "#ccc"
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }

                                Repeater {
                                    model: ListModel {
                                        ListElement {
                                            question: "1. 我感到沮丧或绝望"
                                            options: "从不/偶尔/经常/总是"
                                        }
                                        ListElement {
                                            question: "2. 我对平常喜欢的事情失去兴趣"
                                            options: "从不/偶尔/经常/总是"
                                        }
                                        ListElement {
                                            question: "3. 我感到疲倦或缺乏活力"
                                            options: "从不/偶尔/经常/总是"
                                        }
                                        ListElement {
                                            question: "4. 我睡眠质量不好"
                                            options: "从不/偶尔/经常/总是"
                                        }
                                        ListElement {
                                            question: "5. 我食欲不振或暴饮暴食"
                                            options: "从不/偶尔/经常/总是"
                                        }
                                    }

                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Label {
                                            text: model.question
                                            color: "white"
                                            font.pixelSize: 16
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                        }

                                        ComboBox {
                                            Layout.fillWidth: true
                                            model: ["从不", "偶尔", "经常", "总是"]
                                            onActivated: {
                                            }
                                        }
                                    }
                                }

                                Button {
                                    text: "提交测评"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    highlighted: true
                                    onClicked: {
                                        appWindow.showToast("测评提交成功，请耐心等待结果分析", false)
                                    }
                                }
                            }
                        }
                    }
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
}
