#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QJsonObject>

class SessionController : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString currentUsername READ currentUsername NOTIFY userInfoChanged)
    Q_PROPERTY(int currentRole READ currentRole NOTIFY userInfoChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)

public:
    explicit SessionController(QObject *parent = nullptr);

    // 登录函数
    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void connectHost(const QString &ip, int port = 9999);

    QString currentUsername() const;
    int currentRole() const;
    bool isConnected() const;

signals:
    void userInfoChanged();
    void loginSuccess(int role); // 登录成功信号
    void loginFailed(const QString &message); // 登录失败信号
    void notificationReceived(const QString &msg);
    void bookingChangeRequested(const QJsonObject &details);
    void connectionStatusChanged(bool connected);
    void sessionKicked(const QString &reason);

private slots:
    // 接收网络层的回包
    void onResponseReceived(const QJsonObject &data);
    // 处理底层网络状态变化
    void onNetStatusChanged(bool connected);

private:
    QString m_username;
    int m_role;
    bool m_isConnected;
};
