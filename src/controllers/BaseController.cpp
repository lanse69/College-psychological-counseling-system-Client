#include "BaseController.h"

#include <QCryptographicHash>

#include "network/NetworkClient.h"

BaseController::BaseController(QObject *parent) : QObject(parent)
{}

void BaseController::sendRequest(CmdType cmd, const QJsonObject &data)
{
    QJsonObject req;
    req[JsonKeys::CMD] = static_cast<int>(cmd);
    
    if (!data.isEmpty()) {
        req[JsonKeys::DATA] = data;
    }

    NetworkClient::instance().sendRequest(req);
}

QString BaseController::hashPassword(const QString &rawPassword)
{
    if (rawPassword.isEmpty()) return "";
    return QString(QCryptographicHash::hash(rawPassword.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QStringList BaseController::timeSlots() const {
    QStringList list;
    for (int i = 0; i < TIME_SLOT_COUNT; ++i) {
        list.append(GetTimeSlotText(i));
    }
    return list;
}