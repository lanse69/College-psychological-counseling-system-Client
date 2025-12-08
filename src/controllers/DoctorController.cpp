#include "DoctorController.h"

#include <QDebug>
#include <QTimer>

#include "network/NetworkClient.h"
#include "config/ProtocolDefs.h"

DoctorController::DoctorController(QObject *parent) : BaseController(parent), m_bookingModel(new BookingModel(this))
{
    // 监听网络回包
    connect(&NetworkClient::instance(),
            &NetworkClient::responseReceived,
            this,
            &DoctorController::onResponseReceived);
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

void DoctorController::completeConsultation(
    int appointmentId)
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

void DoctorController::onResponseReceived(const QJsonObject &root)
{
    int cmd = root[JsonKeys::CMD].toInt();
    int code = root[JsonKeys::CODE].toInt();
    QString msg = root[JsonKeys::MSG].toString();

    switch (cmd) {
        case (int) CmdType::DOCTOR_GET_APPOINTMENTS:
            if (code == (int) StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                
                QVector<BookingItem> items;
                items.reserve(list.size()); // 预分配内存

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
                    
                    // 预先计算显示文本
                    item.timeSlotText = getTimeSlotText(item.timeSlot);
                    item.statusText = getStatusText(item.status);

                    items.append(item);
                }

                // 更新模型
                m_bookingModel->updateData(items);
                // 默认应用"全部"筛选
                m_bookingModel->applyFilter("全部");
                
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::DOCTOR_CONFIRM_APPOINTMENT:
        case (int) CmdType::DOCTOR_REJECT_APPOINTMENT:
            emit operationResult(code == (int) StatusCode::SUCCESS, msg);
            break;

        case (int)CmdType::DOCTOR_GET_PATIENT_HISTORY:
            if (code == (int)StatusCode::SUCCESS) {
                QJsonArray list = root[JsonKeys::DATA].toArray();
                emit patientHistoryReceived(list);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int)CmdType::GET_DOCTOR_SCHEDULE:
            if (code == (int)StatusCode::SUCCESS) {
                QJsonObject map = root[JsonKeys::DATA].toObject();
                emit scheduleMaskReceived(map);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int)CmdType::UPDATE_SCHEDULE:
            emit operationResult(code == (int)StatusCode::SUCCESS, msg);
            break;

        case (int) CmdType::DOCTOR_COMPLETE_CONSULTATION:
            if (code == (int) StatusCode::SUCCESS) {
                emit operationResult(true, msg);
                // 完成咨询成功后刷新预约列表
                QTimer::singleShot(500, this, &DoctorController::fetchAppointments);
            } else {
                emit operationResult(false, msg);
            }
            break;

        case (int) CmdType::DOCTOR_SUBMIT_REPORT:
            if (code == (int) StatusCode::SUCCESS) {
                emit operationResult(true, msg);
                emit reportSubmitted(); // 发出报告提交成功信号
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