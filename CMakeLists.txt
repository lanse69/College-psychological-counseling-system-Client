cmake_minimum_required(VERSION 3.16)

project(PsyClient LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找依赖
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

# 开启 Qt 自动化工具
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

qt_standard_project_setup()

qt_add_executable(PsyClient)

qt_add_qml_module(PsyClient
    URI PsyClient
    VERSION 1.0
    SOURCES
        src/main.cpp
        src/config/ProtocolDefs.h
        src/controllers/AdminController.h src/controllers/AdminController.cpp
        src/controllers/DoctorController.h src/controllers/DoctorController.cpp
        src/controllers/SessionController.h src/controllers/SessionController.cpp
        src/controllers/StudentController.h src/controllers/StudentController.cpp
        src/models/BookingModel.h src/models/BookingModel.cpp
        src/models/ChatModel.h src/models/ChatModel.cpp
        src/models/DoctorListModel.h src/models/DoctorListModel.cpp
        src/network/NetworkClient.h src/network/NetworkClient.cpp
        src/network/PacketDispatcher.h src/network/PacketDispatcher.cpp
    QML_FILES
        qml/Main.qml
        qml/components/CCalendar.qml
        qml/components/CChart.qml
        qml/components/CToast.qml
        qml/globals/Theme.qml
        qml/views/LoginView.qml
        qml/views/admin/AdminDash.qml
        qml/views/admin/StatsView.qml
        qml/views/admin/UserEditor.qml
        qml/views/doctor/DoctorDash.qml
        qml/views/doctor/PatientView.qml
        qml/views/doctor/ReportWrite.qml
        qml/views/doctor/ScheduleMgr.qml
        qml/views/student/DoctorDetail.qml
        qml/views/student/MySchedule.qml
        qml/views/student/StudentDash.qml
        qml/views/student/SurveyFill.qml
    RESOURCES resources.qrc
)

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

set_target_properties(PsyClient PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)