# iOS UI + Interaction Showcase

A small, domain-neutral set of iOS snippets extracted and anonymized from production-style work to demonstrate architecture, UI composition, and interaction handling without exposing any client/product details.

## Tooling

- Xcode **26.2**
- Swift **6.2**

## What’s inside

- **SwiftUI: Info Panel**
  - Measurement-driven layout (dynamic corner rounding / media alignment)
  - View-ViewModel separation (`ObservableObject`)
  - Self-contained helpers (size reading, per-corner rounding)

- **UIKit: Passive Touch Tracking**
  - A *non-interfering* `UIGestureRecognizer` that observes touch state without “recognizing”
  - Deterministic, unit-testable pinch state machine (`PinchLogic`)
  - Combine publishers for observability

- **UIKit/MapKit: Generic Annotation Rendering**
  - `MKAnnotationView` rendering driven by a `MapRenderable` protocol
  - Shadow + outline rendering and transform logic (rotation / optional flipping)

## Goals

- Showcase **implementation details** (layout, state management, testability, gesture plumbing)
- Avoid all domain/product identifiers (names, assets, endpoints, proprietary types)
- Keep examples readable and suitable for discussion in interviews / contracts

## License

MIT (or your preferred license).
