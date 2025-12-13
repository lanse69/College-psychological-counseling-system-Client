import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PsyClient

Item {
    id: tabRoot
    property var controller: null

    // 存储从后端拿到的数据: [{label: "X轴", value: 10}, ...]
    property var chartData: []
    property string currentTitle: "每月咨询人数趋势"

    Component.onCompleted: refresh()

    function refresh() {
        // 默认加载趋势图
        fetchData("consult_trend")
    }

    function fetchData(type) {
        if (controller) controller.fetchStatistics(type)
        if (type === "consult_trend") currentTitle = "近12个月咨询量趋势"
        else currentTitle = "热门心理咨询问题 TOP 10"
    }

    Connections {
        target: controller
        function onStatisticsReceived(data) {
            var tmp = []
            for(var i=0; i<data.length; i++) {
                tmp.push(data[i])
            }
            tabRoot.chartData = tmp
            canvas.requestPaint() // 触发重绘
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 顶部控制栏
        RowLayout {
            Layout.fillWidth: true
            Label { text: "数据可视化报表"; font.bold: true; font.pixelSize: 20 }
            Item { Layout.fillWidth: true }
            
            ButtonGroup { id: chartGroup }
            
            Button {
                text: "咨询趋势图"
                checkable: true
                checked: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("consult_trend")
            }
            Button {
                text: "热门问题分布"
                checkable: true
                ButtonGroup.group: chartGroup
                onClicked: fetchData("common_issues")
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
                
                Label { 
                    text: currentTitle
                    font.bold: true
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Canvas {
                    id: canvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        var w = width;
                        var h = height;

                        // 清空背景
                        ctx.clearRect(0, 0, w, h);
                        
                        var data = tabRoot.chartData;
                        if (data.length === 0) {
                            ctx.fillStyle = "#888";
                            ctx.font = "16px sans-serif";
                            ctx.fillText("暂无数据", w/2 - 30, h/2);
                            return;
                        }

                        // 计算最大值用于归一化高度
                        var maxVal = 0;
                        for(var i=0; i<data.length; i++) if(data[i].value > maxVal) maxVal = data[i].value;
                        if(maxVal === 0) maxVal = 10;

                        // 绘图参数
                        var padding = 40;
                        var drawW = w - padding * 2;
                        var drawH = h - padding * 2;
                        var barWidth = drawW / data.length * 0.6;
                        var gap = drawW / data.length;

                        // 绘制坐标轴
                        ctx.strokeStyle = Theme.divider;
                        ctx.beginPath();
                        ctx.moveTo(padding, padding);
                        ctx.lineTo(padding, h - padding); // Y轴
                        ctx.lineTo(w - padding, h - padding); // X轴
                        ctx.stroke();

                        // 绘制柱状图
                        for(var j=0; j<data.length; j++) {
                            var item = data[j];
                            var barH = (item.value / maxVal) * drawH;
                            
                            var x = padding + j * gap + (gap - barWidth)/2;
                            var y = h - padding - barH;

                            // 柱子
                            ctx.fillStyle = Theme.primary;
                            ctx.fillRect(x, y, barWidth, barH);

                            // 数值
                            ctx.fillStyle = Theme.textPrimary;
                            ctx.font = "12px sans-serif";
                            ctx.fillText(item.value, x + barWidth/2 - 5, y - 5);
                            ctx.fillText(item.label, x, h - padding + 15);
                        }
                    }
                }
            }
        }
    }
}