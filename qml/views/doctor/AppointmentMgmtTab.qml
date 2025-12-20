import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient
import "../../components"

Item {
    id: tabRoot
    property var controller: null

    Component.onCompleted: {
        if (controller) {
            controller.fetchAppointments()
        }
    }

    Connections {
        target: controller
        function onSurveyContentReceived(data) {
            surveyDetailDialog.surveyTitle = data.title || "问卷详情"
            surveyDetailDialog.questions = data.questions || []
            surveyDetailDialog.answers = data.existingAnswers || []
            surveyDetailDialog.open()
        }
    }

    onVisibleChanged: {
        if (visible && controller) controller.fetchAppointments()
    }

    function refresh() {
        if (controller) controller.fetchAppointments()
    }

    function updateList() {
        if (controller && controller.appointmentModel) {
            var status = filterCombo.currentText === "全部状态" ? "全部" : filterCombo.currentText
            var keyword = searchField.text
            controller.appointmentModel.applyFilter(status, keyword)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        RowLayout {
            Label { text: "预约列表"; font.bold: true; font.pixelSize: 20; color: Theme.textPrimary}
            Item { Layout.fillWidth: true }
            Button { text: "刷新列表"; onClicked: refresh() }
        }

        // 状态筛选器
        ComboBox {
            id: filterCombo
            Layout.fillWidth: true
            model: ["全部状态", "待确认", "已确认", "已完成", "已取消"]
            onActivated: updateList()

            contentItem: Text {
                leftPadding: 10
                text: parent.displayText
                color: Theme.textPrimary
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: Theme.inputBackground
                border.color: Theme.border
                radius: 4
            }
            popup: Popup {
                y: parent.height - 1
                width: parent.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: filterCombo.delegateModel
                    currentIndex: filterCombo.highlightedIndex
                }
                background: Rectangle {
                    color: Theme.surface
                    border.color: Theme.border
                }
            }
            delegate: ItemDelegate {
                width: parent.width
                contentItem: Text {
                    text: modelData
                    color: Theme.textPrimary
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.highlighted ? Theme.surfaceHighlight : "transparent"
                }
                highlighted: filterCombo.highlightedIndex === index
            }
        }

        // 搜索框
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "搜索学生姓名..."
            color: Theme.textPrimary
            placeholderTextColor: Theme.textPlaceholder
            background: Rectangle { color: Theme.inputBackground; border.color: Theme.border }
            
            // 监听输入变化
            onTextChanged: updateList()
            
            // 右侧内边距
            rightPadding: 30
            
            Item {
                width: 30
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: parent.text.length > 0
                z: 2

                Text {
                    text: "✕"
                    anchors.centerIn: parent
                    color: clearMa.containsMouse ? Theme.primary : Theme.textPlaceholder
                    font.bold: true
                }
                
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchField.text = ""
                        searchField.forceActiveFocus()
                    }
                }
            }
        }

        ListView {
            id: apptList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            
            model: controller ? controller.appointmentModel : null

            delegate: Rectangle {
                width: ListView.view.width
                height: 140
                color: Theme.surface
                radius: 8
                border.color: Theme.border
                
                visible: true 

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.studentName || "未知学生"
                            font.bold: true
                            font.pixelSize: 18
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: model.statusText
                            font.bold: true
                            color: getStatusColor(model.status)
                        }
                    }

                    Text { 
                        text: "时间: " + model.appointmentDate + " " + model.timeSlotText 
                        color: Theme.textSecondary
                    }
                    Text { 
                        text: "备注: " + (model.reason || "无")
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                    // 操作按钮区
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Item { Layout.fillWidth: true }

                        Text {
                            visible: model.status === 2 || model.status === 3
                            text: model.status === 2 ? "咨询已归档" : "预约已失效"
                            color: Theme.textSecondary
                        }

                        // 状态 0: 待确认 -> 显示 接受/拒绝
                        Button {
                            text: "拒绝"
                            visible: model.status === 0
                            onClicked: {
                                rejectDialog.targetId = model.id
                                rejectDialog.studentName = model.studentName
                                rejectDialog.open()
                            }
                            background: Rectangle { color: Theme.surface; radius: 4; border.color: Theme.border }
                            contentItem: Text { text: "拒绝"; color: Theme.error; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }

                        Button {
                            text: "接受预约"
                            visible: model.status === 0
                            highlighted: true
                            onClicked: controller.confirmAppointment(model.id)
                        }

                        Button {
                            text: "查看问卷"
                            // 状态 1(已确认) 2(已完成) 时显示
                            visible: model.status === 1 || model.status === 2
                            onClicked: {
                                controller.fetchAppointmentSurvey(model.id)
                            }
                        }

                        // 状态 1: 已确认 -> 显示 完成咨询
                        Button {
                            text: "填写报告并完成"
                            visible: model.status === 1
                            highlighted: true
                            onClicked: {
                                // 跳转到写报告页面
                                stackView.push("ReportWrite.qml", {
                                    "appointmentId": model.id,
                                    "studentName": model.studentName
                                })
                            }
                        }

                        Button {
                            text: "改期"
                            visible: model.status === 0 || model.status === 1
                            onClicked: {
                                modifyDialog.targetId = model.id
                                modifyDialog.selectedDate = model.appointmentDate
                                modifyDialog.selectedSlot = model.timeSlot
                                modifyDialog.open()
                            }
                        }

                        // 删除记录按钮
                        Button {
                            text: "删除记录"
                            visible: model.status === 3
                            
                            contentItem: Text {
                                text: parent.text
                                color: Theme.error
                            }
                            background: Rectangle {
                                color: "transparent"
                                border.color: Theme.error
                                radius: 4
                            }
                            
                            onClicked: {
                                confirmDeleteDialog.targetId = model.id
                                confirmDeleteDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: rejectDialog
        property int targetId: 0
        property string studentName: ""
        title: "拒绝确认"
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No
        Text { text: "确定要拒绝 " + rejectDialog.studentName + " 的预约吗？" }
        onAccepted: controller.rejectAppointment(rejectDialog.targetId)

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: 8
        }

        header: Label {
            text: parent.title
            visible: parent.title.length > 0
            font.bold: true
            font.pixelSize: 18
            padding: 15
            color: Theme.textPrimary
            background: Rectangle { color: "transparent" }
        }

        footer: DialogButtonBox {
            visible: rejectDialog.standardButtons !== 0
            standardButtons: rejectDialog.standardButtons
            background: Rectangle {
                color: "transparent"
                Rectangle { width: parent.width; height: 1; color: Theme.divider; anchors.top: parent.top }
            }
            
            delegate: Button {
                id: dlgBtn
                flat: true
                implicitHeight: 40
                implicitWidth: 80
                contentItem: Text {
                    text: dlgBtn.text
                    font.bold: true
                    font.pixelSize: 14
                    color: (DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.YesRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.OkRole) 
                            ? Theme.primary : Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: dlgBtn.down ? Theme.surfaceHighlight : "transparent"; radius: 4 }
            }
        }
    }

    Dialog {
        id: confirmDeleteDialog
        property int targetId: 0
        title: "确认删除"
        width: 300
        implicitWidth: 300
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No
        
        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: 8
            implicitWidth: 300
        }

        header: Label {
            text: parent.title
            visible: parent.title.length > 0
            font.bold: true
            font.pixelSize: 18
            padding: 15
            color: Theme.textPrimary
            background: Rectangle { color: "transparent" }
        }

        footer: DialogButtonBox {
            visible: confirmDeleteDialog.standardButtons !== 0
            standardButtons: confirmDeleteDialog.standardButtons
            background: Rectangle {
                color: "transparent"
                Rectangle { width: parent.width; height: 1; color: Theme.divider; anchors.top: parent.top }
            }
            
            delegate: Button {
                id: dlgBtn
                flat: true
                implicitHeight: 40
                implicitWidth: 80
                contentItem: Text {
                    text: dlgBtn.text
                    font.bold: true
                    font.pixelSize: 14
                    color: (DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.YesRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.OkRole) 
                            ? Theme.primary : Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: dlgBtn.down ? Theme.surfaceHighlight : "transparent"; radius: 4 }
            }
        }

        contentItem: Text { 
            text: "确定要移除这条已取消的记录吗？"
            color: Theme.textPrimary 
            font.pixelSize: 16
            padding: 20
            wrapMode: Text.Wrap
            width: parent.width
        }
        
        onAccepted: {
            controller.deleteAppointment(confirmDeleteDialog.targetId)
        }
    }

    Dialog {
        id: surveyDetailDialog
        title: "学生问卷填写情况"
        width: 600
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Close
        
        property string surveyTitle: ""
        property var questions: []
        property var answers: []

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: 8
        }

        header: Label {
            text: parent.title
            visible: parent.title.length > 0
            font.bold: true
            font.pixelSize: 18
            padding: 15
            color: Theme.textPrimary
            background: Rectangle { color: "transparent" }
        }

        footer: DialogButtonBox {
            visible: surveyDetailDialog.standardButtons !== 0
            standardButtons: surveyDetailDialog.standardButtons
            background: Rectangle {
                color: "transparent"
                Rectangle { width: parent.width; height: 1; color: Theme.divider; anchors.top: parent.top }
            }
            
            delegate: Button {
                id: dlgBtn
                flat: true
                implicitHeight: 40
                implicitWidth: 80
                contentItem: Text {
                    text: dlgBtn.text
                    font.bold: true
                    font.pixelSize: 14
                    color: (DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.YesRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.OkRole) 
                            ? Theme.primary : Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: dlgBtn.down ? Theme.surfaceHighlight : "transparent"; radius: 4 }
            }
        }

        contentItem: ColumnLayout {
            Label {
                text: surveyDetailDialog.surveyTitle
                font.bold: true; font.pixelSize: 18
                Layout.alignment: Qt.AlignHCenter
                color: Theme.textPrimary
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Repeater {
                        model: surveyDetailDialog.questions
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            // 题目
                            Text {
                                text: (index + 1) + ". " + modelData.question
                                font.bold: true
                                color: Theme.textPrimary
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            
                            // 学生的回答
                            Text {
                                property string ans: (surveyDetailDialog.answers.length > index) 
                                                     ? surveyDetailDialog.answers[index] 
                                                     : "未作答"
                                text: "回答: " + ans
                                color: Theme.primary
                                font.pixelSize: 14
                                Layout.leftMargin: 20
                            }
                        }
                    }
                    
                    Label {
                        visible: surveyDetailDialog.questions.length === 0
                        text: "该学生暂未填写问卷"
                        color: Theme.textPlaceholder
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    Dialog {
        id: modifyDialog
        title: "修改预约时间"
        width: 450
        implicitWidth: 450
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        property int targetId: 0
        property string selectedDate: ""
        property int selectedSlot: -1

        // 内部日历实例
        CCalendar {
            id: docCalendar
            onDateSelected: function(str) {
                modifyDialog.selectedDate = str
                dateField.text = str
            }
        }

        // 每次打开弹窗时重置状态
        onOpened: {
            slotGroup.checkState = Qt.Unchecked 
            modifyDialog.selectedSlot = -1
        }

        background: Rectangle {
            color: Theme.surface
            radius: 8
            border.color: Theme.border
            implicitWidth: 450
        }

        header: Label {
            text: parent.title
            visible: parent.title.length > 0
            font.bold: true
            font.pixelSize: 18
            padding: 15
            color: Theme.textPrimary
            background: Rectangle { color: "transparent" }
        }

        footer: DialogButtonBox {
            visible: modifyDialog.standardButtons !== 0
            standardButtons: modifyDialog.standardButtons
            background: Rectangle {
                color: "transparent"
                Rectangle { width: parent.width; height: 1; color: Theme.divider; anchors.top: parent.top }
            }
            
            delegate: Button {
                id: dlgBtn
                flat: true
                implicitHeight: 40
                implicitWidth: 80
                contentItem: Text {
                    text: dlgBtn.text
                    font.bold: true
                    font.pixelSize: 14
                    color: (DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.YesRole || 
                            DialogButtonBox.buttonRole === DialogButtonBox.OkRole) 
                            ? Theme.primary : Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: dlgBtn.down ? Theme.surfaceHighlight : "transparent"; radius: 4 }
            }
        }

        contentItem: ColumnLayout {
            width: parent.width 
            spacing: 20
            Label { 
                text: "请选择新的日期和时间"
                color: Theme.textSecondary
                font.bold: true
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }

            // 日期输入
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                Label { text: "日期 (YYYY-MM-DD):"; color: Theme.textSecondary }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    TextField {
                        id: dateField
                        Layout.fillWidth: true
                        placeholderText: "例如: 2026-05-20"
                        placeholderTextColor: Theme.textPlaceholder
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd") // 默认今天
                        color: Theme.textPrimary
                        background: Rectangle {
                            color: Theme.inputBackground
                            border.color: Theme.border
                            radius: 4
                        }
                        // 实时绑定到 property
                        onTextEdited: modifyDialog.selectedDate = text
                        Component.onCompleted: modifyDialog.selectedDate = text
                    }
                    
                    Button {
                        text: "H"
                        onClicked: docCalendar.open()
                    }
                }
            }

            // 时间段选择
            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                Label { text: "时间段:"; color: Theme.textSecondary }

                // ButtonGroup 管理互斥状态
                ButtonGroup {
                    id: slotGroup
                    // 当组内选中的按钮改变时，更新 selectedSlot
                    onCheckedButtonChanged: {
                        if (checkedButton) {
                            modifyDialog.selectedSlot = checkedButton.slotIndex
                        } else {
                            modifyDialog.selectedSlot = -1
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Repeater {
                        model: tabRoot.controller ? tabRoot.controller.timeSlots : []
                        
                        delegate: Button {
                            text: modelData
                            checkable: true
                            // 绑定到 ButtonGroup
                            ButtonGroup.group: slotGroup
                            
                            // 自定义属性存储索引
                            property int slotIndex: index
                            
                            // 选中时变色
                            highlighted: checked
                            
                            // 确保打开弹窗时状态正确 (如果 selectedSlot 为 -1，则不选中)
                            checked: modifyDialog.selectedSlot === index
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? Theme.textInverted : Theme.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.checked ? Theme.primary : "transparent"
                                border.color: parent.checked ? Theme.primary : Theme.border
                                radius: 4
                            }
                        }
                    }
                }
            }

            Label {
                text: "提交后将发送请求给学生，需学生确认后生效。"
                color: Theme.warning
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
        
        onAccepted: {
            // 校验逻辑
            if (targetId === 0) {
                appWindow.showToast("未选中预约记录", true)
                return
            }
            if (selectedDate.length < 8) {
                appWindow.showToast("日期格式不正确", true)
                return
            }
            if (selectedSlot === -1) {
                appWindow.showToast("请选择一个时间段", true)
                return
            }

            // 发起请求
            if (controller) {
                controller.requestModification(targetId, selectedDate, selectedSlot)
            }
        }
    }

    function getStatusColor(s) {
        if(s===0) return Theme.warning; 
        if(s===1) return Theme.success; 
        if(s===2) return Theme.primary; 
        return Theme.textPlaceholder;
    }
}