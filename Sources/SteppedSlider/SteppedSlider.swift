// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

public struct SteppedSlider: View {

  @Binding private var value: CGFloat
  @State private var currentIndex: Int
  @State private var scrollIndex: Int?
  @State private var contentSize: CGSize = .zero

  // NOTE: なぜかitemWidthとspacingをいい感じに入れないとメモリがずれる
  static private let itemWidth: CGFloat = 20
  static private let spacing: CGFloat = 0

  private let range: ClosedRange<CGFloat>
  private let steps: CGFloat

  private var maximumIndex: Int {
    Int(((range.upperBound - range.lowerBound) / steps))
  }

  private var onEditing: () -> Void

  private let feedback = UISelectionFeedbackGenerator()

  public init(
    value: Binding<CGFloat>,
    range: ClosedRange<CGFloat>,
    steps: CGFloat,
    onEditing: @escaping () -> Void
  ) {

    self._value = value
    self.range = range
    self.steps = steps
    self.onEditing = onEditing
    self.currentIndex = .init(SteppedSlider.calculateCurrentIndex(value: value.wrappedValue, steps: steps, range: range))
  }

  public var body: some View {
    ScrollViewReader { scrollProxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: Self.spacing) {
          // itemWidth/2は｜のサイズの最優の余白分スクロールのInsetがずれて見えてしまう問題の対応
          // spacingはSpacerが入ってしまっているのでHStackのspacingが含まれてしまっている問題の対応
          Spacer(minLength: contentSize.width/2 -  Self.itemWidth/2 - Self.spacing).fixedSize()
          // 両端にメモリを置きたいので一つ追加している
          ForEach(0..<maximumIndex+1, id: \.self) { index in
            let isBold = shouldBold(index: index)
            ZStack {
              Rectangle()
                .foregroundStyle(Color.primary)
                .frame(width: isBold ? 2 : 1, height: isBold ? 24 : 12)
            }
            .frame(width: Self.itemWidth)
            .overlay(
              ZStack {
                // 一定間隔でメモリを表示
                if shouldBold(index: index) {
                  Text(String(format: "%g", CGFloat(index) * steps + range.lowerBound))
                    .font(.caption2)
                    .fixedSize()
                    .offset(y: -20)
                }
              }
            )
            .padding(.top, 12)
            .id(index)
          }
          Spacer(minLength: contentSize.width/2 -  Self.itemWidth/2 - Self.spacing).fixedSize()
        }
        .frame(height: 60)
        .scrollTargetLayout()
      }
      .scrollPosition(id: $scrollIndex, anchor: .center)
//      .scrollTargetBehavior(.viewAligned)
      .scrollTargetBehavior(.snap(step: Self.spacing + Self.itemWidth))
      .overlay(
        Rectangle()
          .frame(width: 2, height: 24)
          .foregroundColor(.red)
          .padding(.top, 12)
      )
      .mask({
        HStack(spacing: 0) {
          LinearGradient(colors: [.black.opacity(0), .black], startPoint: .leading, endPoint: .trailing).frame(width: 24)
          Color.black
          LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing).frame(width: 24)
        }
      })
      .measureSize($contentSize)
      .onChange(of: scrollIndex ?? 0, { oldValue, newValue in
        value = range.lowerBound + CGFloat(newValue) * steps
        feedback.selectionChanged()
        onEditing()
      })
      .onChange(of: value, { oldValue, newValue in

        // 履歴をタップして反映させる時, 他のスライダーに連動して反映する時

        let index = Self.calculateCurrentIndex(value: newValue, steps: steps, range: range)

        // 自分でスライダーを移動した場合はスクロールさせない
        guard index != scrollIndex else { return }

        withAnimation {
          scrollProxy.scrollTo(index, anchor: .center)
        }
      })
      .onAppear {
        withAnimation {
          scrollProxy.scrollTo(currentIndex, anchor: .center)
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  private func shouldBold(index: Int) -> Bool {
    index == 0 || index == maximumIndex || (index % 5 == 0)
  }

  static private func calculateCurrentIndex(value: CGFloat, steps: CGFloat, range: ClosedRange<CGFloat>) -> Int {
    let index = (value - range.lowerBound) / steps
    return Int(round(index))
  }

}

#Preview {
  @Previewable @State var value: CGFloat = 5
  VStack {

    SteppedSlider(value: $value, range: 1...20, steps: 0.1, onEditing: {})
      .padding()

    Text("\(value)")
    
    HStack {
      Button(action: {
        value -= 1
      }, label: {
        Text("-= 1")
      })
      Button(action: {
        value += 1
      }, label: {
        Text("+= 1")
      })
    }

  }
}

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



