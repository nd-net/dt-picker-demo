import Foundation

/// One D/T combination on the 9×9 grid. Rows are difficulty, columns are terrain.
struct DTCell: Hashable, Identifiable {
    let row: Int
    let col: Int

    var id: Int { row * DTRange.count + col }
    var difficulty: Double { DTRange.steps[row] }
    var terrain: Double { DTRange.steps[col] }

    init(row: Int, col: Int) {
        self.row = min(max(row, 0), DTRange.count - 1)
        self.col = min(max(col, 0), DTRange.count - 1)
    }

    init(difficulty: Double, terrain: Double) {
        self.init(row: DTRange.index(of: difficulty), col: DTRange.index(of: terrain))
    }

    static let all: [DTCell] = (0..<DTRange.count).flatMap { row in
        (0..<DTRange.count).map { col in DTCell(row: row, col: col) }
    }
}

/// A rectangular D/T selection – exactly the four values the existing filter stores.
struct DTRange: Equatable {
    var difficulty: ClosedRange<Double>
    var terrain: ClosedRange<Double>

    static let steps: [Double] = Array(stride(from: 1.0, through: 5.0, by: 0.5))
    static let count = steps.count
    static let full: ClosedRange<Double> = 1...5
    static let all = DTRange(difficulty: full, terrain: full)

    static func index(of value: Double) -> Int {
        Int(((value - 1) * 2).rounded())
    }

    init(difficulty: ClosedRange<Double>, terrain: ClosedRange<Double>) {
        self.difficulty = difficulty
        self.terrain = terrain
    }

    /// The rectangle spanned by two corner cells, in any order.
    init(from a: DTCell, to b: DTCell) {
        difficulty = min(a.difficulty, b.difficulty)...max(a.difficulty, b.difficulty)
        terrain = min(a.terrain, b.terrain)...max(a.terrain, b.terrain)
    }

    init(single cell: DTCell) {
        self.init(from: cell, to: cell)
    }

    var isAll: Bool { self == .all }

    /// The cell if exactly one combination is selected.
    var singleCell: DTCell? {
        guard difficulty.lowerBound == difficulty.upperBound,
              terrain.lowerBound == terrain.upperBound else { return nil }
        return DTCell(difficulty: difficulty.lowerBound, terrain: terrain.lowerBound)
    }

    func contains(_ cell: DTCell) -> Bool {
        difficulty.contains(cell.difficulty) && terrain.contains(cell.terrain)
    }

    var difficultyText: String { Self.text(for: difficulty) }
    var terrainText: String { Self.text(for: terrain) }

    /// Compact one-line summary for list rows, e.g. "D 2–3.5 · T any".
    var summary: String {
        isAll ? "Any difficulty and terrain" : "D \(difficultyText) · T \(terrainText)"
    }

    private static func text(for range: ClosedRange<Double>) -> String {
        if range == full { return "any" }
        if range.lowerBound == range.upperBound { return range.lowerBound.dtLabel }
        return "\(range.lowerBound.dtLabel)–\(range.upperBound.dtLabel)"
    }
}

extension Double {
    var dtLabel: String {
        String(format: "%.1f", self)
    }
}
