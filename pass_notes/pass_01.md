# Ignis — Pass 1 Notes
**Date:** 2026-10-12  
**Pass:** 1 of 5  
**File written:** Ignis.lua (complete rewrite from v2.0.0 → v2.1.0)

---

## What was done

### AnimationManager (new)
- Added `local Anim` table with 13 named categories: Toggle, ToggleTrack, Slider, Button, ButtonOut, Tab, Row, Window, Notif, NotifOut, Keybind, Dropdown, Default.
- Added `_DEF_DUR` and `_DEF_STYLE` tables — base durations and easing per category.
- Added `_ANIM_PRESETS` table with four built-in presets: Default, Snappy, Smooth, Bounce, None.
- Added `_rebuildAnim(preset, speed, scope)` function that builds all TweenInfo entries from base + overrides + speed multiplier. Row/Dropdown durations are safety-capped at 0.12s even when Smooth is active.
- Modified `tw()` to skip TweenService and do direct property assignment when `_animEnabled = false`.
- Removed all direct references to old `TI_FAST`, `TI_MED`, `TI_SPRING`, `TI_LINEAR` constants from element call sites — replaced with `Anim.Toggle`, `Anim.Tab`, `Anim.Row`, `Anim.Button`, etc.
- `AnimationManager` object exposed via `Library:GetAnimationManager()` and `Window:GetAnimManager()`.
- API: `:SetEnabled(bool)`, `:SetSpeed(num)`, `:SetScope(str|table)`, `:SetPreset(name)`, `:AddPreset(name,cats)`, `:RemovePreset(name)`, `:GetPresetNames()`, `:SetCategory(cat, TweenInfo)`, `:GetCategory(cat)`.

### ThemeManager (new)
- Extracted theme logic from Library into a `ThemeManager` object.
- Centralised theme application through `_applyTheme(name)` — fires all `_themeSubs` subscribers on change.
- `ThemeManager` object exposed via `Library:GetThemeManager()` and `Window:GetThemeManager()`.
- API: `:SetTheme(name)`, `:GetTheme()`, `:GetThemes()`, `:AddTheme(name, overrides)`, `:RemoveTheme(name)`, `:GetToken(token)`, `:SetToken(token, color3)`, `:Reset()`, `:OnChanged(fn) → unsub`.
- Library:SetTheme / Library:GetTheme / Library:GetThemeNames kept as pass-through for compatibility.

### SaveManager (new)
- Window-scoped manager, retrieved via `Window:GetSaveManager()`.
- API: `:SetFolder(str)`, `:SetKey(str)`, `:GetData()`, `:SetData(table)`, `:Save(key?)`, `:Load(key?)`, `:Delete(key?)`, `:AutoSave(interval)`, `:StopAutoSave()`, `:OnSave(fn)`, `:OnLoad(fn)`.
- AutoSave uses `task.spawn` + `task.wait` loop with a closure-based stop flag (not RunService.Heartbeat, which was a bug in the first draft — corrected before writing).
- Old Window:SaveSettings / LoadSettings / SaveToFile / LoadFromFile kept as thin wrappers over SaveManager for compatibility.

### Other fixes in this pass
- Notification system: `task.delay` for slide-out uses `(Anim.NotifOut :: TweenInfo).Time + 0.05` instead of a hardcoded `0.26` — now respects the AnimationManager's NotifOut duration.
- Progress bar in notifications: when `_animEnabled = false`, the tween is skipped and the bar collapses via a `task.delay` instead.
- Input TextBox and Paragraph TextLabel now have `Creator.Reg` entries so they repaint on theme change (was missing before — these text elements were not responding to SetTheme).
- Version bumped to 2.1.0.

---

## What was NOT done (deferred to later passes)

- Fonts (FONT_TITLE, FONT_TAB, FONT_UI, FONT_BOLD) are still hardcoded constants. A LayoutManager or FontManager pass is needed.
- Row heights (44, 56, 68, 72, 36) are still hardcoded per-element. They derive from whether a Description is present — this is structural, not arbitrary, but could be exposed.
- Stroke widths (2.8, 1.8, 1.5, 1.4, 1.2, 1.0) are still hardcoded. Not exposed.
- Bevel strip sizes (4px) are hardcoded.
- Header height (52px) is hardcoded.
- Sidebar width (140px) is partially exposed via `SIDE_W` local but not a public config.
- Slider knob size (13px), toggle dimensions (TW=46, TH=22, KS=16), slider track height (6px) are hardcoded.
- Scroll bar thickness (4px) is hardcoded.
- Notif card height (68px), notif holder width (290px) are hardcoded.
- No validation that AnimationManager preset names passed to SetPreset are strings.
- AutoSave stop mechanism is a function closure — works but is not the most robust pattern.
- SaveManager:Save's legacy Window:SaveToFile wrapper ignores the `folder` argument and always uses SaveManager._folder. This is a known compatibility break — the old API's folder parameter is silently dropped.
- No test/example update yet.

---

## Known issues introduced

- `Window:SaveToFile(folder, name)` legacy wrapper silently ignores the `folder` argument. The old signature was `(folder, name)` but SaveManager uses its own `_folder`. Callers relying on the folder arg of the old API will get unexpected behavior. This should be documented or fixed in Pass 2.
- `AutoSave` uses `task.spawn` but the stop closure does not cancel a `task.wait` mid-sleep. There is a maximum one-interval lag before the loop exits after `StopAutoSave()` is called. This is acceptable but should be noted.
