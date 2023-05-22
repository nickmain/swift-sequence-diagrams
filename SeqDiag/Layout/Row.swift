// Copyright (c) 2023 David N Main

import SwiftUI

protocol RowLayout: LayoutElement {
    var bottomEdge: YValue { get }
}

extension DiagramLayout {
    var nextTopEdge: YValue {
        if let lastBottomEdge = rows.last?.bottomEdge {
            return lastBottomEdge + config.interRowGap
        } else {
            return firstRowTop
        }
    }
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

struct ErrorLayout: RowLayout {
    let bottomEdge: YValue

    private let textLayout: LayoutText?
    private let textBackRect: Rect?

    init(message: String, diagram: DiagramLayout) {
        let topEdge = diagram.nextTopEdge
        let text = Text(message.md).font(diagram.config.errorFont)
        let textLayout = diagram.makeText(text: text, color: \.noteText)
        self.textLayout = textLayout

        let rectSize = ComputedSize(width: diagram.contentBounds.size.width,
                                    height: textLayout.size.height + (diagram.config.errorPadding * 2))
        let rect = Rect(origin: Point(x: diagram.config.horizontalMargin,
                                      y: topEdge),
                        size: rectSize)
        self.textBackRect = rect

        bottomEdge = rect.bottomY
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        guard let textBackRect,
              let textLayout,
              let text = textLayout.resolvedText
        else { return }

        gc.fill(rect: textBackRect, with: colors.errorBackground)
        gc.draw(text, at: textBackRect.center.cgpoint, anchor: .center)
    }
}

struct NoteLayout: RowLayout {
    let bottomEdge: YValue

    private let textLayout: LayoutText?
    private let textBackRect: Rect?

    init(note: SequenceDiagramModel.Note, diagram: DiagramLayout) throws {
        let topEdge = diagram.nextTopEdge
        let text = Text(note.text).font(diagram.config.noteFont)
        let textLayout = diagram.makeText(text: text, color: \.noteText)
        self.textLayout = textLayout

        switch note.position {
        case .over(let id):
            if let col = diagram.columnFromId[id] {
                let rectSize = textLayout.size.larger(by: diagram.config.notePadding * 2)
                let rectTop = Point(x: col.centerX, y: topEdge)
                let rect = Rect.withTopCenter(point: rectTop,
                                              size: rectSize)
                self.textBackRect = rect

                bottomEdge = rect.bottomY
                return
            } else {
                throw LayoutException(message: "Unknown participant or actor")
            }

        case .spanning(let id1, let id2):
            if let (_, col1, col2) = diagram.colsInOrder(id1, id2) {
                let textWidth = textLayout.size.width + (diagram.config.notePadding * 2)

                // push cols apart if text is wider
                let col2Center = col1.leftEdge + textWidth - col2.width.half
                col2.centerXRequirements.add(argument: col2Center)

                let colSpanWidth = col2.rightEdge - col1.leftEdge
                let height = textLayout.size.height + (diagram.config.notePadding * 2)

                let rect = Rect(origin: Point(x: col1.leftEdge,
                                              y: topEdge),
                                size: ComputedSize(width: colSpanWidth,
                                                   height: height))
                self.textBackRect = rect
                bottomEdge = rect.bottomY
                return

            } else {
                throw LayoutException(message: "Unknown participant or actor")
            }
            
        default: break
        }

        throw LayoutException(message: "Note type not implemented")
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        guard let textBackRect,
              let textLayout,
              let text = textLayout.resolvedText
        else { return }

        gc.fill(rect: textBackRect, with: colors.noteBackground)
        gc.draw(text, at: textBackRect.center.cgpoint, anchor: .center)
    }
}

struct LayoutException: Error {
    let message: String
}

struct SeparatorLayout: RowLayout {
    let bottomEdge: YValue

    private let stroke: StrokeStyle
    private let lineBackRect: Rect

    private let textLayout: LayoutText?
    private let textBackRect: Rect?

    init(sep: SequenceDiagramModel.Separator, diagram: DiagramLayout) {
        let topEdge = diagram.nextTopEdge

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
            let textLayout = diagram.makeText(text: text, color: \.separatorText)
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
