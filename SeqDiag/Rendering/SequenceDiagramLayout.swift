// Copyright (c) 2023 David N Main

import SwiftUI

class SequenceDiagramLayout {
    let model: SequenceDiagramModel
    let config: Configuration

    private var cols = [ParticipantColumnModel]()
    private var rows = [RowModel]()
    private var activations = [[ActivationModel]]()

    private var contentSize = MutableSize()
    private var maxBoxHeight = MemoizedValue() // column header boxes
    private var firstRowY = MemoizedValue() // y of top of first row

    private var participantIndices: [Participant.ID: Int] = [:]

    private var renderModel: RenderModel<ConfigColors>
    private var columnLayer: RenderLayer<ConfigColors>
    private var activeLayer: RenderLayer<ConfigColors>
    private var rowLayer: RenderLayer<ConfigColors>

    init(model: SequenceDiagramModel, config: Configuration) {
        self.config = config
        self.model = model

        renderModel = RenderModel<ConfigColors>(backgroundColor: \.background)
        columnLayer = renderModel.newLayer()
        activeLayer = renderModel.newLayer()
        rowLayer    = renderModel.newLayer()

        // map the part ids to their column indices
        for (index, part) in model.participants.enumerated() {
            participantIndices[part.id] = index
        }
    }

    func layout() -> RenderModel<ConfigColors> {
        setUpColumns()
        setUpRows()
        setUpSizeComputations()

        // firstRowY is dependent on the max box height of the participants
        firstRowY.computation = config.verticalMargin + maxBoxHeight + config.participantBottomMargin

        return renderModel
    }

    // set up dynamic computations for the overall size
    private func setUpSizeComputations() {
        if let firstCol = cols.first, let lastCol = cols.last {
            contentSize.widthValue.computation = lastCol.rect.rightX - firstCol.rect.x
        } else {
            contentSize.widthValue.computation = nil
        }

        if let firstRow = rows.first, let lastRow = rows.last {
            let maxBoxHeight = self.maxBoxHeight
            let participantBottomMargin = config.participantBottomMargin

            contentSize.heightValue.computation = lastRow.rect.bottomY
                                                - firstRow.rect.y
                                                + maxBoxHeight
                                                + participantBottomMargin
        } else {
            contentSize.heightValue.computation = nil
        }
    }

    private func setUpRows() {
        rows.removeAll()
        firstRowY.value = 0

        for element in model.elements {
            switch element {
            case .message(let message): layout(message: message)
            case .activate(let id): layout(activation: id)
            case .deactivate(let id): layout(deactivation: id)
            case .note(let note): layout(note: note)
            case .fragmentStart(_): break // TODO
            case .fragmentAlternate(_): break // TODO
            case .fragmentEnd: break // TODO
            case .separator(let sep): layout(separator: sep)
            case .padding(let value): layout(padding: value)
            }
        }
    }

    // Get the bottom Y of the previously layed out row plus the gap
    private func newRowTop() -> MemoizedValue {
        if let last = rows.last {
            return MemoizedValue(last.rect.bottomY + config.interRowGap)
        } else {
            return firstRowY
        }
    }

    // Get column for part id or render an error
    private func column(for id: Participant.ID) -> ParticipantColumnModel? {
        guard let col = (participantIndices[id].map { cols[$0] }) else {
            layout(error: "Could not find participant '\(id)'")
            return nil
        }

        return col
    }

    private func layout(activation id: Participant.ID) {
        guard let col = (participantIndices[id].map { cols[$0] }) else {
            layout(error: "Activate: could not find participant '\(id)'")
            return
        }
        let rowIndex = rows.count

        activate(col: col, row: .init(rowIndex, .top), pos: .center, startY: newRowTop())
    }

    private func layout(deactivation id: Participant.ID) {
        guard let col = (participantIndices[id].map { cols[$0] }) else {
            layout(error: "Deactivate: could not find participant '\(id)'")
            return
        }
        let prevIndex = rows.count - 1 // deactivating after the previous row

        deactivate(col: col, row: .init(prevIndex, .bottom), pos: .center, endY: newRowTop())
    }

    private enum ActivationPos { case left, center, right }

