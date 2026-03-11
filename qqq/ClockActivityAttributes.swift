//
//  ClockActivityAttributes.swift
//  qqq
//

import ActivityKit
import Foundation

struct ClockActivityAttributes: ActivityAttributes {
    static let activityType = "uk.jkjk.qqq.clock"

    struct ContentState: Codable, Hashable {
        var date: Date
        var hourStart: Date
    }
}
