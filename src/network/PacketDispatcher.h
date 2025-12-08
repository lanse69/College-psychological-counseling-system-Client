#pragma once

#include <QObject>
#include <QJsonObject>
#include <QMap>

class PacketDispatcher : public QObject
{
    Q_OBJECT
public:
    static PacketDispatcher& instance();

signals:
    void onAuthResponse(const QJsonObject& data);
    void onAdminResponse(const QJsonObject& data);
    void onBookingResponse(const QJsonObject& data);
    void onDoctorResponse(const QJsonObject& data);
    void onStudentResponse(const QJsonObject& data);

    // 推送通知
    void onNotification(const QJsonObject& data);

private slots:
    void dispatch(const QJsonObject& data);

private:
    explicit PacketDispatcher(QObject* parent = nullptr);
};
