// Copyright (c) 2023 David N Main

import Foundation

extension CGSize {
    /// The largest finite size
    static let greatest = CGSize(width: Double.greatestFiniteMagnitude,
                                 height: Double.greatestFiniteMagnitude)

    /// Return a size with the largest of each dimension
    func combined(with other: CGSize) -> CGSize {
        CGSize(width: max(self.width, other.width),
               height: max(self.height, other.height))
    }

    var halved: CGSize {
        CGSize(width: self.width/2, height: self.height/2)
    }

    /// Add the given padding on all sides
    func padded(with value: CGFloat) -> CGSize {
        CGSize(width: self.width + (value * 2), height: self.height + (value * 2))
    }

    /// Add some extra width
    func extra(width: CGFloat) -> CGSize {
        CGSize(width: self.width + width, height: self.height)
    }

    /// Add some extra height
    func extra(height: CGFloat) -> CGSize {
        CGSize(width: self.width, height: self.height + height)
    }
}

extension CGPoint {

    /// Move right
    func right(by dx: CGFloat) -> CGPoint {
        CGPoint(x: self.x + dx, y: self.y)
    }

    /// Move left
    func left(by dx: CGFloat) -> CGPoint {
        CGPoint(x: self.x - dx, y: self.y)
    }

    /// Move down
    func down(by dy: CGFloat) -> CGPoint {
        CGPoint(x: self.x, y: self.y + dy)
    }

    /// New point at the offset
    func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: self.x + dx, y: self.y + dy)
    }
}

extension CGRect {

    /// The center point of the rect
    var center: CGPoint {
        CGPoint(x: self.origin.x + self.width/2,
                y: self.origin.y + self.height/2)
    }

    /// The bottom center point
    var bottomCenter: CGPoint {
        CGPoint(x: self.origin.x + self.width/2,
                y: self.origin.y + self.height)
    }

    /// Make a new rect of the given size, centered at the top
    /// of this one
    func rectCenteredAtTop(size: CGSize) -> CGRect {
        CGRect(x: self.minX + self.width/2 - size.width/2,
               y: self.minY,
               width: size.width,
               height: size.height)
    }

    /// Make a new rect of the given size centered in this one
    func centeredRect(size: CGSize) -> CGRect {
        CGRect(origin: CGPoint(x: origin.x + (width / 2) - (size.width / 2),
                               y: origin.y + (height / 2) - (size.height / 2)),
               size: size)
    }

    /// Make a same-sized rect at the new origin
    func rect(at newOrigin: CGPoint) -> CGRect {
        CGRect(origin: newOrigin, size: self.size)
    }

    /// Make a new rect with the given height
    func rect(height: CGFloat) -> CGRect {
        CGRect(origin: self.origin,
               size: CGSize(width: self.width, height: height))
    }

    /// Add the given padding on all sides
    func padded(with value: CGFloat) -> CGRect {
        CGRect(origin: self.origin.offset(dx: -value, dy: -value),
               size: self.size.padded(with: value))
    }

    /// Remove the given padding on all sides
    func unpadded(with value: CGFloat) -> CGRect {
        CGRect(origin: self.origin.offset(dx: value, dy: value),
               size: self.size.padded(with: -value))
    }
}
