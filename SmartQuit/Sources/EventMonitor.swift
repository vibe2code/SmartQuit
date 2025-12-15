import Cocoa
@preconcurrency import ApplicationServices

@MainActor
class EventMonitor: ObservableObject {
    static let shared = EventMonitor()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var accessCheckTimer: Timer?
    
    @Published var isAccessEnabled: Bool = false
    @Published var isTapActive: Bool = false
    
    init() {
        self.isAccessEnabled = AXIsProcessTrusted()
    }
    
    func start() {
        print("Starting EventMonitor...")
        if !AXIsProcessTrusted() {
            print("Accessibility access not granted. Prompting user...")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            
            // Start polling for access
            accessCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.checkAccessAndStart()
                }
            }
            return
        }
        
        createTap()
    }
    
    func checkAccessAndStart() {
        if AXIsProcessTrusted() {
            isAccessEnabled = true
            accessCheckTimer?.invalidate()
            accessCheckTimer = nil
            createTap()
        }
    }
    
    private func createTap() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.leftMouseUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .leftMouseUp {
                    return EventMonitor.shared.handleMouseUp(event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            print("Failed to create event tap. Retrying in 3 seconds...")
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task { @MainActor in
                    EventMonitor.shared.createTap()
                }
            }
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isTapActive = true
        print("Event tap started successfully")
    }
    
    func checkAccess() {
        isAccessEnabled = AXIsProcessTrusted()
    }
    
    private func handleMouseUp(event: CGEvent) -> Unmanaged<CGEvent>? {
        let location = event.location
        let x = Float(location.x)
        let y = Float(location.y)
        
        let systemWide = AXUIElementCreateSystemWide()
        // Set timeout to avoid freezing if target app is busy (e.g. 0.5s)
        AXUIElementSetMessagingTimeout(systemWide, 0.5)
        
        var element: AXUIElement?
        
        let result = AXUIElementCopyElementAtPosition(systemWide, x, y, &element)
        
        guard result == .success, let foundElement = element else {
            return Unmanaged.passUnretained(event)
        }
        
        // 2. Check if it is a close button
        var roleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(foundElement, kAXRoleAttribute as CFString, &roleValue)
        
        var subroleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(foundElement, kAXSubroleAttribute as CFString, &subroleValue)
        
        guard let role = roleValue as? String,
              let subrole = subroleValue as? String else {
            return Unmanaged.passUnretained(event)
        }
        
        if role == "AXButton" && subrole == "AXCloseButton" {
             // 3. Identify the application
            var pid: pid_t = 0
            AXUIElementGetPid(foundElement, &pid)
            
            // Safety: Never kill ourselves
            if pid == ProcessInfo.processInfo.processIdentifier {
                return Unmanaged.passUnretained(event)
            }
            
            if let app = NSRunningApplication(processIdentifier: pid),
               let bundleId = app.bundleIdentifier {
                
                print("EventMonitor: Detected Close on \(bundleId)")
                
                // 4. Check whitelist
                if WhitelistManager.shared.isWhitelisted(bundleId: bundleId) {
                    return Unmanaged.passUnretained(event)
                }
                
                // 5. Multi-window check
                let appElement = AXUIElementCreateApplication(pid)
                AXUIElementSetMessagingTimeout(appElement, 0.5) // Timeout for this app queries too
                
                var windowsValue: CFTypeRef?
                let winRest = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
                
                var windowCount = 1 // Default to 1 if check fails
                if winRest == .success, let windows = windowsValue as? [AXUIElement] {
                    windowCount = windows.count
                }
                
                print("Window count for \(bundleId): \(windowCount)")
                
                if windowCount > 1 {
                    DispatchQueue.main.async {
                        self.showMultiWindowPrompt(app: app)
                    }
                    return nil // Consume event to prevent close
                }
                
                // Single window - User requested "Smooth" close.
                // Strategy: Pass the event (let window close naturally), then terminate after small delay.
                print("EventMonitor: Single window. Passing event and scheduling quit.")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Check if app is still running? Yes.
                    print("EventMonitor: Terminating \(bundleId)")
                    app.terminate()
                }
                
                return Unmanaged.passUnretained(event) // Pass event!
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func showMultiWindowPrompt(app: NSRunningApplication) {
        // Find existing prompt or prevent spam? 
        // For simplicity, just show alert.
        NSApp.activate(ignoringOtherApps: true)
        
        let alert = NSAlert()
        alert.messageText = LocalizationManager.shared.string("prompt_title")
        alert.informativeText = LocalizationManager.shared.string("prompt_message")
        
        alert.addButton(withTitle: LocalizationManager.shared.string("quit_approv")) // Quit App
        alert.addButton(withTitle: LocalizationManager.shared.string("close_current")) // Close Window
        alert.addButton(withTitle: LocalizationManager.shared.string("cancel")) // Cancel
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn: // Quit App
            app.hide()
            app.terminate()
        case .alertSecondButtonReturn: // Close Window
            // We intercepted the click, so the window didn't close.
            // We need to tell the app to close the front window.
            // Or easier: Just let the user click again? No that's bad UX.
            // We should simulate the close action.
            // However, simulating click on the button we just intercepted is hard because we don't have the element reference here easily (unless we pass it).
            // Better approach: Unhide app (if hidden) and let user handle it?
            // Actually, "Close Current Window" means we should perform the action we intercepted.
            // But we already consumed the event.
            // We can send Cmd+W?
            print("User chose to close window only.")
            
            // Try to activate app and send Cmd+W
            app.activate(options: .activateIgnoringOtherApps)
            
            // Give it a split second to focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let src = CGEventSource(stateID: .hidSystemState)
                let cmdd = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: true)! // Cmd
                let w = CGEvent(keyboardEventSource: src, virtualKey: 0x0D, keyDown: true)! // W (0x0D is W)
                
                cmdd.flags = .maskCommand
                w.flags = .maskCommand
                
                cmdd.post(tap: .cghidEventTap)
                w.post(tap: .cghidEventTap)
                
                // Release
                let wUp = CGEvent(keyboardEventSource: src, virtualKey: 0x0D, keyDown: false)!
                let cmddUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)!
                
                wUp.post(tap: .cghidEventTap)
                cmddUp.post(tap: .cghidEventTap)
            }
            
        default:
            break // Cancel
        }
    }
}
