// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI

class ElementRow {
    let leftColumn: Int
    let rightColumn: Int
    let innerSize: CGSize // size of element between the L/R columns
    let outerSize: CGSize // size of the element in total
    var errorMessage: String?

    init(leftColumn: Int, rightColumn: Int, innerSize: CGSize, outerSize: CGSize) {
        self.leftColumn = leftColumn
        self.rightColumn = rightColumn
        self.innerSize = innerSize
        self.outerSize = outerSize
    }

    static func from(element: Element,
                     columnIndices: [Participant.ID: Int],
                     config: Configuration,
                     colors: ConfigColors,
                     gc: GraphicsContext) -> ElementRow? {

        switch element {
        case .message(let msg):
            return MessageRow(msg: msg, columnIndices: columnIndices,
                              config: config, colors: colors, gc: gc)

        case .activate(_): return nil
        case .deactivate(_): return nil

        case .note(let note):
            return NoteRow(note: note, columnIndices: columnIndices,
                              config: config, colors: colors, gc: gc)

        case .fragmentStart(_): return nil
        case .fragmentAlternate(_): return nil
        case .fragmentEnd: return nil

        case .separator(let sep):
            return SeparatorRow(separator: sep, config: config, colors: colors, gc: gc)

        case .padding(let padding):
            // dummy row just to cause vertical padding
            return ElementRow(leftColumn: 0, rightColumn: 0, innerSize: .zero, outerSize: CGSize(width: 0, height: padding))
        }
    }

//    func draw(y: CGFloat, lifelines: [LifeLineInfo],
//              config: Configuration, colors: ConfigColors,
//              gc: GraphicsContext, canvasSize: CGSize) {
//        // to be overridden
//    }
//
//    func draw(errorMessage: GraphicsContext.ResolvedText,
//              y: CGFloat, lifelines: [LifeLineInfo],
//              config: Configuration, colors: ConfigColors,
//              gc: GraphicsContext, canvasSize: CGSize) {
//
//        guard !lifelines.isEmpty else { return }
//        let firstCol = lifelines.first!
//        let lastCol = lifelines.last!
//
//        // spill the message beyond the left/right lifelines
//        let leftX = firstCol.x - (config.minParticipantSize.width / 2)
//        let rightX = lastCol.x + (config.minParticipantSize.width / 2)
//        let width = rightX - leftX
//        let origin = CGPoint(x: leftX, y: y)
//
//        let text = errorMessage
//        let textSize = text.measure(in: .greatest)
//        let textRect = CGRect(origin: origin.right(by: (width / 2) - (textSize.width / 2)),
//                              size: textSize)
//
//        let backRect = CGRect(origin: origin,
//                              size: CGSize(width: width, height: textSize.height))
//                            .padded(with: 10)
//        gc.fill(Path(backRect), with: .color(.red))
//        gc.draw(text, in: textRect)
//    }
}
