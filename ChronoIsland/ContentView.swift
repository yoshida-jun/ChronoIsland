//
//  ContentView.swift
//  ChronoIsland
//

import SwiftUI
import Combine
import ActivityKit
import UIKit

// MARK: - Theme

enum ClockTheme: String, CaseIterable {
    case white  = "ホワイト"
    case amber  = "アンバー"
    case green  = "グリーン"
    case blue   = "ブルー"

    var accent: Color {
        switch self {
        case .white: return .white
        case .amber: return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .green: return Color(red: 0.2, green: 1.0, blue: 0.4)
        case .blue:  return Color(red: 0.3, green: 0.7, blue: 1.0)
        }
    }

    var secondHand: Color {
        switch self {
        case .white: return Color(red: 1, green: 0.3, blue: 0.3)
        case .amber: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .green: return Color(red: 0.0, green: 1.0, blue: 0.6)
        case .blue:  return Color(red: 0.0, green: 0.8, blue: 1.0)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var showDigital = true
    @State private var liveActivity: Activity<ClockActivityAttributes>?
    @State private var activityUpdateTask: Task<Void, Never>?
    @State private var theme: ClockTheme = .white

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            clockTab
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("時計")
                }

            WorldClockView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("世界時計")
                }

            StopwatchView()
                .tabItem {
                    Image(systemName: "stopwatch.fill")
                    Text("ストップウォッチ")
                }
        }
        .tint(theme.accent)
        .onReceive(timer) { _ in
            currentTime = Date()
            updateLiveActivity()
        }
        .onAppear {
            startLiveActivity()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Clock Tab

    private var clockTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Group {
                    if showDigital {
                        DigitalClockView(time: currentTime, theme: theme)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        AnalogClockView(time: currentTime, theme: theme)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            let h = value.translation.width
                            guard abs(h) > abs(value.translation.height) else { return }
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showDigital.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )

                Spacer()

                // テーマカラーピッカー
                HStack(spacing: 16) {
                    ForEach(ClockTheme.allCases, id: \.self) { t in
                        Button {
                            withAnimation { theme = t }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Circle()
                                .fill(t.accent)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: theme == t ? 2 : 0)
                                        .padding(-4)
                                )
                        }
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.4)) { showDigital.toggle() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(showDigital ? "アナログ表示" : "デジタル表示")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Live Activity

    private func makeState() -> ClockActivityAttributes.ContentState {
        let now = Date()
        let hourStart = Calendar.current.dateInterval(of: .hour, for: now)!.start
        let minuteStart = Calendar.current.dateInterval(of: .minute, for: now)!.start
        return ClockActivityAttributes.ContentState(date: now, hourStart: hourStart, minuteStart: minuteStart)
    }

    private func startLiveActivity() {
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else { return }
        do {
            let attrs = ClockActivityAttributes()
            let content = ActivityContent(state: makeState(), staleDate: nil)
            liveActivity = try Activity.request(attributes: attrs, content: content)
        } catch {}
    }

    private func updateLiveActivity() {
        let cal = Calendar.current
        guard cal.component(.second, from: currentTime) == 0 else { return }
        activityUpdateTask?.cancel()
        let content = ActivityContent(state: makeState(), staleDate: nil)
        activityUpdateTask = Task {
            guard !Task.isCancelled else { return }
            await liveActivity?.update(content)
        }
    }
}

// MARK: - Digital Clock

struct DigitalClockView: View {
    let time: Date
    var theme: ClockTheme = .white

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return f.string(from: time)
    }
    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yy年M月d日(E)"
        return f.string(from: time)
    }
    private var warekiString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.calendar = Calendar(identifier: .japanese); f.dateFormat = "GGyy年"
        return f.string(from: time)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(timeString)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(theme.accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(dateString)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(warekiString)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(theme.accent.opacity(0.7))
        }
    }
}

// MARK: - Analog Clock

struct AnalogClockView: View {
    let time: Date
    var theme: ClockTheme = .white

    private var cal: Calendar { Calendar.current }
    private var seconds: Double { Double(cal.component(.second, from: time)) }
    private var minutes: Double { Double(cal.component(.minute, from: time)) + seconds / 60 }
    private var hours: Double {
        Double(cal.component(.hour, from: time)).truncatingRemainder(dividingBy: 12) + minutes / 60
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.accent.opacity(0.15), lineWidth: 2)
                .frame(width: 280, height: 280)