    private func activate(col: ParticipantColumnModel, row: Activation.Row, pos: ActivationPos, startY: LayoutValue) {

        let activation: Activation.Info?
        switch pos {
        case .left:   activation = col.activations.newLeftActivation(at: row)
        case .center: activation = col.activations.newCenterActivation(at: row)
        case .right:  activation = col.activations.newRightActivation(at: row)
        }
        guard let activation else { return }

        let startOffset = startY
        let centerOffset = (activation.centerOffsetCount * config.activationCenterOffset)
        let origin = Point(x: col.centerX + centerOffset - (config.activationWidth / 2),
                           y: startOffset)
        let size = ComputedSize(width: config.activationWidth,
                                height: activation.endY - startOffset)
        let rect = Rect(origin: origin, size: size)

        // set the activation end to the content bottom until a deactivation happens
        activation.endY.computation = renderModel.canvasSize.height - config.verticalMargin

        activeLayer.add(rect: rect, fillColor: \.activationFill,
                        strokeColor: \.activationLine, stroke: config.activationLineStroke)
    }

    private func deactivate(col: ParticipantColumnModel, row: Activation.Row, pos: ActivationPos, endY: LayoutValue) {
        guard row.row >= 0 else { return }

        let activation: Activation.Info?
        switch pos {
        case .left:  activation = col.activations.activeLeft(at: row)
        case .right: activation = col.activations.activeRight(at: row)
        case .center:
            activation = col.activations.activeCenter(at: row)

            // deactivating the center implies also deactivating all left and right
            for act in col.activations.left.at(row: row) {
                act.end = row
                act.endY.computation = endY
            }
            for act in col.activations.right.at(row: row) {
                act.end = row
                act.endY.computation = endY
            }
        }
        guard let activation else { return }

        // set the row and rectangle ends
        activation.end = row
        activation.endY.computation = endY
    }

    private func layout(note: SequenceDiagramModel.Note) {

        let text = Text(note.text).font(config.noteFont)
        let textSize = MutableSize()

        switch note.position {
        case .over(let id):
            if let col = column(for: id) {
                let topCenter = Point(x: col.rect.centerX, y: newRowTop())
                let noteRect = Rect.withTopCenter(point: topCenter,
                                                  size: textSize.larger(by: config.notePadding * 2))

                rowLayer.add(rect: noteRect, fillColor: \.noteBackground)
                rowLayer.add(text: text, color: \.noteText, size: textSize,
                             point: noteRect.center, anchor: .center)

                rows.append(.init(rect: noteRect, span: nil))
            }
        case .spanning(let id1, let id2):
            if let col1 = column(for: id1), let col2 = column(for: id2) {
                let swapped = col1.index > col2.index
                let left = swapped ? col2.rect.x : col1.rect.x
                let right = swapped ? col1.rect.rightX : col2.rect.rightX
                let width = right - left
                let topCenter = Point(x: left + width.half, y: newRowTop())
                let paddedTextSize = textSize.larger(by: config.notePadding * 2)
                let rectSize = ComputedSize(width: max(width, paddedTextSize.width), height: paddedTextSize.height)
                let noteRect = Rect.withTopCenter(point: topCenter, size: rectSize)

                rowLayer.add(rect: noteRect, fillColor: \.noteBackground)
                rowLayer.add(text: text, color: \.noteText, size: textSize,
                             point: noteRect.center, anchor: .center)

                rows.append(.init(rect: noteRect, span: nil))
            }
        case .leftOf(let id):
            if let col = column(for: id) {
                let paddedTextSize = textSize.larger(by: config.notePadding * 2)
                let origin = Point(x: col.rect.centerX - config.noteHorzOffset - paddedTextSize.width,
                                   y: newRowTop())
                let noteRect = Rect(origin: origin, size: paddedTextSize)

                rowLayer.add(rect: noteRect, fillColor: \.noteBackground)
                rowLayer.add(text: text, color: \.noteText, size: textSize,
                             point: noteRect.center, anchor: .center)

                rows.append(.init(rect: noteRect, span: nil))
            }
        case .rightOf(let id):
            if let col = column(for: id) {
                let origin = Point(x: col.rect.centerX + config.noteHorzOffset, y: newRowTop())
                let noteRect = Rect(origin: origin,
                                    size: textSize.larger(by: config.notePadding * 2))

                rowLayer.add(rect: noteRect, fillColor: \.noteBackground)
                rowLayer.add(text: text, color: \.noteText, size: textSize,
                             point: noteRect.center, anchor: .center)

                rows.append(.init(rect: noteRect, span: nil))
            }
        }
    }

    private func layout(padding: CGFloat) {
        let rect = Rect(origin: Point(x: 0, y: newRowTop()),
                        size: ComputedSize(width: 0, height: padding))

        rows.append(.init(rect: rect, span: nil))
    }

