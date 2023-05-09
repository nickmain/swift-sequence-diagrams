// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import SwiftUI

// Aggregation of things needed for rendering
class RenderContext {
    let gc: GraphicsContext
    let size: CGSize
    let colors: ConfigColors
    let config: Configuration

    var columns: [ParticipantColumn] = []
    var rows: [ElementRow] = []
    var participantIndices = [Participant.ID: Int]() // id to column index
    var largestColumnBoxHeight: CGFloat = 0

    init(gc: GraphicsContext, size: CGSize, colors: ConfigColors, config: Configuration) {
        self.gc = gc
        self.size = size
        self.colors = colors
        self.config = config
    }

    // make columns for participants
    func setUp(participants: [Participant]) {
        for (index, part) in participants.enumerated() {
            let column = ParticipantColumn(part: part, ctx: self)
            columns.append(column)
            participantIndices[part.id] = index
            largestColumnBoxHeight = max(largestColumnBoxHeight, column.boxSize.height)
        }

        // remove the left and right margins
        columns.first?.leftMargin = 0
        columns.last?.rightMargin = 0
    }

    // make rows for the elements
    func setUp(elements: [Element]) {

    }
}
