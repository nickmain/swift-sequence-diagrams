// Copyright (c) 2023 David N Main

import SwiftUI

// Layout for a participant
struct ParticipantColumnModel {
    let index: Int
    let part: Participant
    let minHeight: LayoutValue
    let centerX: MemoizedValue
    let rect: Rect
    let centerXRequirements: AggregateComputation
    let activations = Activation()

    /// Get the offset to the right of the center due to activation rectangles
    func rightOfCenterOffsetX(at row: Activation.Row, config: Configuration) -> LayoutValue {
        let count = Double(activations.rightCount(at: row))
        if count > 0 {
            return FixedValue((count * config.activationCenterOffset) + (config.activationWidth / 2))
        } else if activations.centerIsActive(at: row) {
            return FixedValue(config.activationWidth / 2)
        }

        return FixedValue(0)
    }

    /// Get the offset to the left of the center due to activation rectangles
    func leftOfCenterOffsetX(at row: Activation.Row, config: Configuration) -> LayoutValue {
        let count = Double(activations.leftCount(at: row))
        if count > 0 {
            return FixedValue((count * config.activationCenterOffset) + (config.activationWidth / 2))
        } else if activations.centerIsActive(at: row) {
            return FixedValue(config.activationWidth / 2)
        }

        return FixedValue(0)
    }
}

/// The Activations for a particular column
class Activation {

    /// The position within a row where an activation starts or ends
    struct Row: Comparable, Equatable {
        enum Position { case top, bottom }

        let pos: Position
        let row: Int

        init(_ row: Int, _ pos: Position) {
            self.row = row
            self.pos = pos
        }

        static func < (lhs: Activation.Row, rhs: Activation.Row) -> Bool {
            if lhs.row < rhs.row { return true }
            if lhs.row > rhs.row { return false }

            return lhs.pos == .top && rhs.pos == .bottom
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.row == rhs.row && lhs.pos == rhs.pos
        }
    }

    class Info {
        let start: Row
        var end: Row = .init(Int.max, .bottom) // i.e. no real end
        let endY = MemoizedValue()
        let centerOffsetCount: Int

        fileprivate init(startRow: Row, centerOffsetCount: Int) {
            self.start = startRow
            self.centerOffsetCount = centerOffsetCount
        }
    }

    var left = [Info]()
    var right = [Info]()
    var center = [Info]()

    /// Create a new center activation starting at the given row.
    /// Return nil if there is already an activation at the row
    func newCenterActivation(at row: Row) -> Info? {
        guard !centerIsActive(at: row) else { return nil}
        let activation = Info(startRow: row, centerOffsetCount: 0)
        center.append(activation)
        return activation
    }

    /// Create a new left activation starting at the given row.
    /// If there is no center activation one is created instead.
    func newLeftActivation(at row: Row) -> Info {
        let activation: Info

        if centerIsActive(at: row) {
            activation = Info(startRow: row,
                                    centerOffsetCount: -leftCount(at: row) - 1)
            left.append(activation)
        } else {
            activation = Info(startRow: row, centerOffsetCount: 0)
            center.append(activation)
        }

        return activation
    }

    /// Create a new right activation starting at the given row.
    /// If there is no center activation one is created instead.
    func newRightActivation(at row: Row) -> Info {
        let activation: Info

        if centerIsActive(at: row) {
            activation = Info(startRow: row,
                                    centerOffsetCount: rightCount(at: row) + 1)
            right.append(activation)
        } else {
            activation = Info(startRow: row, centerOffsetCount: 0)
            center.append(activation)
        }

        return activation
    }

    func leftCount(at row: Row) -> Int {
        left.at(row: row).count
    }

    func rightCount(at row: Row) -> Int {
        right.at(row: row).count
    }

    func centerIsActive(at row: Row) -> Bool {
        !center.at(row: row).isEmpty
    }

    func activeCenter(at row: Row) -> Info? {
        center.at(row: row).first // should only be 0 or 1
    }

    // Activation at left, including center
    func activeLeft(at row: Row) -> Info? {
        left.at(row: row).last ?? activeCenter(at: row)
    }

    // Activation at right, including center
    func activeRight(at row: Row) -> Info? {
        right.at(row: row).last ?? activeCenter(at: row)
    }

    init() {}
}
extension Array where Element == Activation.Info {
    /// Get the activations that span the given row
    func at(row: Activation.Row) -> [Activation.Info] {
        self.filter { $0.start <= row && $0.end >= row }
    }
}

// An activation
class ActivationModel {
    var position: Int  // 0=center, <0 to the left, >0 to the right
    var startRow: Int
    var endRow: Int
    var rect: Rect
    var startOffset: MemoizedValue
    var endOffset: MemoizedValue
    var centerXOffset: MemoizedValue

    init(position: Int, startRow: Int, endRow: Int, rect: Rect, startOffset: MemoizedValue, endOffset: MemoizedValue, centerXOffset: MemoizedValue) {
        self.position = position
        self.startRow = startRow
        self.endRow = endRow
        self.rect = rect
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.centerXOffset = centerXOffset
    }
}

struct RowModel {
    let rect: Rect
    let span: ColumnSpan?
}

struct ColumnSpan {
    let leftColumnIndex: Int?
    let rightColumnIndex: Int?
}
