#include "PacketDispatcher.h"

#include <QDebug>

#include "NetworkClient.h"
#include "config/ProtocolDefs.h"

PacketDispatcher &PacketDispatcher::instance()
{
    static PacketDispatcher _inst;
    return _inst;
}

PacketDispatcher::PacketDispatcher(QObject *parent) : QObject(parent)
{
    connect(&NetworkClient::instance(), &NetworkClient::responseReceived,
            this, &PacketDispatcher::dispatch);
}

void PacketDispatcher::dispatch(const QJsonObject &data)
{
    if (!data.contains(JsonKeys::CMD)) {
        qWarning() << "收到无效数据包：缺少 CMD 字段";
        return;
    }

    int cmdVal = data[JsonKeys::CMD].toInt();
    CmdType cmd = static_cast<CmdType>(cmdVal);

    if (cmd == CmdType::GET_SURVEY_CONTENT) {
        emit onStudentResponse(data);
        emit onDoctorResponse(data);
        return;
    }

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

        // 医生业务
        case CmdType::GET_DOCTOR_LIST:
        case CmdType::GET_DOCTOR_DETAIL:
        case CmdType::GET_DOCTOR_SCHEDULE:
        case CmdType::UPDATE_SCHEDULE:
        case CmdType::DOCTOR_GET_APPOINTMENTS:
        case CmdType::DOCTOR_GET_PATIENTS:
        case CmdType::DOCTOR_CONFIRM_APPOINTMENT:
        case CmdType::DOCTOR_REJECT_APPOINTMENT:
        case CmdType::DOCTOR_COMPLETE_CONSULTATION:
        case CmdType::DOCTOR_SUBMIT_REPORT:
        case CmdType::DOCTOR_GET_PATIENT_HISTORY:
        case CmdType::DOCTOR_GET_MY_SURVEY:
        case CmdType::DOCTOR_SAVE_SURVEY:
            emit onDoctorResponse(data);
            break;

        // 学生业务 & 预约通用
        case CmdType::CREATE_BOOKING:
        case CmdType::CANCEL_BOOKING:
        case CmdType::GET_MY_BOOKINGS:
        case CmdType::STUDENT_GET_DOCTOR_LIST:
        case CmdType::STUDENT_BOOK_APPOINTMENT:
        case CmdType::STUDENT_GET_MY_SCHEDULE:
        case CmdType::STUDENT_CANCEL_APPOINTMENT:
        case CmdType::STUDENT_DELETE_BOOKING:
        case CmdType::STUDENT_SUBMIT_SURVEY:
            emit onStudentResponse(data);
            break;

        // 推送通知
        case CmdType::PUSH_NOTIFICATION:
            emit onNotification(data);
            break;
            
        case CmdType::HEARTBEAT:
            break;

        default:
            qWarning() << "PacketDispatcher: 未分类的指令" << cmdVal;
            break;
    }
}