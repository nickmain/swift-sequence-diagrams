// Copyright (c) 2023 David N Main

import SwiftUI

fileprivate class RenderingPrimitive<ColorScheme> {
    /// Draw the primitive in the given context
    public func draw(gc: GraphicsContext, colors: ColorScheme) {}
}

public class RenderModel<ColorScheme> {

    fileprivate var textToBeResolved = [RenderText<ColorScheme>]()
    private var layers = [RenderLayer<ColorScheme>]()
    private let backgroundColor: KeyPath<ColorScheme, Color>?

    /// Initialized to the canvas size before rendering
    let canvasSize = MutableSize()

    /// - Parameter backgroundColor: optional background fill for the canvas
    public init(backgroundColor: KeyPath<ColorScheme, Color>? = nil) {
        self.backgroundColor = backgroundColor
    }

    /// Render this model
    public func render(gc: GraphicsContext, canvasSize: CGSize, colors: ColorScheme) {
        self.canvasSize.set(cgsize: canvasSize)

        if let backgroundColor {
            gc.fill(Path(CGRect(origin: .zero, size: canvasSize)),
                    with: .color(colors[keyPath: backgroundColor]))
        }

        for text in textToBeResolved { text.resolve(gc: gc, colors: colors) }
        for layer in layers { layer.draw(gc: gc, colors: colors) }
    }

    /// Create a new layer for adding rendering primitives.
    ///
    /// Layers are drawn in the order they are created.
    ///
    public func newLayer() -> RenderLayer<ColorScheme> {
        let layer = RenderLayer(parentModel: self)
        layers.append(layer)
        return layer
    }
}

/// Layers are drawn in the order they are created
public class RenderLayer<ColorScheme> {

    private var primitives = [RenderingPrimitive<ColorScheme>]()
    private let parentModel: RenderModel<ColorScheme>

    fileprivate init(parentModel: RenderModel<ColorScheme>) {
        self.parentModel = parentModel
    }

    fileprivate func draw(gc: GraphicsContext, colors: ColorScheme) {
        for prim in primitives {
            prim.draw(gc: gc, colors: colors)
        }
    }

    /// Add text to be drawn.
    ///
    /// The text is resolved before any drawing occurs and the size of the
    /// resolved text is used to initialize the given Size.
    ///
    /// - Parameters:
    ///    - text: the rext to be resolved and rendered
    ///    - color: the path to a foreground color to be applied to the text
    ///    - size: the size to be initialized when the text is resolved
    ///    - point: the point to render the text at
    ///    - anchor: the unit point for rendering
    ///
    func add(text: Text, color: KeyPath<ColorScheme, Color>, size: MutableSize, point: Point, anchor: UnitPoint) {
        let rt = RenderText(text: text, color: color, size: size, point: point, anchor: anchor)
        parentModel.textToBeResolved.append(rt)
        primitives.append(rt)
    }

    /// Add a rectangle to be drawn
    ///
    /// - Parameters:
    ///    - rect: the rectangle to draw
    ///    - fillColor: if present, fill the rectangle with this color
    ///    - strokeColor: if present (along with stroke style), stroke the rectangle
    ///    - stroke: if present (along with stroke color), stroke the rectangle
    ///
    func add(rect: Rect,
             fillColor: KeyPath<ColorScheme, Color>? = nil,
             strokeColor: KeyPath<ColorScheme, Color>? = nil,
             stroke: StrokeStyle? = nil) {
        primitives.append(RenderRect(rect: rect,
                                     fillColor: fillColor,
                                     strokeColor: strokeColor, stroke: stroke))
    }

    /// Add an image to be drawn
    ///
    /// - Parameters:
    ///    - image: the image to draw
    ///    - rect: the rectangle to draw in
    ///    - shading: optional shading to apply to the image
    ///
    func add(image: Image, rect: Rect, shading: KeyPath<ColorScheme, Color>? = nil) {
        primitives.append(RenderImage(image: image, shading: shading, rect: rect))
    }

    /// Add a line to be drawn
    ///
    /// - Parameters:
    ///    - line: the points that define the line
    ///    - color: the line color
    ///    - stroke: the line stroke style
    ///
    func add(line points: Point..., color: KeyPath<ColorScheme, Color>, stroke: StrokeStyle) {
        primitives.append(RenderLine(points: points, color: color, stroke: stroke))
    }

    /// Add a path to be filled
    ///
    /// - Parameters:
    ///    - path: the points that define the path
    ///    - color: the fill color
    ///
    func addFilled(path points: [Point], color: KeyPath<ColorScheme, Color>) {
        primitives.append(RenderFilledPath(points: points, color: color))
    }

