// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI

class MessageRow: ElementRow {
    let text: GraphicsContext.ResolvedText
    let textSize: CGSize
    let isInvalid: Bool
    let isBackwards: Bool

    init(msg: SequenceDiagramModel.Message,
         columnIndices: [Participant.ID: Int],
         config: Configuration,
         colors: ConfigColors,
         gc: GraphicsContext) {

        guard let startCol = columnIndices[msg.start],
              let endCol = columnIndices[msg.end] else {
            isInvalid = true
            isBackwards = false
            text = gc.resolve(Text("Unknown message participants")
                        .font(config.errorFont)
                        .foregroundColor(.white))
            textSize = .zero
            super.init(leftColumn: 0, rightColumn: columnIndices.count - 1,
                       innerSize: CGSize(width: 0, height: 50), outerSize: .zero)
            return
        }

        text = gc.resolve(Text(msg.comment)
                                .font(config.messageFont)
                                .foregroundColor(colors.messageText))
        textSize =  text.measure(in: .greatest)
        let innerSize = textSize.extra(width: config.messageArrowLength +
                                              (config.messageTextHorizontalPadding * 2))
                                .extra(height: config.messageArrowWidth + config.messageTextBottomPadding)
        isInvalid = false

        isBackwards = startCol > endCol
        if isBackwards {
            super.init(leftColumn: endCol, rightColumn: startCol, innerSize: innerSize, outerSize: innerSize)
        } else {
            super.init(leftColumn: startCol, rightColumn: endCol, innerSize: innerSize, outerSize: innerSize)
        }
    }

//    override func draw(y: CGFloat, lifelines: [LifeLineInfo],
//                       config: Configuration, colors: ConfigColors,
//                       gc: GraphicsContext, canvasSize: CGSize) {
//
//        if isInvalid {
//            draw(errorMessage: text,
//                 y: y, lifelines: lifelines,
//                 config: config, colors: colors, gc: gc, canvasSize: canvasSize)
//            return
//        }
//
//        let leftX = lifelines[leftColumn].x + lifelines[leftColumn].righMargin
//        let rightX = lifelines[rightColumn].x - lifelines[rightColumn].leftMargin
//        let width = rightX - leftX
//        let origin = CGPoint(x: leftX, y: y)
//
//        // Center text rect in provided width
//        var textOrigin = origin.right(by: ((width - config.messageArrowLength) / 2) - (textSize.width / 2))
//        if isBackwards {
//            textOrigin = textOrigin.right(by: config.messageArrowLength)
//        }
//        let textRect = CGRect(origin: textOrigin, size: textSize)
//        let textBGRect = textRect.padded(with: config.messageTextBackgroundPadding)
//        gc.fill(Path(textBGRect), with: .color(colors.messageTextBackground))
//        gc.draw(text, in: textRect)
//
//        let lineStart = origin.down(by: textSize.height + (config.messageArrowWidth / 2) + config.messageTextBottomPadding)
//        let lineEnd = lineStart.right(by: width)
//
//        var linePath = Path()
//        linePath.addLines([lineStart, lineEnd])
//        gc.stroke(linePath, with: .color(colors.messageLine), style: config.messageLineStroke)
//
//        var arrowPath = Path()
//        if isBackwards {
//            arrowPath.addLines([
//                lineStart,
//                lineStart.offset(dx: config.messageArrowLength, dy: -config.messageArrowWidth / 2),
//                lineStart.offset(dx: config.messageArrowLength, dy: config.messageArrowWidth / 2),
//                lineStart
//            ])
//        } else {
//            arrowPath.addLines([
//                lineEnd,
//                lineEnd.offset(dx: -config.messageArrowLength, dy: -config.messageArrowWidth / 2),
//                lineEnd.offset(dx: -config.messageArrowLength, dy: config.messageArrowWidth / 2),
//                lineEnd
//            ])
//        }
//        gc.fill(arrowPath, with: .color(colors.messageLine))
//
//        // TODO: arrow head types
//        // TODO: no arrow
//        // TODO: dashed line
//    }
}
