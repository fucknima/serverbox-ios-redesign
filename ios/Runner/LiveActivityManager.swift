//
//  LiveActivityManager.swift
//  Runner
//
//  Handles starting/updating/stopping Terminal Live Activities from Flutter via MethodChannel.
//
//  On sideloaded builds the app has no Live Activities entitlement (or the
//  system disables them), and calling into ActivityKit there makes the
//  framework read its activity plist and assert inside Foundation — which on
//  iOS 27 beta aborts the process on the main thread while the terminal's
//  5-second update tick is running. Every entry point therefore gates on
//  `areActivitiesEnabled` first and swallows every error afterwards, so a
//  sanctioned App Store build still gets its Live Activities and an ad-hoc
//  build simply never touches ActivityKit.
//

import Foundation
import ActivityKit

@available(iOS 16.2, *)
@MainActor
class LiveActivityManager {
    private static var current: Activity<TerminalAttributes>?

    struct Payload: Decodable {
        let id: String
        let title: String
        let subtitle: String
        let startTimeMs: Int
        let status: String
        let hasTerminal: Bool?
        let connectionCount: Int?
    }

    /// False on sideloaded/unsigned builds, broken entitlements, or when the
    /// user turned Live Activities off. Guarding every entry avoids touching
    /// ActivityKit (and the plist read that aborts) entirely in that case.
    private static var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private static func parse(_ json: String) -> Payload? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }

    private static func trackedActivities() -> [Activity<TerminalAttributes>] {
        var activities = Activity<TerminalAttributes>.activities
        if let current = current, !activities.contains(where: { $0.id == current.id }) {
            activities.append(current)
        }
        return activities
    }

    private static func updatableActivity() -> Activity<TerminalAttributes>? {
        if let current = current,
           current.activityState == .active || current.activityState == .stale {
            return current
        }
        let activity = Activity<TerminalAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
        current = activity
        return activity
    }

    static func start(json: String) {
        guard activitiesEnabled else { return }
        guard let p = parse(json) else { return }
        let attributes = TerminalAttributes(id: p.id)
        let date = Date(timeIntervalSince1970: TimeInterval(p.startTimeMs) / 1000.0)
        // Localize multi-connection title/subtitle on iOS side
        let isMulti = (p.id == "multi_connections")
        let title = isMulti
            ? String(format: NSLocalizedString("%d connections", comment: "Title for multiple connections"), p.connectionCount ?? 1)
            : p.title
        let subtitle = isMulti
            ? NSLocalizedString("Multiple SSH sessions active", comment: "Subtitle for multiple connections")
            : p.subtitle
        let state = TerminalAttributes.ContentState(
            id: p.id,
            title: title,
            subtitle: subtitle,
            status: p.status,
            startTime: date,
            hasTerminal: p.hasTerminal ?? true,
            connectionCount: p.connectionCount ?? 1
        )
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity = updatableActivity() {
            current = activity
            let duplicates = trackedActivities().filter { $0.id != activity.id }
            Task {
                do {
                    try await activity.update(content)
                    for duplicate in duplicates {
                        try await duplicate.end(dismissalPolicy: .immediate)
                    }
                } catch {
                    // Live Activities are best-effort; a failure here must
                    // never take the process down.
                }
            }
            return
        }

        do {
            current = try Activity<TerminalAttributes>.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            // ignore
        }
    }

    static func update(json: String) {
        guard activitiesEnabled else { return }
        guard let p = parse(json) else { return }
        let date = Date(timeIntervalSince1970: TimeInterval(p.startTimeMs) / 1000.0)
        // Localize multi-connection title/subtitle on iOS side
        let isMulti = (p.id == "multi_connections")
        let title = isMulti
            ? String(format: NSLocalizedString("%d connections", comment: "Title for multiple connections"), p.connectionCount ?? 1)
            : p.title
        let subtitle = isMulti
            ? NSLocalizedString("Multiple SSH sessions active", comment: "Subtitle for multiple connections")
            : p.subtitle
        let state = TerminalAttributes.ContentState(
            id: p.id,
            title: title,
            subtitle: subtitle,
            status: p.status,
            startTime: date,
            hasTerminal: p.hasTerminal ?? true,
            connectionCount: p.connectionCount ?? 1
        )
        if let activity = updatableActivity() {
            current = activity
            let duplicates = trackedActivities().filter { $0.id != activity.id }
            Task {
                do {
                    try await activity.update(ActivityContent(state: state, staleDate: nil))
                    for duplicate in duplicates {
                        try await duplicate.end(dismissalPolicy: .immediate)
                    }
                } catch {
                    // best-effort; never fatal
                }
            }
        } else {
            start(json: json)
        }
    }

    static func stop() async {
        guard activitiesEnabled else { return }
        let activities = trackedActivities()
        current = nil
        for activity in activities {
            do {
                try await activity.end(dismissalPolicy: .immediate)
            } catch {
                // best-effort; never fatal
            }
        }
    }
}