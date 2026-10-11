import SwiftUI

/// 9×9 Difficulty × Terrain grid. Tap selects one combination, drag selects the rectangle
/// between the start cell and the current cell, and a tap while exactly one cell is
/// selected extends the selection to the tapped cell.
///
/// With `showsHeaders`, a header row (terrain) and column (difficulty) frame the cells;
/// tapping a header selects that whole row/column, the corner selects everything.
struct DTGrid: View {
    @Binding var range: DTRange
    /// True while a finger is down – lets a sheet disable interactive dismissal meanwhile.
    @Binding var isTouching: Bool
    let showsHeaders: Bool

    @State private var anchor: Target?
    @State private var hover: Target?
    @State private var rangeAtTouchDown: DTRange?
    @State private var isDragging = false

    private let gap: CGFloat = 1
    private let outerRadius: CGFloat = 10

    init(range: Binding<DTRange>, isTouching: Binding<Bool> = .constant(false), showsHeaders: Bool = false) {
        _range = range
        _isTouching = isTouching
        self.showsHeaders = showsHeaders
    }

    var body: some View {
        // Header column width == header row height keeps the whole control square.
        GeometryReader { geo in
            let metrics = Metrics(width: geo.size.width, header: showsHeaders ? 28 : 0)
            ZStack(alignment: .topLeading) {
                if showsHeaders { headers(metrics) }
                ForEach(DTCell.all) { cell in
                    cellView(cell, pitch: metrics.pitch)
                        .frame(width: metrics.pitch - gap, height: metrics.pitch - gap)
                        .position(metrics.center(of: .cell(cell)))
                }
                if let hover {
                    loupe(for: hover, metrics: metrics)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(metrics))
        }
        .aspectRatio(1, contentMode: .fit)
        .sensoryFeedback(trigger: hover) { old, new in
            new != nil && old != new ? .selection : nil
        }
        .accessibilityRepresentation {
            VStack {
                stepper("Minimum difficulty", \.difficulty, lower: true)
                stepper("Maximum difficulty", \.difficulty, lower: false)
                stepper("Minimum terrain", \.terrain, lower: true)
                stepper("Maximum terrain", \.terrain, lower: false)
            }
        }
    }

    // MARK: Gesture

    private func dragGesture(_ metrics: Metrics) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let target = metrics.target(at: value.location)
                if anchor == nil {
                    anchor = target
                    rangeAtTouchDown = range
                    isDragging = false
                    isTouching = true
                }
                if target != anchor { isDragging = true }
                hover = target
                if isDragging, let anchor {
                    range = anchor.span.hull(target.span).range
                } else {
                    range = tapResult(for: target)
                }
            }
            .onEnded { _ in
                anchor = nil
                hover = nil
                rangeAtTouchDown = nil
                isDragging = false
                isTouching = false
            }
    }

    /// A tap on a cell extends a single-cell selection to a rectangle; otherwise a tap selects
    /// just what was tapped (a cell, a whole row/column, or everything).
    private func tapResult(for target: Target) -> DTRange {
        if case .cell(let cell) = target, let single = rangeAtTouchDown?.singleCell, single != cell {
            return DTRange(from: single, to: cell)
        }
        return target.span.range
    }

    // MARK: Drawing

    private func cellView(_ cell: DTCell, pitch: CGFloat) -> some View {
        let selected = range.contains(cell)
        let shape = cornerShape(for: cell)
        return ZStack {
            shape.fill(selected ? Theme.green : Theme.cellFill)
            if anchor == .cell(cell) {
                shape.strokeBorder(selected ? Color.white : Theme.green, lineWidth: 2)
            }
            if !showsHeaders {
                VStack(spacing: -pitch * 0.04) {
                    Text(cell.difficulty.dtLabel + " /")
                    Text(cell.terrain.dtLabel).opacity(selected ? 0.9 : 0.75)
                }
                .font(.system(size: pitch * 0.3, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(selected ? Color.white : Color.primary)
            }
        }
    }

    /// Square inner cells; only the four corner cells round their outer corner so the
    /// block of cells reads as one rounded rectangle.
    private func cornerShape(for cell: DTCell) -> UnevenRoundedRectangle {
        let last = DTRange.count - 1
        func r(_ isCorner: Bool) -> CGFloat { isCorner ? outerRadius : 0 }
        return UnevenRoundedRectangle(
            topLeadingRadius: r(cell.row == 0 && cell.col == 0),
            bottomLeadingRadius: r(cell.row == last && cell.col == 0),
            bottomTrailingRadius: r(cell.row == last && cell.col == last),
            topTrailingRadius: r(cell.row == 0 && cell.col == last),
            style: .continuous
        )
    }

    @ViewBuilder
    private func headers(_ metrics: Metrics) -> some View {
        let font = Font.system(size: 12, weight: .medium, design: .rounded)
        Text("D/T")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(range.isAll ? Theme.green : .secondary)
            .position(metrics.center(of: .corner))
        ForEach(0..<DTRange.count, id: \.self) { i in
            let value = DTRange.steps[i]
            Text(value.dtLabel)
                .font(font)
                .foregroundStyle(range.terrain.contains(value) ? Theme.green : .secondary)
                .fontWeight(range.terrain.contains(value) ? .bold : .medium)
                .position(metrics.center(of: .col(i)))
            Text(value.dtLabel)
                .font(font)
                .foregroundStyle(range.difficulty.contains(value) ? Theme.green : .secondary)
                .fontWeight(range.difficulty.contains(value) ? .bold : .medium)
                .position(metrics.center(of: .row(i)))
        }
        .monospacedDigit()
        .minimumScaleFactor(0.7)
    }

    /// Callout above the finger so the touched cell stays readable. On the top two rows (and
    /// the terrain header) it moves beside the finger instead, so it isn't clipped.
    private func loupe(for target: Target, metrics: Metrics) -> some View {
        let size = CGSize(width: 124, height: isDragging ? 58 : 44)
        let c = metrics.center(of: target)
        let pitch = metrics.pitch
        var position: CGPoint
        if c.y - metrics.header >= pitch * 2 {
            position = CGPoint(x: c.x, y: c.y - pitch * 1.1 - size.height / 2)
        } else {
            let towardsCenter: CGFloat = c.x < metrics.width / 2 ? 1 : -1
            position = CGPoint(x: c.x + towardsCenter * (pitch * 0.9 + size.width / 2), y: c.y + pitch * 0.3)
        }
        position.x = min(max(position.x, size.width / 2), metrics.width - size.width / 2)

        return VStack(spacing: 2) {
            Text(target.title)
                .font(.system(.headline, design: .rounded))
            if isDragging {
                Text(range.summary)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.8))
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .frame(width: size.width, height: size.height)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
        .position(position)
        .allowsHitTesting(false)
    }

    // MARK: Accessibility

    private func stepper(_ title: String, _ axis: WritableKeyPath<DTRange, ClosedRange<Double>>, lower: Bool) -> some View {
        let binding = Binding<Double>(
            get: { lower ? range[keyPath: axis].lowerBound : range[keyPath: axis].upperBound },
            set: { value in
                let current = range[keyPath: axis]
                range[keyPath: axis] = lower
                    ? min(value, current.upperBound)...current.upperBound
                    : current.lowerBound...max(value, current.lowerBound)
            }
        )
        return Stepper(title, value: binding, in: DTRange.full, step: 0.5)
            .accessibilityValue(binding.wrappedValue.dtLabel)
    }
}

// MARK: - Hit targets & geometry

/// What a touch lands on: a cell, a difficulty (row) header, a terrain (column) header, or the corner.
private enum Target: Hashable {
    case cell(DTCell)
    case row(Int)
    case col(Int)
    case corner

    var span: Span {
        let all = 0...(DTRange.count - 1)
        switch self {
        case .cell(let c): return Span(rows: c.row...c.row, cols: c.col...c.col)
        case .row(let r): return Span(rows: r...r, cols: all)
        case .col(let c): return Span(rows: all, cols: c...c)
        case .corner: return Span(rows: all, cols: all)
        }
    }

    var title: String {
        switch self {
        case .cell(let c): return "D \(c.difficulty.dtLabel)  T \(c.terrain.dtLabel)"
        case .row(let r): return "D \(DTRange.steps[r].dtLabel)  T any"
        case .col(let c): return "D any  T \(DTRange.steps[c].dtLabel)"
        case .corner: return "Any"
        }
    }
}

/// Rectangle of grid indices.
private struct Span {
    var rows: ClosedRange<Int>
    var cols: ClosedRange<Int>

    func hull(_ other: Span) -> Span {
        Span(rows: min(rows.lowerBound, other.rows.lowerBound)...max(rows.upperBound, other.rows.upperBound),
             cols: min(cols.lowerBound, other.cols.lowerBound)...max(cols.upperBound, other.cols.upperBound))
    }

    var range: DTRange {
        DTRange(difficulty: DTRange.steps[rows.lowerBound]...DTRange.steps[rows.upperBound],
                terrain: DTRange.steps[cols.lowerBound]...DTRange.steps[cols.upperBound])
    }
}

private struct Metrics {
    let width: CGFloat
    /// Width of the header column == height of the header row (0 without headers).
    let header: CGFloat
    var pitch: CGFloat { (width - header) / CGFloat(DTRange.count) }

    /// Position-based hit-testing: every point maps to a target, gaps included.
    func target(at p: CGPoint) -> Target {
        let col = Int(((p.x - header) / pitch).rounded(.down))
        let row = Int(((p.y - header) / pitch).rounded(.down))
        let inHeaderCol = header > 0 && p.x < header
        let inHeaderRow = header > 0 && p.y < header
        let clamp = { (i: Int) in min(max(i, 0), DTRange.count - 1) }
        switch (inHeaderRow, inHeaderCol) {
        case (true, true): return .corner
        case (true, false): return .col(clamp(col))
        case (false, true): return .row(clamp(row))
        case (false, false): return .cell(DTCell(row: row, col: col))
        }
    }

    func center(of target: Target) -> CGPoint {
        let x = { (col: Int) in self.header + (CGFloat(col) + 0.5) * self.pitch }
        let y = { (row: Int) in self.header + (CGFloat(row) + 0.5) * self.pitch }
        switch target {
        case .cell(let c): return CGPoint(x: x(c.col), y: y(c.row))
        case .row(let r): return CGPoint(x: header / 2, y: y(r))
        case .col(let c): return CGPoint(x: x(c), y: header / 2)
        case .corner: return CGPoint(x: header / 2, y: header / 2)
        }
    }
}

// MARK: - Panel

/// Readout + legend + grid. Shared by all presentation variants.
struct DTPickerPanel: View {
    @Binding var range: DTRange
    var isTouching: Binding<Bool> = .constant(false)
    var showsHeaders = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 2) {
                    GridRow {
                        Text("Difficulty").foregroundStyle(.secondary)
                        Text(range.difficultyText).fontWeight(.semibold)
                    }
                    GridRow {
                        Text("Terrain").foregroundStyle(.secondary)
                        Text(range.terrainText).fontWeight(.semibold)
                    }
                }
                .font(.system(.title3, design: .rounded))
                .monospacedDigit()
                Spacer()
                Button("Any") { range = .all }
                    .buttonStyle(.bordered)
                    .disabled(range.isAll)
            }
            .padding(.horizontal, 6)

            if !showsHeaders {
                HStack(spacing: 6) {
                    VStack(spacing: -2) {
                        Text("D /")
                        Text("T").opacity(0.75)
                    }
                    .font(.system(size: 9, design: .rounded))
                    .frame(width: 20, height: 20)
                    .background(Theme.cellFill, in: RoundedRectangle(cornerRadius: 4))
                    Text("Difficulty ↓ rows · Terrain → columns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .accessibilityHidden(true)
            }

            DTGrid(range: $range, isTouching: isTouching, showsHeaders: showsHeaders)
        }
    }
}

#Preview("Values in cells") {
    @Previewable @State var range = DTRange(difficulty: 2...3.5, terrain: 1...2.5)
    DTPickerPanel(range: $range).padding(4)
}

#Preview("Headers") {
    @Previewable @State var range = DTRange(difficulty: 2...3.5, terrain: 1...2.5)
    DTPickerPanel(range: $range, showsHeaders: true).padding(4)
}
