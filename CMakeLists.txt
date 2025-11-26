cmake_minimum_required(VERSION 3.16)

project(PsyClient LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 开启 Qt 自动化工具
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 查找依赖
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

# 收集源码
file(GLOB_RECURSE CLIENT_SRCS 
    "src/*.h"
    "src/*.cpp"
)

# 指定资源文件
set(CLIENT_RESOURCES resources.qrc)

add_executable(PsyClient WIN32 ${CLIENT_SRCS} ${CLIENT_RESOURCES})

# 链接库
target_link_libraries(PsyClient PRIVATE 
    Qt6::Core 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Network
)

target_include_directories(PsyClient PRIVATE 
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
)