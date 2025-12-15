import SwiftUI
import AppKit

if #available(macOS 13.0, *) {
    SmartQuitApp.main()
} else {
    print("SmartQuit requires macOS 13.0 or later.")
    exit(1)
}
