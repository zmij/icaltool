//
//  CalendarSerialisation.swift
//  icaltool
//
//  Created by Sergei A. Fedorov on 25.04.2020.
//  Copyright © 2020 Sergei A. Fedorov. All rights reserved.
//

import Foundation
import EventKit
import ArgumentParser

struct IcalJsonOutput {
    public static var dateFormat : String = "yyyy-MM-dd'T'HH:mm::ssZZZZZ"
}

extension CGColor {
    func description() -> String {
        if let components = self.components {
            var color = "#"
            for c in components {
                color += String(format: "%02x", Int(c * 255))
            }
            return color
        }
        return "#000"
    }
}

extension EKEventStatus {
    func description() -> String {
        switch self {
        case .none:
            return "none"
        case .confirmed:
            return "confirmed"
        case .tentative:
            return "tentative"
        case .canceled:
            return "canceled"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKEventAvailability {
    func description() -> String {
        switch self {
        case .notSupported:
            return "not supported"
        case .busy:
            return "busy"
        case .free:
            return "free"
        case .tentative:
            return "tentative"
        case .unavailable:
            return "unavailable"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKParticipantStatus {
    func description() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .pending:
            return "pending"
        case .accepted:
            return "accepted"
        case .declined:
            return "declined"
        case .tentative:
            return "tentative"
        case .delegated:
            return "delegated"
        case .completed:
            return "completed"
        case .inProcess:
            return "in process"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKParticipantStatus : ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "unknown":
            self = .unknown
            break
        case "pending":
            self = .pending
            break
        case "accepted":
            self = .accepted
            break
        case "declined":
            self = .declined
            break
        case "tentative":
            self = .tentative
            break
        case "delegated":
            self = .delegated
            break
        case "competed":
            self = .completed
            break
        case "in process":
            self = .inProcess
            break
        default:
            self = .unknown
            break
        }
    }
}


extension EKParticipantRole {
    func description() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .required:
            return "required"
        case .optional:
            return "optional"
        case .chair:
            return "chair"
        case .nonParticipant:
            return "non participant"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKParticipantType {
    func description() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .person:
            return "person"
        case .room:
            return "room"
        case .resource:
            return "resource"
        case .group:
            return "group"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKParticipant : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
        try container.encode(participantStatus.description(), forKey: .status)
        try container.encode(participantRole.description(), forKey: .role)
        try container.encode(participantType.description(), forKey: .type)
        try container.encode(isCurrentUser, forKey: .current_user)
    }
    enum CodingKeys: String, CodingKey {
        case url        = "url"
        case name       = "name"
        case status      = "status"
        case role        = "role"
        case type        = "type"
        case current_user = "current_user"
    }
}

extension EKRecurrenceFrequency {
    func description() -> String {
        switch self {
        case .daily:
            return "daily"
        case .weekly:
            return "weekly"
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        @unknown default:
            return String(self.rawValue)
        }
    }
}

extension EKRecurrenceEnd : Encodable {
    public func encode(to encoder: Encoder) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = IcalJsonOutput.dateFormat
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(occurrenceCount, forKey: .occurenceCount)
        if let date = endDate {
            try container.encode(formatter.string(from: date), forKey: .endDate)
        }
    }
    enum CodingKeys : String, CodingKey {
        case endDate = "end-date"
        case occurenceCount = "occurence-count"
    }
}

extension EKWeekday {
    func description() -> String {
        switch self {
        case .sunday:
            return "sunday"
        case .monday:
            return "monday"
        case .tuesday:
            return "tuesday"
        case .wednesday:
            return "wednesday"
        case .thursday:
            return "thursday"
        case .friday:
            return "friday"
        case .saturday:
            return "saturday"
        }
    }
}

extension EKRecurrenceDayOfWeek : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dayOfTheWeek.description(), forKey: .dayOfTheWeek)
        try container.encode(weekNumber, forKey: .weekNumber)
    }
    
    enum CodingKeys : String, CodingKey {
        case dayOfTheWeek = "day-of-the-week"
        case weekNumber = "week-number"
    }
}

extension NSNumber : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.intValue)
    }
}

