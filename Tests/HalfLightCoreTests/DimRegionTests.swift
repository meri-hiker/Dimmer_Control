import XCTest
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
