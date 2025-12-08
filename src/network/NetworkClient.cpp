#include "NetworkClient.h"

#include <QDebug>

#include "config/ProtocolDefs.h" // 引用协议定义

NetworkClient& NetworkClient::instance() {
    static NetworkClient _instance;
    return _instance;
}

NetworkClient::NetworkClient(QObject *parent) : QObject(parent) {
    m_socket = new QTcpSocket(this);

    connect(m_socket, &QTcpSocket::readyRead, this, &NetworkClient::onReadyRead);
    connect(m_socket, &QTcpSocket::connected, this, &NetworkClient::onConnected);
    connect(m_socket, &QTcpSocket::disconnected, this, &NetworkClient::onDisconnected);
    connect(m_socket, &QTcpSocket::errorOccurred, this, &NetworkClient::onSocketError);
}

NetworkClient::~NetworkClient() {
    m_socket->abort();
}

void NetworkClient::connectToServer(const QString &ip, int port) {
    m_socket->abort(); // 取消之前的连接
    m_socket->connectToHost(ip, port);
    qDebug() << "连接到" << ip << ":" << port;
}

bool NetworkClient::isConnected() const {
    return m_socket->state() == QAbstractSocket::ConnectedState;
}

void NetworkClient::sendRequest(const QJsonObject &data) {
    if (m_socket->state() != QAbstractSocket::ConnectedState) {
        qWarning() << "未连接服务端!";
        return;
    }

    QJsonDocument doc(data);
    QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

    QByteArray packet;
    QDataStream out(&packet, QIODevice::WriteOnly);
    out.setVersion(QDataStream::Qt_6_0);

    // 协议：[长度 4字节][JSON数据]
    out << (quint32)jsonData.size();
    packet.append(jsonData);

    qint64 bytesWritten = m_socket->write(packet);
    if (bytesWritten == -1) {
        qWarning() << "发送数据失败:" << m_socket->errorString();
    }
    m_socket->flush();
}

void NetworkClient::onReadyRead() {
    // 粘包处理逻辑
    m_buffer.append(m_socket->readAll());

    while (m_buffer.size() >= PACKET_HEAD_SIZE) {  
        QDataStream stream(m_buffer);  
        stream.setVersion(QDataStream::Qt_6_0);  
          
        quint32 packetSize = 0;  
        stream >> packetSize;  
  
        // 如果包过大，认为是异常数据，断开连接并清空缓冲  
        if (packetSize > MAX_PACKET_SIZE) {  
            qWarning() << "包大小过大:" << packetSize << " 删除连接.";
            m_socket->abort();  
            m_buffer.clear();  
            return;  
        }  
  
        // 如果缓冲区数据不足一个完整的包，等待下一次读取  
        if (m_buffer.size() < PACKET_HEAD_SIZE + packetSize) {  
            return;   
        }  
  
        // 提取数据  
        QByteArray data = m_buffer.mid(PACKET_HEAD_SIZE, packetSize);  
        m_buffer.remove(0, PACKET_HEAD_SIZE + packetSize);  
  
        QJsonParseError parseError;  
        QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);  
        if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
            emit responseReceived(doc.object());  
        } else {  
            qWarning() << "JSON 解析失败:" << parseError.errorString();
        }  
    }
}

void NetworkClient::onConnected() {
    qDebug() << "连接服务端成功!";
    emit connectionStatusChanged(true);
}

void NetworkClient::onDisconnected() {
    qDebug() << "从服务端断开连接.";
    emit connectionStatusChanged(false);
}

void NetworkClient::onSocketError(QAbstractSocket::SocketError socketError) {
    QString errorMsg;
    switch (socketError) {
    case QAbstractSocket::ConnectionRefusedError:
        errorMsg = "连接被拒绝，请检查服务端是否启动或IP端口是否正确。";
        break;
    case QAbstractSocket::RemoteHostClosedError:
        errorMsg = "服务端关闭了连接。";
        break;
    case QAbstractSocket::HostNotFoundError:
        errorMsg = "找不到主机地址。";
        break;
    default:
        errorMsg = QString("网络错误: %1").arg(m_socket->errorString());
        break;
    }
    qWarning() << errorMsg;
    emit connectionStatusChanged(false);
}
