import Foundation

/// Pure monthly-quota state. Period is anchored to the subscription start and
/// rolls forward one calendar month at a time, resetting usage each roll.
struct QuotaState: Equatable {
    var usedThisPeriod: Int
    var periodStart: Date?

    func remaining(quota: Int) -> Int { max(0, quota - usedThisPeriod) }

    func consuming() -> QuotaState {
        QuotaState(usedThisPeriod: usedThisPeriod + 1, periodStart: periodStart)
    }

    /// Roll the period forward (resetting usage) for every whole period elapsed
    /// since `periodStart`. No-op if `periodStart` is nil or still in-period.
    func advancing(now: Date, unit: Calendar.Component = .month, calendar: Calendar = .current) -> QuotaState {
        guard var start = periodStart else { return self }
        var used = usedThisPeriod
        while let next = calendar.date(byAdding: unit, value: 1, to: start), next <= now {
            start = next
            used = 0
        }
        return QuotaState(usedThisPeriod: used, periodStart: start)
    }
}
