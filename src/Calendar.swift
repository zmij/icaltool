//
//  Calendar.swift
//  icaltool
//
//  Created by Sergei A. Fedorov on 26.04.2020.
//  Copyright © 2020 Sergei A. Fedorov. All rights reserved.
//

import Foundation
import EventKit


func get_calendar_access(store: EKEventStore) -> Bool {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
        NSLog("Authorized")
        break
    case .restricted:
        NSLog("Access resticted")
        return false
    case .denied:
        NSLog("Access denied")
        return false
    case .notDetermined:
        let group = DispatchGroup()
        var wasGranted = false
        group.enter()
        store.requestAccess(to: .event) { (granted: Bool, NSError) in
            if granted {
                NSLog("Granted")
            } else {
                NSLog("No access granted")
            }
            wasGranted = granted
            group.leave()
        }
        group.wait()
        return wasGranted
    @unknown default:
        break
    }
    return true
}

struct AccessError : Error {}

extension Calendar {
    static private let calendar : Calendar = Calendar.current
    
    static func startOfDay(date: Date) -> Date {
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
    }
    
    static func nextDay(date: Date) -> Date {
        return calendar.date(byAdding: DateComponents(day:1), to: date)!
    }
    
    static func fromNow(diff: DateComponents) -> Date {
        return calendar.date(byAdding: diff, to: Date())!
    }
}

struct CalendarTool {
    private let store : EKEventStore = EKEventStore()
    
    init() throws {
        if !get_calendar_access(store: store) {
            NSLog("No access to calendar")
            throw AccessError()
        }
    }
    
    func calendarList(calendarName: String?) -> [EKCalendar] {
        var calendars = store.calendars(for: .event)
        if let cn = calendarName {
            // Filter by name
            calendars = calendars.filter({$0.title == cn})
        }
        return calendars
    }
    
    func eventList(calendars: [EKCalendar], startAfter: Date, endBefore: Date,
                   sortOrder: EventSortOrder = .none, reverse: Bool = false,
                   filter: ((EKEvent) -> Bool)? = nil) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: startAfter, end: endBefore, calendars: calendars)
        var events : [EKEvent] = store.events(matching: predicate)
        // TODO Build a filtering predicate
        if let f =  filter {
            events = events.filter(f)
        }
        NSLog("Sort by \(sortOrder)")
        sortOrder.sort(events: &events)
        if sortOrder != .none && reverse {
            events.reverse()
        }
        return events
    }
}

