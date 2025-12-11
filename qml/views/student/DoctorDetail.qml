import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root
    title: "预约医生"
    
    // 由 DoctorListTab 传入
    property var selectedDoctor: null
    
    property string selectedDate: ""
    property int selectedTimeSlot: -1

    header: ToolBar {
        Button {
            text: "返回"
            onClicked: stackView.pop()
        }
        Label { text: "医生详情"; anchors.centerIn: parent }
    }

    StudentController {
        id: studentCtrl
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                // 预约成功，返回上一页（列表页）
                stackView.pop() 
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: Math.min(parent.width * 0.9, 600)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 30 
            spacing: 20
            
            // 顶部间距
            Item { height: 20 }

            // 信息展示
            Rectangle {
                Layout.fillWidth: true
                height: 150
                color: "white"
                radius: 10
                border.color: "#ddd"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { 
                        text: selectedDoctor ? selectedDoctor.realName : ""
                        font.bold: true; font.pixelSize: 24 
                    }
                    Text { 
                        text: selectedDoctor ? ("领域: " + selectedDoctor.specializedField) : ""
                        color: "#666"; font.pixelSize: 16
                    }
                    Text { 
                        text: selectedDoctor ? selectedDoctor.intro : ""
                        color: "#888"; width: parent.width; horizontalAlignment: Text.AlignHCenter 
                    }
                }
            }

            // 日期选择
            Label { text: "预约日期 (YYYY-MM-DD):" }
            TextField {
                id: dateInput
                Layout.fillWidth: true
                text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                onTextChanged: selectedDate = text
            }

            // 时间段选择
            Label { text: "选择时间段:" }
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10; columnSpacing: 10

                Repeater {
                    model: ["08:30-09:30", "09:30-10:30", "10:30-11:30", "14:30-15:30", "15:30-16:30", "16:30-17:30", "17:30-18:30"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        highlighted: selectedTimeSlot === index
                        onClicked: selectedTimeSlot = index
                    }
                }
            }

            // 提交按钮
            Button {
                text: "确认预约"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.topMargin: 20
                highlighted: true
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#1976d2" : "#2196F3"
                    radius: 5
                }

                onClicked: {
                    if (selectedTimeSlot === -1) {
                        appWindow.showToast("请选择时间段", true)
                        return
                    }
                    if (dateInput.text.length < 10) {
                        appWindow.showToast("日期格式不正确", true)
                        return
                    }
                    // 发起请求
                    studentCtrl.bookAppointment(selectedDoctor.id, dateInput.text, selectedTimeSlot)
                }
            }
        }
    }
}