#include "SessionController.h"

#include <QCryptographicHash>
#include <QDebug>

#include "network/NetworkClient.h"
#include "network/PacketDispatcher.h"
#include "config/ProtocolDefs.h"

SessionController::SessionController(QObject *parent) : BaseController(parent), m_role{0}, m_isConnected{false} {
    // 监听 Dispatcher
    connect(&PacketDispatcher::instance(), &PacketDispatcher::onAuthResponse,
            this, &SessionController::onResponseReceived);
    
    // 通知单独监听
    connect(&PacketDispatcher::instance(), &PacketDispatcher::onNotification,
            this, &SessionController::onResponseReceived);

    connect(&NetworkClient::instance(), &NetworkClient::connectionStatusChanged,
            this, &SessionController::onNetStatusChanged);
}

void SessionController::connectHost(const QString &ip, const int port) {
    if (NetworkClient::instance().isConnected()) {
        qDebug() << "已连接, 跳过连接主机.";
        return;
    }
    NetworkClient::instance().connectToServer(ip, port);
}

void SessionController::onNetStatusChanged(bool connected) {
    if (m_isConnected != connected) {
        m_isConnected = connected;
        emit connectionStatusChanged(connected);
    }
}

bool SessionController::isConnected() const {
    return m_isConnected;
}

void SessionController::login(const QString &username, const QString &password) {
    // 登录前检查连接状态
    if (!m_isConnected) {
        emit loginFailed("未连接服务器，请检查 IP 设置");
        return;
    }
    
    if (username.isEmpty() || password.isEmpty()) {
        emit loginFailed("用户名或密码不能为空");
        return;
    }

    // 客户端先进行一次 Hash，避免明文传输
    QString passwordHash = QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());

    QJsonObject data;
    data[JsonKeys::USERNAME] = username;
    data[JsonKeys::PASSWORD] = passwordHash; // Hash
    
    sendRequest(CmdType::LOGIN, data);
}

void SessionController::onResponseReceived(const QJsonObject &root) {
    int cmd = root[JsonKeys::CMD].toInt();
    
    // 处理登录相关的回包
    if (cmd == (int)CmdType::LOGIN) {
        int code = root[JsonKeys::CODE].toInt();
        if (code == (int)StatusCode::SUCCESS) {
            QJsonObject data = root[JsonKeys::DATA].toObject();
            m_username = data[JsonKeys::USERNAME].toString();
            m_role = data[JsonKeys::ROLE].toInt();
            
            emit userInfoChanged();
            emit loginSuccess(m_role);
        } else {
            QString msg = root[JsonKeys::MSG].toString();
            emit loginFailed(msg);
        }
    } else if (cmd == (int)CmdType::PUSH_NOTIFICATION) { // 处理推送通知
        QString msg = root[JsonKeys::MSG].toString();
        int code = root[JsonKeys::CODE].toInt();
        
        if (code == (int)StatusCode::CONFLICT) { // 被踢下线
            emit sessionKicked(msg);
        } else if (code == (int)StatusCode::NEGOTIATION_REQUIRED) { // 协商修改
            QJsonObject requestData = root[JsonKeys::DATA].toObject();
            emit bookingChangeRequested(requestData);
        } else { // 普通通知
            emit notificationReceived(msg);
        }
    }
}

QString SessionController::currentUsername() const {
    return m_username;
}

int SessionController::currentRole() const {
    return m_role;
}
