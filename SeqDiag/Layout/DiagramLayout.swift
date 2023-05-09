// Copyright (c) 2023 David N Main - All Rights Reserved.

import SwiftUI

protocol LayoutElement {
    /// Draw the element in the given context with the given color scheme
    func draw(gc: GraphicsContext, colors: ConfigColors)
}

// Text that needs to be resolved and measured.
// The resolved text size is set on the size property
class LayoutText {
    let text: Text
    let color: KeyPath<ConfigColors, Color>
    let size = MutableSize()
    var resolvedText: GraphicsContext.ResolvedText?

    init(text: Text, color: KeyPath<ConfigColors, Color>) {
        self.text = text
        self.color = color
    }

    // set the resolvedText and the size
    func resolve(gc: GraphicsContext, colors: ConfigColors) {
        let resolved = gc.resolve(text.foregroundColor(colors[keyPath: color]))
        let cgsize = resolved.measure(in: .greatest)

        resolvedText = resolved
        size.set(cgsize: cgsize)
    }
}

class DiagramLayout {
    var layoutText = [LayoutText]()
    var columns = [ColumnLayout]()
    var rows = [RowLayout]()

    var participantLayer = [LayoutElement]()
    var activationLayer = [LayoutElement]()
    var rowLayer = [LayoutElement]()

    let bounds: Rect // the canvas minus the margins
    let contentBounds: Rect
    let maxColumnHeaderHeight = AggregateComputation.maximum()
    let firstRowTop: YValue
    let config: Configuration

    // set to canvas size before drawing
    let canvasSize = MutableSize()

    init(model: SequenceDiagramModel, config: Configuration) {
        self.config = config

        bounds = Rect(x: config.horizontalMargin,
                      y: config.verticalMargin,
                      w: canvasSize.width - (config.horizontalMargin * 2),
                      h: canvasSize.height - (config.verticalMargin * 2))

        maxColumnHeaderHeight.add(argument: config.minParticipantSize.height)

        firstRowTop = config.verticalMargin + maxColumnHeaderHeight + config.participantBottomMargin

        let boundsSize = MutableSize()
        contentBounds = Rect(origin: Point(x: config.horizontalMargin,
                                           y: config.verticalMargin),
                            size: boundsSize)

        boundsSize.widthValue.computation = Computation { [weak self] in
            if let rightEdge = self?.columns.last?.rightEdge,
               let leftEdge = self?.config.horizontalMargin {
                return rightEdge.value - leftEdge
            }
            return 0
        }

        boundsSize.heightValue.computation = Computation { [weak self] in
            if let bottomEdge = self?.rows.last?.bottomEdge,
               let topEdge = self?.config.verticalMargin {
                return bottomEdge.value - topEdge
            }
            return self?.maxColumnHeaderHeight.value ?? 0
        }

        for part in model.participants {
            let layout = ColumnLayout(participant: part, diagram: self)
            columns.append(layout)
            participantLayer.append(layout)
            participantLayer.append(LifeLineLayout(column: layout, diagram: self))
        }

        for row in model.elements {
            var rowLayout: RowLayout?

            switch row {
            case .message(_): continue // TODO:
            case .activate(_): continue // TODO:
            case .deactivate(_): continue // TODO:
            case .note(_): continue // TODO:
            case .fragmentStart(_): continue // TODO:
            case .fragmentAlternate(_): continue // TODO:
            case .fragmentEnd: continue // TODO:
            case .separator(let sep):
                rowLayout = SeparatorLayout(sep: sep, diagram: self)
            case .padding(let padding):
                rowLayout = PaddingLayout(padding: padding, diagram: self)
            }

            if let rowLayout {
                rows.append(rowLayout)
                rowLayer.append(rowLayout)
            }
        }


    }

