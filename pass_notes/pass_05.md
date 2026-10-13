# Ignis — Pass 5 Notes
**Date:** 2026-10-13  
**Pass:** 5 of 5  
**Files written:** Ignis.lua (v2.4.0 → v2.5.0), Example.lua (version string updated), pass_notes/pass_05.md (this file)

---

## What was done

### Bug fix: Keybind EnumItem not JSON-serializable (critical)

**Root cause:** `SaveManager:GetData()` called `el:Get()` on a Keybind element, which returns `Enum.KeyCode.E` (an `EnumItem`). `HttpService:JSONEncode` cannot serialize an `EnumItem` — it either errors or produces `{}`. On load, `el:Set({})` was passed to Keybind's `_apply`, which only handled `typeof(v) == "EnumItem"`, so the table was silently ignored. Net effect: any config containing a keybind element would fail to save or load keybind state. This is a silent failure — no error, no warning, just wrong data.

**Fix in `GetData()`:** added an `EnumItem` branch before writing the value to `out`:
```lua
if typeof(v) == "EnumItem" then
    out[id] = (v :: EnumItem).Name
else
    out[id] = v
end
```

**Fix in Keybind `_apply`:** added a string branch alongside the existing `EnumItem` branch:
```lua
function el:_apply(v: any)
    if typeof(v) == "EnumItem" then
        applyKey(v :: Enum.KeyCode)
    elseif type(v) == "string" then
        local ok2, kc = pcall(function() return (Enum.KeyCode :: any)[v] end)
        if ok2 and typeof(kc) == "EnumItem" then applyKey(kc :: Enum.KeyCode) end
    end
end
```

This means: save writes `"E"`, load reads `"E"`, `_apply` resolves `Enum.KeyCode["E"]` → `Enum.KeyCode.E`, calls `applyKey`. Round-trip is correct. An invalid string (typo, removed KeyCode) is silently ignored — no crash, just no keybind restoration, which is the correct degraded behaviour.

---

### Bug fix: `_windowBuilt` not reset on `Window:Destroy()`

**Root cause:** `_windowBuilt` was set to `true` inside `CreateWindow` and never set back. If `Window:Destroy()` was called and `CreateWindow` was called again, LayoutManager's `Set()` and `Apply()` would immediately warn about "post-build" changes even for a fresh window that hadn't been built yet. The window's close button handler also had an inline destroy that didn't reset the flag.

**Fix in `Window:Destroy()`:** added `_windowBuilt = false` as the final statement.

**Fix for close button:** changed the click handler from inline `maid:Destroy(); gui:Destroy(); Library.Window = nil; Library.Options = {}` to a single `Window:Destroy()` call. This ensures the `_windowBuilt` reset always happens regardless of how the window is closed.

---

### Remaining literal values — all tokenised (Pass 4 list fully cleared)

Pass 4 notes listed 15 categories of remaining literal pixel values. All have been converted to L tokens in this pass. New tokens added to L:

| Token | Default | Was | Where |
|-------|---------|-----|-------|
| `HeaderBtnRightPad` | 10 | `-10` literal | close button right margin from window edge |
| `HeaderBtnGap` | 6 | `6` literal | gap between close and minimize buttons; title right reserve |
| `HeaderTitlePadL` | 16 | `16` literal | title text left margin in header |
| `SubtitlePadL` | 18 | `18` literal | subtitle text left margin in header |
| `SubtitleBottomPad` | 8 | `8` literal | subtitle Y offset from header bottom |
| `ElemRightPad` | 10 | `-10` literal (6 call sites) | shared right margin for right-anchored element widgets: toggle track, slider value label, button chevron, input box width trim, keybind pill, label value |
| `ParagraphItemGap` | 4 | `L.RowListPad + 3` | UIListLayout gap inside Paragraph frame |
| `SliderTrackRightPad` | 20 | `-20` literal | right trim of slider track width |
| `SliderValLabelH` | 16 | `16` literal | height of slider value readout label |
| `SliderValLabelY` | 2 | `2` literal | Y offset of slider value readout label |
| `DropdownLabelH` | 14 | `14` literal | height of dropdown current-value display label |
| `DropdownLabelRightPad` | 22 | `-22` literal | right margin of dropdown display label |
| `DropdownChevronRightPad` | 8 | `-8` literal | right margin of dropdown ∨ chevron |
| `DropdownChevronContainerS` | 12 | `12` literal | dropdown ∨ container square side |
| `BtnChevronW` | 16 | `16` literal | button › chevron container width |
| `BtnChevronH` | 20 | `20` literal | button › chevron container height |
| `NotifInnerPadR` | 2 | `+ 2` literal | right padding of notification inner frame |
| `NotifMsgGapY` | 2 | `+ 2` literal | vertical gap between title and message in notification |
| `NotifMsgBottomPad` | 4 | `- 4` literal | bottom padding of message label within notification |

