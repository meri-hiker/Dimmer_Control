import AppKit
import Combine
import HalfLightCore

struct DisplayChoice: Identifiable {
    let id: UInt32
    let name: String
}

@MainActor
final class DimmerModel: ObservableObject {
    @Published private(set) var state: DimmingState { didSet { refresh(); save() } }
    @Published var divider: Double { didSet { refresh(); save() } }
    @Published var displayID: UInt32 { didSet { refresh(); save() } }
    @Published private(set) var displays: [DisplayChoice] = []
    var isEnabled: Bool { state.isEnabled }

    private let overlay = OverlayController()
    private let defaults = UserDefaults.standard
    var onStateChange: ((Bool) -> Void)?

    init() {
        let legacy = 1 - DimRegion.opacity(defaults.object(forKey: "intensity") as? Double ?? 0.55)
        state = DimmingState(leftBrightness: defaults.object(forKey: "leftBrightness") as? Double ?? legacy,
                             rightBrightness: defaults.object(forKey: "rightBrightness") as? Double ?? legacy)
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
            pause()
            displayID = displays.first?.id ?? 0
        }
        refresh()
    }

    func toggle(_ side: DimSide) { state.setEnabled(!state.isEnabled(for: side), for: side) }
    func setBrightness(_ value: Double, for side: DimSide) { state.setBrightness(value, for: side) }
    func toggleAll() { state.toggleAll() }
    func pause() { state.pause() }
    func swapSide() { state.swapSides() }

    private func refresh() {
        if let screen = NSScreen.screens.first(where: { Self.id(of: $0) == displayID }) {
            overlay.update(on: screen, state: state, divider: divider)
        } else {
            overlay.hide()
        }
        onStateChange?(isEnabled)
    }

    private func save() {
        defaults.set(state.leftBrightness, forKey: "leftBrightness")
        defaults.set(state.rightBrightness, forKey: "rightBrightness")
        defaults.set(divider, forKey: "divider")
        defaults.set(Int(displayID), forKey: "displayID")
    }

    private static func id(of screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
