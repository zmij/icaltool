//
//  main.swift
//  icaltool
//
//  Created by Sergei A. Fedorov on 24.04.2020.
//  Copyright © 2020 Sergei A. Fedorov. All rights reserved.
//

import Foundation
import EventKit
import ArgumentParser

protocol EventFilter {
    var calendar : String? { get }
    
    var myStatus : EKParticipantStatus? { get }
    
    var allDay      : FilterOption { get }
    var recurring   : FilterOption { get }
    
    var sortOrder : EventSortOrder { get }
    var reverseOrder: Bool { get }
    
    var showAttendees : Bool{ get }
    var showRecurrencyRules : Bool { get }
    
    var dateFormat : String{ get }
    
    func startAfter() -> Date
    func endBefore() -> Date
    
    func getFilter() -> ((EKEvent) -> Bool)?
}

extension EventFilter {
    static func makeFilter(status: EKParticipantStatus?,
                           allDay: FilterOption, recurring: FilterOption,
                           and: ((EKEvent) -> Bool)? = nil) -> ((EKEvent) -> Bool)? {
        if (allDay != .show) || (recurring != .show) || and != nil {
            return {
                (allDay.filter(flag: $0.isAllDay))
                && (recurring.filter(flag: $0.hasRecurrenceRules))
                && (and == nil || and!($0))
                && (status == nil || $0.myStatus() == status!)
            }
        }
        return nil
    }
    func startAfter() -> Date {
        return Calendar.startOfDay(date: Date())
    }
    func endBefore() -> Date {
        return Calendar.nextDay(date: startAfter())
    }
    func getFilter() -> ((EKEvent) -> Bool)? {
        return Self.makeFilter(status: myStatus, allDay: allDay, recurring: recurring)
    }
    
    func printEvents() throws {
        EKEvent.serializeAttendees = showAttendees
        EKEvent.showRecurrencyRules = showRecurrencyRules
        IcalJsonOutput.dateFormat = dateFormat
        
        let tool = try CalendarTool()
        let cc = tool.calendarList(calendarName: calendar)
        let events = tool.eventList(calendars: cc,
                                    startAfter: startAfter(),
                                    endBefore: endBefore(),
                                    sortOrder: sortOrder, reverse: reverseOrder,
                                    filter: getFilter())
        let encoder = JSONEncoder()
        let json_data = try encoder.encode(events)
        print(String(data: json_data, encoding: .utf8) ?? "")
    }
}

class CalendarCommand : ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Outputs events from calendar to console",
        subcommands: [Events.self, ListCalendars.self, ListDateFormats.self],
        defaultSubcommand: Events.self
    )
    required init() {}
}

extension CalendarCommand {
    struct ListCalendars : ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List calendars"
        )
        func run() throws {
            let tool = try CalendarTool()
            
            let cc = tool.calendarList(calendarName: nil)
            let encoder = JSONEncoder()
            let json_data = try encoder.encode(cc)
            print(String(data: json_data, encoding: .utf8) ?? "")
        }
    }
    struct ListDateFormats : ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List supported input date formats"
        )
        func run() throws {
            print(Date.formats.joined(separator: "\n"))
        }
    }
    struct Events : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Display events in a range of dates",
            subcommands: [Now.self, Today.self, At.self, In.self, On.self],
            defaultSubcommand: Today.self
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?

        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?
        
        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Sort in reverse order")
        var reverseOrder: Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        @Option(name: .long, help: "Events starting after, in ISO 8601 format (\(IcalJsonOutput.dateFormat))")
        var start : Date?
        @Option(name: .long, help: "Events ending before, in ISO 8601 format (\(IcalJsonOutput.dateFormat))")
        var end : Date?
        
        func startAfter() -> Date {
            return start!
        }
        func endBefore() -> Date {
            return end!
        }
        
        func run() throws {
            guard start != nil else {
                throw ValidationError("Missing expected argument '--start <date>'")
            }
            guard end != nil else {
                throw ValidationError("Missing expected argument '--start <date>'")
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "\(IcalJsonOutput.dateFormat)"
            NSLog("Events from \(formatter.string(from: start!)) to \(formatter.string(from: end!)) sort by \(sortOrder)")
            try printEvents()
        }
    }
}

