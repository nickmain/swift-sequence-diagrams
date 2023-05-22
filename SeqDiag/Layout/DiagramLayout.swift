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

    fileprivate init(text: Text, color: KeyPath<ConfigColors, Color>) {
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

    var columnFromId = [Participant.ID: ColumnLayout]()

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

        for (index, part) in model.participants.enumerated() {
            let layout = ColumnLayout(participant: part, index: index, diagram: self)
            columns.append(layout)
            participantLayer.append(layout)
            participantLayer.append(LifeLineLayout(column: layout, diagram: self))

            columnFromId[part.id] = layout
        }

        for row in model.elements {
            var rowLayout: RowLayout?

            do {
                switch row {
                case .message(_):
                    rowLayout = ErrorLayout(message: "UNIMPLEMENTED **message**", diagram: self)
                case .activate(_):
                    rowLayout = ErrorLayout(message: "UNIMPLEMENTED **activate**", diagram: self)
                case .deactivate(_):
                    rowLayout = ErrorLayout(message: "UNIMPLEMENTED **deactivate**", diagram: self)
                case .note(let note):
                    rowLayout = try NoteLayout(note: note, diagram: self)
                case .fragmentStart(_): continue // TODO:
                case .fragmentAlternate(_): continue // TODO:
                case .fragmentEnd: continue // TODO:
                case .separator(let sep):
                    rowLayout = SeparatorLayout(sep: sep, diagram: self)
                case .padding(let padding):
                    rowLayout = PaddingLayout(padding: padding, diagram: self)
                }
            } catch {
                if let err = error as? LayoutException {
                    rowLayout = ErrorLayout(message: err.message, diagram: self)
                } else {
                    rowLayout = ErrorLayout(message: error.localizedDescription, diagram: self)
                }
            }

            if let rowLayout {
                rows.append(rowLayout)
                rowLayer.append(rowLayout)
            }
        }
    }

    // Get the col layouts for the given ids, in left-to-right order and
    // also return a boolean that is true if the ids were reversed
    func colsInOrder(_ id1: Participant.ID, _ id2: Participant.ID) -> (Bool, ColumnLayout, ColumnLayout)? {
        guard let col1 = columnFromId[id1],
              let col2 = columnFromId[id2]
        else { return nil }

        if col1.index > col2.index {
            return (true, col2, col1)
        }

        return (false, col1, col2)
    }

    // Make a LayoutText and register it for resolution at rendering time
    func makeText(text: Text, color: KeyPath<ConfigColors, Color>) -> LayoutText {
        let lt = LayoutText(text: text, color: color)
        layoutText.append(lt)
        return lt
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

        // draw debug rects around content
//        gc.draw(rect: bounds, with: .red, stroke: config.messageLineStroke)
//        gc.draw(rect: contentBounds, with: .yellow, stroke: config.messageLineStroke)
    }
}
