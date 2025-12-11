#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>

#include "BaseController.h"

class AdminController : public BaseController {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit AdminController(QObject *parent = nullptr);

    /**
     * @brief 添加用户
     * @param role 1=Student, 2=Doctor
     */
    Q_INVOKABLE void addUser(const QString &username, const QString &password,
                             int role, const QString &realName,
                             const QString &intro, const QString &spec);

    /**
     * @brief 删除用户
     */
    Q_INVOKABLE void deleteUser(int targetId);

    /**
     * @brief 修改用户信息 (管理员权限)
     * @param password 若为空字符串，则不修改密码
     */
    Q_INVOKABLE void updateUserInfo(int targetId, const QString &realName, const QString &password,
                                    const QString &intro, const QString &spec);

    /**
     * @brief 获取用户列表
     */
    Q_INVOKABLE void fetchUserList();

    /**
     * @brief 获取统计数据
     */
    Q_INVOKABLE void fetchStatistics(const QString &type);

signals:
    void userListReceived(const QJsonArray &users);
    void statisticsReceived(const QJsonArray &data);

private slots:
    void onResponseReceived(const QJsonObject &data);
};
