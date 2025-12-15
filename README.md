# SmartQuit: Cmd+Q for the Modern Era

<p align="center">
  <img src="smart.png" alt="SmartQuit Icon" width="128" />
</p>

**SmartQuit** is a lightweight macOS utility designed to enhance your workflow by "smartly" handling application quitting. It provides features like preventing accidental quits, whitelisting essential apps, and autostart capabilities.

## ✨ Features

- **Smart Quitting**: Intercepts `Cmd+Q` (conceptually) or monitors app behavior to keep your workspace clean.
- **Whitelist System**: Prevent specific applications from being quit automatically or accidentally.
- **Autostart**: Option to launch SmartQuit automatically when you log in.
- **Menu Bar Integration**: Unobtrusive menu bar icon for quick access to settings and controls.
- **Modern UI**: Built with pure SwiftUI for a native and responsive experience on macOS 13+.

## 🛠️ Requirements

- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel

## 🚀 Installation

1. Download the [latest release](https://github.com/vibe2code/SmartQuit/releases/latest) from GitHub.
2. Drag `SmartQuit.app` to your `Applications` folder.
3. Launch the app.
4. Grant the necessary **Accessibility Permissions** when prompted (required to monitor application events).

## ⚙️ Usage

1. **Access Settings**: Click the SmartQuit icon in the menu bar and select "Settings..."
2. **Manage Whitelist**:
   - Go to the **Exceptions** section in Settings.
   - Click **+ Add App** to select applications you want to protect.
   - SmartQuit will remember these choices.
3. **Autostart**:
   - Toggle "Start at Login" in Settings to ensure SmartQuit manages your apps from the moment you boot up.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