    private func layout(selfMessage: SequenceDiagramModel.Message) {
        guard let col = column(for: selfMessage.start) else { return }

        // draw message on the left side if this is the last column
        let isOnLeftSide = selfMessage.selfSide == .left || col.index == cols.count - 1

        if isOnLeftSide {
            layout(selfMessage: selfMessage, onLeftOf: col)
        } else {
            layout(selfMessage: selfMessage, onRightOf: col)
        }
    }

    private func layout(selfMessage: SequenceDiagramModel.Message,
                        onLeftOf col: ParticipantColumnModel) {
        let rowIndex = rows.count
        let top = newRowTop()
        let toplineY = MemoizedValue()
        let bottomlineY = toplineY + config.selfMessageHeight

        // offsets from column center lifelines due to activation rectangles
        let startOffset = col.leftOfCenterOffsetX(at: .init(rowIndex, .top), config: config)
        if selfMessage.deactivateSender {
            deactivate(col: col, row: .init(rowIndex, .top), pos: .left, endY: toplineY)
        }
        if selfMessage.activateTarget {
            activate(col: col, row: .init(rowIndex, .bottom), pos: .left, startY: bottomlineY)
        }
        let endOffset = col.leftOfCenterOffsetX(at: .init(rowIndex, .bottom), config: config)

        let startX = col.centerX - startOffset
        let endX = col.centerX - endOffset
        let centerOffset = max(startOffset, endOffset)
        let rightmostX = max(startX, endX)
        let rightOffset = abs(endX - startX) // extra width caused by activations

        let text = Text(selfMessage.comment).font(config.messageFont)
        let textSize = MutableSize()
        let textWidth = textSize.width + (config.messageTextHorizontalPadding * 2)
        let textHeight = textSize.height + config.messageTextBottomPadding
        toplineY.computation = top + textHeight

        let height = config.selfMessageHeight + (config.messageArrowWidth / 2) + textHeight
        let width = max(config.selfMessageWidth, textWidth) + rightOffset + centerOffset

        let rect = Rect(x: rightmostX, y: top, w: width, h: height)

        let startPoint = Point(x: startX, y: toplineY)
        let endPoint = Point(x: endX, y: bottomlineY)
        let radius = config.selfMessageHeight / 2
        let leftMostX = rightmostX - config.selfMessageWidth - rightOffset
        let arcStartX = leftMostX + radius
        let arcStart = Point(x: arcStartX, y: toplineY)
        let arcCenter = Point(x: arcStartX, y: toplineY + radius)
        let arcEnd = Point(x: arcStartX, y: bottomlineY)

        let path = {
            var p = Path()
            p.move(to: startPoint.cgpoint)
            p.addLine(to: arcStart.cgpoint).self
            p.addArc(center: arcCenter.cgpoint, radius: radius,
                     startAngle: .degrees(-90), endAngle: .degrees(90),
                     clockwise: true)
            p.addLine(to: endPoint.cgpoint)
            return p
        }

        rowLayer.add(text: text, color: \.messageText, size: textSize,
                     point: startPoint.offset(dx: -config.messageTextHorizontalPadding,
                                              dy: -config.messageTextBottomPadding),
                     anchor: .bottomTrailing)

        rowLayer.add(path: path,
                     color: \.messageLine,
                     stroke: selfMessage.line == .solid ?
                         config.messageLineStroke :
                         config.messageDashedLineStroke)

        layout(arrow: selfMessage.arrow, on: (arcEnd, endPoint), isBackwards: false)

        rows.append(.init(rect: rect, span: nil))

        let prevColIndex = col.index - 1
        if prevColIndex >= 0 {
            let prevCol = cols[prevColIndex]
            let prevOffset = prevCol.rightOfCenterOffsetX(at: .init(rowIndex, .top), config: config)
            col.centerXRequirements.add(argument: prevCol.centerX + prevOffset + textWidth + (config.messageTextHorizontalPadding * 2))
        }
    }

