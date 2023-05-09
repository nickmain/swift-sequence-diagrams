// Copyright (c) 2023 David N Main

import SwiftUI

extension GraphicsContext {

    func fill(rect: Rect, with color: Color) {
        self.fill(Path(rect.cgrect), with: .color(color))
    }

    func fill(size: CGSize, with color: Color) {
        self.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
    }

    func draw(rect: Rect, with color: Color, stroke: StrokeStyle) {
        self.stroke(Path(rect.cgrect), with: .color(color), style: stroke)
    }

    func draw(line points: Point..., with color: Color, stroke: StrokeStyle) {
        var linePath = Path()
        linePath.addLines(points.map(\.cgpoint))
        self.stroke(linePath, with: .color(color), style: stroke)
    }
}
