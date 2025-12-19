#include "DoctorController.h"

#include <QDebug>
#include <QTimer>
#include <QDateTime>

#include "network/NetworkClient.h"
#include "network/PacketDispatcher.h"
#include "config/ProtocolDefs.h"

static bool isTimePassed(const QString &dateStr, int slot) {
    QDate date = QDate::fromString(dateStr, Qt::ISODate);
    if (!date.isValid()) date = QDate::fromString(dateStr, "yyyy-M-d"); 
    if (!date.isValid()) return true;

    QDateTime now = QDateTime::currentDateTime();
    if (date < now.date()) return true;
    if (date > now.date()) return false;

    int h = 0;
    switch(slot) {
        case 0: h = 8; break; case 1: h = 9; break; case 2: h = 10; break;
        case 3: h = 14; break; case 4: h = 15; break; case 5: h = 16; break; case 6: h = 17; break;
        default: return true;
    }
    return now.time() >= QTime(h, 30);
}

DoctorController::DoctorController(QObject *parent) : BaseController(parent), m_bookingModel(new BookingModel(this))
{
    connect(&PacketDispatcher::instance(), &PacketDispatcher::onDoctorResponse,
            this, &DoctorController::onResponseReceived);

    connect(&PacketDispatcher::instance(), &PacketDispatcher::onNotification,
            this, &DoctorController::onNotificationReceived);
}

QJsonObject DoctorController::myProfile() const { 
    return m_myProfile; 
}

// 更新个人信息
void DoctorController::updateMyProfile(const QString &realName, const QString &password, 
                                       const QString &intro, const QString &spec) 
{
    int myId = m_myProfile["id"].toInt();
    if (myId == 0) {
        emit operationResult(false, "未获取到用户信息，请先刷新");
        return;
    }

    QJsonObject data;
    data[JsonKeys::TARGET_ID] = myId;
    data[JsonKeys::REAL_NAME] = realName;
    data[JsonKeys::PASSWORD] = password;
    data[JsonKeys::INTRO] = intro;
    data[JsonKeys::SPEC] = spec;
    
    sendRequest(CmdType::UPDATE_USER_INFO, data);
}

void DoctorController::fetchMyProfile() {
    sendRequest(CmdType::GET_USER_INFO);
}

void DoctorController::fetchAppointments()
{
    sendRequest(CmdType::DOCTOR_GET_APPOINTMENTS);
}

BookingModel* DoctorController::appointmentModel() const { 
    return m_bookingModel; 
}

void DoctorController::confirmAppointment(int appointmentId)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::DOCTOR_CONFIRM_APPOINTMENT, data);
}

void DoctorController::rejectAppointment(int appointmentId)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::DOCTOR_REJECT_APPOINTMENT, data);
}

void DoctorController::completeConsultation(int appointmentId)
{
    if (appointmentId <= 0) {
        emit operationResult(false, "预约ID无效");
        return;
    }

    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::DOCTOR_COMPLETE_CONSULTATION, data);
}

void DoctorController::fetchPatients()
{
    sendRequest(CmdType::DOCTOR_GET_PATIENTS);
}

void DoctorController::submitReport(const QJsonObject &reportData)
{
    sendRequest(CmdType::DOCTOR_SUBMIT_REPORT, reportData);
}

void DoctorController::deleteAppointment(int appointmentId)
{
    if (appointmentId <= 0) return;
    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::DOCTOR_DELETE_BOOKING, data);
}

void DoctorController::fetchAppointmentSurvey(int appointmentId)
{
    if (appointmentId <= 0) return;
    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    sendRequest(CmdType::GET_SURVEY_CONTENT, data);
}

void DoctorController::requestModification(int appointmentId, const QString &newDate, int newSlot) {
    if (appointmentId <= 0 || newDate.isEmpty() || newSlot < 0) {
        emit operationResult(false, "参数无效");
        return;
    }
    if (isTimePassed(newDate, newSlot)) {
        emit operationResult(false, "不能修改到已经过去的时间");
        return;
    }
    QJsonObject data;
    data[JsonKeys::APPOINTMENT_ID] = appointmentId;
    data["date"] = newDate;
    data["timeSlot"] = newSlot;
    sendRequest(CmdType::MODIFY_BOOKING_REQ, data);
}

