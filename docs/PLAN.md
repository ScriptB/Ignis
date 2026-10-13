# Ignis — Development Plan

## Current State (v3.3.0)
- Single-file library (`Ignis.lua`) — loadstring delivery, no dependencies
- Window → Tab → Section → Element hierarchy fully working
- Elements: Toggle, Slider, Dropdown, Button (normal + primary), Input, Keybind, Label, Paragraph, ColorPicker
- Visuals: restored 1:1 to original dark blue-black palette — opaque rows, dark sidebar tabs with red accent strip, visible section boxes with bevel strips
- Three built-in theme presets: Ignis Dark, Ignis Crimson, Ignis Ember
- Animation, theme, and save systems baked into `Ignis.lua` (to be extracted)

---

## Phase 1 — Standalone Manager Architecture

The core library stays framework-only. Heavy systems move to separate loadstring modules.
Each manager receives the `Library` table and patches in its capabilities. None are required.

```lua
local Ignis = loadstring(game:HttpGet("...Ignis.lua"))()
local Anim  = loadstring(game:HttpGet("...AnimationManager.lua"))(Ignis)
local Theme = loadstring(game:HttpGet("...ThemeManager.lua"))(Ignis)
local Save  = loadstring(game:HttpGet("...SaveManager.lua"))(Ignis)
```

### AnimationManager
- Extract `Anim` table, `_rebuildAnim`, `tw` out of `Ignis.lua`
- Expose: `:SetPreset("Default"|"Snappy"|"Smooth"|"Bounce"|"None")`, `:SetSpeed(n)`, `:SetCurve(cat, info)`
- `Ignis.lua` falls back to instant property sets when AnimationManager not loaded

### ThemeManager
- Extract `BASE`, `THEME_PRESETS`, `T`, `Creator.UpdateTheme`, `:SetTheme` out of `Ignis.lua`
- Expose: `:Set(token, color)` for live token override, `:NewPreset(name, overrides)`, `:Reset()`
- `Ignis.lua` keeps `Creator.Reg` (registry) and a minimal default color set so elements render without ThemeManager

### SaveManager
- Build out the existing stub into a real module
- Expose: `:SetFolder(path)`, `:Save(name)`, `:Load(name)`, `:ListConfigs()`, `:AutoLoad(name)`
- Reads/writes `Library.Options[id]:Get()` / `:Set(v)` for all saveable element types
- Uses executor `writefile` / `readfile` / `makefolder` APIs; gracefully no-ops in Studio

---

## Phase 2 — Core Library Cleanup (after Phase 1)

With managers extracted, `Ignis.lua` becomes significantly smaller and more stable.

- Strip all animation TweenInfo setup — replace with direct `inst[k] = v` fallback calls
- Strip theme preset logic — keep only `Creator.Reg` and a hardcoded minimal default palette
- Refactor large element builders: each element type should be ≤ 25-line builder function
- Fix section block indentation (currently cosmetically inconsistent after v3.3.0 Python patch)

---

## Phase 3 — API & DX

- **Docs site** — proper README on the GitHub repo covering the full API surface with copy-paste examples
- **ThemeManager docs** — token reference table, how to create a custom preset
- **SaveManager docs** — folder structure, config file format, autoload pattern
- **LayoutManager docs** — all `L` keys, recommended override patterns

---

## Phase 4 — Visual Polish (post-architecture)

All visual changes go through ThemeManager once it exists. No more direct BASE edits.

- **Reopen pill** — currently a plain red `Frame`; style to match the rest of the library
- **Scrollbar** — currently default Roblox thumb; replace with custom styled thumb
- **Dropdown animation** — expand/collapse with height tween (currently instant)
- **ColorPicker** — consider HSV wheel as alternative to R/G/B sliders
- **Notification stack** — currently single slot; support up to 3 stacked with slide-in

---

## Constraints (never break)

- Single-file delivery — `Ignis.lua` must remain one file, no `require`, no ModuleScript deps
- Luau 200-local ceiling — no new top-level locals; wrap in IIFEs
- Managers optional — library works standalone without any manager loaded
- Versioning — bump `Library.Version` + header comment together on every release
