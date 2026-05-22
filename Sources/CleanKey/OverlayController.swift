import AppKit
import CleanKeyCore
import os
import SwiftUI

final class OverlayController {
    static let shared = OverlayController()

    private var windows: [NSWindow] = []

    private init() {}

    func show(lockController: LockController, shortcut: GlobalShortcut) {
        hide()
        AppLogger.overlay.info("Showing overlay on \(NSScreen.screens.count, privacy: .public) screen(s).")

        for screen in NSScreen.screens {
            let window = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.canHide = false
            window.contentView = NSHostingView(
                rootView: LockOverlayView(lockController: lockController, shortcut: shortcut)
            )
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)

            AppLogger.overlay.info(
                "Overlay ordered front on frame \(String(describing: screen.frame), privacy: .public)."
            )
        }
    }

    func hide() {
        guard !windows.isEmpty else {
            return
        }
        AppLogger.overlay.info("Hiding \(self.windows.count, privacy: .public) overlay window(s).")
        windows.forEach { $0.close() }
        windows.removeAll()
    }
}

private struct LockOverlayView: View {
    @ObservedObject var lockController: LockController
    let shortcut: GlobalShortcut

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.1)) { context in
            let displayState = displayState(at: context.date)

            ZStack {
                Color.black.opacity(0.78)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Image(systemName: displayState.symbolName)
                        .font(.system(size: 52, weight: .medium))
                        .symbolRenderingMode(.hierarchical)

                    Text(displayState.title)
                        .font(.system(size: 34, weight: .semibold))

                    Text(displayState.subtitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)

                    CountdownRing(progress: displayState.progress, tint: displayState.tint) {
                        VStack(spacing: 4) {
                            Text(displayState.primaryValue)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()

                            Text(displayState.secondaryValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 148, height: 148)
                    .padding(.top, 6)

                    Text(displayState.footer)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(displayState.tint)
                        .monospacedDigit()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )

                    if lockController.isDevelopmentPreview {
                        Button("Déverrouiller") {
                            lockController.unlock()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 4)
                    }
                }
                .foregroundStyle(.white)
                .padding(36)
            }
        }
    }

    private func displayState(at date: Date) -> OverlayDisplayState {
        if lockController.isReleaseGuardActive {
            let remaining = remainingSeconds(until: lockController.releaseGuardDeadline, at: date)
            return OverlayDisplayState(
                symbolName: "hourglass",
                title: "Relâche les touches",
                subtitle: "CleanKey bloque encore les entrées pendant 1 seconde.",
                primaryValue: "\(remaining)",
                secondaryValue: "seconde",
                footer: "Protection anti-raccourci active",
                progress: progress(
                    from: lockController.releaseGuardStartedAt,
                    to: lockController.releaseGuardDeadline,
                    at: date
                ),
                tint: .green
            )
        }

        if lockController.isUnlockHoldActive {
            let remaining = remainingSeconds(until: lockController.unlockDeadline, at: date)
            let progress = progress(
                from: lockController.unlockStartedAt,
                to: lockController.unlockDeadline,
                at: date
            )
            return OverlayDisplayState(
                symbolName: "stopwatch.fill",
                title: "Déverrouillage en cours",
                subtitle: "Continue de maintenir \(shortcut.displayString).",
                primaryValue: "\(remaining)",
                secondaryValue: remaining == 1 ? "seconde" : "secondes",
                footer: progress >= 0.75 ? "Presque fini" : "Maintien détecté",
                progress: progress,
                tint: progress >= 0.75 ? .green : .orange
            )
        }

        let remaining = remainingSeconds(until: lockController.autoUnlockDeadline, at: date)
        let progress = progress(
            from: lockController.lockStartedAt,
            to: lockController.autoUnlockDeadline,
            at: date
        )
        return OverlayDisplayState(
            symbolName: "lock.fill",
            title: "CleanKey verrouillé",
            subtitle: lockController.isDevelopmentPreview
                ? "Mode dev: les entrées ne sont pas bloquées."
                : "Maintiens \(shortcut.displayString) pendant \(durationLabel(lockController.unlockHoldDuration)) pour déverrouiller.",
            primaryValue: formattedDuration(remaining),
            secondaryValue: "auto",
            footer: lockController.isDevelopmentPreview
                ? "Prévisualisation sans autorisation macOS"
                : progress >= 0.85 ? "Déverrouillage automatique imminent" : "Sécurité 3 minutes maximum",
            progress: progress,
            tint: progress >= 0.85 ? .green : .white
        )
    }

    private func progress(from startDate: Date?, to endDate: Date?, at date: Date) -> Double {
        guard let startDate, let endDate else {
            return 0
        }

        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0 else {
            return 1
        }

        let elapsed = date.timeIntervalSince(startDate)
        return min(max(elapsed / duration, 0), 1)
    }

    private func remainingSeconds(until date: Date?, at currentDate: Date) -> Int {
        guard let date else {
            return 0
        }

        return max(0, Int(ceil(date.timeIntervalSince(currentDate))))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let minutes = clampedSeconds / 60
        let seconds = clampedSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func durationLabel(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        return seconds == 1 ? "1 seconde" : "\(seconds) secondes"
    }
}

private struct OverlayDisplayState {
    let symbolName: String
    let title: String
    let subtitle: String
    let primaryValue: String
    let secondaryValue: String
    let footer: String
    let progress: Double
    let tint: Color
}

private struct CountdownRing<Content: View>: View {
    let progress: Double
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.16), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            content
        }
    }
}
