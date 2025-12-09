#include "PacketDispatcher.h"

#include <QDebug>

#include "NetworkClient.h"
#include "config/ProtocolDefs.h"

PacketDispatcher &PacketDispatcher::instance()
{
    static PacketDispatcher _inst;
    return _inst;
}

PacketDispatcher::PacketDispatcher(QObject *parent)
    : QObject(parent)
{
    connect(&NetworkClient::instance(),
            &NetworkClient::responseReceived,
            this,
            &PacketDispatcher::dispatch);
}

void PacketDispatcher::dispatch(const QJsonObject &data)
{
    if (!data.contains(JsonKeys::CMD)) {
        qWarning() << "收到无效数据包：缺少 CMD 字段";
        return;
    }

    int cmdVal = data[JsonKeys::CMD].toInt();
    CmdType cmd = static_cast<CmdType>(cmdVal);

    switch (cmd) {
        // 认证与基础
        case CmdType::LOGIN:
        case CmdType::LOGOUT:
        case CmdType::UPDATE_PWD:
        case CmdType::GET_USER_INFO:
            emit onAuthResponse(data);
        break;

        // 管理员业务
        case CmdType::ADMIN_ADD_USER:
        case CmdType::ADMIN_DEL_USER:
        case CmdType::ADMIN_GET_USER_LIST:
        case CmdType::UPDATE_USER_INFO: 
        case CmdType::GET_STATISTICS:
            emit onAdminResponse(data);
        break;

        // 医生/排班业务
        case CmdType::GET_DOCTOR_LIST:
        case CmdType::GET_DOCTOR_DETAIL:
        case CmdType::GET_DOCTOR_SCHEDULE:
        case CmdType::UPDATE_SCHEDULE:
        case CmdType::WRITE_REPORT:
        case CmdType::UPLOAD_SURVEY:
        case CmdType::DOCTOR_GET_APPOINTMENTS: 
        case CmdType::DOCTOR_GET_PATIENTS:    
        // 医生操作相关指令
        case CmdType::DOCTOR_CONFIRM_APPOINTMENT:   // 1201
        case CmdType::DOCTOR_REJECT_APPOINTMENT:    // 1202
        case CmdType::DOCTOR_COMPLETE_CONSULTATION: // 1203
        case CmdType::DOCTOR_SUBMIT_REPORT:
        case CmdType::DOCTOR_GET_PATIENT_HISTORY:
            emit onDoctorResponse(data);
        break;

        // 预约业务 (通用/查询类)
        case CmdType::CREATE_BOOKING:
        case CmdType::CANCEL_BOOKING:
        case CmdType::MODIFY_BOOKING_DIRECT:
        case CmdType::MODIFY_BOOKING_REQ:
        case CmdType::MODIFY_BOOKING_REPLY:
        case CmdType::GET_MY_BOOKINGS:
            emit onBookingResponse(data);
        break;

        // 学生/问卷业务
        case CmdType::GET_SURVEY_LIST:
        case CmdType::GET_SURVEY_CONTENT:
        case CmdType::SUBMIT_SURVEY:
        case CmdType::GET_REPORT:
        case CmdType::STUDENT_GET_DOCTOR_LIST:
        case CmdType::STUDENT_GET_MY_SCHEDULE:
        case CmdType::STUDENT_CANCEL_APPOINTMENT:
        case CmdType::STUDENT_SUBMIT_SURVEY:
        // 学生预约指令
        case CmdType::STUDENT_BOOK_APPOINTMENT:     // 1101
            emit onStudentResponse(data);
        break;

        // 系统推送
        case CmdType::PUSH_NOTIFICATION:
            emit onNotification(data);
        break;

        // 心跳
        case CmdType::HEARTBEAT:
            break; // 静默处理

        // 其他
        default:
            qWarning() << "未处理的指令类型:" << cmdVal;
        break;
    }
}