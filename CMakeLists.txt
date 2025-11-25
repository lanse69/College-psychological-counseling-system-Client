cmake_minimum_required(VERSION 3.16)

project(PsyClient LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 开启 Qt 自动化工具（MOC 处理信号槽，RCC 处理资源）
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 客户端依赖：GUI, QML, Quick, Network。注意：不需要 Sql 模块！
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

# 收集源码
file(GLOB_RECURSE CLIENT_SRCS 
    "src/*.h"
    "src/*.cpp"
)

# 指定资源文件
set(CLIENT_RESOURCES resources.qrc)

add_executable(PsyClient ${CLIENT_SRCS} ${CLIENT_RESOURCES})

# 链接 Qt 库
target_link_libraries(PsyClient PRIVATE 
    Qt6::Core 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Network
)

# 确保构建时能找到 QML 模块（如果使用了额外的 QML 插件）
# 对于基础 QML 开发，通常不需要额外配置，但建议包含资源目录到 Include
target_include_directories(PsyClient PRIVATE src)
