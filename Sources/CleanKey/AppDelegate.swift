import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let singleInstanceGuard = SingleInstanceGuard.shared
    private var appState: AppState?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard singleInstanceGuard.acquire() else {
            NSApp.terminate(nil)
            return
        }

        let appState = AppState()
        self.appState = appState
        statusBarController = StatusBarController(appState: appState)
        appState.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.shutdown()
        singleInstanceGuard.release()
    }
}
