#include "StudentController.h"

#include <QDebug>
#include <QDate>

#include "network/NetworkClient.h"
#include "network/PacketDispatcher.h"
#include "config/ProtocolDefs.h"

StudentController::StudentController(QObject *parent) : BaseController(parent)
{
    connect(&PacketDispatcher::instance(), &PacketDispatcher::onStudentResponse,
            this, &StudentController::onResponseReceived);

    connect(&PacketDispatcher::instance(), &PacketDispatcher::onNotification,
            this, &StudentController::onNotificationReceived);
}

void StudentController::fetchDoctorList()
{
    sendRequest(CmdType::STUDENT_GET_DOCTOR_LIST);
}

void StudentController::fetchDoctorDetail(int doctorId)
{
    if (doctorId <= 0) {
        emit operationResult(false, "医生ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::DOCTOR_ID] = doctorId;
    sendRequest(CmdType::GET_DOCTOR_DETAIL, data);
}

void StudentController::bookAppointment(int doctorId, const QString &date, int timeSlot)
{
    if (doctorId <= 0 || date.isEmpty()) {
        emit operationResult(false, "医生ID和日期不能为空");
        return;
    }

    // 尝试解析用户输入的日期
    QDate qDate = QDate::fromString(date, Qt::ISODate);
    if (!qDate.isValid()) {
        qDate = QDate::fromString(date, "yyyy/MM/dd");
    }
    
    // 允许用户输入不带前导零的日期
    if (!qDate.isValid()) {
        qDate = QDate::fromString(date, "yyyy-M-d"); 
    }

    if (!qDate.isValid()) {
        emit operationResult(false, "日期格式错误，请输入 YYYY-MM-DD");
        return;
    }

    if (qDate < QDate::currentDate()) {
        emit operationResult(false, "无法预约过去的日期");
        return;
    }

    // 转换为标准 ISO 字符串
    QString standardDate = qDate.toString(Qt::ISODate);
    
    QJsonObject data;
    data[JsonKeys::DOCTOR_ID] = doctorId;
    data["date"] = standardDate;
    data["timeSlot"] = timeSlot;
    
    sendRequest(CmdType::STUDENT_BOOK_APPOINTMENT, data);
}

void StudentController::fetchMySchedule()
{
    sendRequest(CmdType::STUDENT_GET_MY_SCHEDULE);
}

void StudentController::cancelAppointment(int appointmentId)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::STUDENT_CANCEL_APPOINTMENT, data);
}

void StudentController::modifyAppointment(int appointmentId, const QString &newDate, int newSlot)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    // 校验日期格式
    QDate qDate = QDate::fromString(newDate, Qt::ISODate);
    if (!qDate.isValid()) {
        qDate = QDate::fromString(newDate, "yyyy-M-d");
    }
    
    if (!qDate.isValid() || qDate < QDate::currentDate()) {
        emit operationResult(false, "日期无效或不能选择过去的时间");
        return;
    }
    
    if (newSlot < 0 || newSlot > 6) {
        emit operationResult(false, "无效的时间段");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    data["date"] = qDate.toString(Qt::ISODate);
    data["timeSlot"] = newSlot;

    // 发送 MODIFY_BOOKING_DIRECT 指令
    sendRequest(CmdType::MODIFY_BOOKING_DIRECT, data);
}

void StudentController::submitSurvey(int appointmentId, const QStringList &answers)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    
    QJsonArray answersArray;
    for (const QString &answer : answers) {
        answersArray.append(answer);
    }
    data["answers"] = answersArray;

    sendRequest(CmdType::STUDENT_SUBMIT_SURVEY, data);
}

void StudentController::fetchSurveyContent(int appointmentId)
{
    if (appointmentId <= 0) return;
    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::GET_SURVEY_CONTENT, data);
}

void StudentController::deleteAppointment(int appointmentId)
{
    if (appointmentId <= 0) return;

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::STUDENT_DELETE_BOOKING, data);
}

void StudentController::replyModification(int appointmentId, bool accept) {
    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    data["accept"] = accept;
    sendRequest(CmdType::MODIFY_BOOKING_REPLY, data);
}

void StudentController::onResponseReceived(const QJsonObject &root)
{
    int cmd = root[JsonKeys::CMD].toInt();
    int code = root[JsonKeys::CODE].toInt();
    QString msg = root[JsonKeys::MSG].toString();

    switch (cmd) {
        case (int) CmdType::STUDENT_GET_DOCTOR_LIST:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit doctorListReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::GET_DOCTOR_LIST:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit doctorListReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::GET_DOCTOR_DETAIL:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonObject doctor = root[JsonKeys::DATA].toObject();
                emit doctorDetailReceived(doctor);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::STUDENT_BOOK_APPOINTMENT:
        case (int) CmdType::STUDENT_CANCEL_APPOINTMENT:
        case (int) CmdType::STUDENT_SUBMIT_SURVEY:
        case (int) CmdType::STUDENT_DELETE_BOOKING: // 处理删除回包
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            break;

        case (int) CmdType::MODIFY_BOOKING_REPLY:
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            if (code == (int) StatusCode::SUCCESS) {
                fetchMySchedule(); 
            }
            break;
        
        case (int) CmdType::MODIFY_BOOKING_DIRECT: // 处理修改结果
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            break;

        case (int) CmdType::STUDENT_GET_MY_SCHEDULE:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit scheduleReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::GET_SURVEY_CONTENT:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonObject survey = root[JsonKeys::DATA].toObject();
                emit surveyContentReceived(survey);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::PUSH_NOTIFICATION: 
            break; 

        default:
            qWarning() << "未处理的命令:" << cmd;
            break;
    }
}

void StudentController::onNotificationReceived(const QJsonObject &root)
{
    QString action = root["action"].toString();
    
    // 如果收到刷新指令，自动刷新预约列表
    if (action == "refresh_schedule") {
        fetchMySchedule();
        
        // 弹窗提示学生
        QString msg = root["msg"].toString();
        if (!msg.isEmpty()) {
            emit operationResult(true, msg);
        }
    }
}