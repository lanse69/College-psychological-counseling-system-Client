import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Page {
    id: root

    property var currentMonth: new Date()
    property var selectedDate: null
    property int currentDayMask: 0 
    property var scheduleCache: ({}) 

    header: ToolBar {
        background: Rectangle {
            color: Theme.surface
            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: Theme.divider }
        }
        
        RowLayout {
            anchors.fill: parent
            Button {
                text: "返回"
                onClicked: stackView.pop()
                contentItem: Text { text: parent.text; color: Theme.textPrimary }
                background: Rectangle { color: "transparent" }
            }
            Label {
                text: "日程安排管理"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
                font.bold: true
                color: Theme.textPrimary
            }
            Item { width: 50 }
        }
    }

    DoctorController {
        id: doctorCtrl

        // 监听操作结果 (比如保存成功/失败)
        onOperationResult: function(success, msg) {
            appWindow.showToast(msg, !success)
            if(success) {
                refreshData()
            }
        }

        // 监听从服务端获取到的排班掩码表
        onScheduleMaskReceived: function(scheduleMap) {
            // 将 JSON 对象转存为本地缓存
            scheduleCache = scheduleMap
            updateCalendar()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 月份导航栏
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Button {
                        text: "<"
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? Theme.background : Theme.surface; radius: 20 }
                        contentItem: Text { text: "<"; color: Theme.textPrimary; font.pixelSize: 18; anchors.centerIn: parent }
                        onClicked: {
                            currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1)
                            refreshData() // 切换月份时重新拉取数据
                        }
                    }

                    Label {
                        text: currentMonth.toLocaleDateString(Qt.locale("zh_CN"), "yyyy年MM月")
                        font.bold: true; font.pixelSize: 24; color: Theme.textPrimary
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        text: ">"
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? Theme.background : Theme.surface; radius: 20 }
                        contentItem: Text { text: ">"; color: Theme.textPrimary; font.pixelSize: 18; anchors.centerIn: parent }
                        onClicked: {
                            currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)
                            refreshData() // 切换月份时重新拉取数据
                        }
                    }

                    Button {
                        text: "今天"
                        onClicked: { 
                            currentMonth = new Date()
                            refreshData()
                        }
                    }
                }
            }

            // 星期标题
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40; color: Theme.surface
                RowLayout {
                    anchors.fill: parent; spacing: 1
                    Repeater {
                        model: ["日", "一", "二", "三", "四", "五", "六"]
                        delegate: Rectangle {
                            Layout.fillHeight: true; Layout.fillWidth: true; color: Theme.inputBackground
                            Text { text: modelData; color: Theme.textPrimary; anchors.centerIn: parent }
                        }
                    }
                }
            }

            // 日历网格
            GridView {
                id: calendarGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 7
                cellHeight: 90
                clip: true
                model: calendarModel

                delegate: Rectangle {
                    width: calendarGrid.cellWidth
                    height: calendarGrid.cellHeight
                    color: model.isCurrentMonth ? Theme.inputBackground : Theme.surface
                    border.color: model.isToday ? Theme.success : Theme.textPlaceholder
                    border.width: model.isToday ? 2 : 1

                    property int mask: model.scheduleMask 
                    // 计算可用时段数 (0代表空闲)
                    property int freeCount: {
                        var count = 0;
                        for(var i=0; i<7; i++) {
                            if ( !((mask >> i) & 1) ) count++;
                        }
                        return count;
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 4

                        // 日期数字
                        Text {
                            text: model.day
                            color: model.isToday ? Theme.success : (model.isCurrentMonth ? Theme.textPrimary : Theme.textPlaceholder)
                            font.bold: model.isToday
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignRight
                        }

                        // 可用状态指示条
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            color: Theme.inputBackground
                            radius: 3
                            visible: model.isCurrentMonth

                            Rectangle {
                                height: parent.height
                                width: parent.width * (parent.parent.parent.freeCount / 7.0)
                                radius: 3
                                color: parent.parent.parent.freeCount > 3 ? Theme.success : 
                                       (parent.parent.parent.freeCount > 0 ? Theme.warning : Theme.error)
                            }
                        }

                        // 文字提示
                        Text {
                            text: model.isCurrentMonth ? 
                                  (parent.parent.freeCount === 0 ? "休息" : "余 " + parent.parent.freeCount) 
                                  : ""
                            color: parent.parent.freeCount > 0 ? Theme.textSecondary : Theme.error
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (model.isCurrentMonth) {
                                selectedDate = new Date(model.date)
                                currentDayMask = model.scheduleMask
                                showDateDetail()
                            }
                        }
                    }
                }
            }
        }
    }

    // 日期详情对话框 (7个时段开关)
    Dialog {
        id: dateDetailDialog
        title: selectedDate ? selectedDate.toLocaleDateString(Qt.locale("zh_CN"), "yyyy年MM月dd日") : ""
        anchors.centerIn: parent
        width: 450
        height: 600
        modal: true
        closePolicy: Popup.NoAutoClose

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
            visible: dateDetailDialog.standardButtons !== 0
            standardButtons: dateDetailDialog.standardButtons
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
            spacing: 15

            Label {
                text: "时段开放管理"
                font.bold: true; font.pixelSize: 18; color: Theme.textPrimary
            }
            
            Label {
                text: "开启 = 可预约，关闭 = 休息/忙碌"
                color: Theme.textSecondary; font.pixelSize: 12
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: doctorCtrl.timeSlots
                        delegate: ItemDelegate {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            
                            // 判断当前位: 0=空闲(Switch On), 1=忙(Switch Off)
                            property bool isAvailable: !((currentDayMask >> index) & 1)

                            contentItem: RowLayout {
                                spacing: 10
                                Label {
                                    text: modelData
                                    color: Theme.textPrimary
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: isAvailable
                                    onToggled: {
                                        if (checked) {
                                            // 开: 设为0 (Clear Bit)
                                            currentDayMask &= ~(1 << index)
                                        } else {
                                            // 关: 设为1 (Set Bit)
                                            currentDayMask |= (1 << index)
                                        }
                                    }
                                }
                            }
                            background: Rectangle { color: parent.hovered ? Theme.primaryHover : "transparent" }
                        }
                    }
                }
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Button {
                    text: "取消"
                    Layout.fillWidth: true
                    onClicked: dateDetailDialog.close()
                }
                Button {
                    text: "保存更改"
                    Layout.fillWidth: true
                    highlighted: true
                    onClicked: {
                        saveDateSettings()
                        dateDetailDialog.close()
                    }
                }
            }
        }
    }

    // 日历模型
    ListModel { id: calendarModel }

    Component.onCompleted: {
        refreshData()
    }

    function refreshData() {
        // 月份在 JS 中是 0-11，需要 +1 传给后端
        var y = currentMonth.getFullYear()
        var m = currentMonth.getMonth() + 1
        doctorCtrl.fetchSchedules(y, m)
    }

    function updateCalendar() {
        calendarModel.clear()
        var year = currentMonth.getFullYear()
        var month = currentMonth.getMonth()

        var firstDay = new Date(year, month, 1)
        var lastDay = new Date(year, month + 1, 0)
        var firstDayOfWeek = firstDay.getDay()

        // 填充上个月
        var prevMonth = new Date(year, month - 1, 0)
        for (var i = firstDayOfWeek - 1; i >= 0; i--) {
            var day = prevMonth.getDate() - i
            calendarModel.append({
                day: day,
                date: new Date(year, month - 1, day),
                isCurrentMonth: false,
                isToday: false,
                scheduleMask: 127 // 上个月显示全忙
            })
        }

        // 填充当前月
        var today = new Date()
        for (var day = 1; day <= lastDay.getDate(); day++) {
            var date = new Date(year, month, day)
            var isToday = date.toDateString() === today.toDateString()
            
            // 格式化日期 key: YYYY-MM-DD (需补0)
            var dateKey = formatDateKey(date)
            
            var mask = 127 // 默认全忙
            if (scheduleCache && scheduleCache.hasOwnProperty(dateKey)) {
                mask = scheduleCache[dateKey]
            } else {
                // 缓存没有，则使用默认规则 (工作日默认空闲，周末默认休息)
                // 这里的空闲是 0，休息是 127 (7个1)
                mask = isWorkingDay(date) ? 0 : 127
            }

            calendarModel.append({
                day: day,
                date: date,
                isCurrentMonth: true,
                isToday: isToday,
                scheduleMask: mask
            })
        }

        // 填充下个月
        var remainingCells = 42 - calendarModel.count
        for (var day = 1; day <= remainingCells; day++) {
             calendarModel.append({
                day: day,
                date: new Date(year, month + 1, day),
                isCurrentMonth: false,
                isToday: false,
                scheduleMask: 127
            })
        }
    }

    function isWorkingDay(date) {
        var dayOfWeek = date.getDay()
        return dayOfWeek >= 1 && dayOfWeek <= 5
    }

    function showDateDetail() {
        dateDetailDialog.open()
    }

    function saveDateSettings() {
        // 格式化日期 YYYY-MM-DD
        var dateStr = formatDateKey(selectedDate)
        
        doctorCtrl.updateSchedule(dateStr, currentDayMask)
        
        console.log("Saving schedule for " + dateStr + " Mask: " + currentDayMask.toString(2))
    }

    // 生成 YYYY-MM-DD 格式字符串
    function formatDateKey(date) {
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        return y + "-" + (m < 10 ? "0"+m : m) + "-" + (d < 10 ? "0"+d : d)
    }
}