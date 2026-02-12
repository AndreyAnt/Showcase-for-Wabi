//
//  PassiveTouchTrackerGestureRecognizer.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import Foundation
import UIKit
import Combine

/// A passive tracker that observes touches without ever "recognizing"
final class PassiveTouchTrackerGestureRecognizer: UIGestureRecognizer {

    // MARK: - Public Observables
    public var userIsPinching: AnyPublisher<Bool, Never> { _userIsPinching.removeDuplicates().eraseToAnyPublisher() }
    public var userIsTouching: AnyPublisher<Bool, Never> { _userIsTouching.removeDuplicates().eraseToAnyPublisher() }
    public var recentIsPinchingStatus: Bool { _userIsPinching.value }
    public var recentIsTouchingStatus: Bool { _userIsTouching.value }

    private let _userIsPinching: CurrentValueSubject<Bool, Never> = .init(false)
    private let _userIsTouching: CurrentValueSubject<Bool, Never> = .init(false)

    /// If you want "pinching" to mean "two fingers down", set this to 0.
    /// Otherwise, use a small value (e.g. 6–12 points) to avoid treating
    /// two-finger taps/holds as pinches.
    var pinchDistanceActivationThreshold: CGFloat {
        get { pinchLogic.activationThreshold }
        set { pinchLogic.activationThreshold = newValue }
    }

    // MARK: - Private state
    private var activeTouches: [ObjectIdentifier: UITouch] = [:]
    private var pinchLogic = PinchLogic(activationThreshold: 8)

    // MARK: - Init
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)

        // Non-interference defaults.
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    // MARK: - Touch lifecycle
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        touches.forEach {
            activeTouches[ObjectIdentifier($0)] = $0
        }

        updateTouchingAndPinchingFlags()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        // We only need movement to decide whether a 2-finger contact is a "pinch".
        updateTouchingAndPinchingFlags()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        touches.forEach {
            activeTouches.removeValue(forKey: ObjectIdentifier($0))
        }

        updateTouchingAndPinchingFlags()

        // Force a clean reset cycle.
        if activeTouches.isEmpty {
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)

        touches.forEach {
            activeTouches.removeValue(forKey: ObjectIdentifier($0))
        }

        updateTouchingAndPinchingFlags()

        if activeTouches.isEmpty {
            state = .failed
        }
    }

    override func reset() {
        super.reset()

        activeTouches.removeAll()
        pinchLogic.reset()

        _userIsTouching.send(false)
        _userIsPinching.send(false)
    }

    // MARK: - Non-interference guarantees
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    // MARK: - Helper
    private func updateTouchingAndPinchingFlags() {
        _userIsTouching.send(!activeTouches.isEmpty)

        guard activeTouches.count >= 2 else {
            pinchLogic.reset()
            _userIsPinching.send(false)
            return
        }

        guard let view else {
            pinchLogic.reset()
            _userIsPinching.send(false)
            return
        }

        let touchesArray = Array(activeTouches.values)
        let p1 = touchesArray[0].location(in: view)
        let p2 = touchesArray[1].location(in: view)

        let pinchingNow = pinchLogic.update(withPoints: [p1, p2])
        _userIsPinching.send(pinchingNow)
    }
}

// MARK: - Testable pinch state machine
extension PassiveTouchTrackerGestureRecognizer {

    /// Deterministic pinch detection logic extracted from the gesture recognizer.
    ///
    /// This enables unit testing without constructing `UITouch` / `UIEvent`.
    struct PinchLogic {
        var activationThreshold: CGFloat
        private var initialDistance: CGFloat?
        private(set) var isPinching: Bool = false

        init(activationThreshold: CGFloat) {
            self.activationThreshold = activationThreshold
        }

        mutating func reset() {
            initialDistance = nil
            isPinching = false
        }

        /// Updates state from touch points; returns current `isPinching`.
        /// - Important: This expects either 0/1 points (no pinch) or 2+ points.
        ///   If more than 2 points are provided, only the first two are used.
        mutating func update(withPoints points: [CGPoint]) -> Bool {
            guard points.count >= 2 else {
                reset()
                return false
            }

            if activationThreshold <= 0 {
                isPinching = true
                return true
            }

            let p1 = points[0]
            let p2 = points[1]
            let distance = hypot(p1.x - p2.x, p1.y - p2.y)

            if initialDistance == nil {
                initialDistance = distance
                isPinching = false
                return false
            }

            if isPinching {
                return true
            }

            let delta = abs(distance - (initialDistance ?? distance))
            if delta >= activationThreshold {
                isPinching = true
            }

            return isPinching
        }
    }
}
