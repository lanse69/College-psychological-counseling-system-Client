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
    qDebug() << "Connecting to" << ip << ":" << port;
}

bool NetworkClient::isConnected() const {
    return m_socket->state() == QAbstractSocket::ConnectedState;
}

void NetworkClient::sendRequest(const QJsonObject &data) {
    if (m_socket->state() != QAbstractSocket::ConnectedState) {
        qWarning() << "Not connected to server!";
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

    m_socket->write(packet);
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
            qWarning() << "Packet size too large:" << packetSize << "Dropping connection.";  
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
            // qDebug() << "[Client] Recv:" << doc.object();  
            emit responseReceived(doc.object());  
        } else {  
            qWarning() << "JSON Parse Error:" << parseError.errorString();  
        }  
    }
}

void NetworkClient::onConnected() {
    qDebug() << "Connected to Server successfully!";
    emit connectionStatusChanged(true);
}

void NetworkClient::onDisconnected() {
    qDebug() << "Disconnected from Server.";
    emit connectionStatusChanged(false);
}

void NetworkClient::onSocketError(QAbstractSocket::SocketError socketError) {
    qWarning() << "Socket Error:" << m_socket->errorString();
    emit connectionStatusChanged(false);
}
