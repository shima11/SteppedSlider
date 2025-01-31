// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

public struct SteppedSlider<Anchor: View, Segment: View, SegmentOverlay: View>: View {

  @Binding private var value: CGFloat

  @State private var currentIndex: Int
  @State private var scrollIndex: Int?
  @State private var contentSize: CGSize = .zero

  private let itemWidth: CGFloat
  private let spacing: CGFloat

  private let range: ClosedRange<CGFloat>
  private let steps: CGFloat
  private let maximumIndex: Int

  private var onEditing: @MainActor () -> Void

  let anchorView: () -> Anchor
  let segmentView: (_ index: Int, _ maximumIndex: Int) -> Segment
  let segmentOverlayView: (_ index: Int, _ maximumIndex: Int) -> SegmentOverlay

  public enum HorizontalEdgeMask {
    case hidden
    case visible(width: CGFloat)
  }

  let horizontalEdgeMask: HorizontalEdgeMask

  public init(
    value: Binding<CGFloat>,
    range: ClosedRange<CGFloat>,
    steps: CGFloat,
    itemWidth: CGFloat = 10,
    spacing: CGFloat = 0,
    horizontalEdgeMask: HorizontalEdgeMask = .visible(width: 12),
    @ViewBuilder anchorView: @MainActor @escaping () -> Anchor,
    @ViewBuilder segmentView: @MainActor @escaping (Int, Int) -> Segment,
    @ViewBuilder segmentOverlayView: @MainActor @escaping (Int, Int) -> SegmentOverlay,
    onEditing: @MainActor @escaping () -> Void
  ) {
    self._value = value
    self.range = range
    self.steps = steps
    self.itemWidth = itemWidth
    self.spacing = spacing
    self.horizontalEdgeMask = horizontalEdgeMask
    self.anchorView = anchorView
    self.segmentView = segmentView
    self.segmentOverlayView = segmentOverlayView
    self.onEditing = onEditing

    self.maximumIndex = Int(((range.upperBound - range.lowerBound) / steps))
    self.currentIndex = .init(SteppedSlider.calculateCurrentIndex(value: value.wrappedValue, steps: steps, range: range))
  }

  public var body: some View {
    ScrollViewReader { scrollProxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: spacing) {
          ForEach(0...maximumIndex, id: \.self) { index in
            segmentView(index, maximumIndex)
              .frame(width: itemWidth)
              .overlay(
                segmentOverlayView(index, maximumIndex)
              )
              .id(index)
//              .scrollTransition(
//                axis: .horizontal,
//                transition: { content, phase in
//                  content
//                    .opacity(phase.isIdentity ? 1.0 : 0.3)
//                }
//              )
          }
        }
        .scrollTargetLayout()
      }
      .contentMargins(.horizontal, contentSize.width/2 - itemWidth/2)
      .scrollPosition(id: $scrollIndex, anchor: .center)
      .scrollTargetBehavior(.snap(step: spacing + itemWidth))
      .mask {
        switch horizontalEdgeMask {
        case .hidden:
          Color.black
        case .visible(let width):
          HStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0), .black], startPoint: .leading, endPoint: .trailing).frame(width: width)
            Color.black
            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing).frame(width: width)
          }
        }
      }
      .overlay(
        anchorView()
      )
      .sensoryFeedback(.selection, trigger: value)
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

  @Previewable @State var value: CGFloat = 5.8

  let range: ClosedRange<CGFloat> = 1...20
  let steps = 0.1
  let shouldBold1: (Int, Int) -> Bool = { index, maximumIndex -> Bool in
    index == 0 || index == maximumIndex || (index % 5 == 0)
  }

  VStack {

    SteppedSlider(
      value: $value,
      range: range,
      steps: steps,
      horizontalEdgeMask: .hidden,
      anchorView: {
        Rectangle()
          .frame(width: 2, height: 24)
          .foregroundColor(.red)
          .padding(.top, 12)
      },
      segmentView: { index, maximumIndex in
        let isBold = shouldBold1(index, maximumIndex)
        Rectangle()
          .foregroundStyle(Color.primary)
          .frame(width: isBold ? 2 : 1, height: isBold ? 24 : 12)
          .padding(.top, 12)
      },
      segmentOverlayView: { index, maximumIndex in
        if shouldBold1(index, maximumIndex) {
          Text(String(format: "%g", CGFloat(index) * steps + range.lowerBound))
            .font(.caption2)
            .fixedSize()
            .offset(y: -20)
            .padding(.top, 12)
        }
      },
      onEditing: {}
    )
    .frame(height: 60)
    .padding()

    Spacer(minLength: 24).fixedSize()

    let shouldBold2: (Int, Int) -> Bool = { index, maximumIndex -> Bool in
      index == 0 || index == maximumIndex || (index % 10 == 0)
    }

    SteppedSlider(
      value: $value,
      range: range,
      steps: steps,
      horizontalEdgeMask: .visible(width: 24),
      anchorView: {
        Rectangle()
          .frame(width: 2)
          .foregroundColor(.red)
      },
      segmentView: { index, maximumIndex in
        let isBold = shouldBold2(index, maximumIndex)
        VStack {
          Rectangle()
            .frame(width: isBold ? 2 : 1, height: isBold ? 16 : 12)
          Spacer()
          Rectangle()
            .frame(width: isBold ? 2 : 1, height: isBold ? 16 : 12)
        }
      },
      segmentOverlayView: { index, maximumIndex in
        let isBold = shouldBold2(index, maximumIndex)
        if isBold {
          Text(String(format: "%g", CGFloat(index) * steps + range.lowerBound))
            .font(.caption2)
            .fixedSize()
        }
      },
      onEditing: {}
    )
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
