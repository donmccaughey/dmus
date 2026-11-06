#if os(macOS)
import AppKit

enum MainMenu {
    static func make(settingsTarget: AnyObject, settingsAction: Selector) -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(appMenuItem(settingsTarget: settingsTarget, settingsAction: settingsAction))
        mainMenu.addItem(fileMenuItem())
        mainMenu.addItem(editMenuItem())
        mainMenu.addItem(windowMenuItem())
        return mainMenu
    }

    private static func appMenuItem(settingsTarget: AnyObject, settingsAction: Selector) -> NSMenuItem {
        let settings = NSMenuItem(title: "Settings…", action: settingsAction, keyEquivalent: ",")
        settings.target = settingsTarget

        let hideOthers = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthers.keyEquivalentModifierMask = [.command, .option]

        let servicesMenu = NSMenu(title: "Services")
        NSApp.servicesMenu = servicesMenu
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        services.submenu = servicesMenu

        return menuItem(title: "MC Mus", items: [
            NSMenuItem(
                title: "About MC Mus",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            ),
            .separator(),
            settings,
            .separator(),
            services,
            .separator(),
            NSMenuItem(title: "Hide MC Mus", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
            hideOthers,
            NSMenuItem(
                title: "Show All",
                action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""
            ),
            .separator(),
            NSMenuItem(title: "Quit MC Mus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ])
    }

    private static func fileMenuItem() -> NSMenuItem {
        menuItem(title: "File", items: [
            NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
        ])
    }

    private static func editMenuItem() -> NSMenuItem {
        menuItem(title: "Edit", items: [
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"),
            .separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: ""),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
        ])
    }

    private static func windowMenuItem() -> NSMenuItem {
        let item = menuItem(title: "Window", items: [
            NSMenuItem(
                title: "Minimize",
                action: #selector(NSWindow.performMiniaturize(_:)),
                keyEquivalent: "m"
            ),
            NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""),
            .separator(),
            NSMenuItem(
                title: "Bring All to Front",
                action: #selector(NSApplication.arrangeInFront(_:)),
                keyEquivalent: ""
            ),
        ])
        NSApp.windowsMenu = item.submenu
        return item
    }

    private static func menuItem(title: String, items: [NSMenuItem]) -> NSMenuItem {
        let menu = NSMenu(title: title)
        for item in items {
            menu.addItem(item)
        }
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menuItem.submenu = menu
        return menuItem
    }
}
#endif
