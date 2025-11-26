#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QJsonObject>

#include "config/ProtocolDefs.h"

class SessionController : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString currentUsername READ currentUsername NOTIFY userInfoChanged)
    Q_PROPERTY(int currentRole READ currentRole NOTIFY userInfoChanged)

public:
    explicit SessionController(QObject *parent = nullptr);

    // 登录函数
    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void connectHost(const QString &ip, int port);

    QString currentUsername() const { return m_username; }
    int currentRole() const { return m_role; }

signals:
    void userInfoChanged();
    void loginSuccess(int role); // 登录成功信号，带上角色以便跳转
    void loginFailed(const QString &message); // 登录失败信号
    void notificationReceived(const QString &msg);
    void bookingChangeRequested(const QJsonObject &details);

private slots:
    // 接收网络层的回包
    void onResponseReceived(const QJsonObject &data);

private:
    QString m_username;
    int m_role = 0;
};