    private func layout(selfMessage: SequenceDiagramModel.Message,
                        onRightOf col: ParticipantColumnModel) {
        let rowIndex = rows.count
        let top = newRowTop()
        let toplineY = MemoizedValue()
        let bottomlineY = toplineY + config.selfMessageHeight

        // offsets from column center lifelines due to activation rectangles
        let startOffset = col.rightOfCenterOffsetX(at: .init(rowIndex, .top), config: config)
        if selfMessage.deactivateSender {
            deactivate(col: col, row: .init(rowIndex, .top), pos: .right, endY: toplineY)
        }
        if selfMessage.activateTarget {
            activate(col: col, row: .init(rowIndex, .bottom), pos: .right, startY: bottomlineY)
        }
        let endOffset = col.rightOfCenterOffsetX(at: .init(rowIndex, .bottom), config: config)

        let startX = col.centerX + startOffset
        let endX = col.centerX + endOffset
        let centerOffset = min(startOffset, endOffset)
        let leftmostX = min(startX, endX)
        let leftOffset = abs(endX - startX) // extra width caused by activations

        let text = Text(selfMessage.comment).font(config.messageFont)
        let textSize = MutableSize()
        let textWidth = textSize.width + (config.messageTextHorizontalPadding * 2)
        let textHeight = textSize.height + config.messageTextBottomPadding
        toplineY.computation = top + textHeight

        let height = config.selfMessageHeight + (config.messageArrowWidth / 2) + textHeight
        let width = max(config.selfMessageWidth, textWidth) + leftOffset + centerOffset

        let rect = Rect(x: leftmostX, y: top, w: width, h: height)

        let startPoint = Point(x: startX, y: toplineY)
        let endPoint = Point(x: endX, y: bottomlineY)
        let radius = config.selfMessageHeight / 2
        let rightMostX = leftmostX + config.selfMessageWidth + leftOffset
        let arcStartX = rightMostX - radius
        let arcStart = Point(x: arcStartX, y: toplineY)
        let arcCenter = Point(x: arcStartX, y: toplineY + radius)
        let arcEnd = Point(x: arcStartX, y: bottomlineY)

        let path = {
            var p = Path()
            p.move(to: startPoint.cgpoint)
            p.addLine(to: arcStart.cgpoint).self
            p.addArc(center: arcCenter.cgpoint, radius: radius,
                     startAngle: .degrees(-90), endAngle: .degrees(90),
                     clockwise: false)
            p.addLine(to: endPoint.cgpoint)
            return p
        }

        rowLayer.add(text: text, color: \.messageText, size: textSize,
                     point: startPoint.offset(dx: config.messageTextHorizontalPadding,
                                              dy: -config.messageTextBottomPadding),
                     anchor: .bottomLeading)

        rowLayer.add(path: path,
                     color: \.messageLine,
                     stroke: selfMessage.line == .solid ?
                         config.messageLineStroke :
                         config.messageDashedLineStroke)

        layout(arrow: selfMessage.arrow, on: (endPoint, arcEnd), isBackwards: true)

        rows.append(.init(rect: rect, span: nil))

        let nextColIndex = col.index + 1
        if nextColIndex < cols.count {
            let nextCol = cols[nextColIndex]
            let nextOffset = nextCol.leftOfCenterOffsetX(at: .init(rowIndex, .top), config: config)
            nextCol.centerXRequirements.add(argument: col.centerX + nextOffset + width)
        }
    }