    // Draw the diagram in the given context
    func draw(gc: GraphicsContext, canvasSize: CGSize, colors: ConfigColors) {
        self.canvasSize.set(cgsize: canvasSize)

        gc.fill(size: canvasSize, with: colors.background)

        for text in layoutText {
            text.resolve(gc: gc, colors: colors)
        }

        for layer in [participantLayer, activationLayer, rowLayer] {
            for element in layer {
                element.draw(gc: gc, colors: colors)
            }
        }

        gc.draw(rect: bounds, with: .red, stroke: config.messageLineStroke)
        gc.draw(rect: contentBounds, with: .yellow, stroke: config.messageLineStroke)
    }
}

struct ActivationLayout: LayoutElement {

    let bounds: Rect

    private let stroke: StrokeStyle

    init(padding: CGFloat, diagram: DiagramLayout) {
        stroke = diagram.config.activationLineStroke

        // TODO:
        bounds = Rect(cgrect: .zero)
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        gc.fill(rect: bounds, with: colors.activationFill)
        gc.draw(rect: bounds, with: colors.activationLine, stroke: stroke)
    }
}

protocol RowLayout: LayoutElement {
    var bottomEdge: YValue { get }
}

struct PaddingLayout: RowLayout {
    let bottomEdge: YValue

    init(padding: CGFloat, diagram: DiagramLayout) {
        bottomEdge = (diagram.rows.last?.bottomEdge ?? diagram.firstRowTop) + padding
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        // nothing
    }
}

struct SeparatorLayout: RowLayout {
    let bottomEdge: YValue

    private let stroke: StrokeStyle
    private let lineBackRect: Rect

    private let textLayout: LayoutText?
    private let textBackRect: Rect?

    init(sep: SequenceDiagramModel.Separator, diagram: DiagramLayout) {
        let topEdge: YValue
        if let lastBottomEdge = diagram.rows.last?.bottomEdge {
            topEdge = lastBottomEdge + diagram.config.interRowGap
        } else {
            topEdge = diagram.firstRowTop
        }

        // height is max of separatorHeight and padded text height
        let height = AggregateComputation.maximum()
        height.add(argument: diagram.config.separatorHeight)

        let bounds = Rect(x: diagram.contentBounds.x,
                          y: topEdge,
                          w: diagram.contentBounds.width,
                          h: height)

        let lineBackSize = ComputedSize(width: diagram.contentBounds.width,
                                        height: diagram.config.separatorHeight)
        self.lineBackRect = bounds.centeredRect(size: lineBackSize)

        if let caption = sep.caption {
            let text = Text(caption).font(diagram.config.separatorFont)
            let textLayout = LayoutText(text: text, color: \.separatorText)
            diagram.layoutText.append(textLayout)
            self.textLayout = textLayout
            height.add(argument: textLayout.size.height)

            // add padding to text size to get background size
            let textBackSize = textLayout.size.larger(by: diagram.config.separatorTextPadding * 2)

            self.textBackRect = bounds.centeredRect(size: textBackSize)

        } else {
            self.textLayout = nil
            self.textBackRect = nil
        }

        self.stroke = diagram.config.separatorLineStroke
        self.bottomEdge = topEdge + height
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        gc.fill(rect: lineBackRect, with: colors.separatorBackground)
        gc.draw(line: lineBackRect.leftCenter, lineBackRect.rightCenter,
                with: colors.separatorLine,
                stroke: stroke)

        if let textLayout,
           let textBackRect,
           let resolvedText = textLayout.resolvedText {

            gc.fill(rect: textBackRect, with: colors.separatorBackground)
            gc.draw(resolvedText, at: textBackRect.center.cgpoint, anchor: .center)
        }
    }
}

struct ColumnLayout: LayoutElement {
    let isActor: Bool
    let centerX: MemoizedValue
    let rightEdge: XValue
    let bottomEdge: YValue // top for life line

    // Computations that specify the X for the center lifeline.
    // These are dependent on things such as the minimum width of a message.
    let centerXRequirements: AggregateComputation

    private let header: HeaderLayout

