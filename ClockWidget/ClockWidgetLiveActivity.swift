//
//  ClockWidgetLiveActivity.swift
//  ClockWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ClockActivityAttributes: ActivityAttributes {
    static let activityType = "uk.jkjk.qqq.clock"

    struct ContentState: Codable, Hashable {
        var date: Date
        var hourStart: Date  // 現在の時間の開始時刻（分:秒タイマー基準）
    }
}

struct ClockWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockActivityAttributes.self) { context in
            // ロック画面 / バナー表示
            HStack(spacing: 16) {
                Text(context.state.date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(context.state.hourStart, style: .timer)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
            }
            .padding(16)
            .background(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.hourStart, style: .timer)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .monospacedDigit()
                }
            } compactLeading: {
                Text(context.state.date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(context.state.hourStart, style: .timer)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
}
