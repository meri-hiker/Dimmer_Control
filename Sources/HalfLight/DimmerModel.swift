import AppKit
import Combine
import HalfLightCore

struct DisplayChoice: Identifiable {
    let id: UInt32
    let name: String
}

@MainActor
final class DimmerModel: ObservableObject {
    @Published var isEnabled = false { didSet { refresh() } }
    @Published var side: DimSide { didSet { save(); refresh() } }
    @Published var intensity: Double { didSet { save(); refresh() } }
    @Published var divider: Double { didSet { save(); refresh() } }
    @Published var displayID: UInt32 { didSet { save(); refresh() } }
    @Published private(set) var displays: [DisplayChoice] = []

    private let overlay = OverlayController()
    private let defaults = UserDefaults.standard
    var onStateChange: ((Bool) -> Void)?

    init() {
        side = DimSide(rawValue: defaults.string(forKey: "side") ?? "left") ?? .left
        intensity = DimRegion.opacity(defaults.object(forKey: "intensity") as? Double ?? 0.55)
        let storedDivider = defaults.object(forKey: "divider") as? Double ?? 0.5
        divider = storedDivider.isFinite ? min(0.8, max(0.2, storedDivider)) : 0.5
        displayID = UInt32(clamping: defaults.integer(forKey: "displayID"))
        updateDisplays()
    }

    func updateDisplays() {
        displays = NSScreen.screens.map {
            DisplayChoice(id: Self.id(of: $0), name: $0.localizedName)
        }
        if !displays.contains(where: { $0.id == displayID }) {
            // Do not unexpectedly dim another display after a monitor is unplugged.
            isEnabled = false
            displayID = displays.first?.id ?? 0
        }
        refresh()
    }

    func pause() { isEnabled = false }
    func swapSide() { side = side == .left ? .right : .left }

    private func refresh() {
        if isEnabled, let screen = NSScreen.screens.first(where: { Self.id(of: $0) == displayID }) {
            overlay.show(on: screen, side: side, divider: divider, opacity: intensity)
        } else {
            overlay.hide()
        }
        onStateChange?(isEnabled)
    }

    private func save() {
        defaults.set(side.rawValue, forKey: "side")
        defaults.set(intensity, forKey: "intensity")
        defaults.set(divider, forKey: "divider")
        defaults.set(Int(displayID), forKey: "displayID")
    }

    private static func id(of screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
