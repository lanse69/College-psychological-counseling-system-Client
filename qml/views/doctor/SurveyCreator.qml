import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root
    title: "问卷编辑器"

    background: Rectangle { color: Theme.background }

    // 顶部工具栏
    header: ToolBar {
        background: Rectangle { 
            color: Theme.surface 
            Rectangle {
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
                color: Theme.divider
            }
        }

        topPadding: 10 
        bottomPadding: 10

        Button {
            text: "返回"
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: stackView.pop()
            
            contentItem: Text {
                text: parent.text
                color: Theme.textPrimary
                font.pixelSize: 14
            }
            background: Rectangle { color: "transparent" }
        }

        Label {
            text: "编辑我的问卷"
            font.pixelSize: 18
            font.bold: true
            color: Theme.textPrimary
            anchors.centerIn: parent
        }

        Button {
            text: "保存并发布"
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            highlighted: true
            
            contentItem: Text {
                text: parent.text
                color: Theme.textInverted
                font.bold: true
            }
            background: Rectangle {
                color: parent.down ? Theme.primaryHover : Theme.primary
                radius: 4
            }
            
            onClicked: saveSurvey()
        }
    }

    // 控制器
    DoctorController {
        id: doctorCtrl
        
        // 监听操作结果
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if (success) {
                stackView.pop() // 保存成功后返回上一页
            }
        }

        // 监听获取到的现有问卷
        onMySurveyReceived: function(data) {
            if (data && data.title) {
                surveyTitle.text = data.title
                questionsModel.clear()
                
                var qList = data.questions
                if (qList) {
                    for (var i = 0; i < qList.length; i++) {
                        var item = qList[i]
                        
                        // 将 options 数组 ["A", "B"] 转为字符串 "A\nB"
                        var optsStr = ""
                        if (Array.isArray(item.options)) {
                            optsStr = item.options.join("\n")
                        } else if (item.options) {
                            // 兼容性处理
                            optsStr = "从不\n偶尔\n经常\n总是"
                        }
                        
                        questionsModel.append({
                            "question": item.question,
                            "type": item.type || "single",
                            "optionsStr": optsStr
                        })
                    }
                }
            } else {
                // 如果是新医生，没有问卷，初始化一个空的
                surveyTitle.text = ""
                questionsModel.clear()
            }
        }
    }

    // 页面加载时拉取现有问卷
    Component.onCompleted: {
        doctorCtrl.fetchMySurvey()
    }

    ListModel { id: questionsModel }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // 问卷标题输入
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            
            Label { 
                text: "问卷标题" 
                color: Theme.textSecondary 
                font.pixelSize: 14 
            }
            
            TextField {
                id: surveyTitle
                placeholderText: "例如: 抑郁自评量表 (SDS)"
                Layout.fillWidth: true
                font.pixelSize: 16
                
                color: Theme.textPrimary
                placeholderTextColor: Theme.textPlaceholder
                
                background: Rectangle { 
                    color: Theme.inputBackground 
                    radius: 4 
                    border.color: Theme.border
                    border.width: parent.activeFocus ? 2 : 1
                }
            }
        }

        Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

        // 问题列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: qList
                model: questionsModel
                width: parent.width
                spacing: 20
                bottomMargin: 20

                delegate: Rectangle {
                    width: ListView.view.width - 20 // 留出滚动条空间
                    height: col.implicitHeight + 30
                    
                    color: Theme.surface
                    radius: 8
                    border.color: Theme.border
                    border.width: 1
                    
                    x: 10

                    ColumnLayout {
                        id: col
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10

                        // 题目头部
                        RowLayout {
                            Layout.fillWidth: true
                            Label { 
                                text: "问题 " + (index + 1)
                                font.bold: true
                                color: Theme.primary
                                font.pixelSize: 16
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "删除"
                                flat: true
                                Layout.preferredHeight: 30
                                contentItem: Text { 
                                    text: "删除"
                                    color: Theme.error 
                                    font.pixelSize: 14 
                                }
                                background: Rectangle { color: "transparent" }
                                onClicked: questionsModel.remove(index)
                            }
                        }

                        // 题目输入框
                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "请输入题目内容..."
                            text: model.question
                            
                            color: Theme.textPrimary
                            placeholderTextColor: Theme.textPlaceholder
                            background: Rectangle { 
                                color: Theme.inputBackground 
                                radius: 4 
                                border.color: Theme.border
                            }
                            
                            // 实时回写 Model
                            onTextChanged: model.question = text 
                        }

                        Label { 
                            text: "选项设置 (每行一个选项):" 
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        // 选项编辑框
                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            placeholderText: "选项1\n选项2\n选项3\n选项4"
                            color: Theme.textPrimary
                            placeholderTextColor: Theme.textPlaceholder
                            background: Rectangle { 
                                color: Theme.inputBackground 
                                radius: 4 
                                border.color: Theme.border
                            }
                            
                            // 绑定 Model 中的字符串
                            text: model.optionsStr
                            
                            // 实时回写 Model
                            onTextChanged: model.optionsStr = text
                        }
                    }
                }
            }
        }

        // 底部添加按钮
        Button {
            text: "+ 添加新问题"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            
            contentItem: Text {
                text: parent.text
                color: Theme.textInverted
                font.bold: true
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                color: parent.down ? Theme.primaryHover : Theme.primary
                radius: 4
            }

            onClicked: {
                questionsModel.append({
                    "question": "",
                    "type": "single",
                    "optionsStr": "从不\n偶尔\n经常\n总是" // 默认选项
                })
                // 滚动到底部
                qList.positionViewAtEnd()
            }
        }
    }

    // 保存
    function saveSurvey() {
        // 基础校验
        if (surveyTitle.text.trim() === "") {
            appWindow.showToast("请输入问卷标题", true)
            return
        }

        if (questionsModel.count === 0) {
            appWindow.showToast("请至少添加一个问题", true)
            return
        }

        var finalQuestions = []
        var hasError = false

        // 遍历 Model 组装数据
        for (var i = 0; i < questionsModel.count; i++) {
            var item = questionsModel.get(i)
            
            // 校验题目
            if (item.question.trim() === "") {
                appWindow.showToast("第 " + (i+1) + " 个问题内容不能为空", true)
                hasError = true
                break
            }

            // 将字符串分割回数组
            var optsList = item.optionsStr.split("\n").filter(function(line) {
                return line.trim() !== ""
            })

            // 校验选项
            if (optsList.length < 2) {
                appWindow.showToast("第 " + (i+1) + " 个问题至少需要2个选项", true)
                hasError = true
                break
            }

            // 构建对象
            finalQuestions.push({
                "question": item.question,
                "type": "single", // 目前仅支持单选
                "options": optsList
            })
        }

        if (hasError) return

        // 发送给后端
        doctorCtrl.saveMySurvey(surveyTitle.text, finalQuestions)
    }
}