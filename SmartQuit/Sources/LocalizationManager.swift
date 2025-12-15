import Foundation

struct LocalizationManager {
    static let shared = LocalizationManager()
    
    enum Language: String {
        case en, ru, es, fr, de, zh, ja, it, pt, ko
    }
    
    private var currentLanguage: Language {
        let langStr = Locale.current.language.languageCode?.identifier ?? "en"
        return Language(rawValue: langStr) ?? .en
    }
    
    func string(_ key: String) -> String {
        let lang = currentLanguage
        switch key {
        case "prompt_title":
            switch lang {
            case .ru: return "Закрыть все окна?"
            case .es: return "¿Cerrar todas las ventanas?"
            case .fr: return "Fermer toutes les fenêtres ?"
            case .de: return "Alle Fenster schließen?"
            case .zh: return "关闭所有窗口？"
            case .ja: return "すべてのウィンドウを閉じますか？"
            default: return "Close all windows?"
            }
        case "prompt_message":
            switch lang {
            case .ru: return "У этого приложения открыто несколько окон. Что вы хотите сделать?"
            case .es: return "Esta aplicación tiene varias ventanas abiertas. ¿Qué deseas hacer?"
            case .fr: return "Cette application a plusieurs fenêtres ouvertes. Que voulez-vous faire ?"
            case .de: return "Diese Anwendung hat mehrere geöffnete Fenster. Was möchten Sie tun?"
            case .zh: return "此应用程序有多个打开的窗口。你想做什么？"
            case .ja: return "このアプリケーションには複数のウィンドウが開いています。どうしますか？"
            default: return "This application has multiple windows open. What would you like to do?"
            }
        case "quit_approv": // Quit App (All windows)
            switch lang {
            case .ru: return "Закрыть приложение"
            case .es: return "Salir de la aplicación"
            case .fr: return "Quitter l'application"
            case .de: return "Anwendung beenden"
            case .zh: return "退出应用程序"
            case .ja: return "アプリを終了"
            default: return "Quit Application"
            }
        case "close_current": // Close just this window
            switch lang {
            case .ru: return "Закрыть текущее окно"
            case .es: return "Cerrar ventana actual"
            case .fr: return "Fermer la fenêtre actuelle"
            case .de: return "Aktuelles Fenster schließen"
            case .zh: return "关闭当前窗口"
            case .ja: return "現在のウィンドウを閉じる"
            default: return "Close Current Window"
            }
        case "cancel":
            switch lang {
            case .ru: return "Отмена"
            case .es: return "Cancelar"
            case .fr: return "Annuler"
            case .de: return "Abbrechen"
            case .zh: return "取消"
            case .ja: return "キャンセル"
            default: return "Cancel"
            }
        // UI Strings
        case "settings_title":
            switch lang {
            case .ru: return "Smart Quit"
            case .es: return "Smart Quit"
            default: return "Smart Quit"
            }
        case "general_section":
            switch lang {
            case .ru: return "Общие"
            case .es: return "General"
            case .zh: return "常规"
            case .de: return "Allgemein"
            default: return "General"
            }
        case "start_login":
            switch lang {
            case .ru: return "Запускать при входе"
            case .es: return "Abrir al iniciar sesión"
            case .zh: return "登录时启动"
            case .de: return "Beim Anmelden öffnen"
            default: return "Start at Login"
            }
        case "exceptions_section":
            switch lang {
            case .ru: return "Исключения"
            case .es: return "Excepciones"
            case .zh: return "例外"
            case .de: return "Ausnahmen"
            default: return "Exceptions"
            }
        case "add_app":
            switch lang {
            case .ru: return "Добавить"
            case .es: return "Añadir"
            case .zh: return "添加"
            case .de: return "Hinzufügen"
            default: return "Add App"
            }
        case "select_app_title":
            switch lang {
            case .ru: return "Выберите приложение"
            case .es: return "Seleccionar aplicación"
            case .zh: return "选择应用程序"
            case .de: return "App auswählen"
            default: return "Select Application"
            }
        case "done":
            switch lang {
            case .ru: return "Готово"
            case .es: return "Listo"
            case .zh: return "完成"
            case .de: return "Fertig"
            default: return "Done"
            }
        case "access_required":
            switch lang {
            case .ru: return "Нужен доступ"
            case .es: return "Acceso requerido"
            case .zh: return "需访问权限"
            case .de: return "Zugriff erforderlich"
            default: return "Access Required"
            }
        default: return key
        }
    }
}
