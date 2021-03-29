//
//  Date+Extensions.swift
//  Test
//
//  Created by Dmitry Yaskel on 28.03.2021.
//

import Foundation

extension Date {
    static func dateDaysAgo(_ daysAgoCount: Int) -> Date {
        return Date(timeIntervalSinceNow: -60 * 60 * 24 * Double(daysAgoCount))
    }
    
    static func startDateForPeriod(_ period: Period) -> Date {
        switch period {
        case .week:
            return Date().startOfWeek()
        case .month:
            return Date().startOfMonth()
        case .year:
            return Date().startOfYear()
        }
    }
    
    static func daysInPeriod(_ period: Period) -> Int {
        let calendar = Calendar.current
        let date = Date()
        
        let dateInterval: DateInterval
        switch period {
        case .week:
            dateInterval = calendar.dateInterval(of: .weekOfYear, for: date)!
        case .month:
            dateInterval = calendar.dateInterval(of: .month, for: date)!
        case .year:
            dateInterval = calendar.dateInterval(of: .year, for: date)!
        }
        return calendar.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day!
    }
}

extension Date {
    func byAdding(component: Calendar.Component, value: Int, wrappingComponents: Bool = false, using calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: component, value: value, to: self, wrappingComponents: wrappingComponents)
    }
    func dateComponents(_ components: Set<Calendar.Component>, using calendar: Calendar = .current) -> DateComponents {
        calendar.dateComponents(components, from: self)
    }
    func startOfYear(using calendar: Calendar = .current) -> Date {
        Date.dateDaysAgo(365)
    }
    func startOfMonth(using calendar: Calendar = .current) -> Date {
        Date.dateDaysAgo(31)
//        calendar.date(from: dateComponents([.year, .month], using: calendar))!
    }
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        Date.dateDaysAgo(6)
//        calendar.date(from: dateComponents([.yearForWeekOfYear, .weekOfYear], using: calendar))!
    }
    var noon: Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    func daysOfPeriod(_ period: Period, using calendar: Calendar = .current) -> [Date] {
        let startDate = Date.startDateForPeriod(period)
        let daysInPeriod = Date.daysInPeriod(period)
        return (0...daysInPeriod).map { startDate.byAdding(component: .day, value: $0, using: calendar)! }
    }
}
