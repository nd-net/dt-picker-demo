import SwiftUI

/// Mock of the app's Filter Options screen with the three D/T presentation variants.
struct FilterOptionsView: View {
    @State private var valueRanges = VariantRanges()
    @State private var headerRanges = VariantRanges()
    /// The popover row whose overlay is shown, if any.
    @State private var overlay: OverlayRequest?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PlaceholderRow(title: "Container Size", detail: "All Sizes")
                    PlaceholderRow(title: "Cache Type", detail: "Traditional, Multi-Cache, Mystery …")
                    PlaceholderRow(title: "Attributes", detail: "Any Attributes")
                }

                variantSection(
                    "Difficulty / Terrain – values in cells",
                    footer: "Three ways to present the same D/T grid. Each row keeps its own selection.",
                    ranges: $valueRanges, showsHeaders: false
                )
                variantSection(
                    "Difficulty / Terrain – row & column headers",
                    footer: "Tap a header to select a whole row or column, the corner for any.",
                    ranges: $headerRanges, showsHeaders: true
                )

                Section("Search Radius") {
                    HStack {
                        Slider(value: .constant(0.8))
                        Text("161 km").monospacedDigit()
                    }
                    .disabled(true)
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        valueRanges = VariantRanges()
                        headerRanges = VariantRanges()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {}
                }
            }
            .toolbarBackground(Theme.green, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .overlay {
            if let overlay {
                DTOverlay(
                    range: overlay.showsHeaders ? $headerRanges.popover : $valueRanges.popover,
                    anchor: overlay.anchor,
                    showsHeaders: overlay.showsHeaders
                ) {
                    withAnimation(.snappy(duration: 0.2)) { self.overlay = nil }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .tint(Theme.green)
    }

    private func variantSection(_ title: String, footer: String, ranges: Binding<VariantRanges>, showsHeaders: Bool) -> some View {
        Section {
            PushVariantRow(range: ranges.push, showsHeaders: showsHeaders)
            PopoverVariantRow(range: ranges.wrappedValue.popover) { frame in
                withAnimation(.snappy(duration: 0.25)) {
                    overlay = OverlayRequest(anchor: frame, showsHeaders: showsHeaders)
                }
            }
            SheetVariantRow(range: ranges.sheet, showsHeaders: showsHeaders)
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }
    }
}

/// Independent selection per presentation variant, so they can be compared side by side.
private struct VariantRanges {
    var push = DTRange.all
    var popover = DTRange.all
    var sheet = DTRange.all
}

private struct OverlayRequest {
    let anchor: CGRect
    let showsHeaders: Bool
}

/// Greyed-out stand-in for filter rows that aren't part of the proposal.
private struct PlaceholderRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.footnote).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote)
        }
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    FilterOptionsView()
}
