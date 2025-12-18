#include "BookingModel.h"

BookingModel::BookingModel(QObject *parent) : QAbstractListModel(parent), m_currentFilter{"全部"}
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
    
    applyFilter(m_currentFilter);
}

void BookingModel::applyFilter(const QString &statusFilter)
{
    m_currentFilter = statusFilter;
    beginResetModel();
    m_displayItems.clear();
    if (statusFilter == "全部" || statusFilter.isEmpty()) {
        m_displayItems = m_allItems; 
    } else {
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