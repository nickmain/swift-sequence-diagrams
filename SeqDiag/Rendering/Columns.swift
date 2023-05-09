// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI

// Layout for a participant
class ParticipantColumn {
    let part: Participant
    let text: GraphicsContext.ResolvedText
    let boxSize: CGSize
    var leftMargin: CGFloat
    var rightMargin: CGFloat
    var lifeLineX: CGFloat = 0 // set when drawn

    var width: CGFloat { leftMargin + rightMargin + boxSize.width }

    init(part: Participant, ctx: RenderContext) {
        self.part = part
        self.leftMargin = ctx.config.minParticipantGap / 2
        self.rightMargin = ctx.config.minParticipantGap / 2

        self.text = ctx.gc.resolve(Text(part.label)
            .font(ctx.config.participantFont)
            .foregroundColor(ctx.colors.participantText))
        let textSize = text.measure(in: .greatest)
        var boxHeight = textSize.height

        if part.isActor {
            boxHeight += ctx.config.actorSymbolSize.height + ctx.config.actorSymbolBottomMargin
        } else {
            boxHeight += ctx.config.participantVerticalPadding * 2
        }

        var boxWidth = textSize.width
        if !part.isActor {
            boxWidth += ctx.config.participantHorizontalPadding * 2
        }

        self.boxSize = CGSize(width: boxWidth, height: boxHeight)
            .combined(with: ctx.config.minParticipantSize)
    }

    func draw(at origin: CGPoint, ctx: RenderContext) {
//
//        let boxRect = CGRect(origin: origin.right(by: leftMargin),
//                             size: CGSize(width: boxSize.width, height: height))
//        var bottomMargin = 0.0 // margin between box bottom and life line
//
//        self.lifeLineX = boxRect.bottomCenter.x
//
//        if part.isActor {
//            let imageRect = boxRect.rectCenteredAtTop(size: config.actorSymbolSize)
//            var image = gc.resolve(Image(systemName: config.actorSymbolName))
//            image.shading = .color(colors.actorSymbol)
//            gc.draw(image, in: imageRect)
//            gc.draw(text, at: boxRect.bottomCenter, anchor: .bottom)
//
//            // a small margin under the actor text to give it space to breath
//            bottomMargin = config.actorBottomMargin
//        } else {
//            let boxPath = Path(boxRect)
//            gc.fill(boxPath, with: .color(colors.participantFill))
//            gc.stroke(boxPath,
//                      with: .color(colors.participantLine),
//                      lineWidth: config.participantLineWidth)
//            gc.draw(text, at: boxRect.center, anchor: .center)
//        }
//
//        // draw life line
//        let lineTop = boxRect.bottomCenter.down(by: bottomMargin)
//        let lineBottom = CGPoint(x: lineTop.x,
//                                 y: canvasSize.height - config.verticalMargin)
//
//        var linePath = Path()
//        linePath.addLines([lineTop, lineBottom])
//        gc.stroke(linePath, with: .color(colors.lifeLine), style: config.lifeLineStroke)
    }
}

