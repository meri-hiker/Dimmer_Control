import XCTest
import CoreGraphics
@testable import HalfLightCore

final class DimRegionTests: XCTestCase {
    func testEqualHalvesCoverScreenWithoutOverlap() {
        let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let left = DimRegion.frame(in: screen, side: .left, divider: 0.5)
        let right = DimRegion.frame(in: screen, side: .right, divider: 0.5)
        XCTAssertEqual(left.width, 756)
        XCTAssertEqual(left.maxX, right.minX)
        XCTAssertEqual(left.union(right), screen)
        XCTAssertEqual(left.height, screen.height)
    }

    func testExternalDisplayWithNegativeOriginAndUnevenSplit() {
        let screen = CGRect(x: -1920, y: -240, width: 1920, height: 1080)
        let left = DimRegion.frame(in: screen, side: .left, divider: 0.35)
        let right = DimRegion.frame(in: screen, side: .right, divider: 0.35)
        XCTAssertEqual(left, CGRect(x: -1920, y: -240, width: 672, height: 1080))
        XCTAssertEqual(right.minX, left.maxX)
        XCTAssertEqual(right.maxX, 0)
        XCTAssertEqual(right.minY, -240)
        XCTAssertEqual(left.union(right), screen)
    }

    func testOddWidthsHaveNoGapAtDivider() {
        let screen = CGRect(x: 20, y: 30, width: 1513, height: 981)
        let left = DimRegion.frame(in: screen, side: .left, divider: 0.5)
        let right = DimRegion.frame(in: screen, side: .right, divider: 0.5)
        XCTAssertEqual(left.maxX, right.minX)
        XCTAssertEqual(left.width + right.width, screen.width)
    }

    func testInvalidPreferencesCannotBlackOutEntireScreen() {
        XCTAssertEqual(DimRegion.opacity(1), 0.85)
        XCTAssertEqual(DimRegion.opacity(-1), 0.1)
        XCTAssertEqual(DimRegion.opacity(.nan), 0.55)
        XCTAssertEqual(DimRegion.opacity(.infinity), 0.55)
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        XCTAssertEqual(DimRegion.frame(in: screen, side: .left, divider: 8).width, 800)
        XCTAssertEqual(DimRegion.frame(in: screen, side: .left, divider: -1).width, 200)
        XCTAssertEqual(DimRegion.frame(in: screen, side: .left, divider: .nan).width, 500)
    }
}

final class DimmingStateTests: XCTestCase {
    func testEachSideCanBeEnabledAndDisabledIndependently() {
        var state = DimmingState()
        XCTAssertFalse(state.isEnabled)
        state.setEnabled(true, for: .left)
        XCTAssertTrue(state.leftEnabled)
        XCTAssertFalse(state.rightEnabled)
        state.setEnabled(true, for: .right)
        state.setEnabled(false, for: .left)
        XCTAssertFalse(state.leftEnabled)
        XCTAssertTrue(state.rightEnabled)
        state.setEnabled(false, for: .right)
        XCTAssertFalse(state.isEnabled)
    }

    func testEveryBrightnessChangeImmediatelyChangesOnlyItsSideOpacity() {
        var state = DimmingState(leftBrightness: 0.45, rightBrightness: 0.6)
        state.setEnabled(true, for: .left)
        state.setEnabled(true, for: .right)
        for value in stride(from: 0.15, through: 0.9, by: 0.01) {
            state.setBrightness(value, for: .left)
            XCTAssertEqual(state.opacity(for: .left), 1 - value, accuracy: 0.000001)
            XCTAssertEqual(state.opacity(for: .right), 0.4, accuracy: 0.000001)
            XCTAssertTrue(state.leftEnabled && state.rightEnabled)
        }
        state.setBrightness(0.8, for: .right)
        XCTAssertEqual(state.opacity(for: .right), 0.2, accuracy: 0.000001)
    }

