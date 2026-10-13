# Architecture & File Map

| Subsystem / Domain | Root Path | Entry Point / Core Files |
| :--- | :--- | :--- |
| Library core | `/` | `Ignis.lua` |
| Animation manager | `/` | `AnimationManager.lua` |
| Theme manager | `/` | `ThemeManager.lua` |
| Save manager | `/` | `SaveManager.lua` |
| API reference | `/` | `Example.lua` |
| Interactive fuzzer | `/` | `ignis_fuzzer.lua` |
| Test suite | `test/` | `run_tests.luau` |
| Dev pass notes | `pass_notes/` | `pass_01.md` … `pass_09.md` |
| Operational context | `ctx/` | `ctx/index.md` |
| Human docs | `docs/` | `docs/README.md` |

## Directory Responsibilities

- `/`: Single-file core library (`Ignis.lua`), standalone companion managers (`AnimationManager.lua`, `ThemeManager.lua`, `SaveManager.lua`), usage example (`Example.lua`), and interactive UI fuzzer (`ignis_fuzzer.lua`).
- `test/`: Lune-based test suite (`run_tests.luau`) — validates layout, element creation, theme switching, animation presets, and options registry.
- `pass_notes/`: Chronological dev notes from each improvement pass (pass_01–pass_09); historical record only, not loaded by the library.
- `ctx/`: AI operational rules and task-specific context; read via `ctx/index.md` router.
- `docs/`: Human-facing documentation and guides.

## Ignis.lua Internal Layout (line ranges)

| Block | Content |
| :--- | :--- |
| 1–62 | Header, services, SafeParentGui, Maid |
| 63–183 | `L` layout constants table |
| 184–248 | `_L_DEFAULTS`, `_liveRefs`, `LayoutManager` |
| 249–269 | Decoupled `Anim` proxy table, fallback `tw` |
| 270–311 | Minimal default `BASE` theme token table |
| 312–392 | `Creator` (New / Reg / UpdateTheme) + Library table methods |
| 393–407 | Fonts (`_refreshFonts`) |
| 408–507 | Notification system (`_ensureNotifGui`, `Library:Notify`) |
| 508–547 | Element base factory (`mkBase`) |
| 548–867 | `CreateWindow`: ScreenGui, MasterContainer, CenterWindow, Header, Sidebars, BottomBar, Search, Notify |
| 868–958 | `activateTab`, `Window:Tab` setup, page ScrollingFrame |
| 959–1058 | `Tab:Section` — secFrame, bevel strips, optional header strip, inner/rowLayout |
| 1059–1794 | Element builders: Toggle, Slider, Button, Input, Keybind, Label, Paragraph, Dropdown, ColorPicker |
| 1795–1867 | Window API (delegated manager getters, settings serialization, Destroy) |
| 1868–1877 | getgenv registration, return Library |
