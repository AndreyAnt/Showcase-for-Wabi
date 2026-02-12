//
//  PassiveTouchTrackerGestureRecognizerPinchLogicTests.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import XCTest
import Combine
@testable import CoreModule

final class PassiveTouchTrackerGestureRecognizerPinchLogicTests: XCTestCase {

    func test_noTouches_isNotPinching() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 8)

        XCTAssertFalse(logic.update(withPoints: []))
        XCTAssertFalse(logic.isPinching)
    }

    func test_singleTouch_isNotPinching() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 8)

        XCTAssertFalse(logic.update(withPoints: [CGPoint(x: 10, y: 10)]))
        XCTAssertFalse(logic.isPinching)
    }

    func test_twoTouches_thresholdPositive_requiresDistanceChange() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 8)

        // First 2-finger contact: establishes baseline distance, should not yet be a pinch.
        XCTAssertFalse(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10)]))
        XCTAssertFalse(logic.isPinching)

        // Small change below threshold: still not pinching.
        XCTAssertFalse(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 16)])) // delta 6
        XCTAssertFalse(logic.isPinching)

        // Change beyond threshold: pinching becomes true.
        XCTAssertTrue(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 20)])) // delta 10
        XCTAssertTrue(logic.isPinching)
    }

    func test_twoTouches_thresholdZero_isPinchingImmediately() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 0)

        XCTAssertTrue(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)]))
        XCTAssertTrue(logic.isPinching)
    }

    func test_pinchingStaysTrue_untilTouchCountDropsBelowTwo() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 8)

        _ = logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10)])
        _ = logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 25)]) // activate pinch
        XCTAssertTrue(logic.isPinching)

        // Move back closer than threshold — should remain true once activated.
        XCTAssertTrue(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 12)]))
        XCTAssertTrue(logic.isPinching)

        // Drop to 1 finger — should reset to not pinching.
        XCTAssertFalse(logic.update(withPoints: [CGPoint(x: 0, y: 0)]))
        XCTAssertFalse(logic.isPinching)
    }

    func test_reset_clearsPinchingState() {
        var logic = PassiveTouchTrackerGestureRecognizer.PinchLogic(activationThreshold: 8)

        _ = logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10)])
        _ = logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 25)])
        XCTAssertTrue(logic.isPinching)

        logic.reset()
        XCTAssertFalse(logic.isPinching)

        // After reset, initial 2-finger contact should again be a baseline (not pinching).
        XCTAssertFalse(logic.update(withPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10)]))
        XCTAssertFalse(logic.isPinching)
    }
}

final class PassiveTouchTrackerGestureRecognizerAPITests: XCTestCase {

    func test_publishersEmitInitialFalse() {
        let gestureRecognizer = PassiveTouchTrackerGestureRecognizer()

        var touching: [Bool] = []
        var pinching: [Bool] = []

        let cancellable1 = gestureRecognizer.userIsTouching.sink { touching.append($0) }
        let cancellable2 = gestureRecognizer.userIsPinching.sink { pinching.append($0) }

        XCTAssertEqual(touching, [false])
        XCTAssertEqual(pinching, [false])

        cancellable1.cancel()
        cancellable2.cancel()
    }

    func test_recentStatusProperties_startFalse() {
        let gestureRecognizer = PassiveTouchTrackerGestureRecognizer()
        XCTAssertFalse(gestureRecognizer.recentIsTouchingStatus)
        XCTAssertFalse(gestureRecognizer.recentIsPinchingStatus)
    }

    func test_nonInterferenceContract() {
        let gestureRecognizer = PassiveTouchTrackerGestureRecognizer()
        let other = UIPanGestureRecognizer()

        XCTAssertFalse(gestureRecognizer.canPrevent(other))
        XCTAssertFalse(gestureRecognizer.canBePrevented(by: other))
    }
}
