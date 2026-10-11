# D/T Grid Picker – Design Decisions

A proposal to replace the two Difficulty / Terrain range sliders in the app's **Filter
Options** with a single 9×9 grid. This file records each decision, the reason for it, the
alternatives considered, and what is still open, so we can come back to it later.

Status legend: ✅ decided · 🧪 decided for the demo, needs validation · ❓ open

---

## 1. Problem ✅

- Today D and T are two separate range sliders (1.0–5.0, 0.5 steps).
- Thumbs are small and close together. Setting e.g. "D 2–3.5, T 1–2.5" means four precise
  drags, and a narrow range (both thumbs on the same value) is hard to grab again.
- The app already has a **D/T Statistics** grid (More → D/T Grid). Users know the
  layout from there: difficulty in rows, terrain in columns, 1–5 in 0.5 steps.

## 2. Core idea: one grid for both axes ✅

- **Decision:** pick D and T together on a 9×9 grid. The selection is always a rectangle
  `D[min…max] × T[min…max]`.
- **Why:** this is exactly the four values the current filter stores, so no backend or
  query change is needed. A rectangle is also what people mean ("easy-ish, low terrain").
- **Alternative rejected:** selecting arbitrary sets of cells (e.g. to fill gaps in a D/T
  matrix). That's more powerful, but the filter can't express it today, and it makes the
  gesture model much harder. It could be a later "fill my matrix" feature on the
  statistics screen.

## 3. Selection model 🧪

| Action | Result |
|---|---|
| Tap a cell | Selects that single D/T combination |
| Tap a second cell while exactly one cell is selected | Extends to the rectangle between the two ("tap start, tap end") |
| Tap a cell while a larger range is selected | Starts over with that single cell |
| Touch down and drag | Rectangle from the touch-down cell (anchor) to the cell under the finger, updated live |
| "Any" button | Resets to 1–5 × 1–5 (no restriction) |

- **Why:** the drag is the fast path. Tap-then-tap gives the same result for people who
  don't drag, or who need to scroll in between.
- **Why tap on a range starts over:** otherwise there would be no way back to a single
  cell without pressing "Any" first.
- ✅ **"Any" is drawn exactly like a full selection** (all cells green). It's the same filter,
  so it should look the same. *(Changed after review: the first version tinted "any" lightly
  so it looked different.)*
- **Whole row / column** (e.g. "D 2, any T"):
  - Without headers: drag across the full row or column.
  - With headers (§4b): tap or drag the header. Tapping the corner selects everything. Header
    taps always select just that row or column and never extend; only cell taps extend.
    Dragging from a cell onto a header widens the selection to the full row or column.

## 4. Cell content and grid look 🧪

The demo has **two sections** that compare the two designs side by side, each with all three
presentation variants (§6):

### 4a. D/T value in every cell, no headers

- Every cell shows its own value as `D /` above `T` (e.g. `2.5 /` over `3.0`). There are no
  row or column headers.
- **Why:** headers take a tenth of the width and height for 9 labels. Without them the cells
  can be ~10 % larger, which matters on the 13 mini (§5). The grid can be read without axes,
  and the readout above it always states the selection in words.
- A small legend ("D over T · Difficulty ↓ rows · Terrain → columns") shows the orientation.
- **Two lines rather than "2.5/3.0" on one line:** "4.5/4.5" doesn't fit a 40 pt cell at a
  readable size. Stacked, the font can be ~12 pt.
- ✅ **Values always use one decimal place** (`1.0`, `2.5`), because that's how D/T ratings are
  usually written. *(Changed after review: the first version used "1", "1.5".)*

### 4b. Row and column headers, blank cells

- A 28 pt header row (terrain) and a 28 pt header column (difficulty) with the values. The
  corner shows `D╲T`. Header width equals header height, so the control stays square.
- Cells are left blank. The headers carry the values, and blank cells leave room for find
  counts later.
- Headers are hit targets too (see §3), which is the main advantage over 4a.
- The headers of selected rows and columns are bold and green, so the range can be read off
  the axes.
