# Element Builder Patterns

## mkRow / mkBase
Every element calls `mkRow(height)` to get a `Frame`, then `mkBase(id, initial, row)` to get the element handle. mkBase registers to `Library.Options[id]` and wires `:Get`, `:Set`, `:Changed`, `:SetDisabled`, `:SetVisible`.

## rowHover
Call `rowHover(row, el)` for non-primary elements. Uses color-only tweens — no BackgroundTransparency changes (rows are opaque, BT=0 base, BT=0.6 when disabled).

## Primary button
Set `row.BackgroundColor3 = T.SliderFill`, `row.BackgroundTransparency = 0.1`. Uses `T.SliderFill` (red accent) throughout — not TabActiveBg (which is dark blue).

## ColorPicker
Panel ZIndex=50, close-shield ZIndex=49 parented to `pagesHolder`. Three mini R/G/B sliders use `hexRef` table pattern so they can update the shared hex label after creation.

## Keybind
Two modes: `Listening` (waiting for keypress) and `Bound` (shows key name in pill). Pill uses `KeybindPillW × KeybindPillH` from L.

## Dropdown
Opens a floating option list below the row. Multi-select supported via `Multi = true`. Options clipped by `ClipsDescendants` on the list container.

## Section label
Passed as first arg to `Tab:Section(label)`. If non-empty: renders a 26px `SectionBevel`-colored header strip with the label text. `inner` positioned at Y=26 offset. No label → `inner` at Y=0, section box still visible.