extension CalendarCommand.Events {
    struct Today : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Events happening today"
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?
        
        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?

        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Sort in reverse order")
        var reverseOrder : Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        func run() throws {
            NSLog("Today sort by \(sortOrder)")
            try printEvents()
        }
    }
    
    struct Now : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Events happening now"
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?
        
        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?

        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Show all-day events")
        var reverseOrder : Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        func getFilter() -> ((EKEvent) -> Bool)? {
            let now = Date()
            return Self.makeFilter(status: myStatus, allDay: allDay, recurring: recurring,
                                   and: { $0.startDate ?? Date.distantPast <= now
                                        && now < $0.endDate ?? Date.distantFuture})
        }

        func run() throws {
            NSLog("Now sort by \(sortOrder)")
            try printEvents()
        }
    }
    
    struct On : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Events happening on a specific date"
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?
        
        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?

        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Show all-day events")
        var reverseOrder : Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        @Argument(help: "Date string in ISO 8601 format (\(IcalJsonOutput.dateFormat))")
        var date : Date
        
        func startAfter() -> Date {
            return Calendar.startOfDay(date: date)
        }
        
        func run() throws {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            NSLog("At \(formatter.string(from: date)) sort by \(sortOrder)")
            try printEvents()
        }
    }

    struct In : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Events happening soon"
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?
        
        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?

        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Show all-day events")
        var reverseOrder : Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        @Argument(help: "Time distance from now, in ISO 8601 format (e.g. PT5M)")
        var diff : DateComponents
                
        func startAfter() -> Date {
            return Calendar.fromNow(diff: diff)
        }

        func getFilter() -> ((EKEvent) -> Bool)? {
            let date = Calendar.fromNow(diff: diff)
            return Self.makeFilter(status: myStatus, allDay: allDay, recurring: recurring,
                                   and: { $0.startDate ?? Date.distantPast <= date
                                    && date < $0.endDate ?? Date.distantFuture})
        }

        func run() throws {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            NSLog("At \(formatter.string(from: Calendar.fromNow(diff: diff))) sort by \(sortOrder)")
            try printEvents()
        }
    }

    struct At : ParsableCommand, EventFilter {
        static let configuration = CommandConfiguration(
            abstract: "Events happening at a certain point of time"
        )
        // TODO Refactor this buggers
        @Option(name: .shortAndLong, help: "Name of calendar to use")
        var calendar: String?
        
        @Option(name: .shortAndLong, help: "Show only events with my status equal to specified")
        var myStatus : EKParticipantStatus?

        @Option(name: [.customShort("a"), .long], default: .show, help: "Filter all-day events (available options \(EnumOption<FilterOption>.description()))")
        var allDay: FilterOption
        @Option(name: [.customShort("u"), .long], default: .show, help: "Filter recurring events (available options \(EnumOption<FilterOption>.description()))")
        var recurring: FilterOption
        
        @Option(name: .shortAndLong, default: EventSortOrder.none, help: "Event sort order (available options \(EnumOption<EventSortOrder>.description()))")
        var sortOrder: EventSortOrder
        @Flag(name: [.customShort("r"), .customLong("reverse-order")], default: false, inversion: .prefixedNo, help: "Show all-day events")
        var reverseOrder : Bool
        
        @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Show event attendees")
        var showAttendees: Bool
        @Flag(name: .customLong("recurrence-rules"), default: false, inversion: .prefixedNo, help: "Show event recurrence rules")
        var showRecurrencyRules: Bool

        @Option(name: [.customShort("f"), .long], default: IcalJsonOutput.dateFormat, help: "Ouput date format")
        var dateFormat : String

        @Argument(help: "Date string in ISO format (\(IcalJsonOutput.dateFormat))")
        var date : Date
        
        func startAfter() -> Date {
            return Calendar.startOfDay(date: date)
        }
        
        func getFilter() -> ((EKEvent) -> Bool)? {
            return Self.makeFilter(status: myStatus, allDay: allDay, recurring: recurring,
                                   and: { $0.startDate ?? Date.distantPast <= self.date
                                    && self.date < $0.endDate ?? Date.distantFuture})
        }

        func run() throws {
            let formatter = DateFormatter()
            formatter.dateFormat = "\(IcalJsonOutput.dateFormat)"
            NSLog("At \(formatter.string(from: date)) sort by \(sortOrder)")
            try printEvents()
        }
    }
}

extension CalendarCommand {
    private static func subcommands(cmd : ParsableCommand.Type) -> Set<String> {
        var commands : Set<String> = Set(cmd.configuration.subcommands.map({$0._commandName}));
        for sub in cmd.configuration.subcommands {
            commands = commands.union(subcommands(cmd: sub))
        }
        return commands
    }
    public static func main(_ arguments: [String]? = nil) -> Never {
        do {
            let arguments = arguments ?? Array(CommandLine.arguments.dropFirst())
            var command = try parseAsRoot(arguments)
            let cmd_type = type(of: command)
            if cmd_type != CalendarCommand.self && cmd_type._commandName != "help" {
                let cmd_names = subcommands(cmd: CalendarCommand.self)
                let args = arguments.filter({ !cmd_names.contains($0) })
                command = try type(of: command).parse(args)
            }
            try command.run()
            exit()
        } catch {
            exit(withError: error)
        }
    }
}

CalendarCommand.main()
