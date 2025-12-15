import SwiftUI

struct SettingsView: View {
    @ObservedObject var whitelistManager = WhitelistManager.shared
    @ObservedObject var autostartManager = AutostartManager.shared
    @ObservedObject var eventMonitor = EventMonitor.shared
    
    @State private var showingAddSheet = false
    @State private var installedApps: [InstalledApp] = []
    
    // User requested gradient: 8B67FF -> 3FCBFD
    let brandGradient = LinearGradient(
        colors: [Color(hex: "8B67FF"), Color(hex: "3FCBFD")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Gradient Text
            HStack {
                Text(LocalizationManager.shared.string("settings_title"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(brandGradient)
                Spacer()
                if !eventMonitor.isAccessEnabled {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .help(LocalizationManager.shared.string("access_required"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // General
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(brandGradient)
                        Text(LocalizationManager.shared.string("start_login"))
                        Spacer()
                        Toggle("", isOn: $autostartManager.isAutostartEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B67FF")))
                    }
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Whitelist Header
                    HStack {
                        Text(LocalizationManager.shared.string("exceptions_section"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            loadInstalledApps()
                            showingAddSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text(LocalizationManager.shared.string("add_app"))
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(brandGradient)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    
                    // Whitelist Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(whitelistManager.whitelist, id: \.self) { bundleId in
                            HStack {
                                if let appIcon = icon(for: bundleId) {
                                    Image(nsImage: appIcon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "cube")
                                        .foregroundColor(.gray)
                                }
                                
                                Text(appName(for: bundleId))
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        whitelistManager.remove(bundleId: bundleId)
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(.ultraThinMaterial)
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingAddSheet) {
            VStack(spacing: 0) {
                HStack {
                    Text(LocalizationManager.shared.string("select_app_title"))
                        .font(.headline)
                    Spacer()
                    Button(LocalizationManager.shared.string("done")) {
                        showingAddSheet = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(brandGradient)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                List {
                    ForEach(installedApps) { app in
                         HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                            Text(app.name)
                            Spacer()
                            if whitelistManager.isWhitelisted(bundleId: app.bundleId) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(brandGradient)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                whitelistManager.add(bundleId: app.bundleId)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
            .frame(width: 350, height: 450)
        }
        .onAppear {
            eventMonitor.checkAccess()
        }
    }
    
    // ... Methods
    
    func deleteApp(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = whitelistManager.whitelist[index]
            whitelistManager.remove(bundleId: item)
        }
    }
    
    func appName(for bundleId: String) -> String {
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return app.lastPathComponent.replacingOccurrences(of: ".app", with: "")
        }
        return bundleId
    }
    
    func icon(for bundleId: String) -> NSImage? {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
             return NSWorkspace.shared.icon(forFile: appUrl.path)
        }
        return nil
    }
}

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let icon: NSImage?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleId)
    }
    
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        return lhs.bundleId == rhs.bundleId
    }
}

extension SettingsView {
    func loadInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var foundApps: [InstalledApp] = []
            let fileManager = FileManager.default
            
            // Directories to scan
            let appDirs = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first?.path ?? ""
            ]
            
            var seenBundleIds = Set<String>()
            
            for dirPath in appDirs {
                guard !dirPath.isEmpty else { continue }
                
                // Enumerator is deeper but slower. Top level seems safer for now or shallow scan?
                // Users might have apps in subfolders. Let's do a shallow scan of the directory first.
                // If we want subfolders (like Utilities), we specifically added it.
                // Common apps are usually top level or in Utilities.
                
                if let contents = try? fileManager.contentsOfDirectory(atPath: dirPath) {
                    for item in contents {
                        if item.hasSuffix(".app") {
                            let fullPath = (dirPath as NSString).appendingPathComponent(item)
                            let url = URL(fileURLWithPath: fullPath)
                            
                            if let bundle = Bundle(url: url),
                               let bundleId = bundle.bundleIdentifier,
                               let name = bundle.infoDictionary?["CFBundleName"] as? String ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                                
                                if !seenBundleIds.contains(bundleId) {
                                    let icon = NSWorkspace.shared.icon(forFile: fullPath)
                                    let app = InstalledApp(name: name, bundleId: bundleId, icon: icon)
                                    foundApps.append(app)
                                    seenBundleIds.insert(bundleId)
                                }
                            }
                        }
                    }
                }
            }
            
            // Also add running apps just in case they are elsewhere
            let running = NSWorkspace.shared.runningApplications
            for app in running {
                if let id = app.bundleIdentifier, let name = app.localizedName, !seenBundleIds.contains(id) {
                    let icon = app.icon
                    foundApps.append(InstalledApp(name: name, bundleId: id, icon: icon))
                    seenBundleIds.insert(id)
                }
            }
            
            let sorted = foundApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.installedApps = sorted
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
    

