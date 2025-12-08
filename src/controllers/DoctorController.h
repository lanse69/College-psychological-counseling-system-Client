#pragma once

#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>

#include "BaseController.h"
#include "models/BookingModel.h"

class DoctorController : public BaseController
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(BookingModel* appointmentModel READ appointmentModel CONSTANT)

public:
    explicit DoctorController(QObject *parent = nullptr);

    BookingModel* appointmentModel() const;

    /**
     * @brief 获取预约列表
     */
    Q_INVOKABLE void fetchAppointments();

    /**
     * @brief 确认预约
     */
    Q_INVOKABLE void confirmAppointment(int appointmentId);

    /**
     * @brief 拒绝预约
     */
    Q_INVOKABLE void rejectAppointment(int appointmentId);

    /**
     * @brief 完成咨询
     */
    Q_INVOKABLE void completeConsultation(int appointmentId);

    /**
     * @brief 获取预约学生列表
     */
    Q_INVOKABLE void fetchPatients();

    /**
     * @brief 提交咨询报告
     */
    Q_INVOKABLE void submitReport(const QJsonObject &reportData);

    Q_INVOKABLE void fetchSchedules(int year, int month);
    Q_INVOKABLE void updateSchedule(const QString &date, int mask);

    /**
     * @brief 获取特定学生的预约历史
     * @param studentId 学生ID
     */
    Q_INVOKABLE void fetchPatientHistory(int studentId);

signals:
    void patientListReceived(const QJsonArray &patients);
    void reportSubmitted();
    void scheduleMaskReceived(const QJsonObject &scheduleMap);
    /**
     * @brief 收到患者历史记录信号
     * @param history 包含预约记录的 JSON 数组
     */
    void patientHistoryReceived(const QJsonArray &history);

private slots:
    void onResponseReceived(const QJsonObject &data);

private:
    BookingModel* m_bookingModel;
    
    QString getTimeSlotText(int slot);
    QString getStatusText(int status);
};
