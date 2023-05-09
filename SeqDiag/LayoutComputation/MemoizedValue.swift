// Copyright (c) 2023 David N Main

import Foundation

/// A Double value that can be mutated and shared by other primitives.
/// The value can stored or computed.
public class MemoizedValue: LayoutValue,
                            ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {

    /// Get the memoized value (compute if not set)
    public var value: Double {
        get { _value ?? compute() }
        set { _value = newValue }
    }

    /// The computation used to initialize the memoized value.
    /// Setting this to a non-nil value will clear the memoized value.
    public var computation: LayoutValue? {
        didSet {
            if computation == nil {
                // make sure there is a value when no computation
                _value = _value ?? 0
            } else {
                _value = nil  // to force computation on next get
            }
        }
    }

    private var _value: Double? = nil

    /// Initialize as a computed value
    ///
    /// - Parameter computation: functions that are called to compute the value.
    public init(_ computation: LayoutValue) {
        self.computation = computation
    }

    /// Initialize as a stored value
    public init(_ value: Double = 0) {
        _value = value
    }

    /// Initialize as a stored value
    required public init(floatLiteral value: Double) {
        _value = value
    }

    /// Initialize as a stored value
    required public init(integerLiteral value: IntegerLiteralType) {
        _value = Double(value)
    }

    /// Reset this value so that it can be recalculated.
    ///
    /// If there is no computation then this does nothing and any memoized value remains
    /// intact.
    /// If there is a computation then the memoized value is cleared so that the
    /// computation will be invoked the next time the value is accessed.
    public func resetComputation() {
        if computation != nil {
            _value = nil
        }
    }

    /// Set the value to the greater of the current and given ones
    public func set(ifLarger value: Double) {
        _value = max(_value ?? 0, value)
    }

    /// Compute and set the memoized value
    private func compute() -> Double {
        if let newValue = computation?.value {
            _value = newValue
            return newValue
        }

        return _value ?? 0
    }
}
