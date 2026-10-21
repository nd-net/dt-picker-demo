# D/T Grid Picker Demo

A SwiftUI prototype for picking a geocache **Difficulty / Terrain** range on a single 9×9
grid, instead of two separate range sliders in a filter screen.

Difficulty runs down the rows and terrain across the columns, both from 1 to 5 in 0.5
steps. The selection is always a rectangle `D[min…max] × T[min…max]`, so it maps directly
onto the four values a classic D/T filter stores.

## What the demo shows

- **Selection gestures:** tap a cell to select it, tap a second cell to extend to the
  rectangle between them, or touch down and drag to draw the rectangle live. **Any**
  resets to the full 1–5 × 1–5 range.
- **Two grid designs:** the D/T value written in every cell, or row and column headers with
  blank cells.
- **Three ways to present the grid** from a filter row, each with both grid designs:
  - push navigation to a full screen,
  - a popover-style overlay attached to the row,
  - a bottom sheet sized to its content.

All variants sit under each other in a mock *Filter Options* screen, so they can be
compared side by side. Each row keeps its own selection.

The reasoning behind each choice, the rejected alternatives, open questions and test notes
are in [DESIGN-DECISIONS.md](DESIGN-DECISIONS.md).

## Requirements

- Xcode with the iOS 26 SDK or later
- iOS 26 or later (simulator or device); laid out with the iPhone 13 mini as the smallest
  target

## Running

Open `DTPickerDemo.xcodeproj` in Xcode, pick an iPhone simulator and run the
`DTPickerDemo` scheme.

## Code layout

| File | Contents |
|---|---|
| `DTRange.swift` | The selection model, independent of any UI |
| `DTGrid.swift` | The grid control and `DTPickerPanel` (grid + Any button) |
| `PresentationVariants.swift` | Push, overlay and sheet presentations |
| `FilterOptionsView.swift` | The mock filter screen hosting all variants |
| `Theme.swift` | Colours |

`DTRange` and `DTGrid` don't depend on how the grid is presented, so they can be lifted
into another app as is.

## License

[MIT No Attribution](LICENSE) (MIT-0): do whatever you like with the code, no credit or
copyright notice required.