    private func layout(message: SequenceDiagramModel.Message) {
        if message.start == message.end {
            layout(selfMessage: message)
            return
        }

        guard let sender = column(for: message.start),
              let target = column(for: message.end)
        else { return }

        let rowIndex = rows.count
        let isBackwards = sender.index > target.index
        let leftCol = isBackwards ? target : sender
        let rightCol = isBackwards ? sender : target

        let lineY = MemoizedValue()

        if message.activateTarget {
            activate(col: target,
                     row: .init(rowIndex, .top),
                     pos: isBackwards ? .right : .left,
                     startY: lineY)
        }

        if message.deactivateSender {
            deactivate(col: sender,
                       row: .init(rowIndex, .top),
                       pos: isBackwards ? .left : .right,
                       endY: lineY)
        }

        // offsets from column center lifelines due to activation rectangles
        let startOffset = leftCol.rightOfCenterOffsetX(at: .init(rowIndex, .top), config: config)
        let endOffset = rightCol.leftOfCenterOffsetX(at: .init(rowIndex, .top), config: config)

        let left = leftCol.centerX + startOffset
        let right = rightCol.centerX - endOffset
        let top = newRowTop()
        let width = right - left

        let text = Text(message.comment).font(config.messageFont)
        let textSize = MutableSize()
        let textWidth = textSize.width + (config.messageTextHorizontalPadding * 2)
        let textHeight = textSize.height + config.messageTextBottomPadding
        let textBGSize = textSize.larger(by: config.messageTextBackgroundPadding * 2)
        let textOffset = isBackwards ? config.messageArrowLength : 0
        let widthLessArrow = width - config.messageArrowLength

        let height = textHeight + config.messageArrowWidth
        let minWidth = textWidth + config.messageArrowLength
        rightCol.centerXRequirements.add(argument: leftCol.centerX + startOffset + minWidth + endOffset)

        let textCenter = Point(x: left + widthLessArrow.half + textOffset,
                               y: top + textHeight.half)
        let textBGRect = Rect.withCenter(point: textCenter, size: textBGSize)

        rowLayer.add(rect: textBGRect, fillColor: \.messageTextBackground)
        rowLayer.add(text: text, color: \.messageText, size: textSize,
                     point: textCenter, anchor: .center)

        let rect = Rect(origin: Point(x: left, y: top), size: ComputedSize(width: width, height: height))

        let halfArrowWidth = config.messageArrowWidth / 2
        lineY.computation = rect.bottomY - halfArrowWidth
        let lineLeft = Point(x: rect.x, y: lineY)
        let lineRight = Point(x: rect.rightX, y: lineY)

        rowLayer.add(line: lineLeft, lineRight,
                     color: \.messageLine,
                     stroke: message.line == .solid ?
                        config.messageLineStroke :
                        config.messageDashedLineStroke)

        layout(arrow: message.arrow, on: (lineLeft, lineRight), isBackwards: isBackwards)

        rows.append(.init(rect: rect, span: nil))
    }

    private func layout(arrow: SequenceDiagramModel.Message.ArrowHead?, on line: (Point, Point), isBackwards: Bool) {

        let point = isBackwards ? line.0 : line.1
        let halfArrowWidth = config.messageArrowWidth / 2

        switch arrow ?? .none {
        case .open:
            let topPoint: Point
            let bottomPoint: Point
            if isBackwards {
                bottomPoint = point.offset(dx: config.messageArrowLength, dy: halfArrowWidth)
                topPoint    = point.offset(dx: config.messageArrowLength, dy: -halfArrowWidth)
            } else {
                bottomPoint = point.offset(dx: -config.messageArrowLength, dy: halfArrowWidth)
                topPoint    = point.offset(dx: -config.messageArrowLength, dy: -halfArrowWidth)
            }
            rowLayer.add(line: point, topPoint,
                         color: \.messageLine, stroke: config.messageLineStroke)
            rowLayer.add(line: point, bottomPoint,
                         color: \.messageLine, stroke: config.messageLineStroke)

        case .solid:
            let arrowPoints: [Point]
            if isBackwards {
                arrowPoints = [
                    point,
                    point.offset(dx: config.messageArrowLength, dy: halfArrowWidth),
                    point.offset(dx: config.messageArrowLength, dy: -halfArrowWidth),
                    point
                ]
            } else {
                arrowPoints = [
                    point,
                    point.offset(dx: -config.messageArrowLength, dy: halfArrowWidth),
                    point.offset(dx: -config.messageArrowLength, dy: -halfArrowWidth),
                    point
                ]
            }
            rowLayer.addFilled(path: arrowPoints, color: \.messageLine)

        case .none:
            return
        }
    }

    private func layout(error message: String) {
        let text = Text(message).font(config.messageFont)
        let textSize = MutableSize()
        let height = textSize.height + (config.errorPadding * 2)
        let size = ComputedSize(width: self.contentSize.width, height: height)
        let rect = Rect(origin: Point(x: config.horizontalMargin, y: newRowTop()), size: size)

        rowLayer.add(rect: rect, fillColor: \.errorBackground)
        rowLayer.add(text: text, color: \.errorText, size: textSize, point: rect.center, anchor: .center)

        rows.append(.init(rect: rect, span: nil))
    }