// https://uvolchyk.medium.com/scrolling-pickers-in-swiftui-de4a9c653fb6

import SwiftUI

// MARK: - Scroll Behavior

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

// MARK: - Picker

public struct WheelPicker: View {
  @Environment(\._wheelPicker_segmentWidth) private var segmentWidth

  @Binding var count: Int

  var values: ClosedRange<Int>
  var spacing: Double
  var steps: Int

  public init(
    count: Binding<Int>,
    values: ClosedRange<Int> = 0...100,
    spacing: Double = 8.0,
    steps: Int = 5
  ) {
    _count = count
    self.values = values
    self.spacing = spacing
    self.steps = steps
  }

  public var body: some View {
    ZStack {
      GeometryReader { proxy in
        ScrollView(.horizontal) {
          HStack(spacing: spacing) {
            ForEach(values, id: \.self) { index in
              let isPrimary = index % steps == .zero

              VStack(spacing: 40.0) {
                Rectangle()
                  .frame(
                    width: segmentWidth,
                    height: isPrimary ? 20.0 : 8.0
                  )
                  .frame(
                    maxHeight: 20.0,
                    alignment: .top
                  )
                Rectangle()
                  .frame(
                    width: segmentWidth,
                    height: isPrimary ? 20.0 : 8.0
                  )
                  .frame(
                    maxHeight: 20.0,
                    alignment: .bottom
                  )
              }
              .scrollTransition(
                axis: .horizontal,
                transition: { content, phase in
                  content
                    .opacity(phase == .topLeading ? 0.2 : 1.0)
                }
              )
              .overlay {
                if isPrimary {
                  Text("\(index)")
                    .font(.system(size: 24.0, design: .monospaced))
                    .fixedSize()
                    .scrollTransition(
                      axis: .horizontal,
                      transition: { content, phase in
                        content
                          .opacity(phase.isIdentity ? 10.0 : 0.4)
                      }
                    )
                }
              }
            }
          }
          .scrollTargetLayout()
        }
        .overlay {
          Rectangle()
            .fill(.red)
            .frame(width: segmentWidth)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.horizontal, proxy.size.width / 2.0)
        .scrollTargetBehavior(.snap(step: spacing + segmentWidth))
        .scrollPosition(
          id: .init(
            get: {
              count
            },
            set: { value, transaction in
              if let value {
                count = value
              }
            }
          )
        )
      }
    }
    .frame(width: 280.0, height: 80.0)
    .sensoryFeedback(.selection, trigger: count)
  }
}

// MARK: - Environment Modifications

struct _WheelPicker_SegmentWidth: EnvironmentKey {
  static let defaultValue: Double = 2.0
}

private extension EnvironmentValues {
  var _wheelPicker_segmentWidth: Double {
    get { self[_WheelPicker_SegmentWidth.self] }
    set(width) { self[_WheelPicker_SegmentWidth.self] = width }
  }
}

public extension View where Self == WheelPicker {
  func segment(width: Double) -> some View {
    environment(\._wheelPicker_segmentWidth, width)
  }
}

#Preview(body: {
  WheelPicker(count: .constant(3), values: 0...100, spacing: 24.0, steps: 5)
})
