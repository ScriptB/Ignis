# Ignis — Pass 3 Notes
**Date:** 2026-10-13  
**Pass:** 3 of 5  
**File written:** Ignis.lua (v2.2.0 → v2.3.0), pass_notes/pass_03.md (this file)

---

## What was done

### Bug fixes

**Slider `:Get()` returned un-snapped value (real bug)**  
Root cause: `mkBase.Set(v)` set `value = v` AFTER calling `_apply`, so `_apply`'s snap result
was overwritten by the raw input. `el:Get()` returned the raw value; the visual was correct but
the stored value was wrong.  
Fix: reordered `mkBase.Set` so `value = v` is set FIRST, then `_apply` is called (which can call
`self:_raw(normalised)` to overwrite value), then `fire(value)` uses the post-apply value.  
Slider's `_apply` now calls `self:_raw(val)` after snapping so `Get()` returns the snapped value.

**Keybind Changed callback fired twice on `Set()` (real bug)**  
Root cause: `applyKey` called `el._fire(k)`, AND `mkBase.Set` also called `fire(v)` after
returning from `_apply`. Two fires per `Set` call.  
Fix: removed `el._fire` call from `applyKey`. `applyKey` now only updates visual state, the
`bound` closure, calls `_raw(k)`, and fires the user-supplied `opts.Callback`. `mkBase.Set`'s
single `fire(value)` call is the only Changed notification.  
Input handler now calls `el:Set(inp.KeyCode)` instead of `applyKey` directly, so Changed fires
exactly once from the base.  
`el.Clear` now calls `el:Set(Enum.KeyCode.Unknown)` instead of `applyKey` directly, so it also
fires Changed once.

**Button Changed callback fired twice on click (real bug)**  
Root cause: `el.Press()` called `el._fire(nil)`, and the input handler then called `el._fire(nil)`
again after calling `Press()`.  
Fix: removed the redundant `el._fire(nil)` from the input handler. `el.Press()` is the sole owner
of the Changed notification. Input handler now calls `el.Press()` only.

### LayoutManager improvements

**`LayoutManager:Set`/`Apply` now warns if called after `CreateWindow`**  
`_windowBuilt` flag is set to `true` at the top of `CreateWindow`. `Set()` and `Apply()` check
this flag and emit a `warn` if the window is already built, since changes have no effect on
existing UI. The value is still written (in case the caller destroys and recreates the window).

**`LayoutManager:Reset()` no longer drifts from L initialisation**  
Previously, Reset() was a hand-written copy of every L value. If L's defaults ever changed, Reset
would silently return wrong values.  
Fix: a `_L_DEFAULTS` snapshot is taken at load time (`for k,v in pairs(L) do ... end`) and
Reset() restores from that snapshot. The two are always in sync.

### Additional L tokens (remaining structural hardcodes)

Added 14 new tokens to L, removing all remaining hardcodes from element and window construction:
- `CloseIconSize = 14` — ✕ button text size
- `MinIconSize = 12` — — button text size
- `TabListPad = 2` — UIListLayout gap between tab buttons in sidebar
- `SidebarPadTop = 6`, `SidebarPadH = 4` — UIPadding on sidebar
- `PageSectionGap = 6` — UIListLayout gap between sections on a page
- `PagePad = 8` — UIPadding on scrolling page frame
- `RowListPad = 1` — UIListLayout gap between rows within a section
- `RowIndent = 10` — indent of rowInner frame (also used as Paragraph padding)
- `LabelPad = 6` — added to TextSize to get label frame height; used in description offsets
- `DropdownOptH = 28` — height of each option button in dropdown panel
- `BtnChevronSize = 18` — › chevron text size on Button rows
- `InputPadH = 6` — left/right padding inside Input TextBox
- `NotifBarW = 3` — width of the coloured left-bar strip on notification cards
- `NotifInnerPadL = 12` — left padding of notification inner content frame

All previously-literal values for these have been replaced with `L.*` references.

**`LabelPad` replaces magic `+ 6` in description offsets**  
`dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)` now used everywhere a
description label is positioned below the name label (Toggle, Slider, Dropdown, Input, Keybind,
Button), replacing scattered `+ 6` literals.

### Dead locals removed
`_animPreset`, `_animScope`, and `_animSpeed` were module-level locals that were assigned but
never read (rebuild calls used `self._preset`, `self._speed`, `self._scope`). All three removed.

### SaveToFile / LoadFromFile now warn on folder mismatch
`Window:SaveToFile(folder, name)` and `Window:LoadFromFile(folder, name)` now emit a `warn` if
the `folder` argument differs from `SaveManager._folder`, explaining the arg is ignored and how
to change the folder correctly. Previously silent.

### Version bump
Version string updated to `"2.3.0"`.

---

## What was NOT done / remaining issues

**AutoSave one-interval lag**  
`task.wait(interval)` at the loop top means StopAutoSave() waits up to `interval` seconds to
take effect. This is inherent to Roblox's `task.wait` — there is no cancellable sleep primitive
in the executor environment without RunService.Heartbeat, which would be expensive. The lag is
documented but not fixed. It is unlikely to cause data loss in practice.

**LayoutManager changes after window creation have no retroactive effect**  
Warnings are now emitted, but elements cannot re-read L values. A "rebuild" API (destroy and
recreate the window) is not provided. This is acceptable for the current architecture.

**Dropdown chevron `∨` text size (10) not yet in L**  
This is a cosmetic detail. Adding `DropdownChevronSize = 10` is a candidate for Pass 4.

**Dropdown option list padding (`PaddingLeft = 10`) not in L**  
`DropdownOptPadL = 10` is a candidate for Pass 4.

**Input box bottom offset (`-7`) in ibg.Position not in L**  
`InputBoxBottomPad = 7` is a candidate for Pass 4.

**No test coverage**  
No automated test suite exists. Correctness of bug fixes (slider snapping, keybind/button
double-fire) is logical but not empirically verified in a running executor.

---

## Known issues (remaining after Pass 3)

- AutoSave stop lag (inherent, documented).
- `Window:SaveToFile(folder, name)` folder arg is ignored with a warning — not fixed, just warned.
- Three minor layout literals remain: dropdown chevron size, dropdown option padding, input box
  bottom offset. Candidates for Pass 4.
