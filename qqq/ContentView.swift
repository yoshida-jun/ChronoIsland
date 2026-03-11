//
//  ContentView.swift
//  qqq
//
//  Created by jun on 2026/03/12.
//

import SwiftUI
import Combine
import ActivityKit

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var showDigital = true
    @State private var liveActivity: Activity<ClockActivityAttributes>?
    @State private var debugMessage = "未開始"

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                if showDigital {
                    DigitalClockView(time: currentTime)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    AnalogClockView(time: currentTime)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Text(debugMessage)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(.horizontal, 12)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showDigital.toggle()
                    }
                }) {
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
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateLiveActivity()
        }
        .onAppear {
            startLiveActivity()
        }
    }

    private func makeState() -> ClockActivityAttributes.ContentState {
        let now = Date()
        let hourStart = Calendar.current.dateInterval(of: .hour, for: now)!.start
        return ClockActivityAttributes.ContentState(date: now, hourStart: hourStart)
    }

    private func startLiveActivity() {
        let info = ActivityAuthorizationInfo()
        debugMessage = "enabled:\(info.areActivitiesEnabled)"
        guard info.areActivitiesEnabled else {
            debugMessage = "❌ areActivitiesEnabled=false"
            return
        }
        do {
            let attributes = ClockActivityAttributes()
            let content = ActivityContent(state: makeState(), staleDate: nil)
            liveActivity = try Activity.request(attributes: attributes, content: content)
            debugMessage = "✅ 開始成功 id:\(liveActivity?.id ?? "nil")"
        } catch {
            debugMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func updateLiveActivity() {
        // 毎時更新（hourStartが変わるタイミングのみ）
        let cal = Calendar.current
        guard cal.component(.minute, from: currentTime) == 0,
              cal.component(.second, from: currentTime) == 0 else { return }
        let content = ActivityContent(state: makeState(), staleDate: nil)
        Task { await liveActivity?.update(content) }
    }

    private func endLiveActivity() {
        let content = ActivityContent(state: makeState(), staleDate: nil)
        Task { await liveActivity?.end(content, dismissalPolicy: .immediate) }
    }
}

// MARK: - Digital Clock

struct DigitalClockView: View {
    let time: Date

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: time)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(timeString)
                .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()

            Text(dateString)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Analog Clock

struct AnalogClockView: View {
    let time: Date

    private var calendar: Calendar { Calendar.current }

    private var seconds: Double {
        Double(calendar.component(.second, from: time))
    }
    private var minutes: Double {
        Double(calendar.component(.minute, from: time)) + seconds / 60
    }
    private var hours: Double {
        Double(calendar.component(.hour, from: time)).truncatingRemainder(dividingBy: 12) + minutes / 60
    }

    var body: some View {
        ZStack {
            // 文字盤
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
                .frame(width: 280, height: 280)

            // 目盛り
            ForEach(0..<60) { i in
                let isHour = i % 5 == 0
                Rectangle()
                    .fill(isHour ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
                    .frame(width: isHour ? 2 : 1, height: isHour ? 12 : 6)
                    .offset(y: -128)
                    .rotationEffect(.degrees(Double(i) * 6))
            }

            // 数字
            ForEach(1...12, id: \.self) { i in
                let angle = Double(i) * 30 - 90
                let radius: Double = 108
                let x = cos(angle * .pi / 180) * radius
                let y = sin(angle * .pi / 180) * radius
                Text("\(i)")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                    .offset(x: x, y: y)
            }

            // 時針
            ClockHand(angle: hours * 30 - 90, length: 70, width: 5, color: .white)

            // 分針
            ClockHand(angle: minutes * 6 - 90, length: 100, width: 3, color: .white.opacity(0.9))

            // 秒針
            ClockHand(angle: seconds * 6 - 90, length: 110, width: 1.5, color: Color(red: 1, green: 0.3, blue: 0.3))

            // 中心点
            Circle()
                .fill(Color(red: 1, green: 0.3, blue: 0.3))
                .frame(width: 10, height: 10)
        }
        .frame(width: 280, height: 280)
    }
}

struct ClockHand: View {
    let angle: Double
    let length: Double
    let width: Double
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle + 90))
            .shadow(color: color.opacity(0.5), radius: 4)
    }
}

#Preview {
    ContentView()
}
