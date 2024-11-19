// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

// https://uvolchyk.medium.com/scrolling-pickers-in-swiftui-de4a9c653fb6

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
      .scrollTargetBehavior(.viewAligned)
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
