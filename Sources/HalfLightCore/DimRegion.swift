import Foundation
import CoreGraphics

public enum DimSide: String, CaseIterable, Identifiable {
    case left, right
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}

public enum DimRegion {
    /// Uses global AppKit coordinates, including displays with negative origins.
    public static func frame(in screen: CGRect, side: DimSide, divider: Double) -> CGRect {
        let fraction = min(0.8, max(0.2, divider.isFinite ? divider : 0.5))
        let splitX = screen.minX + (screen.width * fraction).rounded()
        switch side {
        case .left:
            return CGRect(x: screen.minX, y: screen.minY,
                          width: splitX - screen.minX, height: screen.height)
        case .right:
            return CGRect(x: splitX, y: screen.minY,
                          width: screen.maxX - splitX, height: screen.height)
        }
    }

    public static func opacity(_ value: Double) -> Double {
        min(0.85, max(0.1, value.isFinite ? value : 0.55))
    }
}

/// Independent side controls with a remembered selection for the global shortcut.
public struct DimmingState {
    public private(set) var leftEnabled = false
    public private(set) var rightEnabled = false
    public private(set) var leftBrightness: Double
    public private(set) var rightBrightness: Double
    private var resumeLeft = true
    private var resumeRight = false

    public init(leftBrightness: Double = 0.45, rightBrightness: Double = 0.45) {
        self.leftBrightness = Self.clamp(leftBrightness)
        self.rightBrightness = Self.clamp(rightBrightness)
    }

    public var isEnabled: Bool { leftEnabled || rightEnabled }
    public func isEnabled(for side: DimSide) -> Bool { side == .left ? leftEnabled : rightEnabled }
    public func brightness(for side: DimSide) -> Double { side == .left ? leftBrightness : rightBrightness }
    public func opacity(for side: DimSide) -> Double { 1 - brightness(for: side) }

    public mutating func setEnabled(_ enabled: Bool, for side: DimSide) {
        if side == .left { leftEnabled = enabled } else { rightEnabled = enabled }
        if isEnabled {
            resumeLeft = leftEnabled
            resumeRight = rightEnabled
        }
    }

    public mutating func setBrightness(_ value: Double, for side: DimSide) {
        if side == .left { leftBrightness = Self.clamp(value) }
        else { rightBrightness = Self.clamp(value) }
    }

    public mutating func pause() {
        if isEnabled {
            resumeLeft = leftEnabled
            resumeRight = rightEnabled
        }
        leftEnabled = false
        rightEnabled = false
    }

    public mutating func toggleAll() {
        if isEnabled { pause() }
        else {
            leftEnabled = resumeLeft
            rightEnabled = resumeRight
        }
    }

    public mutating func swapSides() {
        swap(&leftEnabled, &rightEnabled)
        swap(&leftBrightness, &rightBrightness)
        swap(&resumeLeft, &resumeRight)
    }

    private static func clamp(_ value: Double) -> Double {
        min(0.9, max(0.15, value.isFinite ? value : 0.45))
    }
}
