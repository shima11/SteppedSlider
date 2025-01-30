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

  @Previewable @State var value: CGFloat = 5.0

  VStack {

    SteppedSlider(value: $value, range: 1...20, steps: 0.1, onEditing: {})
      .frame(height: 60)
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

    Spacer(minLength: 48).fixedSize()

    SamplePicker(count: .constant(3), values: 0...100, spacing: 24.0, steps: 5)

  }
}

#if DEBUG

// https://youtu.be/5S08AZ8cYek

struct SamplePicker: View {

  @Binding var count: Int

  var values: ClosedRange<Int>
  var spacing: Double
  var steps: Int

  private var segmentWidth = 2.0

  init(
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

  var body: some View {
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

#Preview(body: {
  SamplePicker(count: .constant(3), values: 0...100, spacing: 24.0, steps: 5)
})

#endif
