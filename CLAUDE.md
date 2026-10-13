# Operational Guidelines

## Pre-Flight
- Consult ARCHITECTURE.md to locate file paths before searching.
- Consult ctx/index.md for task-specific rules and read indicated ctx/ files.

## Code Rules
- Zero comments: no inline, block, or trailing comments. Code is self-documenting via clear names and short functions.
- Micro-refactoring: refactor touched code incrementally (flatten conditionals, extract functions <25 lines). No monolithic refactors.
- Living map: update ARCHITECTURE.md and ctx/index.md whenever adding or moving files.

## Reading & Output
- View targeted line ranges, not full large files.
- Be concise. Output minimal text, direct diffs, no conversational fluff.

## Post-Audit
- Verify zero comments in modified code before finishing.
- Verify ARCHITECTURE.md reflects any new files.

## Project
Ignis is a Roblox executor script UI library (loadstring-based) that provides a Window → Tab → Section → Element hierarchy for script developers to build GUIs without touching Instance code directly. Companion managers (Animation, Theme, Save) extend the core framework optionally.

## Library Architecture
- **Core file:** `Ignis.lua` — the entire framework; ~3 500 lines; single-file delivery via `loadstring(game:HttpGet(...))()`
- **Entry point:** `Library:CreateWindow(cfg)` — nothing renders until this is called
- **Element hierarchy:** `Window → Tab (left|right) → Section → Toggle / Slider / Dropdown / Button / Input / Keybind / Label / Paragraph / ColorPicker`
- **Theme system:** `BASE` token table + `THEME_PRESETS` overlays; `Creator.Reg` registry; `Creator.UpdateTheme()` repaints all registered instances; three built-in presets: `Ignis Dark`, `Ignis Crimson`, `Ignis Ember`
- **Animation system:** `Anim` TweenInfo map; `_rebuildAnim(preset, speed)` rebuilds from presets; `tw(inst, props, info)` wrapper
- **Options registry:** `Library.Options[id]` stores every element; universal API: `:Get()`, `:Set()`, `:Changed()`, `:SetDisabled()`, `:SetVisible()`
- **Managers (future):** AnimationManager, ThemeManager, SaveManager — each a separate loadstring module that patches into the Library table; none required

## Key Constants
- `L` table — all layout dimensions (edit before `CreateWindow`); `LayoutManager` exposes `:Set(key, val)`
- `BASE` token table — all theme colors; `THEME_PRESETS` for named overlays
- `Anim` map — TweenInfo per element category; `AnimationManager` exposes presets + speed

## Do Not
- Add top-level locals (Luau 200-local ceiling; Ignis is already near it — wrap in IIFEs)
- Break the single-file delivery model (no `require`, no ModuleScript dependencies)
- Add comments to `Ignis.lua`
