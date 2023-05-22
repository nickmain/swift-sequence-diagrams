// Copyright (c) 2023 David N Main

import SwiftUI

public struct Configuration {

    public var horizontalMargin = 30.0
    public var verticalMargin = 30.0

    public var minParticipantSize = CGSize(width: 150.0, height: 30.0)
    public var participantHorizontalPadding = 30.0
    public var participantVerticalPadding = 10.0
    public var minParticipantGap = 50.0
    public var participantBottomMargin = 30.0
    public var participantFont: Font = .system(size: 18, design: .default)
    public var participantStroke = StrokeStyle(lineWidth: 2)
    public var lifeLineStroke = StrokeStyle(lineWidth: 2, dash: [10.0, 5.0])
    public var actorLifeLineStroke = StrokeStyle(lineWidth: 2)

    public var actorSymbolName = "figure.arms.open"
    public var actorSymbolSize = CGSize(width: 30, height: 40)
    public var actorSymbolBottomMargin = 8.0
    public var actorBottomMargin = 10.0

    public var messageFont: Font = .system(size: 18, design: .default)
    public var messageTextHorizontalPadding = 10.0
    public var messageTextBottomPadding = 5.0
    public var messageTextBackgroundPadding = 5.0
    public var messageArrowWidth = 12.0
    public var messageArrowLength = 14.0
    public var messageLineStroke = StrokeStyle(lineWidth: 2)
    public var messageDashedLineStroke = StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3.0, 5.0])
    public var selfMessageWidth = 50.0
    public var selfMessageHeight = 30.0

    public var separatorHeight = 40.0
    public var separatorFont: Font = .system(size: 18, design: .default)
    public var separatorLineStroke = StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5.0, 8.0])
    public var separatorTextPadding = 10.0

    public var noteFont: Font = .system(size: 16, design: .default)
    public var notePadding = 10.0
    public var noteHorzOffset = 20.0

    public var interRowGap = 20.0

    public var errorFont: Font = .system(size: 16, design: .monospaced)
    public var errorPadding = 5.0

    public var activationWidth = 20.0
    public var activationCenterOffset = 15.0
    public var activationLineStroke = StrokeStyle(lineWidth: 2)

    public var fragmentLabelFont: Font = .system(size: 18, design: .default)
    public var fragmentCaptionFont: Font = .system(size: 18, design: .default)
    public var fragmentLineStroke = StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5.0, 8.0])

    public init() {}
}

public struct ConfigColors {
    public static let lightBackground: Color = .white
    public static let darkBackground: Color = .black
    public static let lightForeground: Color = .black
    public static let darkForeground: Color = .white

    public let background: Color
    public let participantLine: Color
    public let participantText: Color
    public let participantFill: Color
    public let actorSymbol: Color
    public let lifeLine: Color
    public let messageLine: Color
    public let messageText: Color
    public let messageTextBackground: Color
    public let separatorLine: Color
    public let separatorText: Color
    public let separatorBackground: Color
    public let noteText: Color
    public let noteBackground: Color
    public let errorText: Color
    public let errorBackground: Color
    public let activationLine: Color
    public let activationFill: Color
    public let fragmentLine: Color
    public let fragmentLabelText: Color
    public let fragmentCaptionText: Color

    public static let light = ConfigColors(
        background: Self.lightBackground,
        participantLine: Self.lightForeground,
        participantText: Self.lightForeground,
        participantFill: Color(red: 0.7, green: 0.7, blue: 0.7),
        actorSymbol: Self.lightForeground,
        lifeLine: Self.lightForeground,
        messageLine: Self.lightForeground,
        messageText: Self.lightForeground,
        messageTextBackground: Self.lightBackground.opacity(0.8),
        separatorLine: .gray,
        separatorText: Self.lightForeground,
        separatorBackground: Self.lightBackground,
        noteText: .black,
        noteBackground: .yellow,
        errorText: .black,
        errorBackground: .red,
        activationLine: Color(red: 0.5, green: 0.5, blue: 0.5),
        activationFill: Color(red: 0.7, green: 0.7, blue: 0.7),
        fragmentLine: Self.lightForeground,
        fragmentLabelText: Self.lightForeground,
        fragmentCaptionText: Self.lightForeground
    )

    public static let dark = ConfigColors(
        background: Self.darkBackground,
        participantLine: Self.darkForeground,
        participantText: Self.darkForeground,
        participantFill: Color(red: 0.3, green: 0.3, blue: 0.3),
        actorSymbol: Self.darkForeground,
        lifeLine: Self.darkForeground,
        messageLine: Self.darkForeground,
        messageText: Self.darkForeground,
        messageTextBackground: Self.darkBackground.opacity(0.8),
        separatorLine: .gray,
        separatorText: Self.darkForeground,
        separatorBackground: Self.darkBackground,
        noteText: .black,
        noteBackground: .orange,
        errorText: .black,
        errorBackground: .red,
        activationLine: Color(red: 0.5, green: 0.5, blue: 0.5),
        activationFill: Color(red: 0.3, green: 0.3, blue: 0.3),
        fragmentLine: Self.darkForeground,
        fragmentLabelText: Self.darkForeground,
        fragmentCaptionText: Self.darkForeground
    )
}
