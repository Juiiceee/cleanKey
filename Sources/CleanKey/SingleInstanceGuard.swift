import Darwin
import Foundation

final class SingleInstanceGuard {
    static let shared = SingleInstanceGuard()

    private let lockPath = "/tmp/dev.loul.CleanKey.lock"
    private var lockFileDescriptor: Int32 = -1

    private init() {}

    func acquire() -> Bool {
        guard lockFileDescriptor < 0 else {
            return true
        }

        let fileDescriptor = open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fileDescriptor >= 0 else {
            AppLogger.lifecycle.error(
                "Unable to open single-instance lock file: \(Self.currentPOSIXError, privacy: .public)."
            )
            return false
        }

        guard flock(fileDescriptor, LOCK_EX | LOCK_NB) == 0 else {
            let message = Self.currentPOSIXError
            close(fileDescriptor)
            AppLogger.lifecycle.warning(
                "Another CleanKey instance is already running or the lock is unavailable: \(message, privacy: .public)."
            )
            return false
        }

        lockFileDescriptor = fileDescriptor
        AppLogger.lifecycle.info("Single-instance lock acquired.")
        return true
    }

    func release() {
        guard lockFileDescriptor >= 0 else {
            return
        }

        flock(lockFileDescriptor, LOCK_UN)
        close(lockFileDescriptor)
        lockFileDescriptor = -1
        AppLogger.lifecycle.info("Single-instance lock released.")
    }

    private static var currentPOSIXError: String {
        String(cString: strerror(errno))
    }
}
