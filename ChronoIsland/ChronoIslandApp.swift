//
//  ChronoIslandApp.swift
//  ChronoIsland
//
//  Created by jun on 2026/03/12.
//

import SwiftUI
import BackgroundTasks
import ActivityKit

@main
struct ChronoIslandApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "uk.jkjk.qqq.hourly-update",
            using: nil
        ) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Self.scheduleNextHourRefresh()
            }
        }
    }

    static func scheduleNextHourRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "uk.jkjk.qqq.hourly-update")
        let cal = Calendar.current
        let now = Date()
        let nextHour = cal.dateInterval(of: .hour, for: now)!.end
        request.earliestBeginDate = nextHour
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BGTask schedule failed: \(error)")
        }
    }

    static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // 次回もスケジュール
        scheduleNextHourRefresh()

        let now = Date()
        let hourStart = Calendar.current.dateInterval(of: .hour, for: now)!.start
        let state = ClockActivityAttributes.ContentState(date: now, hourStart: hourStart)
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            for activity in Activity<ClockActivityAttributes>.activities {
                await activity.update(content)
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }
}
