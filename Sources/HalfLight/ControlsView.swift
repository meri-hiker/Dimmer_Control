import AppKit
import SwiftUI
import HalfLightCore

struct ControlsView: View {
    @ObservedObject var model: DimmerModel
    let shortcutsAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HalfLight").font(.title3.weight(.semibold))
                    Text("A little less distraction.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(model.isEnabled ? "ON" : "OFF")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(model.isEnabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            preview

            Toggle("Dim split screen", isOn: $model.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)
                .help("Enable after arranging two apps side by side. Turn off when leaving Split View.")

            VStack(alignment: .leading, spacing: 8) {
                Text("DIMMED SIDE").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Picker("Dimmed side", selection: $model.side) {
                    ForEach(DimSide.allCases) { side in Text(side.title).tag(side) }
                }
                .pickerStyle(.segmented).labelsHidden()
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Darkness")
                    Spacer()
                    Text("\(Int(model.intensity * 100))%")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $model.intensity, in: 0.1...0.85, step: 0.01)
                    .accessibilityLabel("Darkness")
                    .accessibilityValue("\(Int(model.intensity * 100)) percent")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Split position")
                    Spacer()
                    Button("Reset") { model.divider = 0.5 }
                        .buttonStyle(.link).font(.caption)
                    Text("\(Int(model.divider * 100)) / \(100 - Int(model.divider * 100))")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $model.divider, in: 0.2...0.8, step: 0.01)
                    .accessibilityLabel("Split position measured from the left")
                Text("Match the divider between your two apps.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if model.displays.count > 1 {
                Picker("Display", selection: $model.displayID) {
                    ForEach(model.displays) { display in
                        Text(display.name).tag(display.id)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Enable in Split View; pause when you leave.\nYour apps stay clickable through the shade.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if shortcutsAvailable {
                    HStack {
                        Text("Toggle  ⌃⌥⌘D")
                        Spacer()
                        Text("Swap  ⌃⌥⌘S")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                    .accessibilityLabel("Control Option Command D toggles dimming. Control Option Command S swaps sides.")
                } else {
                    Text("Shortcuts unavailable; use the controls above.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            HStack {
                Button("Pause") { model.pause() }.disabled(!model.isEnabled)
                Spacer()
                Button("Quit HalfLight") { NSApp.terminate(nil) }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 350)
    }

    private var preview: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 3) {
                    previewPane(title: "Left", symbol: "doc.text", width: geometry.size.width * model.divider - 1.5)
                    previewPane(title: "Right", symbol: "text.alignleft", width: geometry.size.width * (1 - model.divider) - 1.5)
                }
                if model.isEnabled {
                    Rectangle().fill(.black.opacity(model.intensity))
                        .frame(width: geometry.size.width * (model.side == .left ? model.divider : 1 - model.divider))
                        .offset(x: model.side == .left ? 0 : geometry.size.width * model.divider)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.primary.opacity(0.12)))
        }
        .frame(height: 104)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.isEnabled ? "Preview: \(model.side.title) side dimmed" : "Preview: dimming paused")
    }

    private func previewPane(title: String, symbol: String, width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 24, weight: .light))
            Text(title).font(.caption)
        }
        .foregroundStyle(.white.opacity(0.9))
        .frame(width: max(0, width), height: 104)
        .background(title == "Left" ? Color(red: 0.29, green: 0.32, blue: 0.55) : Color(red: 0.34, green: 0.45, blue: 0.50))
    }
}
