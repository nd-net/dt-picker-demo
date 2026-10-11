import SwiftUI

/// Title + current selection, styled like the app's "Container Size / All Sizes" rows.
private struct VariantLabel: View {
    let title: String
    let range: DTRange

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(range.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: 1 – Push navigation

struct PushVariantRow: View {
    @Binding var range: DTRange
    let showsHeaders: Bool

    var body: some View {
        NavigationLink {
            DTGridScreen(range: $range, showsHeaders: showsHeaders)
        } label: {
            VariantLabel(title: "Push navigation", range: range)
        }
    }
}

struct DTGridScreen: View {
    @Binding var range: DTRange
    let showsHeaders: Bool

    var body: some View {
        VStack {
            DTPickerPanel(range: $range, showsHeaders: showsHeaders)
                .padding(.horizontal, 8)
                .padding(.top, 12)
            Spacer()
        }
        .navigationTitle("Difficulty & Terrain")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: 2 – Popover

/// Row that opens `DTOverlay`. A system `.popover` was tried first, but on iPhone it is
/// confined to the space above or below the row and shrank the grid to ~14 pt cells.
struct PopoverVariantRow: View {
    let range: DTRange
    /// Called with the row's global frame; the overlay is attached to it.
    let open: (CGRect) -> Void
    @State private var frame: CGRect = .zero

    var body: some View {
        Button {
            open(frame)
        } label: {
            HStack {
                VariantLabel(title: "Popover", range: range)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }
}

/// Popover-style card attached to a row: below it if it fits, else above, else as close as
/// possible (overlapping the row). Tapping the dimmed background dismisses it.
struct DTOverlay: View {
    @Binding var range: DTRange
    let anchor: CGRect
    let showsHeaders: Bool
    let dismiss: () -> Void
    @State private var cardHeight: CGFloat = 0

    private let margin: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let bounds = geo.frame(in: .global)
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: dismiss)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Close")

                DTPickerPanel(range: $range, showsHeaders: showsHeaders)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: bounds.width - 2 * margin)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardHeight = $0 }
                    .offset(x: margin, y: cardTop(in: bounds) - bounds.minY)
                    .opacity(cardHeight > 0 ? 1 : 0)
            }
        }
    }

    private func cardTop(in bounds: CGRect) -> CGFloat {
        let below = anchor.maxY + 4
        let above = anchor.minY - 4 - cardHeight
        if below + cardHeight <= bounds.maxY - margin { return below }
        if above >= bounds.minY + margin { return above }
        let centered = anchor.midY - cardHeight / 2
        return min(max(centered, bounds.minY + margin), bounds.maxY - margin - cardHeight)
    }
}

// MARK: 3 – Bottom sheet

struct SheetVariantRow: View {
    @Binding var range: DTRange
    let showsHeaders: Bool
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                VariantLabel(title: "Bottom sheet", range: range)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            DTSheet(range: $range, showsHeaders: showsHeaders)
        }
    }
}

private struct DTSheet: View {
    @Binding var range: DTRange
    let showsHeaders: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isTouching = false
    @State private var contentHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Difficulty & Terrain").font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 6)
            DTPickerPanel(range: $range, isTouching: $isTouching, showsHeaders: showsHeaders)
        }
        .padding(.horizontal, 6)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        // A vertical drag inside the grid must select, not dismiss the sheet.
        .interactiveDismissDisabled(isTouching)
    }
}
