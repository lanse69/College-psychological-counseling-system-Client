#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QVector>
#include <QDate>

struct BookingItem {
    int id;
    int studentId;
    QString studentName;
    QString appointmentDate;
    int timeSlot;
    int status;
    QString reason;
    QString timeSlotText; 
    QString statusText;
    QString pendingDate;
    int pendingSlot = -1;
};

class BookingModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum BookingRoles {
        IdRole = Qt::UserRole + 1,
        StudentIdRole,
        StudentNameRole,
        DateRole,
        TimeSlotRole,
        TimeSlotTextRole,
        StatusRole,
        StatusTextRole,
        ReasonRole,
        PendingDateRole = Qt::UserRole + 10,
        PendingSlotRole
    };

    explicit BookingModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const QVector<BookingItem> &newItems);

    Q_INVOKABLE void applyFilter(const QString &statusFilter, const QString &searchFilter = "");

private:
    QVector<BookingItem> m_allItems;    // 存储所有数据
    QVector<BookingItem> m_displayItems; // 存储当前显示的数据(经过筛选)
    QString m_currentStatusFilter;
    QString m_currentSearchFilter;
};