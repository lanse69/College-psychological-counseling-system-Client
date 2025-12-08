import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    property var currentSurvey: null
    property var currentAppointment: null

    header: ToolBar {
        Button {
            text: "返回"
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: stackView.pop()
        }
        Label {
            text: "心理测评"
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
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 测评标题
            Label {
                text: currentSurvey ? currentSurvey.title : "心理测评"
                font.bold: true
                font.pixelSize: 24
                color: "white"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

            // 说明文字
            Label {
                text: "请根据您的真实感受选择最符合的选项"
                color: "#ccc"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 20

                ColumnLayout {
                    width: Math.min(parent.width * 0.9, 700)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    // 动态生成问题
                    Repeater {
                        id: questionRepeater
                        model: ListModel {
                            ListElement {
                                question: "1. 我感到沮丧或绝望"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "2. 我对平常喜欢的事情失去兴趣"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "3. 我感到疲倦或缺乏活力"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "4. 我睡眠质量不好"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "5. 我食欲不振或暴饮暴食"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "6. 我感到焦虑或紧张"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "7. 我难以集中注意力"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "8. 我对未来感到悲观"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "9. 我感到孤独或被孤立"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                            ListElement {
                                question: "10. 我有自我伤害的想法"
                                type: "single"
                                options: ["从不", "偶尔", "经常", "总是"]
                            }
                        }

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: questionColumn.implicitHeight + 40
                            color: "#2b2b2b"
                            radius: 8
                            border.color: "#555"
                            border.width: 1

                            ColumnLayout {
                                id: questionColumn
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Label {
                                    text: model.question
                                    color: "white"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }

                                // 单选题选项
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Repeater {
                                        model: model.options

                                        delegate: RadioButton {
                                            Layout.fillWidth: true
                                            text: modelData

                                            contentItem: Text {
                                                text: parent.text
                                                color: parent.checked ? "#4CAF50" : "#ccc"
                                                font.pixelSize: 14
                                                wrapMode: Text.Wrap
                                            }

                                            indicator: Rectangle {
                                                implicitWidth: 20
                                                implicitHeight: 20
                                                radius: 10
                                                border.color: parent.checked ? "#4CAF50" : "#666"
                                                border.width: 2
                                                color: "transparent"

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 10
                                                    height: 10
                                                    radius: 5
                                                    color: "#4CAF50"
                                                    visible: parent.parent.checked
                                                }
                                            }

                                            background: Rectangle {
                                                color: "transparent"
                                            }

                                            onCheckedChanged: {
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 提交按钮
                    Button {
                        text: "提交测评"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        Layout.topMargin: 20
                        highlighted: true

                        onClicked: {
                            // 检查是否所有问题都已回答
                            var allAnswered = true
                            var answers = []

                            for (var i = 0; i < questionRepeater.itemAt(0).children.length; i++) {
                                var item = questionRepeater.itemAt(0).children[i]
                                if (item && item.children && item.children.length > 1) {
                                    var questionGroup = item.children[1] // 选项组
                                    var answered = false
                                    var answerText = ""

                                    for (var j = 0; j < questionGroup.children.length; j++) {
                                        var radioButton = questionGroup.children[j]
                                        if (radioButton && radioButton.checked) {
                                            answered = true
                                            answerText = radioButton.text
                                            break
                                        }
                                    }

                                    if (!answered) {
                                        allAnswered = false
                                        break
                                    } else {
                                        answers.push(answerText)
                                    }
                                }
                            }

                            if (!allAnswered) {
                                appWindow.showToast("请回答所有问题后再提交", true)
                                return
                            }

                            appWindow.showToast("测评提交成功，请耐心等待结果分析", false)
                            
                            // 如果有关联的预约，提交到服务器
                            if (currentAppointment) {
                                studentCtrl.submitSurvey(currentAppointment.id, answers)
                            }
                        }
                    }

                    // 提示信息
                    Label {
                        text: "注：如果您有严重的心理困扰或自我伤害的想法，请及时寻求专业帮助"
                        color: "#FFA726"
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        Layout.topMargin: 20
                    }
                }
            }
        }
    }
}
