//
//  File.swift
//  SteppedSlider
//
//  Created by Jinsei Shima on 2024/11/28.
//

import Foundation
import SwiftUI

struct SizingPreferenceKey: PreferenceKey {

  typealias Value = CGSize

  static let defaultValue: Value = .zero

  static func reduce(value: inout Value, nextValue: () -> Value) {
    let next = nextValue()
    value = next
  }

}

extension View {

  /**
   Measures the receiver view size using GeometryReader.
   */
  public func measureSize(_ size: Binding<CGSize>) -> some View {
    background(Color.clear._measureSize(size))
  }

  private func _measureSize(_ size: Binding<CGSize>) -> some View {

    self.background(
      GeometryReader(content: { proxy in
        Color.clear
          .preference(key: SizingPreferenceKey.self, value: proxy.size)
      })
    )
    .onPreferenceChange(SizingPreferenceKey.self) { _size in
      size.wrappedValue = _size
    }

  }

}
