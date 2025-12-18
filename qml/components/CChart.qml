import QtQuick
import PsyClient

Rectangle {
    id: root
    color: "transparent"
    
    // 数据模型
    property var chartData: []
    // 柱子颜色
    property color barColor: Theme.primary
    // 标题
    property string title: ""

    // 监听数据变化，重绘
    onChartDataChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        // 开启抗锯齿
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;

            // 清空画布
            ctx.clearRect(0, 0, w, h);

            var data = root.chartData;
            if (!data || data.length === 0) {
                drawNoData(ctx, w, h);
                return;
            }

            // 计算最大值 (用于Y轴缩放)
            var maxVal = 0;
            for (var i = 0; i < data.length; i++) {
                if (data[i].value > maxVal) maxVal = data[i].value;
            }
            // 留出顶部 20% 空间
            var yAxisMax = (maxVal === 0) ? 10 : Math.ceil(maxVal * 1.2);

            // 定义边距
            var paddingLeft = 50;
            var paddingBottom = 40;
            var paddingTop = 30;
            var paddingRight = 20;

            var drawW = w - paddingLeft - paddingRight;
            var drawH = h - paddingTop - paddingBottom;

            // 绘制坐标轴
            ctx.lineWidth = 1;
            ctx.strokeStyle = Theme.textSecondary;
            ctx.beginPath();
            // Y轴
            ctx.moveTo(paddingLeft, paddingTop);
            ctx.lineTo(paddingLeft, h - paddingBottom);
            // X轴
            ctx.lineTo(w - paddingRight, h - paddingBottom);
            ctx.stroke();

            // 绘制参考线 (5条)
            ctx.fillStyle = Theme.textSecondary;
            ctx.font = "12px sans-serif";
            ctx.textAlign = "right";
            
            for (var j = 0; j <= 5; j++) {
                var yVal = Math.round(yAxisMax * j / 5);
                var yPos = h - paddingBottom - (yVal / yAxisMax) * drawH;
                
                // 文字
                ctx.fillText(yVal.toString(), paddingLeft - 5, yPos + 4);
                
                // 虚线
                if (j > 0) {
                    ctx.strokeStyle = Qt.rgba(0.5, 0.5, 0.5, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(paddingLeft, yPos);
                    ctx.lineTo(w - paddingRight, yPos);
                    ctx.stroke();
                }
            }

            // 绘制柱子
            var count = data.length;
            // 柱子宽度 + 间隙
            // 间隙设为柱子宽度的 50%
            var stepX = drawW / count;
            var barWidth = stepX * 0.6;
            var marginX = stepX * 0.2;

            for (var k = 0; k < count; k++) {
                var item = data[k];
                var barHeight = (item.value / yAxisMax) * drawH;
                
                var xPos = paddingLeft + (k * stepX) + marginX;
                var yPos = h - paddingBottom - barHeight;

                // 柱体
                // 渐变色
                var gradient = ctx.createLinearGradient(xPos, yPos, xPos, yPos + barHeight);
                gradient.addColorStop(0, root.barColor);
                gradient.addColorStop(1, Qt.lighter(root.barColor, 1.3));
                ctx.fillStyle = gradient;
                
                ctx.fillRect(xPos, yPos, barWidth, barHeight);

                // 柱顶数值
                ctx.fillStyle = Theme.textPrimary;
                ctx.textAlign = "center";
                ctx.fillText(item.value.toString(), xPos + barWidth/2, yPos - 5);

                // X轴标签
                ctx.fillStyle = Theme.textSecondary;
                // 如果标签太长，截断
                var label = item.label;
                if (label.length > 5 && count > 8) label = label.substring(0,4) + "..";
                
                ctx.fillText(label, xPos + barWidth/2, h - paddingBottom + 15);
            }
        }

        function drawNoData(ctx, w, h) {
            ctx.fillStyle = Theme.textPlaceholder;
            ctx.font = "20px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("暂无统计数据", w/2, h/2);
        }
    }
}