//
//  File.swift
//  SteppedSlider
//
//  Created by Jinsei Shima on 2024/11/30.
//

import Foundation
import SwiftUI

// https://uvolchyk.medium.com/scrolling-pickers-in-swiftui-de4a9c653fb6

/// A structure that defines a snapping behavior for scroll targets, conforming to `ScrollTargetBehavior`.
struct SnapScrollTargetBehavior: ScrollTargetBehavior {
  /// The step value to which the scroll target should snap.
  let step: Double

  /// Computes the closest multiple of `b` to the given value `a`.
  /// - Parameters:
  ///   - a: The value to snap.
  ///   - b: The step to which `a` should snap.
  /// - Returns: The closest multiple of `b` to `a`.
  private func closestMultiple(
    a: Double,
    b: Double
  ) -> Double {
    let lowerMultiple = floor((a / b)) * b
    let upperMultiple = floor(lowerMultiple + b)

    return if abs(a - lowerMultiple) <= abs(a - upperMultiple) {
      lowerMultiple
    } else {
      upperMultiple
    }
  }

  func updateTarget(
    _ target: inout ScrollTarget,
    context: TargetContext
  ) {

    let x1 = target.rect.origin.x
    let x2 = closestMultiple(a: x1, b: step)

    target.rect.origin.x = x2
  }
}

extension ScrollTargetBehavior where Self == SnapScrollTargetBehavior {
  /// Creates a `SnapScrollTargetBehavior` with the specified step.
  /// - Parameter step: The step value to which the scroll target should snap.
  /// - Returns: A `SnapScrollTargetBehavior` instance with the given step value.
  static func snap(step: Double) -> SnapScrollTargetBehavior { .init(step: step) }
}
