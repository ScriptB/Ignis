# Ignis — Pass 2 Notes
**Date:** 2026-10-13  
**Pass:** 2 of 5  
**File written:** Ignis.lua (v2.1.0 → v2.2.0), Example.lua (updated), pass_notes/pass_02.md (this file)

---

## What was done

### LayoutManager (new)
- Added a module-level `L` table containing every structural constant previously hardcoded across
  the library. All elements and window construction code now read from `L.*` at construction time.
- Tokens added to `L`:
  - Window: `WindowW`, `WindowH`, `HeaderH`, `SidebarW`, `TitleSize`, `SubtitleSize`
  - Sidebar/tabs: `TabH`, `TabTextSize`, `TabAccentW`
  - Section: `SectionHeaderH`, `SectionHeaderTextSize`, `BevelSize`
  - Row heights: `RowH`, `RowHDesc`, `RowHLabel`
  - Slider: `SliderRowH`, `SliderRowHDesc`, `SliderTrackH`, `SliderKnobS`, `SliderTrackY`, `SliderTrackYD`
  - Input: `InputRowH`, `InputRowHDesc`, `InputBoxH`
  - Toggle: `ToggleW`, `ToggleH`, `ToggleKnobS`
  - Stroke widths: `StrokeRoot`, `StrokeHdr`, `StrokeClose`, `StrokeSidebar`, `StrokeTabBtn`,
    `StrokeSection`, `StrokeRow`, `StrokeToggle`, `StrokePanel`, `StrokeInput`, `StrokeNotif`
  - Fonts (Enum.Font values): `FontTitle`, `FontTab`, `FontUI`, `FontBold`
  - Element text sizes: `ElemNameSize`, `ElemDescSize`, `ElemValueSize`
  - Notification: `NotifW`, `NotifH`, `NotifGap`, `NotifEdge`
  - Misc: `ScrollBarThick`, `TitleStrokeW`
- `LayoutManager` object exposed via `Library:GetLayoutManager()` and `Window:GetLayoutManager()`.
- API: `:Set(key, value)`, `:Get(key)`, `:Apply({[key]: value})`, `:Reset()`
- `:Set()` asserts the key exists to catch typos at the call site rather than silently doing nothing.
- `:Reset()` restores all tokens to their library defaults (mirrors the L initialisation block).
- Font resolution: `FONT_TITLE`, `FONT_TAB`, `FONT_UI`, `FONT_BOLD` locals are built from `L.Font*`
  values via `Font.fromEnum()` at load time. `Library._refreshFonts()` is exposed so callers can
  re-resolve fonts after a `LayoutManager:Set("FontUI", ...)` call before building the window.
- Example updated to show LayoutManager usage.

### SaveToFile folder-argument fix (deferred from Pass 1)
- `Window:SaveToFile(folder, name)` previously silently dropped the `folder` argument, using
  SaveManager's own `_folder` regardless. The wrapper now documents this explicitly with a comment
  and forwards `name` as the save key (matching v2.1.0 behaviour), rather than pretending to use
  `folder`. The correct migration path is `Window:GetSaveManager():SetFolder(folder)` before
  calling `:Save(name)`. This is documented in both the wrapper comment and Example.lua.
- `Window:LoadFromFile` receives the same treatment — `folder` arg is documented as ignored.

### Version bump
- Version string updated to `"2.2.0"`.

---

## What was NOT done (deferred to later passes)

- LayoutManager changes made after `CreateWindow` is called do NOT retroactively update existing
  UI — layout values are read once per element at construction time. This is documented in the L
  table comment. A live-update mechanism (reparse on change) is out of scope for this pass.
- `CreateWindow` cfg.Width / cfg.Height override `L.WindowW` / `L.WindowH` at call time, but do
  not write back into `L`. This is correct behaviour but slightly inconsistent — a call to
  `LayoutManager:Get("WindowW")` after `CreateWindow` will return the L value, not the cfg override.
  This is a minor documentation gap, not a runtime bug.
- No element-level refresh API — elements cannot re-read L values after construction.
- Toggle, Slider, Dropdown knob/track sizes are now in L but elements still capture them as locals
  at row-build time; if L is changed after Window is built it has no effect on existing rows.
  This is expected but not yet warned about.
- AutoSave one-interval lag (from Pass 1) still present — not addressed in this pass.
- No test/coverage update.

---

## Known issues (carry-forward from Pass 1, plus new)

- AutoSave: up to one `interval` lag before loop exits after `StopAutoSave()`.
- LayoutManager changes after `CreateWindow` silently have no effect on the built UI. There is no
  warning or error when this happens.
- `Window:SaveToFile(folder, name)` ignores the `folder` argument. Documented with a comment but
  not enforced (no warning emitted). Callers using the old API with a non-default folder will
  silently get wrong save paths.
