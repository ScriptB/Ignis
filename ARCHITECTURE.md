# Architecture & File Map

| Subsystem / Domain | Root Path | Entry Point / Core Files |
| :--- | :--- | :--- |
| Library core | `/` | `Ignis.lua` |
| API reference | `/` | `Example.lua` |
| Interactive fuzzer | `/` | `ignis_fuzzer.lua` |
| Test suite | `test/` | `run_tests.luau` |
| Dev pass notes | `pass_notes/` | `pass_01.md` … `pass_09.md` |
| Operational context | `ctx/` | `ctx/index.md` |
| Human docs | `docs/` | `docs/README.md` |

## Directory Responsibilities

- `/`: Single-file library (`Ignis.lua`), usage example (`Example.lua`), and interactive UI fuzzer (`ignis_fuzzer.lua`).
- `test/`: Lune-based test suite (`run_tests.luau`) — validates layout, element creation, theme switching, and options registry.
- `pass_notes/`: Chronological dev notes from each improvement pass (pass_01–pass_09); historical record only, not loaded by the library.
- `ctx/`: AI operational rules and task-specific context; read via `ctx/index.md` router.
- `docs/`: Human-facing documentation and guides.

## Ignis.lua Internal Layout (line ranges)

| Block | Content |
| :--- | :--- |
| 1–62 | Header, services, SafeParentGui, Maid |
| 63–175 | `L` layout constants table |
| 176–315 | Font vars, AnimationManager internals (`_rebuildAnim`, `tw`) |
| 316–388 | `BASE` theme token table + `THEME_PRESETS` |
| 389–450 | `Creator` (New / Reg / UpdateTheme) + Library table |
| 451–700 | Library methods: LayoutManager, AnimationManager, SetTheme, SaveManager stub, Destroy |
| 701–1008 | `CreateWindow`: ScreenGui, MasterContainer, CenterWindow, Header, Sidebars, BottomBar, Search, Notify |
| 1009–1099 | `activateTab`, `Window:Tab` setup, page ScrollingFrame |
| 1100–1200 | `Tab:Section` — secFrame, bevel strips, optional header strip, inner/rowLayout |
| 1200–1900+ | Element builders: Toggle, Slider, Button, Input, Keybind, Label, Paragraph, Dropdown, ColorPicker |
