import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    property var selectedDoctor: null
    property int doctorId: 0

    // 预约相关属性
    property string selectedDate: ""
    property int selectedTimeSlot: -1

    Component.onCompleted: {
        // 从属性中获取医生ID并获取详情
        if (selectedDoctor && selectedDoctor.id) {
            doctorId = selectedDoctor.id
            studentCtrl.fetchDoctorDetail(doctorId)
        } else {
            console.error("无法获取医生ID")
        }
    }

    header: ToolBar {
        Button {
            text: "返回"
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: stackView.pop()
        }
        Label {
            text: "医生详情"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
    }

    StudentController {
        id: studentCtrl

        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                stackView.pop()
            }
        }

        onDoctorDetailReceived: function(doctor) {
            selectedDoctor = doctor
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width 
        bottomPadding: 40 

        ColumnLayout {
            width: Math.min(parent.width * 0.9, 600)
            anchors.horizontalCenter: parent.horizontalCenter 
            spacing: 20
            anchors.top: parent.top
            anchors.topMargin: 20

            // 医生基本信息卡片
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: infoCol.implicitHeight + 40
                color: "#2b2b2b"
                radius: 10
                border.color: "#555"
                border.width: 1

                ColumnLayout {
                    id: infoCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 20
                    spacing: 10

                    Label {
                        text: selectedDoctor && selectedDoctor.realName ? selectedDoctor.realName : "加载中..."
                        font.bold: true
                        font.pixelSize: 24
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: selectedDoctor && selectedDoctor.specializedField ? selectedDoctor.specializedField : "专业领域未知"
                        font.pixelSize: 16
                        color: "#4CAF50"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: selectedDoctor && selectedDoctor.intro ? selectedDoctor.intro : "医生简介暂无"
                        color: "#ccc"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap // 自动换行
                    }
                }
            }

            // 预约时间选择
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: timeCol.implicitHeight + 40
                color: "#2b2b2b"
                radius: 10
                border.color: "#555"
                border.width: 1

                ColumnLayout {
                    id: timeCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 20
                    spacing: 15

                    Label {
                        text: "选择预约时间"
                        font.bold: true
                        font.pixelSize: 18
                        color: "white"
                    }

                    // 日期选择
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: "预约日期:"
                            color: "#ccc"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: dateField
                            placeholderText: "YYYY-MM-DD"
                            Layout.fillWidth: true
                            color: "black"
                            background: Rectangle {
                                color: "#f0f0f0"
                                radius: 4
                            }
                            onTextChanged: {
                                selectedDate = text
                            }
                        }
                    }

                    // 时间段选择
                    Label {
                        text: "时间段:"
                        color: "#ccc"
                        font.pixelSize: 14
                    }

                    GridLayout {
                        id: timeGrid
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 15
                        columnSpacing: 15

                        // 时间段按钮
                        Repeater {
                            model: [
                                "08:30-09:30", 
                                "09:30-10:30", 
                                "10:30-11:30", 
                                "14:30-15:30", 
                                "15:30-16:30", 
                                "16:30-17:30", 
                                "17:30-18:30"
                            ]

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                text: modelData
                                property bool selected: false

                                contentItem: Text {
                                    text: parent.text
                                    color: parent.selected ? "white" : "#ccc"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.selected ? "#4CAF50" : "transparent"
                                    border.color: parent.selected ? "#4CAF50" : "#666"
                                    border.width: 1
                                    radius: 6
                                }

                                onClicked: {
                                    // 清除其他按钮的选择状态
                                    for (var i = 0; i < timeGrid.children.length; i++) {
                                        var child = timeGrid.children[i];
                                        // 检查是否有 selected 属性
                                        if (child.hasOwnProperty("selected")) {
                                            child.selected = false
                                        }
                                    }
                                    // 设置当前按钮为选中状态
                                    selected = true
                                    selectedTimeSlot = index
                                }
                            }
                        }
                    }
                }
            }

            // 预约理由 - 已隐藏
            /*
            Rectangle {
                Layout.preferredWidth: 600
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
                        text: "预约理由"
                        font.bold: true
                        font.pixelSize: 16
                        color: "white"
                    }

                    TextArea {
                        id: reasonField
                        placeholderText: "请简述您想要咨询的问题..."
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.Wrap
                        color: "black"
                        background: Rectangle {
                            color: "#f0f0f0"
                            radius: 4
                        }
                        onTextChanged: {
                            appointmentReason = text
                        }
                    }
                }
            }
            */

            // 确认预约按钮
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
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.down ? "#1976d2" : "#2196F3"
                    radius: 6
                }

                onClicked: {
                    if (!selectedDoctor) {
                        appWindow.showToast("医生信息错误", true)
                        return
                    }

                    if (selectedDate === "") {
                        appWindow.showToast("请选择预约日期", true)
                        return
                    }

                    if (selectedTimeSlot === -1) {
                        appWindow.showToast("请选择时间段", true)
                        return
                    }

                    // 执行预约
                    if (selectedDoctor.id) {
                        studentCtrl.bookAppointment(selectedDoctor.id, selectedDate, selectedTimeSlot)
                    } else {
                        appWindow.showToast("医生信息无效，无法预约", true)
                    }
                }
            }
        }
    }
}