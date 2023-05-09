// Copyright (c) 2023 David N Main

import Foundation

// typealiases for self-documentation
public typealias Width = LayoutValue
public typealias Height = LayoutValue
public typealias XValue = LayoutValue
public typealias YValue = LayoutValue

public struct Point {
    public let x: LayoutValue
    public let y: LayoutValue

    public var cgpoint: CGPoint { CGPoint(x: x.value, y: y.value) }

    public init(x: LayoutValueConvertiable, y: LayoutValueConvertiable) {
        self.x = x.asValue
        self.y = y.asValue
    }

    public init(cgpoint: CGPoint) {
        x = FixedValue(cgpoint.x)
        y = FixedValue(cgpoint.y)
    }

    /// Make a new point that is down by the given value
    public func down(by value: LayoutValueConvertiable) -> Point {
        Point(x: x, y: y + value)
    }

    /// Make a new point that is up by the given value
    public func up(by value: LayoutValueConvertiable) -> Point {
        Point(x: x, y: y - value)
    }

    /// Make a new point that is right by the given value
    public func right(by value: LayoutValueConvertiable) -> Point {
        Point(x: x + value, y: y)
    }

    /// Make a new point that is left by the given value
    public func left(by value: LayoutValueConvertiable) -> Point {
        Point(x: x - value, y: y)
    }

    /// Make a new point with a relative offset
    public func offset(dx: LayoutValueConvertiable, dy: LayoutValueConvertiable) -> Point {
        Point(x: self.x + dx, y: self.y + dy)
    }
}

public protocol Size {
    var width: LayoutValue { get }
    var height: LayoutValue { get }
}

public struct ComputedSize: Size {
    public let width: LayoutValue
    public let height: LayoutValue

    public init(width: LayoutValueConvertiable, height: LayoutValueConvertiable) {
        self.width = width.asValue
        self.height = height.asValue
    }

    /// Make a fixed size from a CGSize
    public init(cgsize: CGSize) {
        width  = FixedValue(cgsize.width)
        height = FixedValue(cgsize.height)
    }
}

/// A Size built on mutable LayoutValues such that it can later be updated.
public struct MutableSize: Size {
    public var width: LayoutValue { widthValue }
    public var height: LayoutValue { heightValue }

    public let widthValue: MemoizedValue
    public let heightValue: MemoizedValue

    public init(width: MemoizedValue = MemoizedValue(0), height: MemoizedValue = MemoizedValue(0)) {
        widthValue = width
        heightValue = height
    }

    /// Make a mutable size from a CGSize
    public init(cgsize: CGSize) {
        widthValue  = MemoizedValue(cgsize.width)
        heightValue = MemoizedValue(cgsize.height)
    }

    /// Set the width and height from the given CGSize
    public func set(cgsize: CGSize) {
        widthValue.value = cgsize.width
        heightValue.value = cgsize.height
    }
}

public struct Rect {
    public let origin: Point
    public let size: Size

    public var cgrect: CGRect { CGRect(origin: origin.cgpoint, size: size.cgsize) }

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    public init(x: LayoutValueConvertiable, y: LayoutValueConvertiable,
         w: LayoutValueConvertiable, h: LayoutValueConvertiable) {
        self.init(origin: Point(x: x, y: y), size: ComputedSize(width: w, height: h))
    }

    public init(cgrect: CGRect) {
        origin = Point(cgpoint: cgrect.origin)
        size = ComputedSize(cgsize: cgrect.size)
    }

    public var x: LayoutValue { origin.x }
    public var y: LayoutValue { origin.y }
    public var width: LayoutValue { size.width }
    public var height: LayoutValue { size.height }

    public var rightX:  Computation { origin.x + size.width }
    public var bottomY: Computation { origin.y + size.height }
    public var centerX: Computation { origin.x + size.width.half }
    public var centerY: Computation { origin.y + size.height.half }

    public var center:       Point { Point(x: centerX, y: centerY) }
    public var topCenter:    Point { Point(x: centerX, y: origin.y) }
    public var bottomCenter: Point { Point(x: centerX, y: bottomY) }
    public var leftCenter:   Point { Point(x: origin.x, y: centerY) }
    public var rightCenter:  Point { Point(x: rightX, y: centerY) }

    /// Make a new Rect of the given size that is dynamically computed
    /// to be at the center of this one
    public func centeredRect(size: Size) -> Rect {
        let newOrigin = Point(x: centerX - size.width.half,
                              y: centerY - size.height.half)
        return Rect(origin: newOrigin, size: size)
    }

    /// Make a new Rect of the given size that is dynamically computed
    /// to be centered at the bottom of this one
    public func centerBottomRect(size: Size) -> Rect {
        let newOrigin = Point(x: centerX - size.width.half,
                              y: bottomY - size.height)
        return Rect(origin: newOrigin, size: size)
    }

    /// Make a new Rect of the given size that is dynamically computed
    /// to be centered at the top of this one
    public func centerTopRect(size: Size) -> Rect {
        let newOrigin = Point(x: centerX - size.width.half, y: origin.y)
        return Rect(origin: newOrigin, size: size)
    }

    /// Make a rect that has the given point as its bottom center
    public static func withBottomCenter(point: Point, size: Size) -> Rect {
        Rect(origin: Point(x: point.x - size.width.half,
                           y: point.y - size.height),
             size: size)
    }

    /// Make a rect that has the given point as its top center
    public static func withTopCenter(point: Point, size: Size) -> Rect {
        Rect(origin: Point(x: point.x - size.width.half,
                           y: point.y),
             size: size)
    }

    /// Make a rect that has the given point as its center
    public static func withCenter(point: Point, size: Size) -> Rect {
        Rect(origin: Point(x: point.x - size.width.half,
                           y: point.y - size.height.half),
             size: size)
    }

    /// Make a rect that has the given point as its bottom left corner
    public static func withBottomLeft(point: Point, size: Size) -> Rect {
        Rect(origin: Point(x: point.x, y: point.y - size.height), size: size)
    }

    /// Make a rect that has the given point as its bottom right corner
    public static func withBottomRight(point: Point, size: Size) -> Rect {
        Rect(origin: Point(x: point.x - size.width, y: point.y - size.height), size: size)
    }
}

public extension Size {
    var cgsize: CGSize { CGSize(width: width.value, height: height.value) }

    /// Make a new size that is taller by the given amount
    func taller(by value: LayoutValueConvertiable) -> Size {
        ComputedSize(width: width, height: height + value)
    }

    /// Make a new size that is larger by the given amount
    func larger(by value: LayoutValueConvertiable) -> Size {
        let comp = value.asValue
        return ComputedSize(width: width + comp, height: height + comp)
    }
}
