#pragma once

#include <QObject>
#include <QTcpSocket>
#include <QJsonObject>
#include <QJsonDocument>
#include <QDataStream>

class NetworkClient : public QObject {
    Q_OBJECT
public:
    static NetworkClient& instance(); // 单例访问

    void connectToServer(const QString &ip, int port);
    void sendRequest(const QJsonObject &data);
    bool isConnected() const;

signals:
    // 收到服务端响应，分发给 Controller
    void responseReceived(const QJsonObject &data);
    void connectionStatusChanged(bool isConnected);

private slots:
    void onReadyRead();
    void onSocketError(QAbstractSocket::SocketError socketError);
    void onConnected();
    void onDisconnected();

private:
    explicit NetworkClient(QObject *parent = nullptr);
    ~NetworkClient();
    NetworkClient(const NetworkClient&) = delete;
    NetworkClient& operator=(const NetworkClient&) = delete;

    QTcpSocket *m_socket;
    QByteArray m_buffer;
};