    /// Add a path to be drawn
    ///
    /// - Parameters:
    ///    - path: thunk to create the path
    ///    - color: the line color
    ///    - stroke: the line stroke style
    ///
    func add(path: @escaping () -> Path, color: KeyPath<ColorScheme, Color>, stroke: StrokeStyle) {
        primitives.append(RenderPath(path: path, color: color, stroke: stroke))
    }
}

/// Draw a rectangle
fileprivate class RenderRect<ColorScheme>: RenderingPrimitive<ColorScheme> {
    private let rect: Rect
    private let fillColor: KeyPath<ColorScheme, Color>?
    private let strokeColor: KeyPath<ColorScheme, Color>?
    private let stroke: StrokeStyle?

    fileprivate init(rect: Rect,
                     fillColor: KeyPath<ColorScheme, Color>?,
                     strokeColor: KeyPath<ColorScheme, Color>?,
                     stroke: StrokeStyle?) {
        self.rect = rect
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.stroke = stroke
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        let path = Path(rect.cgrect)

        if let fillColor {
            gc.fill(path, with: .color(colors[keyPath: fillColor]))
        }

        if let strokeColor, let stroke {
            gc.stroke(path, with: .color(colors[keyPath: strokeColor]), style: stroke)
        }
    }
}

/// Draw a line
fileprivate class RenderLine<ColorScheme>: RenderingPrimitive<ColorScheme> {
    fileprivate let points: [Point]
    fileprivate let color: KeyPath<ColorScheme, Color>
    fileprivate let stroke: StrokeStyle

    fileprivate init(points: [Point], color: KeyPath<ColorScheme, Color>, stroke: StrokeStyle) {
        self.points = points
        self.color = color
        self.stroke = stroke
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        var linePath = Path()
        linePath.addLines(points.map { $0.cgpoint })
        gc.stroke(linePath, with: .color(colors[keyPath: color]), style: stroke)
    }
}

/// Draw a filled path
fileprivate class RenderFilledPath<ColorScheme>: RenderingPrimitive<ColorScheme> {
    fileprivate let points: [Point]
    fileprivate let color: KeyPath<ColorScheme, Color>

    fileprivate init(points: [Point], color: KeyPath<ColorScheme, Color>) {
        self.points = points
        self.color = color
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        var path = Path()
        path.addLines(points.map { $0.cgpoint })
        gc.fill(path, with: .color(colors[keyPath: color]))
    }
}

/// Draw a path
fileprivate class RenderPath<ColorScheme>: RenderingPrimitive<ColorScheme> {
    fileprivate let path: () -> Path
    fileprivate let color: KeyPath<ColorScheme, Color>
    fileprivate let stroke: StrokeStyle

    fileprivate init(path: @escaping () -> Path, color: KeyPath<ColorScheme, Color>, stroke: StrokeStyle) {
        self.path = path
        self.color = color
        self.stroke = stroke
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        gc.stroke(path(), with: .color(colors[keyPath: color]), style: stroke)
    }
}

/// Image to be resolved and rendered
fileprivate class RenderImage<ColorScheme>: RenderingPrimitive<ColorScheme> {
    private let image: Image
    private let shading: KeyPath<ColorScheme, Color>?
    private let rect: Rect

    fileprivate init(image: Image, shading: KeyPath<ColorScheme, Color>?, rect: Rect) {
        self.image = image
        self.shading = shading
        self.rect = rect
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        var resolvedImage = gc.resolve(image)
        if let shading {
            resolvedImage.shading = .color(colors[keyPath: shading])
        }
        gc.draw(resolvedImage, in: rect.cgrect)
    }
}

/// Text to be resolved and rendered
fileprivate class RenderText<ColorScheme>: RenderingPrimitive<ColorScheme> {
    private let text: Text
    private let color: KeyPath<ColorScheme, Color>
    private let size: MutableSize
    private let point: Point
    private let anchor: UnitPoint
    private var resolvedText: GraphicsContext.ResolvedText?

    fileprivate init(text: Text, color: KeyPath<ColorScheme, Color>, size: MutableSize, point: Point, anchor: UnitPoint) {
        self.text = text
        self.color = color
        self.size = size
        self.point = point
        self.anchor = anchor
    }

    fileprivate func resolve(gc: GraphicsContext, colors: ColorScheme) {
        let resolved = gc.resolve(text.foregroundColor(colors[keyPath: color]))
        let cgsize = resolved.measure(in: .greatest)

        resolvedText = resolved
        size.set(cgsize: cgsize)
    }

    fileprivate override func draw(gc: GraphicsContext, colors: ColorScheme) {
        guard let resolvedText else { return }
        gc.draw(resolvedText, at: point.cgpoint, anchor: anchor)
    }
}
