#pragma once

#include <QObject>
#include <QJsonObject>

#include "config/ProtocolDefs.h"

class BaseController : public QObject
{
    Q_OBJECT
public:
    explicit BaseController(QObject *parent = nullptr);

signals:
    void operationResult(bool success, const QString &msg);

protected:
    /**
     * @brief 统一发送请求的辅助函数
     * @param cmd 指令类型
     * @param data 数据对象
     */
    void sendRequest(CmdType cmd, const QJsonObject &data = {});
};