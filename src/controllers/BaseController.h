#pragma once

#include <QObject>
#include <QJsonObject>
#include <QStringList>

#include "config/ProtocolDefs.h"

class BaseController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList timeSlots READ timeSlots CONSTANT)
public:
    explicit BaseController(QObject *parent = nullptr);

    // 动态生成时间段字符串
    QStringList timeSlots() const;
    
signals:
    void operationResult(bool success, const QString &msg);

protected:
    /**
     * @brief 发送请求
     * @param cmd 指令类型
     * @param data 数据对象
     */
    void sendRequest(CmdType cmd, const QJsonObject &data = {});

    // 密码哈希
    QString hashPassword(const QString &rawPassword);
};