// Copyright (c) 2023 David N Main

import Foundation

/// Common protocol for Parts and Actors
public protocol ParticipantOrActor {
    var participant: Participant { get }
}
public struct Part: ParticipantOrActor {
    public let participant: Participant
    public init(_ label: String) { participant = Participant(label: label.md, isActor: false) }
}
public struct Actor: ParticipantOrActor {
    public let participant: Participant
    public init(_ label: String) { participant = Participant(label: label.md, isActor: true) }
}

public struct SDModel {
    var parts = [Participant]()
    var elements = [Element]()
}

@resultBuilder
public enum SequenceDiagramBuilder {

    public static func buildExpression(_ expression: ParticipantOrActor) -> SDModel {
        SDModel(parts: [expression.participant], elements: [])
    }

    public static func buildExpression(_ expression: SequenceDiagramModel.Message) -> SDModel {
        SDModel(parts: [], elements: [.message(expression)])
    }

    public static func buildExpression(_ expression: SequenceDiagramModel.Note) -> SDModel {
        SDModel(parts: [], elements: [.note(expression)])
    }

    public static func buildExpression(_ expression: String) -> SDModel {
        SDModel(parts: [], elements: [.separator(.init(caption: expression.md))])
    }

    public static func buildExpression(_ expression: Int) -> SDModel {
        SDModel(parts: [], elements: [.padding(CGFloat(expression))])
    }

    public static func buildExpression(_ expression: Element) -> SDModel {
        SDModel(parts: [], elements: [expression])
    }

    public static func buildPartialBlock(first: SDModel) -> SDModel {
        first
    }

    public static func buildPartialBlock(accumulated: SDModel, next: SDModel) -> SDModel {
        var acc = accumulated
        acc.parts.append(contentsOf: next.parts)
        acc.elements.append(contentsOf: next.elements)
        return acc
    }

    public static func buildFinalResult(_ component: SDModel) -> SequenceDiagramModel {
        return SequenceDiagramModel(participants: component.parts,
                                    elements: component.elements)
    }
}

public extension ParticipantOrActor {
    var activate: SequenceDiagramModel.Element {
        .activate(participant.id)
    }

    var deactivate: SequenceDiagramModel.Element {
        .deactivate(participant.id)
    }
}

public extension String {
    /// Make an attributed string from this string containing markdown
    var md: AttributedString {
        try! AttributedString(markdown: self,
                              options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    func from(_ partA: any ParticipantOrActor, to partB: any ParticipantOrActor) -> SequenceDiagramModel.Message {
        .init(start: partA.participant.id, end: partB.participant.id, comment: self.md)
    }

    func toSelf(_ part: any ParticipantOrActor) -> SequenceDiagramModel.Message {
        .init(start: part.participant.id, end: part.participant.id, comment: self.md)
    }

    func note(over part: any ParticipantOrActor) -> SequenceDiagramModel.Note {
        .init(text: self.md, position: .over(part.participant.id))
    }

    func note(leftOf part: any ParticipantOrActor) -> SequenceDiagramModel.Note {
        .init(text: self.md, position: .leftOf(part.participant.id))
    }

    func note(rightOf part: any ParticipantOrActor) -> SequenceDiagramModel.Note {
        .init(text: self.md, position: .rightOf(part.participant.id))
    }

    func note(from partA: any ParticipantOrActor, to partB:  any ParticipantOrActor) -> SequenceDiagramModel.Note {
        .init(text: self.md, position: .spanning(partA.participant.id, partB.participant.id))
    }
}