    func testPauseAndResumeRestoreBothSidesAndTheirLevels() {
        var state = DimmingState(leftBrightness: 0.2, rightBrightness: 0.8)
        state.setEnabled(true, for: .left)
        state.setEnabled(true, for: .right)
        state.toggleAll()
        XCTAssertFalse(state.isEnabled)
        state.toggleAll()
        XCTAssertTrue(state.leftEnabled && state.rightEnabled)
        XCTAssertEqual(state.leftBrightness, 0.2)
        XCTAssertEqual(state.rightBrightness, 0.8)
        state.setEnabled(false, for: .right)
        state.pause()
        state.toggleAll()
        XCTAssertTrue(state.leftEnabled)
        XCTAssertFalse(state.rightEnabled)
    }

    func testSwapMovesPowerAndBrightnessTogetherEvenWhenPaused() {
        var state = DimmingState(leftBrightness: 0.25, rightBrightness: 0.75)
        state.setEnabled(true, for: .left)
        state.swapSides()
        XCTAssertFalse(state.leftEnabled)
        XCTAssertTrue(state.rightEnabled)
        XCTAssertEqual(state.rightBrightness, 0.25)
        XCTAssertEqual(state.leftBrightness, 0.75)
        state.pause()
        state.swapSides()
        state.toggleAll()
        XCTAssertTrue(state.leftEnabled)
        XCTAssertFalse(state.rightEnabled)
        XCTAssertEqual(state.leftBrightness, 0.25)
    }

    func testBrightnessBoundsAndStartupSafety() {
        var state = DimmingState(leftBrightness: .nan, rightBrightness: .infinity)
        XCTAssertFalse(state.isEnabled)
        XCTAssertEqual(state.leftBrightness, 0.45)
        XCTAssertEqual(state.rightBrightness, 0.45)
        state.setBrightness(-10, for: .left)
        state.setBrightness(10, for: .right)
        XCTAssertEqual(state.leftBrightness, 0.15)
        XCTAssertEqual(state.rightBrightness, 0.9)
        XCTAssertFalse(state.isEnabled)
    }
}

#if HALFLIGHT_APP_TESTS
import AppKit
import SwiftUI

final class LiveControlsTests: XCTestCase {
    @MainActor
    func testContinuousSliderUpdatesOverlayBeforeActionReturns() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.screens.first)
        let model = DimmerModel()
        model.displayID = try XCTUnwrap(model.displays.first).id
        model.toggle(.left)
        let host = NSHostingView(rootView: ControlsView(model: model, shortcutsAvailable: false))
        let window = NSWindow(contentRect: NSRect(x: 40, y: 40, width: 350, height: 650),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFront(nil)
        defer { model.pause(); window.close() }
        host.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        func sliders(in view: NSView) -> [NSSlider] {
            (view as? NSSlider).map { [$0] } ?? view.subviews.flatMap { sliders(in: $0) }
        }
        let slider = try XCTUnwrap(sliders(in: host).first { $0.accessibilityLabel() == "Left side brightness" })
        XCTAssertTrue(slider.isContinuous, "Mouse tracking must emit values before mouse-up.")
        XCTAssertTrue(slider.isEnabled)
        let leftFrame = DimRegion.frame(in: screen.frame, side: .left, divider: model.divider)
        let panel = try XCTUnwrap(NSApp.windows.first { $0.ignoresMouseEvents && $0.frame == leftFrame })
        let untouchedRight = model.state.rightBrightness
        for brightness in [0.2, 0.35, 0.6, 0.85] {
            slider.doubleValue = brightness
            XCTAssertTrue(slider.sendAction(slider.action, to: slider.target))
            // These assertions run immediately, without mouse-up or a run-loop wait.
            XCTAssertEqual(model.state.leftBrightness, brightness, accuracy: 0.000001)
            XCTAssertEqual(panel.alphaValue, CGFloat(1 - brightness), accuracy: 0.000001)
            XCTAssertEqual(model.state.rightBrightness, untouchedRight)
            XCTAssertFalse(model.state.rightEnabled)
        }
        model.toggle(.right)
        let rightFrame = DimRegion.frame(in: screen.frame, side: .right, divider: model.divider)
        let rightPanel = try XCTUnwrap(NSApp.windows.first { $0.ignoresMouseEvents && $0.frame == rightFrame })
        XCTAssertTrue(panel.isVisible && rightPanel.isVisible)
        model.toggle(.left)
        XCTAssertFalse(panel.isVisible)
        XCTAssertTrue(rightPanel.isVisible)
    }
}
#endif
