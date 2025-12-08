import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    property int appointmentId: 0
    property string patientName: ""

    DoctorController {
        id: doctorCtrl

        onOperationResult: function(success, msg) {

            if (!success) {
                appWindow.showToast("操作失败: " + msg, true)
                return
            }

            stackView.pop()
        }

        onReportSubmitted: function() {
            appWindow.showToast("报告提交成功，正在完成咨询...", false)

            doctorCtrl.completeConsultation(appointmentId)
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
            text: "撰写咨询报告"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
    }



    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 20

            ColumnLayout {
                width: Math.min(parent.width * 0.9, 800)
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                anchors.top: parent.top
                anchors.topMargin: 20

                // 报告标题
                Label {
                    text: "心理咨询报告"
                    font.bold: true
                    font.pixelSize: 24
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }

                // 基本信息卡片
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Label {
                                text: "预约学生姓名:"
                                color: "#ccc"
                                font.pixelSize: 14
                            }

                            Label {
                                text: patientName
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Label {
                                text: "报告日期:"
                                color: "#ccc"
                                font.pixelSize: 14
                            }

                            Label {
                                text: new Date().toLocaleDateString()
                                color: "white"
                                font.pixelSize: 16
                            }
                        }
                    }
                }

                // 主要问题描述
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "主要问题描述"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        TextArea {
                            id: problemDescription
                            placeholderText: "详细描述预约学生的主要心理问题、症状表现、持续时间等..."
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            color: "black"
                            background: Rectangle {
                                color: "#f0f0f0"
                                radius: 4
                            }
                        }
                    }
                }

                // 咨询过程
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "咨询过程"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        TextArea {
                            id: consultationProcess
                            placeholderText: "记录咨询过程中使用的方法、技术，预约学生的反应和表现等..."
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            color: "black"
                            background: Rectangle {
                                color: "#f0f0f0"
                                radius: 4
                            }
                        }
                    }
                }

                // 分析评估
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "分析评估"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        TextArea {
                            id: analysis
                            placeholderText: "对预约学生问题的专业分析、评估和建议..."
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            color: "black"
                            background: Rectangle {
                                color: "#f0f0f0"
                                radius: 4
                            }
                        }
                    }
                }

                // 治疗建议
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "治疗建议"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        TextArea {
                            id: treatmentPlan
                            placeholderText: "提出具体的治疗建议、下次咨询安排等..."
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            color: "black"
                            background: Rectangle {
                                color: "#f0f0f0"
                                radius: 4
                            }
                        }
                    }
                }

                // 结果标签
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "问题标签"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        Flow {
                            id: tagFlow
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            Repeater {
                                model: ListModel {
                                    ListElement { tag: "学业压力"; color: "#FFA726" }
                                    ListElement { tag: "人际关系"; color: "#42A5F5" }
                                    ListElement { tag: "情感问题"; color: "#EF5350" }
                                    ListElement { tag: "焦虑"; color: "#FF7043" }
                                    ListElement { tag: "抑郁"; color: "#AB47BC" }
                                    ListElement { tag: "睡眠问题"; color: "#26A69A" }
                                    ListElement { tag: "家庭问题"; color: "#66BB6A" }
                                    ListElement { tag: "就业压力"; color: "#FFCA28" }
                                    ListElement { tag: "社交恐惧"; color: "#8D6E63" }
                                    ListElement { tag: "自我认知"; color: "#78909C" }
                                }

                                delegate: Button {
                                    property bool selected: false
                                    text: model.tag
                                    Layout.preferredHeight: 35
                                    Layout.preferredWidth: text.implicitWidth + 20

                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.selected ? "white" : model.color
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: parent.selected ? model.color : "transparent"
                                        border.color: model.color
                                        border.width: 2
                                        radius: 17
                                    }

                                    onClicked: {
                                        selected = !selected
                                    }
                                }
                            }
                        }

                        Label {
                            text: "已选择标签: " + getSelectedTags()
                            color: "#4CAF50"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }
                }

                // 保密等级
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: "#2b2b2b"
                    radius: 10
                    border.color: "#555"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Label {
                            text: "保密等级"
                            font.bold: true
                            font.pixelSize: 18
                            color: "white"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            RadioButton {
                                id: confidential
                                text: "保密"
                                checked: true
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.checked ? "#4CAF50" : "#ccc"
                                    font.pixelSize: 14
                                }
                            }

                            RadioButton {
                                id: restricted
                                text: "限制性保密"
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.checked ? "#FFA726" : "#ccc"
                                    font.pixelSize: 14
                                }
                            }

                            RadioButton {
                                id: publicy
                                text: "公开"
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.checked ? "#F44336" : "#ccc"
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }

                // 操作按钮
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    spacing: 20

                    Button {
                        text: "保存草稿"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: parent.down ? "#666" : "#888"
                            radius: 4
                        }

                        onClicked: {
                            saveReport(false)
                        }
                    }

                    Button {
                        text: "提交报告"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        highlighted: true

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: parent.down ? "#1976d2" : "#2196F3"
                            radius: 4
                        }

                        onClicked: {
                            if (validateReport()) {
                                saveReport(true)
                            }
                        }
                    }
                }

                // 提示信息
                Label {
                    text: "注：咨询报告涉及预约学生隐私，请妥善保管。提交后将自动标记咨询为完成状态。"
                    color: "#FFA726"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    function getSelectedTags() {
        var selected = []
        var flow = tagFlow  // 使用ID直接访问Flow组件
        if (flow && flow.children) {
            for (var i = 0; i < flow.children.length; i++) {
                if (flow.children[i].selected) {
                    selected.push(flow.children[i].text)
                }
            }
        }
        return selected.join(", ")
    }

    function validateReport() {
        if (problemDescription.text.trim() === "") {
            appWindow.showToast("请填写主要问题描述", true)
            return false
        }

        if (consultationProcess.text.trim() === "") {
            appWindow.showToast("请填写咨询过程", true)
            return false
        }

        if (analysis.text.trim() === "") {
            appWindow.showToast("请填写分析评估", true)
            return false
        }

        if (treatmentPlan.text.trim() === "") {
            appWindow.showToast("请填写治疗建议", true)
            return false
        }

        return true
    }

    function saveReport(isSubmit) {
        var reportData = {
            appointmentId: appointmentId,
            problemDescription: problemDescription.text,
            consultationProcess: consultationProcess.text,
            analysis: analysis.text,
            treatmentPlan: treatmentPlan.text,
            tags: getSelectedTags(),
            confidentialityLevel: confidential.checked ? "confidential" : (restricted.checked ? "restricted" : "public")
        }

        if (isSubmit) {
            doctorCtrl.submitReport(reportData)
        } else {
            appWindow.showToast("草稿已保存", false)
        }
    }
}

