//
//  ClockActivityAttributes.swift
//  ChronoIsland
//

import ActivityKit
import Foundation

struct ClockActivityAttributes: ActivityAttributes {
    static let activityType = "uk.jkjk.ChronoIsland.clock"

    struct ContentState: Codable, Hashable {
        var date: Date
        var hourStart: Date
    }
}
