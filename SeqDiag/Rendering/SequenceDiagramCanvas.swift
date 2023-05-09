// Copyright (c) 2023 David N Main

import Foundation
import SwiftUI
//import SequenceDiagram

public typealias Participant = SequenceDiagramModel.Participant
public typealias Element = SequenceDiagramModel.Element

public struct SequenceDiagramCanvas: View {
    
    private let sequenceDiagramModel: SequenceDiagramModel
    private let config = Configuration()
    @Environment(\.colorScheme) private var colorScheme
    
    public init(_ model: SequenceDiagramModel) {
        self.sequenceDiagramModel = model
    }

    public init(@SequenceDiagramBuilder _ content: () -> SequenceDiagramModel) {
        self.sequenceDiagramModel = content()
    }

    public var body: some View {
        let colors = colorScheme == .light ? ConfigColors.light : ConfigColors.dark

        Canvas { gc, size in
//            let layout = DiagramLayout(model: sequenceDiagramModel, config: config)
//            layout.draw(gc: gc, canvasSize: size, colors: colors)


            let layout = SequenceDiagramLayout(model: sequenceDiagramModel, config: config)
            let renderModel = layout.layout()

            renderModel.render(gc: gc, canvasSize: size, colors: colors)
        }
        .multilineTextAlignment(.center)
    }
}
