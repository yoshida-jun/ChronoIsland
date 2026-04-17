//
//  ClockWidgetLiveActivity.swift
//  ClockWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ClockWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockActivityAttributes.self) { context in
            // ロック画面 / バナー表示
            HStack(spacing: 12) {
                Text(context.state.date, format: .dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 0) {
                    Text(context.state.hourStart, format: .dateTime.hour(.twoDigits(amPM: .omitted)))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    Text(":")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    Text(timerInterval: context.state.hourStart...context.state.hourStart.addingTimeInterval(3600), countsDown: false)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .monospacedDigit()
                }
            }
            .padding(16)
            .background(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ZStack(alignment: .leading) {
                        Text(timerInterval: context.state.minuteStart...context.state.minuteStart.addingTimeInterval(60), countsDown: false)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .monospacedDigit()
                        Text("0:")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            } compactLeading: {
                TimelineView(.periodic(from: .distantPast, by: 1)) { timeline in
                    let sec = Calendar.current.component(.second, from: timeline.date)
                    Text(String(format: "%02d", sec))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .monospacedDigit()
                }
            } compactTrailing: {
                Text(context.state.date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
}
