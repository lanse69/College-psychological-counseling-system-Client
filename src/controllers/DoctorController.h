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
    Q_PROPERTY(QJsonObject myProfile READ myProfile NOTIFY myProfileChanged)

public:
    explicit DoctorController(QObject *parent = nullptr);

    BookingModel* appointmentModel() const;

    QJsonObject myProfile() const;

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

    // 获取个人信息
    Q_INVOKABLE void fetchMyProfile();

    // 更新个人信息
    Q_INVOKABLE void updateMyProfile(const QString &realName, const QString &password, const QString &intro, const QString &spec);

    // 获取我当前的问卷
    Q_INVOKABLE void fetchMySurvey();
    
    // 保存新问卷
    Q_INVOKABLE void saveMySurvey(const QString &title, const QVariantList &questions);

    Q_INVOKABLE void deleteAppointment(int appointmentId);

    Q_INVOKABLE void fetchAppointmentSurvey(int appointmentId);

signals:
    void patientListReceived(const QJsonArray &patients);
    void reportSubmitted();
    void scheduleMaskReceived(const QJsonObject &scheduleMap);
    /**
     * @brief 收到预约学会历史记录信号
     * @param history 包含预约记录的 JSON 数组
     */
    void patientHistoryReceived(const QJsonArray &history);
    void myProfileChanged();
    void mySurveyReceived(const QJsonObject &surveyData);
    void surveyContentReceived(const QJsonObject &data);

private slots:
    void onResponseReceived(const QJsonObject &data);
    void onNotificationReceived(const QJsonObject &data);

private:
    BookingModel* m_bookingModel;
    QJsonObject m_myProfile;
    
    QString getTimeSlotText(int slot);
    QString getStatusText(int status);
};
