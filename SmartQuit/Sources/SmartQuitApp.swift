import SwiftUI

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    var settingsWindow: NSWindow?
    
    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.center()
        window.title = "Smart Quit"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false // Important!
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@available(macOS 13.0, *)
struct SmartQuitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var eventMonitor = EventMonitor.shared
    
    var body: some Scene {
        MenuBarExtra("SmartQuit", systemImage: eventMonitor.isTapActive ? "power.circle.fill" : "exclamationmark.triangle.fill") {
            Text("Smart Quit: \(eventMonitor.isTapActive ? "Running" : "Inactive")")
            
            if !eventMonitor.isAccessEnabled {
                Button("Grant Permissions") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
            
            Button("Settings") {
                WindowManager.shared.openSettings()
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    init() {
        // Start monitoring on launch
        EventMonitor.shared.start()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
