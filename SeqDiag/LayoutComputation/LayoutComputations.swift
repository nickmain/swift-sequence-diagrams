// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation

/// A layout value that may be computed or return a memoized value
public protocol LayoutValue: LayoutValueConvertiable {

    /// Compute the value
    var value: Double { get }
}

/// A fixed value
public struct FixedValue: LayoutValue {
    public let value: Double

    public init(_ value: Double) { self.value = value }
    public init(_ value: CGFloat) { self.value = value }
    public init(_ value: Int) { self.value = Double(value) }
}

/// A LayoutValue that uses a closure to compute the value
public struct Computation: LayoutValue {
    public let computation: () -> Double
    public var value: Double { computation() }

    public init(_ computation: @escaping () -> Double) {
        self.computation = computation
    }
}

/// LayoutValye that is an aggregate computation.
/// 
/// This is class based so that arguments can be added incrementally in addition
/// to via the initializer.
public class AggregateComputation: LayoutValue {
    public let computation: ([LayoutValue]) -> Double
    public var value: Double { computation(arguments) }
    public var arguments: [LayoutValue]

    public init(_ arguments: [LayoutValue] = [], _ computation: @escaping ([LayoutValue]) -> Double) {
        self.computation = computation
        self.arguments = arguments
    }

    /// Add an argument for the computation
    public func add(argument: LayoutValueConvertiable) {
        arguments.append(argument.asValue)
    }

    /// Create an AggregateComputation that is the max of its arguments
    public static func maximum() -> AggregateComputation {
        AggregateComputation { max($0).value }
    }

    /// Create an AggregateComputation that is the min of its arguments
    public static func minimum() -> AggregateComputation {
        AggregateComputation { min($0).value }
    }
}

/// Wrapper that prints a message when the value is fetched
public struct DebugComputation: LayoutValue {
    public var value: Double {
        let val = layoutValue.value
        print("\(message) = \(val)")
        return val
    }

    private let layoutValue: LayoutValue
    private let message: String

    public init(message: String, _ layoutValue: LayoutValueConvertiable) {
        self.layoutValue = layoutValue.asValue
        self.message = message
    }
}

/// Wrap a computation with a debug message
public func debug(_ msg: String, _ computation: LayoutValueConvertiable) -> DebugComputation {
    DebugComputation(message: msg, computation)
}

public extension LayoutValue {
    /// Half the value
    var half: Computation { self / 2 }
}

// Make a new computation that adds two values
public func +(left: LayoutValueConvertiable, right: LayoutValueConvertiable) -> Computation {
    let a = left.asValue
    let b = right.asValue
    return Computation { a.value + b.value }
}

// Make a new computation that substracts
public func -(left: LayoutValueConvertiable, right: LayoutValueConvertiable) -> Computation {
    let a = left.asValue
    let b = right.asValue
    return Computation { a.value - b.value }
}

// Make a new computation that multiplies two values
public func *(left: LayoutValueConvertiable, right: LayoutValueConvertiable) -> Computation {
    let a = left.asValue
    let b = right.asValue
    return Computation { a.value * b.value }
}

// Make a new computation that divides two values
public func /(left: LayoutValueConvertiable, right: LayoutValueConvertiable) -> Computation {
    let a = left.asValue
    let b = right.asValue
    return Computation { a.value / b.value }
}

// Make a new computation that is the max of several values
public func max(_ values: LayoutValueConvertiable...) -> Computation {
    let comps = values.map { $0.asValue }
    return Computation { comps.reduce(0) { max($0, $1.value) }}
}

/// Make a new computation that is the max of several values.
/// This captures the current elements of the array and only should be called
/// once the array has been fully populated.
public func max(_ values: [LayoutValueConvertiable]) -> Computation {
    let comps = values.map { $0.asValue }
    return Computation { comps.reduce(0) { max($0, $1.value) }}
}

// Make a new computation that is the min of several values
public func min(_ values: LayoutValueConvertiable...) -> Computation {
    let comps = values.map { $0.asValue }
    return Computation { comps.reduce(Double.greatestFiniteMagnitude) { min($0, $1.value) }}
}

/// Make a new computation that is the min of several values.
/// This captures the current elements of the array and only should be called
/// once the array has been fully populated.
public func min(_ values: [LayoutValueConvertiable]) -> Computation {
    let comps = values.map { $0.asValue }
    return Computation { comps.reduce(Double.greatestFiniteMagnitude) { min($0, $1.value) }}
}

/// Computation for the absolute value of another computation
public func abs(_ computation: LayoutValueConvertiable) -> Computation {
    let comp = computation.asValue
    return Computation { abs(comp.value) }
}

// MARK: - Conversion to Layout Value

public protocol LayoutValueConvertiable {
    var asValue: LayoutValue { get }
}
public extension LayoutValueConvertiable where Self: LayoutValue {
    var asValue: LayoutValue { self }
}
extension Double: LayoutValueConvertiable {
    public var asValue: LayoutValue { FixedValue(self) }
}
extension CGFloat: LayoutValueConvertiable {
    public var asValue: LayoutValue { FixedValue(self) }
}
extension Int: LayoutValueConvertiable {
    public var asValue: LayoutValue { FixedValue(self) }
}