    init(participant: Participant, diagram: DiagramLayout) {
        isActor = participant.isActor
        centerXRequirements = .maximum()
        centerX = MemoizedValue(centerXRequirements)

        let topCenter = Point(x: centerX, y: diagram.bounds.y)

        header = isActor ?
            ActorLayout(participant: participant, topCenter: topCenter, diagram: diagram) :
            ParticipantLayout(participant: participant, topCenter: topCenter, diagram: diagram)

        // center x minimum constraint, determined from right edge of previous col
        // or left edge of diagram bounds
        let leftEdge: LayoutValue
        if let previousColumn = diagram.columns.last {
            leftEdge = previousColumn.rightEdge + diagram.config.minParticipantGap
        } else {
            leftEdge = diagram.bounds.x
        }
        centerXRequirements.add(argument: leftEdge + header.width.half)

        self.rightEdge = leftEdge + header.width
        self.bottomEdge = topCenter.y
                        + diagram.maxColumnHeaderHeight
                        + (isActor ? diagram.config.actorBottomMargin : 0)
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        header.draw(gc: gc, colors: colors)
    }
}

// Actor or Participant header
protocol HeaderLayout: LayoutElement {
    var width: Width { get }
}

struct ParticipantLayout: HeaderLayout {
    let width: Width

    private let rect: Rect
    private let textLayout: LayoutText
    private let stroke: StrokeStyle

    init(participant part: Participant, topCenter: Point, diagram: DiagramLayout) {
        stroke = diagram.config.participantStroke

        let text = Text(part.label).font(diagram.config.participantFont)
        textLayout = LayoutText(text: text, color: \.participantText)
        diagram.layoutText.append(textLayout)

        width = max(textLayout.size.width + (diagram.config.participantHorizontalPadding * 2), diagram.config.minParticipantSize.width)
        let height = textLayout.size.height + (diagram.config.participantVerticalPadding * 2)
        diagram.maxColumnHeaderHeight.add(argument: height)

        rect = Rect(origin: topCenter.left(by: width.half),
                    size: ComputedSize(width: width,
                                       height: diagram.maxColumnHeaderHeight))
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        gc.fill(rect: rect, with: colors.participantFill)
        gc.draw(rect: rect, with: colors.participantLine, stroke: stroke)

        if let resolvedText = textLayout.resolvedText {
            gc.draw(resolvedText, at: rect.center.cgpoint, anchor: .center)
        }
    }
}

struct ActorLayout: HeaderLayout {
    let width: Width

    private let image: Image
    private let imageRect: Rect
    private let textLayout: LayoutText
    private let textBottomCenter: Point

    init(participant part: Participant, topCenter: Point, diagram: DiagramLayout) {
        let text = Text(part.label).font(diagram.config.participantFont)
        textLayout = LayoutText(text: text, color: \.participantText)
        diagram.layoutText.append(textLayout)

        self.image = Image(systemName: diagram.config.actorSymbolName)
        let imageSize = ComputedSize(cgsize: diagram.config.actorSymbolSize)
        self.imageRect = Rect.withTopCenter(point: topCenter, size: imageSize)
        self.width = max(textLayout.size.width, imageRect.width, diagram.config.minParticipantSize.width)

        let height = textLayout.size.height + imageSize.height + diagram.config.actorSymbolBottomMargin
        diagram.maxColumnHeaderHeight.add(argument: height)

        self.textBottomCenter = topCenter.down(by: diagram.maxColumnHeaderHeight)
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        var resolvedImage = gc.resolve(image)
        resolvedImage.shading = .color(colors.actorSymbol)
        gc.draw(resolvedImage, in: imageRect.cgrect)

        if let resolvedText = textLayout.resolvedText {
            gc.draw(resolvedText, at: textBottomCenter.cgpoint, anchor: .bottom)
        }
    }
}

struct LifeLineLayout: LayoutElement {
    private let stroke: StrokeStyle
    private let top: Point
    private let bottom: Point

    init(column: ColumnLayout, diagram: DiagramLayout) {
        stroke = column.isActor ? diagram.config.actorLifeLineStroke : diagram.config.lifeLineStroke

        top = Point(x: column.centerX, y: column.bottomEdge)
        bottom = Point(x: column.centerX, y: diagram.bounds.bottomY)
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        gc.draw(line: top, bottom,
                with: colors.participantLine,
                stroke: stroke)
    }
}
