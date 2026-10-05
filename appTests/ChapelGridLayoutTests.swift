//
//  ChapelGridLayoutTests.swift
//  Lumen Viae Tests
//
//  The Chapel's grid, laid out offscreen and measured: a full section
//  takes the row, two halves share one and end on the same line (the
//  row stretches every tile to its height), a half left alone keeps its
//  own, two full rows stand 20 apart and a row of halves 18 from its
//  neighbours, and the halves 12 apart across the gutter.
//

import SwiftUI
import Testing
@testable import app

@MainActor
final class FrameBox {
    var frames: [Int: CGRect] = [:]
}

@MainActor
struct ChapelGridLayoutTests {

    private let width: CGFloat = 360

    /// Writes a tile's frame down as the grid draws it
    private struct Recorder: View {
        let index: Int
        let frame: CGRect
        let box: FrameBox
        var body: some View {
            box.frames[index] = frame
            return Color.clear
        }
    }

    /// Lays out tiles of (span, height) and returns their frames and the
    /// grid's whole height
    private func layout(_ tiles: [(span: Int, height: CGFloat)]) -> (frames: [CGRect], height: CGFloat) {
        let box = FrameBox()
        let grid = ChapelGridLayout {
            ForEach(Array(tiles.enumerated()), id: \.offset) { index, tile in
                // Its natural height when asked, and whatever the row
                // gives it when placed
                Color.clear
                    .frame(idealHeight: tile.height)
                    .overlay {
                        GeometryReader { proxy in
                            Recorder(index: index, frame: proxy.frame(in: .named("grid")), box: box)
                        }
                    }
                    .chapelSpan(tile.span)
            }
        }
        .frame(width: width)
        .coordinateSpace(name: "grid")
        .fixedSize(horizontal: false, vertical: true)

        let renderer = ImageRenderer(content: grid)
        renderer.scale = 1
        let height = renderer.uiImage?.size.height ?? 0
        let frames = tiles.indices.map { box.frames[$0] ?? .null }
        return (frames, height)
    }

    private var half: CGFloat { (width - 12) / 2 }

    /// Equal to the hundredth of a point: the grid's sums are drawn in
    /// floating point
    private func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

    @Test func aFullSectionTakesTheWholeRow() {
        let result = layout([(2, 100)])
        #expect(result.frames[0] == CGRect(x: 0, y: 0, width: width, height: 100))
        #expect(result.height == 100)
    }

    @Test func twoFullRowsStandTwentyApart() {
        let result = layout([(2, 100), (2, 60)])
        #expect(near(result.frames[1].minY, 120))
        #expect(near(result.height, 180))
    }

    @Test func twoHalvesShareARowAndEndOnTheSameLine() {
        let result = layout([(1, 50), (1, 80)])
        #expect(result.frames[0] == CGRect(x: 0, y: 0, width: half, height: 80))
        #expect(result.frames[1] == CGRect(x: half + 12, y: 0, width: half, height: 80))
        #expect(result.height == 80)
    }

    @Test func aRowOfHalvesStandsEighteenFromItsNeighbours() {
        let result = layout([(2, 100), (1, 40), (1, 40), (2, 100)])
        #expect(near(result.frames[1].minY, 118))
        #expect(near(result.frames[3].minY, 118 + 40 + 18))
        #expect(near(result.height, 118 + 40 + 18 + 100))
    }

    @Test func aHalfLeftAloneKeepsItsOwnHeightAndPlace() {
        let result = layout([(1, 70)])
        #expect(result.frames[0] == CGRect(x: 0, y: 0, width: half, height: 70))
    }

    @Test func aFullSectionBreaksAnOpenPairOfHalves() {
        // A half, then a full section: the half stands alone on its row
        let result = layout([(1, 30), (2, 50), (1, 30)])
        #expect(result.frames[0].minX == 0 && result.frames[0].width == half)
        #expect(near(result.frames[1].minY, 30 + 18))
        #expect(near(result.frames[2].minY, 30 + 18 + 50 + 18))
        #expect(result.frames[2].minX == 0, "the next half begins a new row")
    }

    @Test func nothingToLayOutIsNoHeight() {
        #expect(layout([]).height == 0)
    }
}
