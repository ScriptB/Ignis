# Ignis — Pass 4 Notes
**Date:** 2026-10-13  
**Pass:** 4 of 5  
**File written:** Ignis.lua (v2.3.0 → v2.4.0), pass_notes/pass_04.md (this file)

---

## What was done

### Three outstanding L tokens from pass_03.md (all three fixed)

**`DropdownChevronSize = 10`** — the `∨` chevron TextSize was hardcoded 10.  
Now reads `L.DropdownChevronSize`.

**`DropdownOptPadL = 10`** — `PaddingLeft` inside each dropdown option button was hardcoded 10.  
Now reads `L.DropdownOptPadL`.

**`InputBoxBottomPad = 7`** — the `-7` pixel offset in the input box `ibg.Position` was hardcoded.  
Now reads `-L.InputBoxBottomPad`.

---

### Additional L tokens (new in this pass)

Full audit of remaining structural literals beyond the three above. The following were hardcoded at call sites and are now in L:

| Token | Default | Was | Where |
|-------|---------|-----|-------|
| `HeaderBtnSize` | 28 | literal `28` | close/min button Size |
| `TabLabelIndent` | 12 | literal `12` | tab button label position/size |
| `SectionLabelIndent` | 12 | literal `12` | section header text position/size |
| `ToggleKnobMargin` | 3 | literal `3` | knob position arithmetic both ends |
| `SliderValLabelW` | 64 | literal `64` | slider value readout label width |
| `KeybindPillW` | 72 | literal `72` | keybind pill width |
| `KeybindPillH` | 22 | literal `22` | keybind pill height |
| `NotifTitleY` | 10 | literal `10` | Y position of title text in notification |

Header button positions are now fully derived from `L.HeaderBtnSize`:
- Close button X: `UDim2.new(1, -10, 0.5, 0)` — right margin `10` is a spacing constant, not yet in L
- Min button X: `UDim2.new(1, -(10 + BS + 6), 0.5, 0)` where `BS = L.HeaderBtnSize` — the `10` and `6` are spacing/gap constants; see remaining issues below
- Title right reserve: computed from `(L.HeaderBtnSize + 6) * 2` — previously hardcoded `-80`

This is a real improvement: `titleRightPad` now auto-adjusts when `HeaderBtnSize` changes instead of silently staying at 80.

---

### AutoSave stop lag fix

**Old behaviour:** AutoSave loop began with `task.wait(interval)`. StopAutoSave() could wait up to `interval` seconds before the stop flag was checked. First save didn't happen until after the first interval elapsed.

**New behaviour:**
```lua
while running do
    self:Save()  -- save immediately on loop start
    local elapsed = 0
    local step = math.min(0.5, interval)
    while running and elapsed < interval do
        task.wait(step); elapsed += step
    end
end
```

- Maximum stop lag reduced from `interval` seconds to `math.min(0.5, interval)` seconds.
- Save now fires immediately when AutoSave starts, not after one full interval.
- Polling step of 0.5s is bounded by `interval` so low-interval configs (e.g., 0.1s) still work correctly — step = 0.1s in that case, not 0.5s.
- No RunService.Heartbeat dependency added. The polling approach is acceptable given the executor environment.

This is a real improvement. The old behaviour could silently miss a save if the script was killed within one interval of starting AutoSave.

---

### Version bump

Version string updated to `"2.4.0"`.

---

## What was NOT done / remaining issues

### Remaining literal pixel values

The following literal numbers are still present in the file. They were considered for L tokenisation but are lower-priority than what has been fixed, and adding tokens for every sub-pixel offset produces diminishing returns:

- `10` — right-side margin for close button (`Position = UDim2.new(1, -10, 0.5, 0)`)
- `6` — gap between close and minimize buttons
- `16` — title text left offset
- `14` — height of dropdown display label (`Size = UDim2.new(0.45, 0, 0, 14)`)
- `22` — right margin of dropdown display label
- `8` — right margin of dropdown chevron
- `12 × 12` — dropdown chevron container size
- `16 × 20` — button chevron container size
- `+ 2` — inner frame width adjustment in notification card
- `- 4` — bottom margin in notification message label
- `+ 3` — extra gap in Paragraph UIListLayout
- `2` — slider value label top offset
- `16` — slider value label pixel height
- ZIndex values (3, 4, 8, 9) — not layout tokens, intentional ordering constants

None of these affect the fundamental layout contract (row heights, sidebar width, fonts, stroke widths, element sizes). They are spacing micro-constants. They could be tokenised in a future pass if needed, but doing so now would bloat L without meaningfully improving configurability.

### LayoutManager post-build still has no retroactive effect

Warnings are emitted correctly. No rebuild API exists. This is a known architectural limitation — elements capture L values at construction time.

### SaveToFile folder arg still warned, not fixed structurally

The wrapper warns and forwards the key correctly, but the folder argument is still ignored. Correct path is `GetSaveManager():SetFolder(folder)` before calling `:Save(name)`.

### No test coverage

All changes are code inspection and logical reasoning. No empirical verification in a running executor has been performed. This is an honest limitation — the library cannot be loaded in a non-executor environment, and no executor test harness exists in this session. Changes that are low-risk (new L tokens replacing literal values with the same numbers) have a near-zero chance of introducing regressions. The AutoSave fix changes observable behaviour (save-on-start, reduced stop lag) and is the highest-risk change in this pass, but the logic is straightforward to audit:

- `self:Save()` before the inner wait loop is called unconditionally on every outer loop iteration — same as the old code except it fires immediately instead of after a delay.
- The inner polling loop terminates when `running = false` is set by `StopAutoSave()`, within at most `math.min(0.5, interval)` seconds.
- No edge case exists for `interval < step`: `step = math.min(0.5, interval)` ensures `step <= interval` always, so `elapsed < interval` will eventually be false even if `running` stays true.

---

## Known issues (remaining after Pass 4)

1. **Minor layout literals** (listed above) — present, low priority for Pass 5.
2. **AutoSave save-on-start may be unexpected** for callers who expected the old behaviour (first save after one interval). This is a deliberate behaviour change. No callers in Example.lua are affected since they call AutoSave at startup.
3. **No test coverage** — unchanged.
4. **LayoutManager post-build no retroactive effect** — unchanged, warned.
5. **SaveToFile folder arg ignored** — unchanged, warned.