- Cost: cells shrink from ~40 pt to ~37 pt on the 13 mini (see test notes).

### Grid look (both variants) ✅

- **Unselected cells use a light green tint**, the same family as the bordered "Any" button.
  It's opaque (green mixed into white, or into near-black in dark mode), so the translucent
  iOS 26 sheet doesn't show through. *(Changed after review: in the headers sheet, the
  earlier grey/white was hard to tell apart from the light-grey sheet background.)* The first
  light tint (16 %) was still too faint and the cells blended together, so it's now 30 %,
  which makes individual cells visible. Dark mode uses 28 %.

- **1 pt gaps** between cells. *(Changed after review: 2 pt with rounded cells used too much
  space.)*
- **Square inner cells.** Only the outer corner of each of the four corner cells is rounded,
  so the whole block reads as one rounded rectangle (`UnevenRoundedRectangle`). Rounding
  every cell wasted visual space.
- **Alternative kept for later:** find counts (as on the statistics screen). These are useful
  for the "which combos am I missing" use case, but they are user-specific, need data, and
  make the cells busier. Options: a small secondary count label, or a heat tint behind the
  D/T value.

## 5. Touch targets on the iPhone 13 mini ✅ (numbers) / 🧪 (feel)

- Screen width 375 pt. Grid at full width with small insets → **cell pitch ≈ 40 pt**
  (push screen ≈ 39.9 pt, popover and sheet slightly less, see test notes). That's below
  Apple's 44 pt guideline, which can't be reached with 9 columns on 375 pt (9 × 44 = 396).
- Ways the control makes up for it:
  - **Position-based hit-testing:** the cell is calculated from the finger location, so the
    1 pt gaps aren't dead zones. The effective target is the full 40 pt pitch.
  - **Loupe:** while touching, a callout above the finger shows "D 2.5 T 3" (plus the range
    while dragging). This deals with the finger hiding the cell. In the top two rows it
    moves beside the finger so it isn't clipped.
  - **Haptics:** a selection tick on every cell change, so steps can be counted by feel.
  - **Corrections are cheap:** the selection updates live and you can keep dragging until
    you lift, so a slightly-off touch-down is fixed by moving the finger.
- **Why not a scrolling or zoomed grid:** it would lose the "see the whole matrix at once"
  advantage, and 40 pt is close enough to the guideline when the measures above are in place.

## 6. Presentation variants 🧪 (the main open design question)

The demo shows all three under each other in the filter screen, once for each grid design
(§4a and §4b). Each row keeps its own selection:

1. **Push navigation ›**: a row with the summary, which pushes a full screen.
   *Pro:* most room, consistent with other filter rows (Container Size, Cache Type…).
   *Con:* heavy for a quick change, and needs a back tap.
2. **Popover ⌃⌄**: a card over the dimmed screen, attached to the row. Tapping the dimmed
   area dismisses it.
   *Pro:* lightweight and stays in context.
   *Con:* the panel is ~465 pt tall, and on a 812 pt screen it rarely fits fully above or below a
   row in the middle of the list. In practice it covers the row.
   - **The system `.popover` was rejected.** On iPhone (with
     `.presentationCompactAdaptation(.popover)`) it only gets the space on one side of the
     row. The grid shrank to ~14 pt cells with unreadable labels, which can't be used.
   - **Replaced by a custom overlay (`DTOverlay`).** It goes below the row if it fits, otherwise
     above, otherwise centred on the row and kept on screen. Cells are ~39 pt.
3. **Bottom sheet**: a sheet sized to its content, like the date/time pickers, with Done.
   *Pro:* familiar, thumb-reachable, and the grid gets nearly full width.
   *Con:* one more modal layer on top of the Filter Options sheet.

- **Gesture conflict (sheet):** a vertical drag in the grid would normally drag the sheet
  down. The grid's gesture has high priority, and interactive dismiss is disabled while a
  finger is down. The grabber and the area outside the grid still dismiss the sheet.
- **Gesture conflict (push):** iOS 26+ allows swipe-back from anywhere in the content. See
  the test notes for whether a horizontal drag in the grid triggers it.
