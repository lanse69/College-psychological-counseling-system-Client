pragma Singleton
import QtQuick

QtObject {
    id: theme

    // 检测系统是否为深色模式
    property bool isDark: SystemPalette ? (SystemPalette.text !== "#000000" && SystemPalette.windowText !== "#000000") : false

    // 页面整体大背景 (浅灰 vs 深黑)
    property color background: isDark ? "#121212" : "#f5f7fa"
    
    // 内容卡片/列表项/弹窗背景 (纯白 vs 深灰)
    property color surface: isDark ? "#1e1e1e" : "#ffffff"
    
    // 输入框背景
    property color inputBackground: isDark ? "#2d2d2d" : "#ffffff"

    // 鼠标悬停/选中高亮
    property color surfaceHighlight: isDark ? "#333333" : "#e3f2fd"

    // 主要文字 (标题、正文)
    property color textPrimary: isDark ? "#e0e0e0" : "#333333"
    // 次要文字 (说明、辅助信息)
    property color textSecondary: isDark ? "#a0a0a0" : "#666666"
    // 反色文字 (用于深色按钮上的文字)
    property color textInverted: "#ffffff"
    // 占位符文字
    property color textPlaceholder: isDark ? "#666666" : "#aab2bd"

    // 线条与边框
    property color divider: isDark ? "#2c2c2c" : "#e0e0e0"
    property color border: isDark ? "#3d3d3d" : "#dcdcdc"

    property color studentColor: isDark ? "#4fc3f7" : "#2196F3"
    property color doctorColor:  isDark ? "#81c784" : "#4CAF50"
    property color adminColor:   isDark ? "#ffb74d" : "#FF9800"

    property color primary: isDark ? "#64b5f6" : "#2196F3"
    property color primaryHover: isDark ? "#42a5f5" : "#1976d2"
    property color purple: isDark ? "#9c27b0": "#6a1c78ff"
    property color orange: isDark ? "#ff5722": "#d14e26ff"
    
    property color success: isDark ? "#81c784" : "#4CAF50"
    property color warning: isDark ? "#ffd54f" : "#FFC107"
    property color error: isDark ? "#e57373" : "#EF5350"

    function toggle() {
        isDark = !isDark
    }
}