void DoctorController::onResponseReceived(const QJsonObject &root)
{
    int cmd = root[JsonKeys::CMD].toInt();
    int code = root[JsonKeys::CODE].toInt();
    QString msg = root[JsonKeys::MSG].toString();

    if (cmd == (int)CmdType::GET_USER_INFO) {
        if (code == (int)StatusCode::SUCCESS) {
            m_myProfile = root[JsonKeys::DATA].toObject();
            emit myProfileChanged();
        } else {
            emit operationResult(false, msg);
        }
        return;
    }

    switch (cmd) {
        case (int) CmdType::DOCTOR_GET_APPOINTMENTS:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                QVector<BookingItem> items;
                
                for (const QJsonValue &v : list) {
                    QJsonObject obj = v.toObject();
                    BookingItem item;
                    item.id = obj["id"].toInt();
                    item.studentId = obj["studentId"].toInt();
                    item.studentName = obj["studentName"].toString();
                    item.appointmentDate = obj["appointmentDate"].toString();
                    item.timeSlot = obj["timeSlot"].toInt();
                    item.status = obj["status"].toInt();
                    item.reason = obj["reason"].toString();
                    
                    item.timeSlotText = getTimeSlotText(item.timeSlot);
                    item.statusText = getStatusText(item.status);

                    // 解析待变更数据
                    if (obj.contains("pendingDate")) {
                        item.pendingDate = obj["pendingDate"].toString();
                        item.pendingSlot = obj["pendingSlot"].toInt();
                    }

                    items.append(item);
                }
                m_bookingModel->updateData(items);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::DOCTOR_GET_PATIENTS:
             if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit patientListReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::GET_DOCTOR_SCHEDULE:
            if (code == (int) StatusCode::SUCCESS) {
                emit scheduleMaskReceived(root[JsonKeys::DATA].toObject());
            }
            break;

        case (int) CmdType::DOCTOR_SUBMIT_REPORT:
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            if (code == (int) StatusCode::SUCCESS) {
                emit reportSubmitted(); 
            }
            break;

        case (int) CmdType::UPDATE_USER_INFO:
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            if (code == (int) StatusCode::SUCCESS) {
                fetchMyProfile(); 
            }
            break;

        case (int) CmdType::DOCTOR_CONFIRM_APPOINTMENT:
        case (int) CmdType::DOCTOR_REJECT_APPOINTMENT:
        case (int) CmdType::DOCTOR_COMPLETE_CONSULTATION:
        case (int) CmdType::UPDATE_SCHEDULE: // 更新排班
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            break;

        case (int) CmdType::DOCTOR_GET_MY_SURVEY:
            if (code == (int) StatusCode::SUCCESS) {
                emit mySurveyReceived(root[JsonKeys::DATA].toObject());
            }
            break;
        case (int) CmdType::DOCTOR_SAVE_SURVEY:
            emit operationResult(code == (int)StatusCode::SUCCESS, msg);
            break;

        // 修改预约请求的回包
        case (int) CmdType::MODIFY_BOOKING_REQ:
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            
            if (code == (int) StatusCode::SUCCESS) {
                fetchAppointments();
            }
            break;

        case (int) CmdType::DOCTOR_DELETE_BOOKING:
            emit operationResult(code == (int)StatusCode::SUCCESS, msg);
            if (code == (int)StatusCode::SUCCESS) {
                fetchAppointments(); // 删除成功后刷新列表
            }
            break;

        case (int) CmdType::GET_SURVEY_CONTENT:
            if (code == (int) StatusCode::SUCCESS) {
                emit surveyContentReceived(root[JsonKeys::DATA].toObject());
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::DOCTOR_GET_PATIENT_HISTORY:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit patientHistoryReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::PUSH_NOTIFICATION:
            break;

        default:
            break;
    }
}

QString DoctorController::getTimeSlotText(int slot) {
    switch(slot) {
        case 0: return "08:30-09:30";
        case 1: return "09:30-10:30";
        case 2: return "10:30-11:30";
        case 3: return "14:30-15:30";
        case 4: return "15:30-16:30";
        case 5: return "16:30-17:30";
        case 6: return "17:30-18:30";
        default: return "未知时段";
    }
}

QString DoctorController::getStatusText(int status) {
    switch(status) {
        case 0: return "待确认";
        case 1: return "已确认";
        case 2: return "已完成";
        case 3: return "已取消";
        case 4: return "待学生确认修改";
        default: return "未知状态";
    }
}

void DoctorController::fetchSchedules(int year, int month) {
    QJsonObject data;
    data["year"] = year;
    data["month"] = month;
    sendRequest(CmdType::GET_DOCTOR_SCHEDULE, data);
}

void DoctorController::updateSchedule(const QString &date, int mask) {
    QJsonObject data;
    data["date"] = date;
    data["mask"] = mask;
    sendRequest(CmdType::UPDATE_SCHEDULE, data);
}

void DoctorController::fetchPatientHistory(int studentId)
{
    if (studentId <= 0) {
        emit operationResult(false, "无效的学生ID");
        return;
    }

    QJsonObject data;
    data["studentId"] = studentId;
    sendRequest(CmdType::DOCTOR_GET_PATIENT_HISTORY, data);
}

void DoctorController::fetchMySurvey() {
    sendRequest(CmdType::DOCTOR_GET_MY_SURVEY);
}

void DoctorController::saveMySurvey(const QString &title, const QVariantList &questions) {
    QJsonObject data;
    data["title"] = title;
    data["questions"] = QJsonArray::fromVariantList(questions);
    
    sendRequest(CmdType::DOCTOR_SAVE_SURVEY, data);
}

void DoctorController::onNotificationReceived(const QJsonObject &root)
{
    // 获取 action 字段
    QString action = root["action"].toString();
    QString msg = root[JsonKeys::MSG].toString();

    // 包含刷新指令，自动重新获取预约列表
    if (action == "refresh_appointments") {
        fetchAppointments(); // 重新拉取数据

        emit operationResult(true, msg);
    }
}