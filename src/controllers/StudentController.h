#pragma once

#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>

#include "BaseController.h"

class StudentController : public BaseController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit StudentController(QObject *parent = nullptr);

    /**
     * @brief 获取医生列表
     */
    Q_INVOKABLE void fetchDoctorList();

    /**
     * @brief 获取医生详情
     * @param doctorId 医生ID
     */
    Q_INVOKABLE void fetchDoctorDetail(int doctorId);

    /**
     * @brief 预约医生
     */
    Q_INVOKABLE void bookAppointment(int doctorId, const QString &date, int timeSlot);

    /**
     * @brief 获取自己的预约
     */
    Q_INVOKABLE void fetchMySchedule();

    /**
     * @brief 取消预约
     */
    Q_INVOKABLE void cancelAppointment(int appointmentId);

    /**
     * @brief 提交心理测评
     */
    Q_INVOKABLE void submitSurvey(int appointmentId, const QStringList &answers);

signals:
    void doctorListReceived(const QJsonArray &doctors);
    void doctorDetailReceived(const QJsonObject &doctor);
    void scheduleReceived(const QJsonArray &schedule);

private slots:
    void onResponseReceived(const QJsonObject &data);
};
