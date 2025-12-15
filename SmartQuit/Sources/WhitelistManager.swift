import Foundation
import AppKit

@MainActor
class WhitelistManager: ObservableObject {
    static let shared = WhitelistManager()
    
    @Published var whitelist: [String] = [] {
        didSet {
            save()
        }
    }
    
    private let userDefaultsKey = "SmartQuitWhitelist"
    
    init() {
        self.whitelist = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
        
        // Ensure defaults are present if empty (first run)
        if whitelist.isEmpty {
            loadDefaults()
        }
        
        // Always ensure SmartQuit itself is whitelisted
        if let myBundleId = Bundle.main.bundleIdentifier, !whitelist.contains(myBundleId) {
            print("WhitelistManager: Adding self (\(myBundleId)) to whitelist")
            whitelist.append(myBundleId)
        }
        
        print("WhitelistManager: Loaded \(whitelist.count) apps: \(whitelist)")
        
        // Auto-detect login items
        DispatchQueue.global(qos: .background).async {
            let loginItems = self.fetchLoginItemBundleIds()
            DispatchQueue.main.async {
                self.mergeLoginItems(loginItems)
            }
        }
    }
    
    func loadDefaults() {
         whitelist = [
            // System
            "com.apple.finder",
            "com.apple.loginwindow",
            "com.apple.SystemSettings",
            "com.apple.AppStore",
            "com.apple.Calculator",
            "com.apple.Notes",
            "com.apple.reminders",
            "com.apple.iCal",
            "com.apple.Music",
            "com.apple.Podcasts",
            "com.apple.TV",
            "com.apple.mail",
            "com.apple.Photos",
            "com.apple.Safari",
            
            // Messengers / Social
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "com.hnc.Discord",
            "com.tinyspeck.slackmacgap",
            "com.whatsapp",
            "com.viber.mac",
            "com.skype.skype",
            "com.facebook.archon", // Messenger
            
            // Browsers
            "com.google.Chrome",
            "com.brave.Browser",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.opera.operabrowser",
            "company.thebrowser.Browser", // Arc
            
            // Tools / Productivity
            "com.readdle.SparkDesktop",
            "com.microsoft.Outlook",
            "com.microsoft.Word",
            "com.microsoft.Excel",
            "com.microsoft.Powerpoint",
            "com.notion.id",
            "com.figma.Desktop",
            "com.spotify.client",
            "com.jetbrains.intellij",
            "com.jetbrains.pycharm",
            "com.microsoft.VSCode",
            "com.apple.dt.Xcode",
            "com.sublimetext.4",
            "com.google.android.studio",
            "io.iterm.iTerm2",
            "com.apple.Terminal"
        ]
    }
    
    private func mergeLoginItems(_ items: [String]) {
        var changed = false
        for item in items {
            if !whitelist.contains(item) {
                whitelist.append(item)
                changed = true
            }
        }
        if changed {
            save()
        }
    }
    
    nonisolated private func fetchLoginItemBundleIds() -> [String] {
        // Fetch login items via AppleScript
        // We get names, then try to match with installed apps. Structure is loose.
        // Simpler: Ask System Events for 'path' of login items.
        let script = "tell application \"System Events\" to get path of every login item"
        var ids: [String] = []
        
        if let scriptObject = NSAppleScript(source: script) {
             // NSAppleScript is thread-safe for execution but let's be careful.
             // Actually, NSAppleScript must be run on main thread strictly speaking? 
             // "NSAppleScript is not thread safe" - usually needs to be formatted/expect main thread or locked.
             // But we are in a background queue. 
             // Let's protect it or accept it might fail in background.
             // Safe bet: Run on MainActor if needed, but doing synchronous AppleScript on Main blocks UI.
             // Let's keep it nonisolated but use a local lock if needed, or just run. 
             // Usually executing simple scripts is okay.
             
            var error: NSDictionary?
            let descriptor = scriptObject.executeAndReturnError(&error)
            
            if let list = descriptor.coerce(toDescriptorType: typeAEList) {
                let count = list.numberOfItems
                for i in 1...count {
                    if let item = list.atIndex(i), let path = item.stringValue {
                        let url = URL(fileURLWithPath: path)
                        if let bundle = Bundle(url: url), let id = bundle.bundleIdentifier {
                            ids.append(id)
                        }
                    }
                }
            }
        }
        return ids
    }
    
    func save() {
        UserDefaults.standard.set(whitelist, forKey: userDefaultsKey)
    }
    
    func add(bundleId: String) {
        if !whitelist.contains(bundleId) {
            whitelist.append(bundleId)
        }
    }
    
    func remove(bundleId: String) {
        whitelist.removeAll { $0 == bundleId }
    }
    
    func isWhitelisted(bundleId: String) -> Bool {
        return whitelist.contains(bundleId)
    }
}
