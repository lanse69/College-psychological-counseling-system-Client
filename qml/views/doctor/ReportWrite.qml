import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root
    title: "撰写咨询报告"
    
    // 接收参数
    property int appointmentId: 0
    property string studentName: ""

    header: ToolBar {
        Button {
            text: "返回"
            onClicked: stackView.pop()
        }
        Label { text: "咨询结案报告"; anchors.centerIn: parent }
    }

    DoctorController {
        id: doctorCtrl
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
        }
        onReportSubmitted: function() {
            // 报告提交成功后，标记预约为完成
            doctorCtrl.completeConsultation(appointmentId)
            stackView.pop() // 返回列表
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: Math.min(parent.width * 0.9, 700)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 15

            Label { 
                text: "正在为预约学生: " + studentName + " 撰写报告"
                font.bold: true
                font.pixelSize: 16
                color: Theme.textPrimary
            }

            Label { text: "1. 主要问题描述" }
            TextArea {
                id: problemArea
                Layout.fillWidth: true; Layout.preferredHeight: 100
                placeholderText: "描述预约学生的主要诉求、症状表现..."
                color: Theme.textSecondary
                background: Rectangle { border.color: Theme.border; radius: 4 }
                activeFocusOnTab: true
                KeyNavigation.tab: processArea
            }

            Label { text: "2. 咨询过程摘要" }
            TextArea {
                id: processArea
                Layout.fillWidth: true; Layout.preferredHeight: 120
                placeholderText: "使用了什么疗法，互动情况如何..."
                color: Theme.textSecondary
                background: Rectangle { border.color: Theme.border; radius: 4 }
                activeFocusOnTab: true
                KeyNavigation.tab: suggestArea
                KeyNavigation.backtab: problemArea
            }

            Label { text: "3. 评估与建议" }
            TextArea {
                id: suggestArea
                Layout.fillWidth: true; Layout.preferredHeight: 100
                placeholderText: "专业评估结论及后续建议..."
                color: Theme.textSecondary
                background: Rectangle { border.color: Theme.border; radius: 4 }
                activeFocusOnTab: true
                KeyNavigation.tab: tagsField
                KeyNavigation.backtab: processArea
            }
            
            Label { text: "4. 结果标签 (用于统计, 逗号分隔)" }
            TextField {
                id: tagsField
                Layout.fillWidth: true
                placeholderText: "例如: 学业压力, 人际关系, 轻度焦虑"
                onAccepted: submitBtn.clicked()
                Keys.onUpPressed: suggestArea.forceActiveFocus()
                Keys.onDownPressed: submitBtn.forceActiveFocus()
            }

            Button {
                text: "提交报告并归档"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.topMargin: 20
                highlighted: true

                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                
                onClicked: {
                    if (problemArea.text === "") {
                        appWindow.showToast("请填写主要问题", true); return;
                    }
                    
                    var reportData = {
                        "appointmentId": appointmentId,
                        "problemDescription": problemArea.text,
                        "consultationProcess": processArea.text,
                        "analysis": suggestArea.text,
                        "tags": tagsField.text
                    }
                    
                    doctorCtrl.submitReport(reportData)
                }
            }
        }
    }
}