extension EKRecurrenceRule : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recurrenceEnd, forKey: .reccurenceEnd)
        try container.encode(frequency.description(), forKey: .frequency)
        try container.encode(interval, forKey: .interval)
        try container.encode(firstDayOfTheWeek, forKey: .firstDayOfTheWeek)
        if let dow = daysOfTheWeek {
            try container.encode(dow, forKey: .daysOfTheWeek)
        }
        if let dom = daysOfTheMonth {
            try container.encode(dom, forKey: .daysOfTheMonth)
        }
        if let doy = daysOfTheYear {
            try container.encode(doy, forKey: .daysOfTheYear)
        }
        if let woy = weeksOfTheYear {
            try container.encode(woy, forKey: .weeksOfTheYear)
        }
        if let moy = monthsOfTheYear {
            try container.encode(moy, forKey: .monthsOfTheYear)
        }
        if let sp = setPositions {
            try container.encode(sp, forKey: .setPositions)
        }
    }
    enum CodingKeys : String, CodingKey {
        case reccurenceEnd = "reccurence-end"
        case frequency = "frequency"
        case interval = "interval"
        case firstDayOfTheWeek = "first-day-of-the-week"
        case daysOfTheWeek = "days-of-the-week"
        case daysOfTheMonth = "days-of-the-month"
        case daysOfTheYear = "days-of-the-year"
        case weeksOfTheYear = "weeks-of-the-year"
        case monthsOfTheYear = "months-of-the-year"
        case setPositions = "setPositions"
    }
}

extension EKEvent : Encodable {
    public static var serializeAttendees : Bool = false
    public static var showRecurrencyRules : Bool = true

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = DateFormatter()
        formatter.dateFormat = IcalJsonOutput.dateFormat
        
        try container.encode(eventIdentifier ?? "<no identifier>", forKey: .id)
        if let calendar = calendar {
            try container.encode(calendar.calendarIdentifier, forKey: .calendar)
        }
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(location, forKey: .location)
        
        if let start = startDate {
            try container.encode(formatter.string(from: start), forKey: .start)
        }
        if let end = endDate {
            try container.encode(formatter.string(from: end), forKey: .end)
        }
        try container.encode(isAllDay, forKey: .allDay)
        try container.encode(hasRecurrenceRules, forKey: .recurrent)
        if hasRecurrenceRules && Self.showRecurrencyRules {
            try container.encode(recurrenceRules, forKey: .recurrence_rules)
            try container.encode(isDetached, forKey: .detached)
            if let occ = occurrenceDate {
                try container.encode(formatter.string(from: occ), forKey: .occurrenceDate)
            }
        }
        
        try container.encode(status.description(), forKey: .status)
        try container.encode(availability.description(), forKey: .availability)
        try container.encode(myStatus().description(), forKey: .my_status)
        if Self.serializeAttendees {
            try container.encode(attendees, forKey: .attendees)
        }
        try container.encode(organizer, forKey: .organizer)

        if let color = calendarColor() {
            try container.encode(color.description(), forKey: .color)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case calendar = "calendar-id"
        case url = "url"
        case title = "title"
        case notes = "notes"
        case start = "start"
        case end = "end"
        case allDay = "all-day"
        case recurrent = "recurrent"
        case recurrence_rules = "recurrence-rules"
        case detached = "detached"
        case occurrenceDate = "occurrence-date"
        case location = "location"
        case status = "status"
        case my_status = "my-status"
        case availability = "availabilty"
        case attendees = "attendees"
        case organizer = "organizer"
        case color = "color"
    }
}

extension EKCalendarItem {
    func myStatus() -> EKParticipantStatus {
        if hasAttendees {
            if let user = attendees!.first(where: {$0.isCurrentUser}) {
                return user.participantStatus
            }
        }
        return .unknown
    }
    func calendarColor() -> CGColor? {
        if let calendar = self.calendar {
            return calendar.cgColor
        }
        return nil
    }
}

extension EKCalendarType {
    func description() -> String {
        switch self {
        case .local:
            return "local"
        case .calDAV:
            return "calDAV"
        case .exchange:
            return "exchange"
        case .subscription:
            return "subscription"
        case .birthday:
            return "birthday"
        @unknown default:
            return String(self.rawValue)
        }
    }
}


extension EKCalendar : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(calendarIdentifier, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(type.description(), forKey: .type)
        if let color = cgColor {
            try container.encode(color.description(), forKey: .color)
        }
        try container.encode(allowsContentModifications, forKey: .allowModification)
        try container.encode(isSubscribed, forKey: .subscribed)
        try container.encode(isImmutable, forKey: .immutable)
    }
    
    enum CodingKeys : String, CodingKey {
        case id                 = "uid"
        case title              = "title"
        case type               = "type"
        case color              = "color"
        case allowModification  = "allow-content-modification"
        case subscribed         = "subscribed"
        case immutable          = "immutable"
    }
}
