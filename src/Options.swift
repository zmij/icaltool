//
//  Options.swift
//  icaltool
//
//  Created by Sergei A. Fedorov on 26.04.2020.
//  Copyright © 2020 Sergei A. Fedorov. All rights reserved.
//

import Foundation
import EventKit
import ArgumentParser

protocol Described {
    func description() -> String
}

extension Date : ExpressibleByArgument {
    public static let formats : [String] = [
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm",
        "yyyy-MM-dd",
    ]
    public init?(argument: String) {
        let formatter = DateFormatter()
        for fmt in Self.formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: argument) {
                self = date
                return
            }
        }
        self = Date()
    }
}

extension DateComponents : ExpressibleByArgument {
    public init?(argument: String) {
        self = DateComponents.durationFrom8601String(durationString: argument)
    }
}


enum EventSortOrder : ExpressibleByArgument, CaseIterable, Described {
    case none, startDate, endDate, title
    
    init?(argument: String) {
        switch argument {
        case "none":
            self = .none
            break
        case "start-date":
            self = .startDate
            break
        case "end-date":
            self = .endDate
            break
        case "title":
            self = .title
            break
        default:
            self = .none
        }
    }
    
    func description() -> String {
        switch self {
        case .none:
            return "none"
        case .startDate:
            return "start-date"
        case .endDate:
            return "end-date"
        case .title:
            return "title"
        }
    }
    
    func sort( events: inout [EKEvent]) -> Void {
        switch self {
        case .startDate:
            events.sort(by: { $0.startDate ?? Date.distantPast < $1.startDate ?? Date.distantPast })
            break
        case .endDate:
            events.sort(by: { $0.endDate ?? Date.distantFuture < $1.endDate ?? Date.distantFuture })
            break
        case .title:
            events.sort(by: { $0.title ?? "" < $1.title ?? "" })
            break
        default:
            break
        }
    }
}

enum FilterOption : ExpressibleByArgument, CaseIterable, Described {
    case show, dontShow, only
    
    init?(argument: String) {
        switch argument {
        case "show":
            self = .show
            break
        case "dont-show":
            self = .dontShow
            break
        case "only":
            self = .only
            break
        default:
            self = .show
        }
    }
    
    func description() -> String {
        switch self {
        case .show:
            return "show"
        case .dontShow:
            return "dont-show"
        case .only:
            return "only"
        }
    }
    
    func filter(flag: Bool) -> Bool {
        switch self {
        case .show:
            return true
        case .dontShow:
            return !flag
        case .only:
            return flag
        }
    }
}

struct EnumOption<Enum: CaseIterable> {
    static func description() -> String {
        Enum.allCases.map({"\($0)"}).joined(separator: ", ")
    }
}

extension EnumOption where Enum : Described {
    static func description() -> String {
        Enum.allCases.map({"\($0.description())"}).joined(separator: ", ")
    }
}



