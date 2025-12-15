import Foundation
import ServiceManagement

@MainActor
class AutostartManager: ObservableObject {
    static let shared = AutostartManager()
    
    @Published var isAutostartEnabled: Bool = false {
        didSet {
            // Update logic here if toggle changes
            if isAutostartEnabled {
                enable()
            } else {
                disable()
            }
        }
    }
    
    private let label = "com.pingvi.smartquit"
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
        isAutostartEnabled = FileManager.default.fileExists(atPath: plistPath.path)
    }
    
    func enable() {
        guard !isAutostartEnabled else { return } // Already enabled check (files might be out of sync though)
        
        let execPath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
        
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        
        let plistUrl = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
            
        do {
            try plistContent.write(to: plistUrl, atomically: true, encoding: .utf8)
            // Load it immediately
            /* 
             Process.run is safer, but "launchctl load" is the standard way.
             However, since this is a simple user tool, writing the plist is usually enough for the *next* login.
             To start immediately, we are already running.
            */
        } catch {
            print("Failed to enable autostart: \(error)")
        }
    }
    
    func disable() {
        let plistUrl = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
        
        do {
            try FileManager.default.removeItem(at: plistUrl)
        } catch {
            print("Failed to disable autostart: \(error)")
        }
    }
}
