import AppKit
import QuartzCore
import HalfLightCore

private final class DimPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayController {
    private var panels: [DimSide: DimPanel] = [:]

    func update(on screen: NSScreen, state: DimmingState, divider: Double) {
        // Update existing windows directly during NSSlider's tracking loop.
        // No animation, debounce, or SwiftUI redraw is needed for screen changes.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            for side in DimSide.allCases {
                guard state.isEnabled(for: side) else {
                    panels[side]?.orderOut(nil)
                    continue
                }
                let panel = panels[side] ?? makePanel()
                panels[side] = panel
                let frame = DimRegion.frame(in: screen.frame, side: side, divider: divider)
                if panel.frame != frame { panel.setFrame(frame, display: true) }
                panel.alphaValue = DimRegion.opacity(state.opacity(for: side))
                if !panel.isVisible { panel.orderFrontRegardless() }
                panel.displayIfNeeded()
            }
        }
        CATransaction.flush()
    }

    func hide() { panels.values.forEach { $0.orderOut(nil) } }

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
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = true
        panel.animationBehavior = .none
        return panel
    }
}
