import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient
import "../../components"

Item {
    id: tabRoot
    property var controller: null

    property var chartData: []
    property string currentTitle: ""
    property string currentType: ""

    Component.onCompleted: {
        // 延迟一点加载，确保 controller 已就绪
        refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: fetchData("consult_trend")
    }

    function refresh() {
        if (currentType !== "") fetchData(currentType)
    }

    Connections {
        target: controller
        function onStatisticsReceived(data) {
            var tmp = []
            for(var i=0; i<data.length; i++) {
                tmp.push(data[i])
            }
            tabRoot.chartData = tmp
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 顶部控制栏
        Flow {
            Layout.fillWidth: true
            spacing: 10

            Label { 
                text: "数据可视化报表"; 
                font.bold: true; 
                font.pixelSize: 16 
                color: Theme.textPrimary
                verticalAlignment: Text.AlignVCenter
                height: 40
            }
            
            ButtonGroup { id: chartGroup }
            
            Button {
                text: "咨询趋势"
                checkable: true
                checked: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("consult_trend")
            }
            Button {
                text: "热门问题"
                checkable: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("common_issues")
            }
            Button {
                text: "学生性别"
                checkable: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("student_gender")
            }
            Button {
                text: "热门医生"
                checkable: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("top_doctors")
            }
            Button {
                text: "时段热力"
                checkable: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("peak_times")
            }
            // TODO: 其他
            Button {
                text: "刷新"
                onClicked: refresh()
            }
        }

        // 图表区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surface
            radius: 8
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                
                Label { 
                    text: currentTitle
                    font.bold: true
                    font.pixelSize: 16
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                CChart {
                    id: chart
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    chartData: tabRoot.chartData
                    
                    barColor: getBarColor(tabRoot.currentType)
                }
            }
        }
    }

    function getBarColor(type) {
        if (type === "consult_trend") return Theme.primary;
        if (type === "common_issues") return Theme.warning;
        if (type === "student_gender") return Theme.purple;
        if (type === "top_doctors") return Theme.success;
        if (type === "peak_times") return Theme.orange;
        // TODO: 其他
        return Theme.primary;
    }

    function fetchData(type) {
        currentType = type
        if (controller) controller.fetchStatistics(type)
        
        // 更新标题逻辑
        switch(type) {
            case "consult_trend": currentTitle = "近12个月完成的咨询数量趋势"; break;
            case "common_issues": currentTitle = "Top 10 热门心理咨询标签/问题"; break;
            case "student_gender": currentTitle = "注册学生性别比例分布"; break;
            case "top_doctors": currentTitle = "最受欢迎心理咨询师 (Top 10)"; break;
            case "peak_times": currentTitle = "预约时段热力分布 (0-6)"; break;
            // TODO: 其他
            default: currentTitle = "未知";break;
        }
    }
}