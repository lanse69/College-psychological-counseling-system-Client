import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root
    title: "填写问卷"

    property var currentAppointment: null

    property var surveyDataList: []
    property var loadedAnswers: []

    // 顶部导航栏
    header: ToolBar {
        height: 60
        topPadding: 10
        background: Rectangle { color: Theme.background }
        
        Button {
            text: "返回"
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            
            contentItem: Text {
                text: parent.text
                color: Theme.textPrimary
            }
            background: Rectangle { color: "transparent" }
            
            onClicked: stackView.pop()
        }

        Label {
            text: "心理测评"
            font.pixelSize: 18
            color: Theme.textPrimary
            anchors.centerIn: parent
        }
    }

    // 业务控制器
    StudentController {
        id: studentCtrl

        // 监听操作结果 (提交成功/失败)
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success) // 弹窗提示
            if (success) {
                stackView.pop() // 提交成功后返回上一页
            }
        }

        // 监听问卷内容数据
        onSurveyContentReceived: function(data) {
            if (data && data.questions) {
                surveyTitleLabel.text = data.title || "心理问卷"
                root.surveyDataList = data.questions
                // 处理历史答案
                if (data.existingAnswers) {
                    var tmp = []
                    for(var i=0; i<data.existingAnswers.length; i++) {
                        tmp.push(data.existingAnswers[i])
                    }
                    root.loadedAnswers = tmp
                } else {
                    root.loadedAnswers = []
                }
            } else {
                surveyTitleLabel.text = "暂无问卷数据"
            }
        }
    }

    // 页面加载时自动拉取问卷
    Component.onCompleted: {
        if (currentAppointment && currentAppointment.id) {
            studentCtrl.fetchSurveyContent(currentAppointment.id)
        }
    }

    // 主体内容区
    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 标题
            Label {
                id: surveyTitleLabel
                text: "加载中..."
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 22
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                Layout.bottomMargin: 20
            }

            // 滚动区域
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: parent.width

                ColumnLayout {
                    width: Math.min(parent.width * 0.9, 700)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    
                    Repeater {
                        id: questionRepeater
                        model: root.surveyDataList

                        delegate: Rectangle {
                            id: delegateRoot
                            Layout.fillWidth: true
                            Layout.preferredHeight: itemCol.implicitHeight + 40
                            
                            color: Theme.surface
                            radius: 8
                            border.color: Theme.border

                            // 存储当前题目的答案
                            property string selectedAnswer: ""
                            // 记录当前题目的索引
                            property int questionIndex: index

                            ColumnLayout {
                                id: itemCol
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                // 题目文本
                                Text {
                                    text: (index + 1) + ". " + ((modelData && modelData.question) ? modelData.question : "Loading...")
                                    color: Theme.textPrimary
                                    font.bold: true
                                    font.pixelSize: 16
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                // 选项
                                ColumnLayout {
                                    spacing: 5
                                    Repeater {
                                        model: (modelData && modelData.options) ? modelData.options : []
                                        
                                        delegate: RadioButton {
                                            id: rbtn
                                            text: modelData
                                            
                                            spacing: 10

                                            contentItem: Text {
                                                text: rbtn.text
                                                color: rbtn.checked ? Theme.primary : Theme.textPrimary
                                                font.pixelSize: 14
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: rbtn.indicator ? (rbtn.indicator.width + rbtn.spacing) : 30
                                                wrapMode: Text.Wrap
                                            }

                                            // 如果历史答案存在，且匹配当前选项文本，则默认选中
                                            checked: {
                                                if (root.loadedAnswers && root.loadedAnswers.length > delegateRoot.questionIndex) {
                                                    return root.loadedAnswers[delegateRoot.questionIndex] === modelData
                                                }
                                                return false
                                            }
                                            
                                            // 选中时更新父级 Rectangle 的属性
                                            onCheckedChanged: {
                                                if (checked) {
                                                    delegateRoot.selectedAnswer = modelData
                                                }
                                            }

                                            Component.onCompleted: {
                                                if (checked) delegateRoot.selectedAnswer = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Button {
                        text: "提交问卷"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        Layout.topMargin: 20
                        Layout.bottomMargin: 50
                        highlighted: true
                        onClicked: submitSurvey()
                    }
                }
            }
        }
    }

    // 提交逻辑函数
    function submitSurvey() {
        var answers = []
        for(var i=0; i<questionRepeater.count; i++) {
            var item = questionRepeater.itemAt(i)
            if(item.selectedAnswer === "") {
                appWindow.showToast("第 " + (i+1) + " 题未完成", true)
                return
            }
            answers.push(item.selectedAnswer)
        }
        studentCtrl.submitSurvey(currentAppointment.id, answers)
    }
}