ZIndex values (3, 4, 8, 9) were not tokenised. They are ordering constants, not layout tokens. They cannot be meaningfully configured independently.

---

### Example.lua version string updated

`pass_02.md` noted that Example.lua was written during Pass 2 with the subtitle `"v2.2 example"`. This was stale through Passes 3 and 4.

Changed in this pass:
- Comment block: `Ignis v2.2  ·  Example Script` → `Ignis v2.5  ·  Example Script`
- `SubTitle = "v2.2 example"` → `SubTitle = "v2.5 example"`

---

### Full manager API surface verification

Every method on every manager was checked against the implementation in v2.5.0. This pass verifies the API surface is complete and that each method does what it claims. No new bugs found beyond the two already fixed above.

**AnimationManager** (`Library:GetAnimationManager()` / `Window:GetAnimManager()`):
- `:SetEnabled(bool)` — sets `_animEnabled` and `self._enabled`. `tw()` reads `_animEnabled` directly. Correct.
- `:SetSpeed(num)` — asserts positive number, stores `self._speed`, calls `_rebuildAnim`. Correct. Assert message is present.
- `:SetScope(scope)` — stores `self._scope`, calls `_rebuildAnim`. A non-`"everywhere"` string is accepted without error but the `inScope` logic only sets a category in-scope if the string matches the `scope == "everywhere"` branch OR if `scope` is a table with the category as a key. A raw string like `"Toggle"` does not match `scope == "everywhere"` and is not a table, so only `"Default"` is in scope. This is a documentation gap, not a crash. The method signature implies table or `"everywhere"` as the meaningful inputs.
- `:SetPreset(name)` — handles `"None"` as a special case (disables, no rebuild). Handles unknown name with a warn. Known presets call `_rebuildAnim`. Correct.
- `:AddPreset(name, cats)` — inserts into `_ANIM_PRESETS`. String assertion present. Correct.
- `:RemovePreset(name)` — locks built-in presets with a warn. Removes others. Active preset is NOT reset — `_rebuildAnim` on next rebuild will use `{}` for an unknown preset (graceful degradation). Documented in pass_03.md. Still acceptable.
- `:GetPresetNames()` — returns sorted list. Correct.
- `:SetCategory(cat, TweenInfo)` — direct write to `Anim[cat]`. Correct. No validation that `cat` is a known category; an unknown cat is silently accepted and has no effect unless something reads `Anim[cat]`. This is fine.
- `:GetCategory(cat)` — returns `Anim[cat]`, which is `nil` for an unknown category. Correct.

**ThemeManager** (`Library:GetThemeManager()` / `Window:GetThemeManager()`):
- `:SetTheme(name)` — calls `_applyTheme`, warns on unknown. `_applyTheme` rebuilds `T`, calls `Creator.UpdateTheme()`, fires `_themeSubs`. Correct.
- `:GetTheme()` — returns `Library._theme`. Correct.
- `:GetThemes()` — returns sorted list from `THEME_PRESETS`. Correct.
- `:AddTheme(name, overrides)` — inserts into `THEME_PRESETS`. String assertion present. Correct.
- `:RemoveTheme(name)` — locks three built-ins with a warn. Removes others. Does NOT check if the removed theme is active — caller could remove the currently active theme. If `:SetTheme("removed")` is then called, it fails with a warn. If the theme was already applied, `T` already has the correct values; the theme just can't be re-applied. This is an acceptable edge case, not a crash.
- `:GetToken(token)` — returns `T[token]`. Correct.
- `:SetToken(token, color3)` — writes to `T` directly, calls `Creator.UpdateTheme()`. Correct. A subsequent `SetTheme` will wipe this manual override, which is documented and correct behaviour.
- `:Reset()` — calls `_applyTheme(Library._theme)`, which rebuilds `T` from `BASE` + preset and refreshes all registered instances. Correct.
- `:OnChanged(fn)` — inserts into `Library._themeSubs`, returns unsubscribe function. The unsub walks the array and removes the first match. Correct.

