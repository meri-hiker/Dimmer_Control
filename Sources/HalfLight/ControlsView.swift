import AppKit
import SwiftUI
import HalfLightCore

struct ControlsView: View {
    @ObservedObject var model: DimmerModel
    let shortcutsAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 26, weight: .light)).foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HalfLight").font(.title3.weight(.semibold))
                    Text("A little less distraction.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(model.isEnabled ? "ON" : "OFF")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(model.isEnabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            preview
            ForEach(DimSide.allCases) { side in sideControls(side) }

            VStack(spacing: 6) {
                HStack {
                    Text("Split position")
                    Spacer()
                    Button("Reset") { model.divider = 0.5 }.buttonStyle(.link).font(.caption)
                    Text("\(Int((model.divider * 100).rounded())) / \(100 - Int((model.divider * 100).rounded()))")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                LiveSlider(value: $model.divider, range: 0.2...0.8,
                           label: "Split position measured from the left")
                    .frame(height: 20)
                Text("Match the divider between your two apps.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if model.displays.count > 1 {
                Picker("Display", selection: $model.displayID) {
                    ForEach(model.displays) { display in Text(display.name).tag(display.id) }
                }
            }

            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Enable either or both sides in Split View.\nYour apps stay clickable through the shade.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if shortcutsAvailable {
                    HStack {
                        Text("Pause / resume  ⌃⌥⌘D")
                        Spacer()
                        Text("Swap  ⌃⌥⌘S")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                    .accessibilityLabel("Control Option Command D pauses or resumes dimming. Control Option Command S swaps side settings.")
                } else {
                    Text("Shortcuts unavailable; use the controls above.").font(.caption2).foregroundStyle(.secondary)
                }
            }
            HStack {
                Button("Pause both") { model.pause() }.disabled(!model.isEnabled)
                Spacer()
                Button("Quit HalfLight") { NSApp.terminate(nil) }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(22).frame(width: 350)
    }

    private func sideControls(_ side: DimSide) -> some View {
        let enabled = model.state.isEnabled(for: side)
        let brightness = model.state.brightness(for: side)
        return VStack(spacing: 8) {
            HStack {
                Label("\(side.title) side", systemImage: side == .left ? "rectangle.lefthalf.filled" : "rectangle.righthalf.filled")
                    .font(.headline)
                Spacer()
                Button { model.toggle(side) } label: {
                    Label(enabled ? "On" : "Off", systemImage: "power")
                        .frame(minWidth: 46)
                }
                .buttonStyle(.borderedProminent)
                .tint(enabled ? Color.indigo : Color.gray)
                .controlSize(.small)
                .accessibilityLabel("Turn \(side.rawValue) dimmer \(enabled ? "off" : "on")")
                .accessibilityValue(enabled ? "On" : "Off")
            }
            HStack {
                Text("Brightness").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((brightness * 100).rounded()))%")
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
            LiveSlider(value: Binding(get: { model.state.brightness(for: side) },
                                      set: { model.setBrightness($0, for: side) }),
                       range: 0.15...0.9, label: "\(side.title) side brightness")
                .frame(height: 20).disabled(!enabled)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var preview: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(DimSide.allCases) { side in
                    let fraction = side == .left ? model.divider : 1 - model.divider
                    VStack(spacing: 8) {
                        Image(systemName: side == .left ? "doc.text" : "text.alignleft")
                            .font(.system(size: 22, weight: .light))
                        Text(side.title).font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: geometry.size.width * fraction, height: 88)
                    .background(side == .left ? Color(red: 0.29, green: 0.32, blue: 0.55) : Color(red: 0.34, green: 0.45, blue: 0.50))
                    .overlay(Color.black.opacity(model.state.isEnabled(for: side) ? model.state.opacity(for: side) : 0))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.primary.opacity(0.12)))
        }
        .frame(height: 88)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview. Left dimmer \(model.state.leftEnabled ? "on" : "off"); right dimmer \(model.state.rightEnabled ? "on" : "off").")
    }
}

/// AppKit delivers every drag event synchronously, including during mouse tracking.
/// Updating the binding calls the model and overlay before this action returns.
private struct LiveSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound,
                              target: context.coordinator, action: #selector(Coordinator.changed(_:)))
        slider.isContinuous = true
        slider.setAccessibilityLabel(label)
        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        context.coordinator.parent = self
        slider.doubleValue = value
        slider.isEnabled = context.environment.isEnabled
        slider.setAccessibilityLabel(label)
        slider.setAccessibilityValue("\(Int((value * 100).rounded())) percent")
    }

    final class Coordinator: NSObject {
        var parent: LiveSlider
        init(_ parent: LiveSlider) { self.parent = parent }
        @objc func changed(_ slider: NSSlider) { parent.value = slider.doubleValue }
    }
}
