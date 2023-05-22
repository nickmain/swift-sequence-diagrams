// Copyright (c) 2023 David N Main

import SwiftUI

struct ActivationLayout: LayoutElement {

    let bounds: Rect

    private let stroke: StrokeStyle

    init(padding: CGFloat, diagram: DiagramLayout) {
        stroke = diagram.config.activationLineStroke

        // TODO:
        bounds = Rect(cgrect: .zero)
    }

    func draw(gc: GraphicsContext, colors: ConfigColors) {
        gc.fill(rect: bounds, with: colors.activationFill)
        gc.draw(rect: bounds, with: colors.activationLine, stroke: stroke)
    }
}