- ❓ **Truly spring-loaded popover** (press the row, drag straight into the grid as it
  appears, release to commit and close it) was not built. A gesture can't carry over into a
  newly presented popover, so this needs a custom in-place overlay. It's worth trying if the
  popover variant is the favourite.

## 7. Accessibility 🧪

- For VoiceOver the grid is replaced by four adjustable steppers (min/max difficulty,
  min/max terrain), each with the value as its accessibility value.
- Cell labels scale with the cell size, not with Dynamic Type, because the grid can't grow.
  The readout above the grid does follow Dynamic Type.
- ❓ Whether 4 steppers are the right VoiceOver model, or one "Difficulty 2 to 3.5" element
  with custom actions would be better.

## 8. Not covered by the demo ❓

- Landscape and iPad layout (the demo is portrait iPhone only).
- Dark mode was checked only roughly. Colors are system colors plus an approximate app green.
- How the D/T row appears in the real Filter Options list (title "Difficulty / Terrain",
  subtitle with the summary, e.g. "D 2–3.5 · T any").

## Implementation notes

- SwiftUI, iOS 26+. UIKit vs SwiftUI didn't matter for the prototype. SwiftUI has native
  sheet detents, popovers and haptics with the least code.
- `DTRange` (model) and `DTGrid` (control) are independent of the presentation, so they can be
  moved into the app as is.
- Files: `DTRange.swift`, `DTGrid.swift` (grid + `DTPickerPanel`), `PresentationVariants.swift`,
  `FilterOptionsView.swift`, `Theme.swift`.

## Test notes

### Simulator, iPhone 13 mini (375×812 pt), iOS 27, 2026-10-11

| Check | Result |
|---|---|
| Push screen grid | 359 pt wide, **pitch 39.9 pt**, labels readable |
| Popover (custom overlay) grid | 351 pt wide, **pitch 39.0 pt** |
| Bottom sheet grid | ~347 pt wide, **pitch 38.5 pt** (iOS 26+ sheets are inset ~8 pt) |
| Tap → single, tap → extend, drag → rectangle, Any → reset | ✅ in all three variants |
| Vertical drag inside the grid in the sheet | ✅ selects, does **not** dismiss the sheet |
| Horizontal drag from the leftmost column on the push screen | ✅ selects, does **not** trigger swipe-back (also tested starting 4 pt from the edge) |
| Loupe in middle rows | ✅ above the finger, both lines readable (subtitle made larger and opaque after the first run) |
| Loupe in top rows | ✅ beside the finger, not clipped |
| System `.popover` | ❌ grid shrank to 14 pt cells, replaced (see §6) |

### Simulator, second round (after review), 2026-10-11

| Check | Result |
|---|---|
| Values in cells: 1 pt gaps, square cells, rounded outer corners, "any" all green | ✅ pitch 39.9 pt (push) |
| Headers: push / popover / sheet | ✅ pitch **36.8 / 35.9 / 35.5 pt** |
| Header tap → row/column, header drag → several rows, corner → any | ✅ |
| Cell tap → tap extend with headers | ✅ only the matching headers are highlighted |
| Grey cells in the translucent sheet let the list behind show through | ❌ → fixed: cell fill is now opaque (later changed to an opaque light green, see §4) |
| Terrain line on green cells too faint | ❌ → fixed: higher opacity on selected cells |

Seen but not yet addressed:
- In the sheet and the popover, VoiceOver's stepper frames stack at the top of the grid
  instead of covering it. Only the focus rectangles are affected.
- The row summary reads "D any · T 2.5" for partial selections but "Any difficulty and terrain"
  when nothing is restricted. This is on purpose, but worth a second look.

- While a finger is down in the sheet, the sheet shifts or scales by ~2 pt (the system's
  touch-down effect on the sheet). Barely noticeable.
- The loupe covers ~4 neighbouring cells while dragging. These are cells you have already
  passed, so this is acceptable.

### Device

_To do: try it on a real iPhone 13 mini. The simulator can't tell us how 40 pt cells feel
under a real finger, or whether the haptics help._
