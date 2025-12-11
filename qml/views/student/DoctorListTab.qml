import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: tabRoot
    property var controller: null

    ListModel { id: doctorListModel }

    Component.onCompleted: {
        if (controller) {
            controller.fetchDoctorList()
        }
    }

    Connections {
        target: controller
        function onDoctorListReceived(doctors) {
            doctorListModel.clear()
            for (var i = 0; i < doctors.length; i++) {
                doctorListModel.append(doctors[i])
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            text: "心理咨询师列表"
            font.bold: true
            font.pixelSize: 22
            color: "white" 
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: doctorListModel
            spacing: 10

            delegate: Rectangle {
                width: ListView.view.width
                height: 100
                color: "white"
                radius: 8
                border.color: "#ddd"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    Rectangle {
                        width: 50; height: 50
                        radius: 25
                        color: "#ccc"
                        Text { 
                            text: model.realName ? model.realName.charAt(0) : "?" 
                            anchors.centerIn: parent
                            color: "black"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.realName || "未知姓名"
                            font.bold: true
                            font.pixelSize: 18 
                            color: "#333"
                        }
                        Text { 
                            text: "擅长: " + (model.specializedField || "通用心理咨询")
                            color: "#666" 
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        text: "查看详情"
                        highlighted: true
                        onClicked: stackView.push("DoctorDetail.qml", { "selectedDoctor": model })
                    }
                }
            }
        }
    }
}