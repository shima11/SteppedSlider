// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

// TODO: OSSとして切り分ける
// TODO: 参考にしてみる
// https://uvolchyk.medium.com/scrolling-pickers-in-swiftui-de4a9c653fb6

struct MySlider: View {

  @Binding var value: CGFloat
  @State private var currentIndex: Int

  let range: ClosedRange<CGFloat>
  let steps: CGFloat

  // NOTE: なぜかitemWidthとspacingをいい感じに入れないとメモリがずれる
  static let itemWidth: CGFloat = 20
  static let spacing: CGFloat = 0

  var maximumIndex: Int {
    Int(((range.upperBound - range.lowerBound) / steps))
  }

  var onEditing: () -> Void

  let feedback = UISelectionFeedbackGenerator()

  init(
    value: Binding<CGFloat>,
    range: ClosedRange<CGFloat>,
    steps: CGFloat,
    onEditing: @escaping () -> Void
  ) {

    self._value = value
    self.range = range
    self.steps = steps
    self.onEditing = onEditing
    self.currentIndex = .init(MySlider.calculateCurrentIndex(value: value.wrappedValue, steps: steps, range: range))
  }

  func shouldBold(index: Int) -> Bool {
    index == 0 || index == maximumIndex || (index % 5 == 0)
  }

  @State var scrollIndex: Int?

  @State var contentSize: CGSize = .zero

  var body: some View {
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

  static func calculateCurrentIndex(value: CGFloat, steps: CGFloat, range: ClosedRange<CGFloat>) -> Int {
    let index = (value - range.lowerBound) / steps
    return Int(round(index))
  }

}

#Preview {
  @Previewable @State var value: CGFloat = 5
  VStack {

    MySlider(value: $value, range: 1...20, steps: 0.1, onEditing: {})
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

// ViewEffectを使う方法

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
