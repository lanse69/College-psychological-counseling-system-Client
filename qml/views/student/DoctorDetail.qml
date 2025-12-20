import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient
import "../../components"

Page {
    id: root
    title: "预约医生"
    
    background: Rectangle { color: Theme.background }

    property var selectedDoctor: null
    property string selectedDate: ""
    property int selectedTimeSlot: -1
    // 排班表
    property var scheduleCache: ({}) 
    // 当前选中日期的掩码 (0=空闲, 1=忙)
    property int currentDayMask: 0

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
        // 接收排班数据
        onScheduleMaskReceived: function(map) {
            scheduleCache = map
            updateCurrentMask()
        }
    }

    function updateCurrentMask() {
        if (!selectedDate || selectedDate.length < 10) {
            currentDayMask = 0
            return
        }
        
        // 尝试从缓存取值
        if (scheduleCache && scheduleCache.hasOwnProperty(selectedDate)) {
            currentDayMask = scheduleCache[selectedDate]
        } else {
            currentDayMask = 0
        }
    }

    // 当日期改变时，去拉取该月的排班
    onSelectedDateChanged: {
        updateCurrentMask()
        
        var dateObj = new Date(selectedDate)
        if (!isNaN(dateObj.getTime())) {
            // JS 月份是 0-11，需要切换为 1-12
            studentCtrl.fetchDoctorSchedule(selectedDoctor.id, dateObj.getFullYear(), dateObj.getMonth() + 1)
        }
        // 重置选中的时间段
        selectedTimeSlot = -1
    }

    function isSlotExpired(dateStr, slotIndex) {
        var d = new Date(dateStr);
        var now = new Date();
        
        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        var target = new Date(d.getFullYear(), d.getMonth(), d.getDate());

        if (target < today) return true;
        if (target > today) return false;

        // 如果是今天，比较小时
        var startHours = [8, 9, 10, 14, 15, 16, 17];
        var h = startHours[slotIndex];
        // 构造今天该 slot 的时间
        var slotTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, 30);
        
        return now >= slotTime;
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
                color: Theme.surface
                border.color: Theme.border
                radius: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { 
                        text: selectedDoctor ? selectedDoctor.realName : ""
                        color: Theme.textPrimary
                        font.bold: true; font.pixelSize: 24 
                    }
                    Text { 
                        text: selectedDoctor ? ("领域: " + selectedDoctor.specializedField) : ""
                        color: Theme.textSecondary; font.pixelSize: 16
                    }
                    Text { 
                        text: selectedDoctor ? selectedDoctor.intro : ""
                        color: Theme.textSecondary; width: parent.width; horizontalAlignment: Text.AlignHCenter 
                    }
                }
            }

            // 日期选择
            Label { 
                text: "预约日期 (YYYY-MM-DD):"
                color: Theme.textPrimary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TextField {
                    id: dateInput
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    placeholderText: "YYYY-MM-DD"
                    placeholderTextColor: Theme.textPlaceholder
                    background: Rectangle {
                        color: Theme.inputBackground
                        border.color: Theme.border
                        radius: 4
                    }
                    text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                    onTextChanged: {
                        if (text.length === 10) root.selectedDate = text
                    }
                    Component.onCompleted: root.selectedDate = text
                }

                // 日历按钮
                Button {
                    text: "H"
                    // Image source: "qrc:/assets/calendar.png"
                    Layout.preferredWidth: 40
                    onClicked: datePicker.open()
                }
            }

            // 日历组件
            CCalendar {
                id: datePicker
                onDateSelected: function(str) {
                    dateInput.text = str
                }
            }

            // 时间段选择
            Label { 
                text: "选择时间段:" 
                color: Theme.textPrimary 
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10; columnSpacing: 10

                Repeater {
                    model: studentCtrl.timeSlots
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        
                        // 过期判断
                        property bool isExpired: isSlotExpired(root.selectedDate, index)
                        
                        // 只要是 服务端占位 OR 已过期，都算忙碌
                        property bool isBusy: ((root.currentDayMask >> index) & 1) || isExpired
                        
                        // 忙碌则不可点
                        enabled: !isBusy
                        
                        highlighted: root.selectedTimeSlot === index
                        
                        contentItem: Text {
                            text: parent.text
                            // 颜色逻辑：
                            // 1. 选中 -> 反色 (白)
                            // 2. 忙碌 -> 占位符色 (深灰)
                            // 3. 普通 -> 主文字色 (黑)
                            color: parent.highlighted ? Theme.textInverted : (parent.isBusy ? Theme.textPlaceholder : Theme.textPrimary)
                            
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.strikeout: parent.isBusy
                            // 忙碌时降低不透明度
                            opacity: parent.isBusy ? 0.6 : 1.0
                        }
                        
                        background: Rectangle {
                            radius: 4
                            
                            // 背景色逻辑：
                            // 1. 选中 -> 主题色 (蓝/绿)
                            // 2. 忙碌 -> 灰色
                            // 3. 普通 -> 表面色
                            color: {
                                if (parent.highlighted) return Theme.primary
                                if (parent.isBusy) return Theme.isDark ? Theme.inputBackground : "#E0E0E0"
                                return Theme.surface
                            }
                            
                            // 边框逻辑：
                            // 普通状态下显示边框，忙碌状态下不需要边框
                            border.color: parent.highlighted ? Theme.primary : Theme.border
                            border.width: parent.highlighted ? 0 : (parent.isBusy ? 0 : 1)
                        }

                        onClicked: root.selectedTimeSlot = index
                    }
                }
            }

            // 底部图例
            RowLayout {
                spacing: 15
                Layout.topMargin: 5
                
                // 空闲图例
                Row {
                    spacing: 5
                    Rectangle { 
                        width: 16; height: 16; radius: 4
                        color: Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { 
                        text: "空闲"; 
                        font.pixelSize: 12 
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // 忙碌图例
                Row {
                    spacing: 5
                    Rectangle { 
                        width: 16; height: 16; radius: 4
                        color: Theme.isDark ? Theme.inputBackground : "#E0E0E0"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { 
                        text: "已满/休息"; 
                        font.pixelSize: 12 
                        color: Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // 已选图例
                Row {
                    spacing: 5
                    Rectangle { 
                        width: 16; height: 16; radius: 4
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { 
                        text: "已选"; 
                        font.pixelSize: 12 
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
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
                    color: Theme.textPrimary
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: parent.down ? Theme.primaryHover : Theme.primary
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