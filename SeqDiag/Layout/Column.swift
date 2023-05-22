// Copyright (c) 2023 David N Main

import SwiftUI

struct ColumnLayout: LayoutElement {
    let index: Int
    let isActor: Bool
    let centerX: MemoizedValue
    let rightEdge: XValue
    let leftEdge: XValue
    let width: Width
    let bottomEdge: YValue // top for life line

    // Computations that specify the X for the center lifeline.
    // These are dependent on things such as the minimum width of a message.
    let centerXRequirements: AggregateComputation

    private let header: HeaderLayout

    init(participant: Participant, index: Int, diagram: DiagramLayout) {
        self.index = index
        isActor = participant.isActor
        centerXRequirements = .maximum()
        centerX = MemoizedValue(centerXRequirements)

        let topCenter = Point(x: centerX, y: diagram.bounds.y)

        header = isActor ?
            ActorLayout(participant: participant, topCenter: topCenter, diagram: diagram) :
            ParticipantLayout(participant: participant, topCenter: topCenter, diagram: diagram)

        leftEdge = centerX - header.width.half
        rightEdge = centerX + header.width.half

        // center x minimum constraint, determined from right edge of previous col
        // or left edge of diagram bounds
        let defaultLeftEdge: LayoutValue
        if let previousColumn = diagram.columns.last {
            defaultLeftEdge = previousColumn.rightEdge + diagram.config.minParticipantGap
        } else {
            defaultLeftEdge = diagram.bounds.x
        }
        centerXRequirements.add(argument: defaultLeftEdge + header.width.half)

        self.width = header.width

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
        textLayout = diagram.makeText(text: text, color: \.participantText)
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
        textLayout = diagram.makeText(text: text, color: \.participantText)
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
