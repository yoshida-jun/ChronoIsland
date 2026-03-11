//
//  ClockWidgetBundle.swift
//  ClockWidget
//
//  Created by jun on 2026/03/12.
//

import WidgetKit
import SwiftUI

@main
struct ClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        ClockWidgetControl()
        ClockWidgetLiveActivity()
    }
}
