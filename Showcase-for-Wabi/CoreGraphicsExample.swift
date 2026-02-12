//
//  CoreGraphicsExample.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import UIKit
import MapKit

public protocol MapRenderable {
    var iconImage: UIImage { get }
    var rotationDegrees: Double { get }
    var shouldFlipHorizontally: Bool { get }
    var shouldDrawOutline: Bool { get }

    // nil disables shadow for this item.
    var shadowMetric: Double? { get }
}

public final class GenericAnnotationView<Item: MapRenderable>: MKAnnotationView {

    enum RenderConfig {
        static let anchorYFactor: CGFloat = 0.5
        static let iconSize: CGSize = CGSize(width: 24, height: 24)
        static let showsShadow: Bool = true
        static let isLightBackground: Bool = false
        static let detailMultiplier: Double = 1.0
        static let outlineColor: UIColor = .systemBlue
    }

    public var item: Item? {
        didSet {
            setNeedsDisplay()
        }
    }

    public private(set) var lastDrawnImage: UIImage?
    public private(set) var lastDrawnRotationBucket: Double = 0

    public override func draw(_ rect: CGRect) {
        guard let item else { return }

        let icon = item.iconImage
        lastDrawnImage = icon

        let rotation = item.rotationDegrees
        lastDrawnRotationBucket = (rotation + 5) / 10

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }

        let size = rect.size
        context.translateBy(x: 0.5 * size.width, y: RenderConfig.anchorYFactor * size.height)

        if rotation != 0 {
            context.rotate(by: rotation * Double.pi / 180.0)
        }

        if item.shouldFlipHorizontally && rotation < 180.0 {
            context.scaleBy(x: -1, y: 1)
        }

        if RenderConfig.showsShadow, let metric = item.shadowMetric {
            applyShadow(metric: metric, in: context)
        }

        if item.shouldDrawOutline {
            drawOutline(for: icon, in: context)
        }

        icon.draw(in: centeredRect(size: RenderConfig.iconSize))
    }

    // MARK: - Helpers

    private func applyShadow(metric: Double, in context: CGContext) {
        let detail = max(RenderConfig.detailMultiplier, 0.5)

        let offset = min(1.0 + metric * 0.001, 7.0) * detail
        let blur = min(1.0 + metric * 0.0002, 5.0) * detail

        let alpha: CGFloat = RenderConfig.isLightBackground ? 0.4 : 0.6
        context.setShadow(
            offset: CGSize(width: 0, height: offset),
            blur: CGFloat(blur),
            color: UIColor(white: 0, alpha: alpha).cgColor
        )
    }

    private func drawOutline(for icon: UIImage, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setShadow(offset: .zero, blur: 0, color: nil)

        let outlineWidth: CGFloat = 1 / UIScreen.main.scale
        let outlined = icon.withTintColor(RenderConfig.outlineColor, renderingMode: .alwaysOriginal)

        let base = centeredRect(size: RenderConfig.iconSize)
        let offsets: [(CGFloat, CGFloat)] = [
            (-outlineWidth, 0), (outlineWidth, 0),
            (0, -outlineWidth), (0, outlineWidth),
            (-outlineWidth, -outlineWidth), (-outlineWidth, outlineWidth),
            (outlineWidth, -outlineWidth), (outlineWidth, outlineWidth)
        ]

        for (dx, dy) in offsets {
            outlined.draw(in: base.offsetBy(dx: dx, dy: dy))
        }
    }

    private func centeredRect(size: CGSize) -> CGRect {
        CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height)
    }
}


