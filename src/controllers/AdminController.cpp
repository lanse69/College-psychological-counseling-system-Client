#include "AdminController.h"

#include <QCryptographicHash>
#include <QDebug>

#include "network/PacketDispatcher.h"
#include "config/ProtocolDefs.h"

AdminController::AdminController(QObject *parent) : BaseController(parent) {
    connect(&PacketDispatcher::instance(), &PacketDispatcher::onAdminResponse,
            this, &AdminController::onResponseReceived);
}

void AdminController::addUser(const QString &username, const QString &password, int role, const QString &realName, const QString &intro, const QString &spec)
{
    if (username.isEmpty() || password.isEmpty()) {
        emit operationResult(false, "用户名和密码不能为空");
        return;
    }

    QString passwordHash = QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());

    QJsonObject data;
    data[JsonKeys::USERNAME] = username;
    data[JsonKeys::PASSWORD] = passwordHash;
    data[JsonKeys::ROLE] = role;
    data[JsonKeys::REAL_NAME] = realName;

    // 医生角色有简介和擅长领域
    if (role == (int)UserRole::DOCTOR) {
        data[JsonKeys::INTRO] = intro;
        data[JsonKeys::SPEC] = spec;
    }

    sendRequest(CmdType::ADMIN_ADD_USER, data);
}

void AdminController::deleteUser(int targetId) {
    if (targetId <= 0) {
        emit operationResult(false, "无效的用户 ID");
        return;
    }

    QJsonObject data;
    data[JsonKeys::TARGET_ID] = targetId;

    sendRequest(CmdType::ADMIN_DEL_USER, data);
}

void AdminController::updateUserInfo(int targetId, const QString &realName, const QString &password, const QString &intro, const QString &spec)
{
    if (targetId <= 0) {
        emit operationResult(false, "无效的用户 ID");
        return;
    }

    QJsonObject data;

    data[JsonKeys::TARGET_ID] = targetId;
    data[JsonKeys::REAL_NAME] = realName;
    if (!password.isEmpty()) {
        QString passwordHash = QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
        data[JsonKeys::PASSWORD] = passwordHash;
    } else {
        data[JsonKeys::PASSWORD] = "";
    }

    data[JsonKeys::INTRO] = intro;
    data[JsonKeys::SPEC] = spec;

    sendRequest(CmdType::UPDATE_USER_INFO, data);
}

void AdminController::fetchUserList() {
    sendRequest(CmdType::ADMIN_GET_USER_LIST);
}

void AdminController::fetchStatistics(const QString &type) {
    QJsonObject data;
    data["type"] = type;
    sendRequest(CmdType::GET_STATISTICS, data);
}

void AdminController::onResponseReceived(const QJsonObject &root) {
    int cmd = root[JsonKeys::CMD].toInt();
    int code = root[JsonKeys::CODE].toInt();
    QString msg = root[JsonKeys::MSG].toString();

    if (cmd == (int)CmdType::ADMIN_ADD_USER ||
        cmd == (int)CmdType::ADMIN_DEL_USER ||
        cmd == (int)CmdType::UPDATE_USER_INFO)
    {
        bool success = (code == (int)StatusCode::SUCCESS);
        emit operationResult(success, msg);
    }

    if (cmd == (int)CmdType::ADMIN_GET_USER_LIST) {
        if (code == (int)StatusCode::SUCCESS) {
            QJsonArray list = root[JsonKeys::DATA].toArray();
            emit userListReceived(list);
        } else {
            emit operationResult(false, msg);
        }
    }

    if (cmd == (int)CmdType::GET_STATISTICS) {
        if (code == (int)StatusCode::SUCCESS) {
            QJsonArray list = root[JsonKeys::DATA].toArray();
            emit statisticsReceived(list);
        } else {
            emit operationResult(false, msg);
        }
    }
}
