// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI

class SeparatorRow: ElementRow {
    let text: GraphicsContext.ResolvedText?
    let textSize: CGSize

    init(separator: SequenceDiagramModel.Separator,
         config: Configuration,
         colors: ConfigColors,
         gc: GraphicsContext) {

        if let caption = separator.caption {
            let text = gc.resolve(Text(caption)
                                    .font(config.separatorFont)
                                    .foregroundColor(colors.separatorText))
            textSize =  text.measure(in: .greatest)
            self.text = text
        } else {
            self.text = nil
            self.textSize = .zero
        }

        let height = max(config.separatorHeight, textSize.height)
        let innerSize = CGSize(width: 0, height: height)
        super.init(leftColumn: 0, rightColumn: 0, innerSize: innerSize, outerSize: innerSize)
    }
//
//    override func draw(y: CGFloat, lifelines: [LifeLineInfo],
//                       config: Configuration, colors: ConfigColors,
//                       gc: GraphicsContext, canvasSize: CGSize) {
//
//        guard !lifelines.isEmpty else { return }
//        let firstCol = lifelines.first!
//        let lastCol = lifelines.last!
//
//        // spill the separator beyond the left/right lifelines
//        let leftX = firstCol.x - (config.minParticipantSize.width / 2)
//        let rightX = lastCol.x + (config.minParticipantSize.width / 2)
//        let width = rightX - leftX
//        let height = innerSize.height
//        let origin = CGPoint(x: leftX, y: y)
//
//        let lineStart = origin.down(by: height / 2)
//        let lineEnd = lineStart.right(by: width)
//
//        let bgRect = CGRect(origin: origin, size: CGSize(width: width, height: height))
//        gc.fill(Path(bgRect), with: .color(colors.separatorBackground))
//
//        var linePath = Path()
//        linePath.addLines([lineStart, lineEnd])
//        gc.stroke(linePath, with: .color(colors.separatorLine), style: config.separatorLineStroke)
//
//        // Center text rect in provided width
//        if let text {
//            let textOrigin = origin.right(by: (width / 2) - (textSize.width / 2))
//                                   .down(by: (height / 2) - (textSize.height / 2))
//            let textRect = CGRect(origin: textOrigin, size: textSize)
//            let bgRect = textRect.padded(with: config.separatorTextPadding)
//            gc.fill(Path(bgRect), with: .color(colors.separatorBackground))
//            gc.draw(text, in: textRect)
//        }
//    }
}
