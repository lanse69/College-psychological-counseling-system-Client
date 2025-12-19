import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../globals"

Popup {
    id: root
    width: 340
    height: 400
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay 
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 对外信号：选中日期时触发 (返回 "YYYY-MM-DD" 格式字符串)
    signal dateSelected(string dateString)

    property date currentMonth: new Date()
    
    // 背景样式
    background: Rectangle {
        color: Theme.surface
        border.color: Theme.border
        radius: 8
    }

    // 内部数据模型
    ListModel { id: calendarModel }

    Component.onCompleted: updateCalendar()

    contentItem: ColumnLayout {
        spacing: 10

        // 顶部导航栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "<"
                Layout.preferredWidth: 40
                onClicked: {
                    root.currentMonth = new Date(root.currentMonth.getFullYear(), root.currentMonth.getMonth() - 1, 1)
                    updateCalendar()
                }
            }

            Label {
                text: root.currentMonth.toLocaleDateString(Qt.locale("zh_CN"), "yyyy年MM月")
                font.bold: true
                font.pixelSize: 18
                color: Theme.textPrimary
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: ">"
                Layout.preferredWidth: 40
                onClicked: {
                    root.currentMonth = new Date(root.currentMonth.getFullYear(), root.currentMonth.getMonth() + 1, 1)
                    updateCalendar()
                }
            }
        }

        // 星期标题
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["日", "一", "二", "三", "四", "五", "六"]
                delegate: Label {
                    text: modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textSecondary
                    font.bold: true
                }
            }
        }

        // 日历网格
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / 7
            cellHeight: cellWidth * 0.8
            clip: true
            model: calendarModel

            delegate: Rectangle {
                width: grid.cellWidth
                height: grid.cellHeight
                color: "transparent"

                property bool isToday: {
                    var now = new Date()
                    return model.dateObj.toDateString() === now.toDateString()
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: width / 2
                    color: model.isCurrentMonth ? (parent.isToday ? Theme.primary : "transparent") : "transparent"
                    border.color: parent.isToday ? Theme.primary : "transparent"
                    
                    // 鼠标悬停/点击效果
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.primary
                        opacity: ma.pressed ? 0.3 : (ma.containsMouse ? 0.1 : 0)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: model.isCurrentMonth ? (parent.isToday ? "#ffffff" : Theme.textPrimary) : Theme.textPlaceholder
                    font.bold: parent.isToday
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: model.isCurrentMonth
                    onClicked: {
                        var d = model.dateObj
                        var y = d.getFullYear()
                        var m = d.getMonth() + 1
                        var day = d.getDate()
                        // 格式化为 YYYY-MM-DD
                        var str = y + "-" + (m < 10 ? "0"+m : m) + "-" + (day < 10 ? "0"+day : day)
                        root.dateSelected(str)
                        root.close()
                    }
                }
            }
        }
        
        // 底部按钮
        Button {
            text: "回到今天"
            Layout.alignment: Qt.AlignRight
            onClicked: {
                root.currentMonth = new Date()
                updateCalendar()
            }
        }
    }

    function updateCalendar() {
        calendarModel.clear()
        var year = currentMonth.getFullYear()
        var month = currentMonth.getMonth() // 0-11

        var firstDay = new Date(year, month, 1)
        var lastDay = new Date(year, month + 1, 0)
        var firstDayOfWeek = firstDay.getDay() // 0(Sun) - 6(Sat)

        // 补前月
        var prevLastDay = new Date(year, month, 0).getDate()
        for (var i = firstDayOfWeek - 1; i >= 0; i--) {
            calendarModel.append({
                day: prevLastDay - i,
                isCurrentMonth: false,
                dateObj: new Date(year, month - 1, prevLastDay - i)
            })
        }

        // 当月
        for (var d = 1; d <= lastDay.getDate(); d++) {
            calendarModel.append({
                day: d,
                isCurrentMonth: true,
                dateObj: new Date(year, month, d)
            })
        }

        // 补后月
        var count = calendarModel.count
        var nextD = 1
        while (count % 7 !== 0 || count < 35) {
            calendarModel.append({
                day: nextD,
                isCurrentMonth: false,
                dateObj: new Date(year, month + 1, nextD)
            })
            nextD++
            count++
        }
    }
}