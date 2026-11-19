import AppKit
import HalfLightCore

private final class DimPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayController {
    private var panel: DimPanel?

    func show(on screen: NSScreen, side: DimSide, divider: Double, opacity: Double) {
        let frame = DimRegion.frame(in: screen.frame, side: side, divider: divider)
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.setFrame(frame, display: true)
        panel.alphaValue = DimRegion.opacity(opacity)
        panel.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    private func makePanel() -> DimPanel {
        let panel = DimPanel(contentRect: .zero,
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.backgroundColor = .black
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        // Keep the menu bar and its controls accessible above the dimmer.
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = true
        panel.animationBehavior = .none
        return panel
    }
}
