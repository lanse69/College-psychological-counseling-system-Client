import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#2b2b2b"

    property ListModel patientModel: null
    property string title: "预约学生列表"

    property bool showToggleButton: false 
    property bool isDetailsVisible: false

    signal patientSelected(var patientData, int index)
    signal refreshClicked()
    signal toggleDetailsClicked()
    signal searchTextChanged(string text)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题栏
        Label {
            text: root.title
            color: "white"
            font.bold: true
            font.pixelSize: 18
            padding: 15
            Layout.fillWidth: true
            background: Rectangle { color: "#333" }
        }

        // 操作栏 (搜索 + 按钮)
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            TextField {
                id: searchInput
                placeholderText: "搜索预约学生..."
                Layout.fillWidth: true
                color: "black"
                background: Rectangle {
                    color: "#f0f0f0"
                    radius: 4
                }
                onTextChanged: root.searchTextChanged(text)
            }

            Button {
                text: "刷新"
                Layout.preferredWidth: 60
                highlighted: true
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
                }
                onClicked: root.refreshClicked()
            }

            Button {
                visible: root.showToggleButton
                text: root.isDetailsVisible ? "隐藏详情" : "显示详情"
                Layout.preferredWidth: 80
                highlighted: true
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#666" : "#888"
                    radius: 4
                }
                onClicked: root.toggleDetailsClicked()
            }
        }

        // 列表区域
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            clip: true

            ScrollBar.vertical: ScrollBar {}

            model: root.patientModel

            delegate: ItemDelegate {
                width: ListView.view.width
                height: 80
                visible: model.hidden === undefined || !model.hidden

                contentItem: ColumnLayout {
                    spacing: 5
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: model.patientName
                            color: "white"
                            font.bold: true
                            font.pixelSize: 16
                            Layout.fillWidth: true
                        }
                        Text {
                            text: model.status
                            color: {
                                if (model.status === "活跃") return "#4CAF50"
                                else if (model.status === "治疗中") return "#FFA726"
                                else return "#2196F3"
                            }
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: "预约: " + model.totalAppointments
                            color: "#ccc"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "完成: " + model.completedAppointments
                            color: "#4CAF50"
                            font.pixelSize: 12
                        }
                    }
                    Text {
                        text: "最后: " + model.lastAppointment
                        color: "#aaa"
                        font.pixelSize: 11
                        Layout.fillWidth: true
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
                }

                highlighted: ListView.isCurrentItem
                onClicked: {
                    listView.currentIndex = index
                    root.patientSelected(model, index)
                }
            }
        }
    }
}