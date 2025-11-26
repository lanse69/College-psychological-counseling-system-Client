#include "SessionController.h"

#include <QDebug>

#include "network/NetworkClient.h"

SessionController::SessionController(QObject *parent) : QObject(parent) {
    // 连接网络层的信号
    connect(&NetworkClient::instance(), &NetworkClient::responseReceived, 
            this, &SessionController::onResponseReceived);
}

void SessionController::connectHost(const QString &ip, const int port = 9999) {
    NetworkClient::instance().connectToServer(ip, port);
}

void SessionController::login(const QString &username, const QString &password) {
    // 登录前检查连接状态
    if (!NetworkClient::instance().isConnected()) {
        qDebug() << "请确认服务端的IP未变化";
        emit loginFailed("正在连接服务器，请稍后重试...");
        return;
    }
    
    if (username.isEmpty() || password.isEmpty()) {
        emit loginFailed("Username or password cannot be empty");
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
        emit loginFailed("Server not connected. Check IP/Port.");
    }
}

void SessionController::onResponseReceived(const QJsonObject &root) {
    int cmd = root[JsonKeys::CMD].toInt();
    
    // 处理登录相关的回包
    if (cmd == (int)CmdType::LOGIN) {
        int code = root[JsonKeys::CODE].toInt();
        if (code == 200) {
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
        if (code == 201) {
            QJsonObject requestData = root[JsonKeys::DATA].toObject();
            emit bookingChangeRequested(requestData); // QML 监听此信号弹出“同意/拒绝”对话框
        }
    }
}