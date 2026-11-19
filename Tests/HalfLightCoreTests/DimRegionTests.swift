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
