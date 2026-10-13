# Theme System

## Token table (BASE)
All color values live in `BASE` (~line 326). `T` is the live copy; `THEME_PRESETS` are overlays applied on top of BASE when a theme is activated.

## Key tokens
| Token | Role |
| :--- | :--- |
| `WinBg` | CenterWindow background |
| `SidebarBg` | Left/right sidebar + inactive tab button |
| `TabHoverBg` | Tab button on mouse-enter |
| `TabActiveBg` | Tab button when active |
| `TabActiveLeft` | Red accent strip on active tab |
| `TabText` / `TabTextActive` | Inactive / active tab label color |
| `SectionBg` / `SectionBevel` | Section box fill / left+bottom bevel strips |
| `RowBg` / `RowBgHover` | Row normal / hover fill |
| `SliderFill` | Slider track fill + primary button background |
| `NotifBar` | Default notification bar color |
| `NotifSuccess/Warning/Info` | Typed notification bar colors |

## Updating theme at runtime
`Creator.UpdateTheme()` walks `Creator.Reg` and reapplies all tokens. Calling `Library:SetTheme(name)` merges the preset over BASE then calls UpdateTheme.

## activateTab registry update
When switching tabs, manually patch `Creator.Reg[btnLabel] = { TextColor3 = "TabText"|"TabTextActive" }` so SetTheme repaint uses the correct token per tab state.

## Presets
Three built-in: `Ignis Dark` (baseline), `Ignis Crimson` (pink-red shift), `Ignis Ember` (orange shift). Add new ones to `THEME_PRESETS` table only — never alter `BASE`.
