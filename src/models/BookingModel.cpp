#include "BookingModel.h"

BookingModel::BookingModel(QObject *parent) : QAbstractListModel(parent)
{}

int BookingModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_displayItems.size();
}

QVariant BookingModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_displayItems.size())
        return QVariant();

    const BookingItem &item = m_displayItems[index.row()];

    switch (role) {
    case IdRole: return item.id;
    case StudentIdRole: return item.studentId;
    case StudentNameRole: return item.studentName;
    case DateRole: return item.appointmentDate;
    case TimeSlotRole: return item.timeSlot;
    case TimeSlotTextRole: return item.timeSlotText;
    case StatusRole: return item.status;
    case StatusTextRole: return item.statusText;
    case ReasonRole: return item.reason;
    default: return QVariant();
    }
}

QHash<int, QByteArray> BookingModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[StudentIdRole] = "studentId";
    roles[StudentNameRole] = "studentName";
    roles[DateRole] = "appointmentDate";
    roles[TimeSlotRole] = "timeSlot";
    roles[TimeSlotTextRole] = "timeSlotText";
    roles[StatusRole] = "status";
    roles[StatusTextRole] = "statusText";
    roles[ReasonRole] = "reason";
    return roles;
}

void BookingModel::updateData(const QVector<BookingItem> &newItems)
{
    beginResetModel(); // 通知视图即将重置，暂停刷新
    m_allItems = newItems;
    m_displayItems = newItems; // 默认显示所有（或保持当前筛选状态）
    endResetModel();   // 通知视图数据已更新，一次性重绘
}

void BookingModel::applyFilter(const QString &statusFilter)
{
    beginResetModel();
    if (statusFilter == "全部" || statusFilter.isEmpty()) {
        // "全部" 显示待确认(0)和已确认(1)，隐藏已完成(2)和已取消(3)
        m_displayItems.clear();
        for (const auto &item : m_allItems) {
            if (item.status == 0 || item.status == 1) {
                m_displayItems.append(item);
            }
        }
    } else {
        m_displayItems.clear();
        int targetStatus = -1;
        if (statusFilter == "待确认") targetStatus = 0;
        else if (statusFilter == "已确认") targetStatus = 1;
        else if (statusFilter == "已完成") targetStatus = 2;
        else if (statusFilter == "已取消") targetStatus = 3;

        for (const auto &item : m_allItems) {
            if (item.status == targetStatus) {
                m_displayItems.append(item);
            }
        }
    }
    endResetModel();
}