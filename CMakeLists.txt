cmake_minimum_required(VERSION 3.28)

project(PsyClient VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

qt_standard_project_setup(REQUIRES 6.9)

qt_add_executable(appPsyClient)

# 标记 Theme.qml 为单例
set_source_files_properties(qml/globals/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE true)

qt_add_qml_module(appPsyClient
    URI PsyClient
    VERSION 1.0
    SOURCES
        src/main.cpp
        src/config/ProtocolDefs.h
        src/controllers/BaseController.h src/controllers/BaseController.cpp
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
        qml/views/admin/UserMgmtTab.qml
        qml/views/admin/StatsTab.qml
        qml/views/doctor/DoctorDash.qml
        qml/views/doctor/AppointmentMgmtTab.qml
        qml/views/doctor/StudentMgmtTab.qml
        qml/views/doctor/ProfileTab.qml
        qml/views/doctor/ReportWrite.qml
        qml/views/doctor/ScheduleMgr.qml
        qml/views/doctor/SurveyCreator.qml
        qml/views/student/DoctorDetail.qml
        qml/views/student/DoctorListTab.qml
        qml/views/student/MyScheduleTab.qml
        qml/views/student/StudentDash.qml
        qml/views/student/SurveyFill.qml
    RESOURCES resources.qrc
)

target_include_directories(appPsyClient PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/controllers"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/models"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/network"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/config"
)

set_target_properties(appPsyClient PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appPsyClient PRIVATE
    Qt6::Core 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Network
)
