// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

public struct SteppedSlider: View {

  @Binding private var value: CGFloat

  @State private var currentIndex: Int
  @State private var scrollIndex: Int?
  @State private var contentSize: CGSize = .zero

  private let itemWidth: CGFloat
  private let spacing: CGFloat

  private let range: ClosedRange<CGFloat>
  private let steps: CGFloat

  private var maximumIndex: Int {
    Int(((range.upperBound - range.lowerBound) / steps))
  }

  private var onEditing: @MainActor () -> Void

  public init(
    value: Binding<CGFloat>,
    range: ClosedRange<CGFloat>,
    steps: CGFloat,
    itemWidth: CGFloat = 10,
    spacing: CGFloat = 0,
    onEditing: @MainActor @escaping () -> Void
  ) {

    self._value = value
    self.range = range
    self.steps = steps
    self.itemWidth = itemWidth
    self.spacing = spacing
    self.onEditing = onEditing
    self.currentIndex = .init(SteppedSlider.calculateCurrentIndex(value: value.wrappedValue, steps: steps, range: range))
  }

  private func shouldBold(index: Int) -> Bool {
    index == 0 || index == maximumIndex || (index % 5 == 0)
  }

  public var body: some View {
    ScrollViewReader { scrollProxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: spacing) {
          ForEach(0...maximumIndex, id: \.self) { index in
            let isBold = shouldBold(index: index)
            ZStack {
              Rectangle()
                .foregroundStyle(Color.primary)
                .frame(width: isBold ? 2 : 1, height: isBold ? 24 : 12)
            }
            .frame(width: itemWidth)
            .overlay(
              ZStack {
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
            .scrollTransition(
              axis: .horizontal,
              transition: { content, phase in
                content
                  .opacity(phase.isIdentity ? 1.0 : 0.3)
              }
            )
          }
        }
        .scrollTargetLayout()
      }
      .contentMargins(.horizontal, contentSize.width/2 - itemWidth/2)
      .scrollPosition(id: $scrollIndex, anchor: .center)
      .scrollTargetBehavior(.snap(step: spacing + itemWidth))
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
      .onGeometryChange(for: CGSize.self, of: \.size, action: {
        contentSize = $0
      })
      .onChange(of: scrollIndex ?? 0, { oldValue, newValue in
        value = range.lowerBound + CGFloat(newValue) * steps
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
      .sensoryFeedback(.selection, trigger: value)
      .onAppear {
        Task { @MainActor in
          withAnimation {
            scrollProxy.scrollTo(currentIndex, anchor: .center)
          }
        }
      }
    }
  }

  static private func calculateCurrentIndex(value: CGFloat, steps: CGFloat, range: ClosedRange<CGFloat>) -> Int {
    let index = (value - range.lowerBound) / steps
    return Int(round(index))
  }

}

#Preview {

  @Previewable @State var value: CGFloat = 5.5

  let range: ClosedRange<CGFloat> = 1...20

  VStack {

    SteppedSlider(value: $value, range: range, steps: 0.1, onEditing: {})
      .frame(height: 60)
      .padding()

    Spacer(minLength: 24).fixedSize()

    Text(String(format: "%g", value))

    HStack {

      Button(action: {
        if range.contains(value - 1) {
          value -= 1
        }
      }, label: {
        Text("-1").bold()
      })
      .buttonStyle(.borderedProminent)
      .disabled(!range.contains(value - 1))

      Button(action: {
        if range.contains(value + 1) {
          value += 1
        }
      }, label: {
        Text("+1").bold()
      })
      .buttonStyle(.borderedProminent)
      .disabled(!range.contains(value + 1))

    }

  }
}
