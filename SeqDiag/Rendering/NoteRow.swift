// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI

class NoteRow: ElementRow {
    let text: GraphicsContext.ResolvedText
    let textSize: CGSize
    let isInvalid: Bool
    let position: SequenceDiagramModel.Note.Position

    init(note: SequenceDiagramModel.Note,
         columnIndices: [Participant.ID: Int],
         config: Configuration,
         colors: ConfigColors,
         gc: GraphicsContext) {

        position = note.position

        switch position {
        case .over(let partId):
            guard let col = columnIndices[partId] else {
                isInvalid = true
                text = gc.resolve(Text("Unknown participant for note")
                            .font(config.errorFont)
                            .foregroundColor(.white))
                textSize = .zero
                super.init(leftColumn: 0, rightColumn: columnIndices.count - 1,
                           innerSize: CGSize(width: 0, height: 50), outerSize: .zero)
                return
            }

            text = gc.resolve(Text(note.text)
                                    .font(config.noteFont)
                                    .foregroundColor(colors.noteText))
            textSize =  text.measure(in: .greatest)
            let innerSize = textSize.padded(with: config.notePadding)
            isInvalid = false

            super.init(leftColumn: col, rightColumn: col, innerSize: innerSize, outerSize: innerSize)

//        case .spanning(_, _):
//        case .leftOf(_):
//        case .rightOf(_):
        default:
            isInvalid = true
            text = gc.resolve(Text("Unimplemented note position")
                .font(config.errorFont)
                .foregroundColor(.white))
            textSize = .zero
            super.init(leftColumn: 0, rightColumn: columnIndices.count - 1,
                       innerSize: CGSize(width: 0, height: 50), outerSize: .zero)
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
//        switch position {
//        case .over(_):
//            let lineX = lifelines[leftColumn].x
//            let rect = CGRect(origin: CGPoint(x: lineX - (innerSize.width / 2), y: y),
//                              size: innerSize)
//            gc.fill(Path(rect), with: .color(colors.noteBackground))
//            gc.draw(text, in: rect.unpadded(with: config.notePadding))
//
//        default: break
//        }
//    }
}