            ForEach(0..<60) { i in
                let isHour = i % 5 == 0
                Rectangle()
                    .fill(isHour ? theme.accent.opacity(0.8) : theme.accent.opacity(0.3))
                    .frame(width: isHour ? 2 : 1, height: isHour ? 12 : 6)
                    .offset(y: -128)
                    .rotationEffect(.degrees(Double(i) * 6))
            }

            ForEach(1...12, id: \.self) { i in
                let angle = Double(i) * 30 - 90
                let r: Double = 108
                Text("\(i)")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(theme.accent.opacity(0.7))
                    .offset(x: cos(angle * .pi / 180) * r,
                            y: sin(angle * .pi / 180) * r)
            }

            ClockHand(angle: hours * 30 - 90,   length: 70,  width: 5,   color: theme.accent)
            ClockHand(angle: minutes * 6 - 90,  length: 100, width: 3,   color: theme.accent.opacity(0.9))
            ClockHand(angle: seconds * 6 - 90,  length: 110, width: 1.5, color: theme.secondHand)

            Circle().fill(theme.secondHand).frame(width: 10, height: 10)
        }
        .frame(width: 280, height: 280)
    }
}

struct ClockHand: View {
    let angle: Double; let length: Double; let width: Double; let color: Color
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle + 90))
            .shadow(color: color.opacity(0.5), radius: 4)
    }
}

// MARK: - World Clock

struct WorldClockView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let zones: [(String, String)] = [
        ("東京",         "Asia/Tokyo"),
        ("ニューヨーク",  "America/New_York"),
        ("ロンドン",      "Europe/London"),
        ("パリ",         "Europe/Paris"),
        ("シドニー",      "Australia/Sydney"),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(zones, id: \.0) { name, tzId in
                        if let tz = TimeZone(identifier: tzId) {
                            WorldClockRow(name: name, timeZone: tz, time: currentTime)
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
        }
        .onReceive(timer) { _ in currentTime = Date() }
    }
}

struct WorldClockRow: View {
    let name: String
    let timeZone: TimeZone
    let time: Date

    private var timeString: String {
        let f = DateFormatter(); f.timeZone = timeZone; f.dateFormat = "HH:mm:ss"
        return f.string(from: time)
    }
    private var dateString: String {
        let f = DateFormatter(); f.timeZone = timeZone
        f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "M/d(E)"
        return f.string(from: time)
    }
    private var offsetString: String {
        let s = timeZone.secondsFromGMT()
        let h = s / 3600; let m = abs((s % 3600) / 60)
        return m == 0
            ? "GMT\(h >= 0 ? "+" : "")\(h)"
            : "GMT\(h >= 0 ? "+" : "")\(h):\(String(format: "%02d", m))"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(offsetString)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(dateString)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Stopwatch

struct StopwatchView: View {
    @State private var isRunning = false
    @State private var laps: [TimeInterval] = []
    @State private var lastStart: Date?
    @State private var accumulated: TimeInterval = 0

    let displayTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    private var displayTime: TimeInterval {
        if isRunning, let start = lastStart {
            return accumulated + Date().timeIntervalSince(start)
        }
        return accumulated
    }

    private func fmt(_ t: TimeInterval) -> String {
        let min = Int(t) / 60
        let sec = Int(t) % 60
        let cs  = Int((t - Double(Int(t))) * 100)
        return String(format: "%02d:%02d.%02d", min, sec, cs)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Text(fmt(displayTime))
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .padding(.bottom, 40)

                HStack(spacing: 40) {
                    // ラップ / リセット
                    Button {
                        if isRunning {
                            laps.insert(displayTime, at: 0)
                        } else {
                            accumulated = 0; laps = []
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(isRunning ? "ラップ" : "リセット")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }

                    // 開始 / 停止
                    Button {
                        if isRunning {
                            accumulated = displayTime; lastStart = nil
                        } else {
                            lastStart = Date()
                        }
                        isRunning.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Circle()
                            .fill(isRunning
                                  ? Color(red: 1, green: 0.3, blue: 0.3)
                                  : Color(red: 0.2, green: 0.8, blue: 0.4))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(isRunning ? "停止" : "開始")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }

                Spacer()

                if !laps.isEmpty {
                    Divider().background(Color.white.opacity(0.2))
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(laps.enumerated()), id: \.offset) { i, lap in
                                let prev = i < laps.count - 1 ? laps[i + 1] : 0
                                HStack {
                                    Text("ラップ \(laps.count - i)")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text(fmt(lap - prev))
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
            }
        }
        .onReceive(displayTimer) { _ in }
    }
}

#Preview {
    ContentView()
}