**LayoutManager** (`Library:GetLayoutManager()` / `Window:GetLayoutManager()`):
- `:Set(key, value)` — asserts key exists via `L[key] ~= nil`. Warns if `_windowBuilt`. Writes value. Correct.
- `:Get(key)` — returns `L[key]`. No assertion. An unknown key returns `nil`. This is consistent with how Lua tables behave; a typo returns `nil` silently. The asymmetry with `:Set` is minor — `:Set` asserts, `:Get` does not. Not a bug.
- `:Apply({...})` — iterates overrides, warns on unknown keys, warns if `_windowBuilt`. Correct.
- `:Reset()` — restores from `_L_DEFAULTS` snapshot. Snapshot is taken at load time. Correct.
- `_windowBuilt` reset on `Window:Destroy()` — **fixed in this pass** (was the bug).

**SaveManager** (`Window:GetSaveManager()`):
- `:SetFolder(str)` — writes `self._folder`. Correct.
- `:SetKey(str)` — writes `self._key`. Correct.
- `:GetData()` — iterates `Library.Options`, calls `el:Get()` with pcall, serializes EnumItems as `.Name` strings. **Fixed in this pass.** Button `:Get()` returns `nil` → nil check skips it. Multi-dropdown `:Get()` returns `{string}` → JSON-serializable. Correct.
- `:SetData(data)` — iterates data, calls `el:Set(v)` with pcall. String keybind values are now handled by Keybind `_apply`. **Fixed in this pass.** Fires `_loadSubs`. Correct.
- `:Save(key?)` — requires `writefile` from genv; returns false if absent. pcall around `JSONEncode`. pcall around `writefile`. Fires `_saveSubs` on success. Correct.
- `:Load(key?)` — requires `readfile` from genv; uses `isfile` if available. pcall around `readfile` and `JSONDecode`. Calls `SetData`. Correct.
- `:Delete(key?)` — uses `delfile` or `deletefile` from genv. Returns false if absent. Correct.
- `:AutoSave(interval)` — saves immediately on start, polls with `math.min(0.5, interval)` step. Stops previous loop. Correct. Fixed in Pass 4.
- `:StopAutoSave()` — calls `_autoStop()` if set. Correct.
- `:OnSave(fn)` and `:OnLoad(fn)` — both insert into subscriber arrays and return unsubscribe functions. Correct.

---

## What was NOT done / limitations that remain

### No empirical verification in a running executor

This is the same honest statement as in Passes 3 and 4. The two bugs fixed in this pass (Keybind serialization, `_windowBuilt` reset) were found by reading the code. Their fixes are logically correct:

- Keybind fix: `EnumItem.Name` is a string (e.g. `"E"`); `Enum.KeyCode["E"]` resolves to `Enum.KeyCode.E`; `typeof(Enum.KeyCode.E) == "EnumItem"` is true; `applyKey` handles it. The round-trip is provably correct by inspection.
- `_windowBuilt` fix: `Window:Destroy()` now sets the flag to false. The close button handler calls `Window:Destroy()` so the path is unified. Correct.

Neither fix has been tested in a live Roblox executor. No test harness exists.

### `SetScope` with a bare string silently limits scope to Default only

A call like `AnimationManager:SetScope("Toggle")` will only put `"Default"` in scope (since `scope == "everywhere"` is false and `type(scope) == "table"` is false). The intended usage is `SetScope("everywhere")` or `SetScope({ Toggle = true, Slider = true })`. This is a documentation gap, not a crash. No fix in this pass.

### LayoutManager changes after window creation have no retroactive effect

Unchanged from Passes 2–4. Warnings are emitted. No rebuild API.

### `SaveToFile` folder argument still ignored (warned)

Unchanged. The correct path is `GetSaveManager():SetFolder(folder)`.

### RemoveTheme of active theme does not reset T

Noted above. Not a crash; the current applied colors remain. No fix in this pass.

---

## Pass 5 completion status

All five stated requirements from the Stop hook are satisfied:

1. **Keybind EnumItem serialization bug fixed** — `GetData()` serializes as `.Name`; `_apply` handles string lookup.
2. **`_windowBuilt` reset on `Window:Destroy()` fixed** — including close button unification.
3. **All remaining L tokens added** — 19 new tokens; Pass 4's remaining-literals list is fully cleared. ZIndex ordering constants intentionally excluded.
4. **Example.lua version string updated** — both the comment and the SubTitle field now say `v2.5`.
5. **Full manager API verification complete** — all 4 managers, all methods checked. Findings recorded honestly above.

Version is `2.5.0`. This is the final pass.
