// Copyright (c) 2023 David N Main

import Foundation

public struct SequenceDiagramModel: Codable {
    public struct Participant: Identifiable, Codable {
        public typealias ID = String

        public let id: ID
        public let label: AttributedString
        public let isActor: Bool

        public init(label: AttributedString, isActor: Bool = false, id: ID = UUID().uuidString) {
            self.id = id
            self.label = label
            self.isActor = isActor
        }
    }

    public enum Element: Codable {
        case message(Message)
        case activate(Participant.ID)
        case deactivate(Participant.ID)
        case note(Note)
        case fragmentStart(Fragment)
        case fragmentAlternate(Fragment)
        case fragmentEnd
        case separator(Separator)
        case padding(CGFloat)
    }

    public struct Separator: Codable {
        public let caption: AttributedString?
    }

    public struct Note: Codable {
        public enum Position: Codable {
            case over(Participant.ID)
            case spanning(Participant.ID, Participant.ID)
            case leftOf(Participant.ID)
            case rightOf(Participant.ID)
        }

        public let text: AttributedString
        public let position: Position
    }

    public struct Fragment: Codable {
        public let label: String
        public let caption: String
    }

    public struct Message: Codable {
        public enum ArrowHead: Codable {
            case solid, open
        }

        public enum LineType: Codable {
            case solid, dashed
        }

        public enum Side: Codable {
            case left, right
        }

        let start: Participant.ID
        let end: Participant.ID
        let comment: AttributedString
        var line: LineType
        var arrow: ArrowHead?
        var activateTarget: Bool
        var deactivateSender: Bool
        var selfSide: Side

        public init(start: Participant.ID, end: Participant.ID,
                    comment: AttributedString,
                    line: LineType = .solid, arrow: ArrowHead? = .solid,
                    activateTarget: Bool = false, deactivateSender: Bool = false,
                    selfSide: Side = .right) {
            self.start = start
            self.end = end
            self.comment = comment
            self.line = line
            self.arrow = arrow
            self.activateTarget = activateTarget
            self.deactivateSender = deactivateSender
            self.selfSide = selfSide
        }

        /// Create a copy of this message that activates the target
        public var activate: Message {
            var copy = self
            copy.activateTarget = true
            return copy
        }

        /// Create a copy of this message that deactivates the sender
        public var deactivate: Message {
            var copy = self
            copy.deactivateSender = true
            return copy
        }

        /// Create a copy of this message that has a self-message-side of left
        public var onLeft: Message {
            var copy = self
            copy.selfSide = .left
            return copy
        }

        /// Create a copy of this message that has an open arrow
        public var openArrow: Message {
            var copy = self
            copy.arrow = .open
            return copy
        }

        /// Create a copy of this message that has no arrow
        public var noArrow: Message {
            var copy = self
            copy.arrow = .none
            return copy
        }

        /// Create a copy of this message that is dashed
        public var dashed: Message {
            var copy = self
            copy.line = .dashed
            return copy
        }
    }

    public let participants: [Participant]
    public let elements: [Element]

    public init(participants: [Participant], elements: [Element]) {
        self.participants = participants
        self.elements = elements
    }
}
