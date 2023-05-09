// Copyright (c) 2023 David N Main

import SwiftUI

// Layout for a participant or actor column
struct ColumnLayoutX: LayoutElement {
    let index: Int
    let part: Participant

    let rect: Rect
    let centerX: MemoizedValue

    // Computations that specify the X for the center lifeline.
    // These are dependent on things such as the minimum width of a message,
    // based on its text.
    let centerXRequirements = AggregateComputation.maximum()

    init(participant: Participant, index: Int, size: Size, top: CGFloat) {
        self.part = participant
        self.index = index
        self.centerX = MemoizedValue(centerXRequirements)

        self.rect = Rect.withTopCenter(point: Point(x: centerX, y: top),
                                       size: size)
    }

//    static func layout(_ participant: Participant, after previousCol: ColumnLayout? = nil, config: Configuration) -> ColumnLayout {
//
//    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        
    }
}
