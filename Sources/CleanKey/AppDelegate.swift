import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppState()
        self.appState = appState
        statusBarController = StatusBarController(appState: appState)
        appState.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.shutdown()
    }
}
