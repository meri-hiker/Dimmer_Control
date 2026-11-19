import Foundation

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
