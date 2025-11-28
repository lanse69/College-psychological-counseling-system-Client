#include "SessionController.h"

#include <QDebug>

#include "network/NetworkClient.h"
#include "config/ProtocolDefs.h"

SessionController::SessionController(QObject *parent) : QObject(parent), m_role{0}, m_isConnected{false} {
    // 连接网络层的信号
    connect(&NetworkClient::instance(), &NetworkClient::responseReceived, 
            this, &SessionController::onResponseReceived);
    // 连接底层网络状态变化的信号
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

    // 构建请求 JSON
    QJsonObject req;
    req[JsonKeys::CMD] = (int)CmdType::LOGIN;
    
    QJsonObject data;
    data[JsonKeys::USERNAME] = username;
    data[JsonKeys::PASSWORD] = password; // 服务端 Hash
    
    req[JsonKeys::DATA] = data;

    // 发送请求
    if (NetworkClient::instance().isConnected()) {
        NetworkClient::instance().sendRequest(req);
    } else {
        emit loginFailed("服务端未连接. 检查IP或端口.");
    }
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
        
        // 发射信号给 QML 显示
        emit notificationReceived(msg); 

        // 特殊的协商请求 (Code 201)
        if (code == (int)StatusCode::NEGOTIATION_REQUIRED) {
            QJsonObject requestData = root[JsonKeys::DATA].toObject();
            emit bookingChangeRequested(requestData); // QML 监听此信号弹出“同意/拒绝”对话框
        }
    }
}

QString SessionController::currentUsername() const {
    return m_username;
}

int SessionController::currentRole() const {
    return m_role;
}
