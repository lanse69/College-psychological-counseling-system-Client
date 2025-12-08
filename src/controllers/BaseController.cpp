#include "BaseController.h"

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