#include "BookingModel.h"

BookingModel::BookingModel(QObject *parent) : QAbstractListModel(parent), m_currentStatusFilter{"全部"}, m_currentSearchFilter("")
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
        case PendingDateRole: return item.pendingDate;
        case PendingSlotRole: return item.pendingSlot;
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
    roles[PendingDateRole] = "pendingDate";
    roles[PendingSlotRole] = "pendingSlot";
    return roles;
}

void BookingModel::updateData(const QVector<BookingItem> &newItems)
{
    m_allItems = newItems;
    applyFilter(m_currentStatusFilter, m_currentSearchFilter);
}

void BookingModel::applyFilter(const QString &statusFilter, const QString &searchFilter)
{
    m_currentStatusFilter = statusFilter;
    m_currentSearchFilter = searchFilter;

    beginResetModel();
    m_displayItems.clear();

    for (const auto &item : m_allItems) {
        // 状态过滤
        bool statusMatch = false;
        if (statusFilter == "全部" || statusFilter.isEmpty()) {
            statusMatch = true;
        } else {
            int targetStatus = -1;
            if (statusFilter == "待确认") targetStatus = 0;
            else if (statusFilter == "已确认") targetStatus = 1;
            else if (statusFilter == "已完成") targetStatus = 2;
            else if (statusFilter == "已取消") targetStatus = 3;
            
            if (item.status == targetStatus) statusMatch = true;
        }

        // 本搜索过滤 (匹配学生姓名)
        bool searchMatch = true;
        if (!searchFilter.isEmpty()) {
            // CaseInsensitive: 不区分大小写
            if (!item.studentName.contains(searchFilter, Qt::CaseInsensitive)) {
                searchMatch = false;
            }
        }

        // 同时满足才加入列表
        if (statusMatch && searchMatch) {
            m_displayItems.append(item);
        }
    }
    endResetModel();
}