    private func layout(separator: SequenceDiagramModel.Separator) {
        let top = newRowTop()
        let height = MemoizedValue()
        let layoutRect = Rect(origin: Point(x: config.horizontalMargin, y: top),
                              size: ComputedSize(width: self.contentSize.width, height: height))

        let lineSize = ComputedSize(width: self.contentSize.width, height: config.separatorHeight)
        let lineRect = layoutRect.centeredRect(size: lineSize)

        rowLayer.add(rect: lineRect, fillColor: \.separatorBackground)
        rowLayer.add(line: lineRect.leftCenter, lineRect.rightCenter,
                     color: \.separatorLine,
                     stroke: config.separatorLineStroke)

        if let caption = separator.caption {
            let text = Text(caption).font(config.separatorFont)
            let textSize = MutableSize()
            let paddedTextSize = textSize.larger(by: config.separatorTextPadding * 2)
            height.computation = paddedTextSize.height

            let textRect = lineRect.centeredRect(size: paddedTextSize)

            rowLayer.add(rect: textRect, fillColor: \.separatorBackground)
            rowLayer.add(text: text, color: \.separatorText, size: textSize,
                         point: textRect.center, anchor: .center)
        } else {
            height.computation = FixedValue(config.separatorHeight)
        }

        rows.append(.init(rect: layoutRect, span: nil))
    }

    private func setUpColumns() {
        cols.removeAll()

        // collection of min column box heights in order to compute a common max height
        let maxOfBoxHeights = AggregateComputation.maximum()
        self.maxBoxHeight.computation = maxOfBoxHeights

        // add a column for each participant
        for part in model.participants {

            let textSize = MutableSize()
            let text = Text(part.label).font(config.participantFont)

            let col = makeParticipantCol(part: part, textSize: textSize)
            maxOfBoxHeights.add(argument: col.minHeight)

            // draw either actor icon or filled box, then text
            if part.isActor {
                let imageSize = ComputedSize(cgsize: config.actorSymbolSize)
                let image = Image(systemName: config.actorSymbolName)
                let imageRectBottom = col.rect.bottomCenter.up(by: textSize.height + config.actorSymbolBottomMargin)
                let imageRect = Rect.withBottomCenter(point: imageRectBottom, size: imageSize)

                columnLayer.add(image: image, rect: imageRect, shading: \.actorSymbol)
                columnLayer.add(text: text, color: \.participantText, size: textSize,
                                point: col.rect.bottomCenter, anchor: .bottom)

            } else {
                columnLayer.add(rect: col.rect,
                                fillColor: \.participantFill,
                                strokeColor: \.participantLine, stroke: config.participantStroke)

                columnLayer.add(text: text, color: \.participantText, size: textSize,
                                point: col.rect.center, anchor: .center)
            }

            // draw the lifeline
            let lifelineGap = part.isActor ? config.actorBottomMargin : 0.0
            let lifeTop = col.rect.bottomCenter.down(by: lifelineGap)
            let lifeBottom = Point(x: col.rect.centerX,
                                   y: renderModel.canvasSize.height  - config.verticalMargin)
            let lifeStroke = part.isActor ? config.actorLifeLineStroke : config.lifeLineStroke

            columnLayer.add(line: lifeTop, lifeBottom,
                            color: \.lifeLine, stroke: lifeStroke)
        }
    }

    private func makeParticipantCol(part: Participant, textSize: Size) -> ParticipantColumnModel {

        // aggregate computation to gather requirements from things like messages with long text
        // that can push columns further apart
        let minimumCenterX = AggregateComputation.maximum()

        // vertical is either text with padding or (actor icon + gap + text)
        let boxHeight = textSize.height +
                (part.isActor ?
                    (config.actorSymbolSize.height + config.actorSymbolBottomMargin) :
                    (config.participantVerticalPadding * 2))
        let boxWidth = textSize.width + (part.isActor ? 0 : (config.participantHorizontalPadding * 2))
        let boxSize = ComputedSize(width: max(boxWidth, config.minParticipantSize.width),
                                   height: max(boxHeight, config.minParticipantSize.height))

        // determine the lifeline position
        if let previousCol = cols.last {
            // add requirement based on minParticipantGap
            minimumCenterX.add(argument: previousCol.rect.rightX + config.minParticipantGap + boxSize.width.half)
        } else {
            // first column is at left edge
            minimumCenterX.add(argument: boxSize.width.half + config.horizontalMargin)
        }
        let centerX = MemoizedValue(minimumCenterX)

        // box text is computed based on size and x of the lifeline
        let origin = Point(x: centerX - boxSize.width.half, y: config.verticalMargin)
        let boxRect = Rect(origin: origin, size: ComputedSize(width: boxSize.width, height: maxBoxHeight))

        let col = ParticipantColumnModel(index: cols.count,
                                         part: part,
                                         minHeight: boxHeight,
                                         centerX: centerX,
                                         rect: boxRect,
                                         centerXRequirements: minimumCenterX)
        self.cols.append(col)
        return col
    }
}
