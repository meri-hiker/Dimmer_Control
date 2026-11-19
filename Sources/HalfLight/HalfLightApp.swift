import AppKit
import SwiftUI

@main
enum HalfLightApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = DimmerModel()
    private let shortcuts = GlobalShortcuts()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.lefthalf.filled", accessibilityDescription: "HalfLight")
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "HalfLight — dimming paused"
        }
        model.onStateChange = { [weak self] enabled in
            self?.statusItem.button?.toolTip = enabled ? "HalfLight — dimming on" : "HalfLight — dimming paused"
            self?.statusItem.button?.appearsDisabled = !enabled
        }
        let available = shortcuts.register { [weak self] identifier in
            guard let self else { return }
            if identifier == 1 { self.model.isEnabled.toggle() }
            if identifier == 2 { self.model.swapSide() }
        }
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ControlsView(model: model, shortcutsAvailable: available))
        NotificationCenter.default.addObserver(self, selector: #selector(displaysChanged),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(pause),
                                                          name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(pause),
                                                          name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        // Explain the controls on first launch, without activating an overlay.
        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            togglePopover()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func displaysChanged() { model.updateDisplays() }
    @objc private func pause() { model.pause() }

    func applicationWillTerminate(_ notification: Notification) {
        model.pause()
        shortcuts.unregister()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
