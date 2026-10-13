# Architecture Constraints

## Single-file delivery
Ignis.lua must remain a single file loaded via `loadstring(game:HttpGet(...))()`. No `require`, no ModuleScript dependencies, no external assets.

## Luau 200-local ceiling
The main chunk is at or near Luau's 200-local limit. Never add top-level `local` declarations. Wrap new feature blocks in IIFEs: `local x = (function() ... end)()`.

## Managers are external
AnimationManager, ThemeManager, SaveManager are separate loadstring modules. They receive the `Library` table and patch into it. The core library must work without any of them loaded.

## Creator.Reg ownership
Only `Creator.New` and deliberate theme-switch logic (activateTab) may write to `Creator.Reg`. Never write raw Instance references into Reg outside those two paths.

## No transparency on rows
Rows are fully opaque (BT=0). Hover uses color tweens only. Disabled rows use BT=0.6. This matches the original v2.5.3 visual contract.

## Tab activation contract
activateTab must: hide old page, tween old btn to SidebarBg, hide old accent, set old label to TabText in both `.TextColor3` and `Creator.Reg`. Then show new page, tween btn to TabActiveBg, show accent, set label to TabTextActive in both places.

## Versioning
Bump `Library.Version` string and the header comment block (`Ignis vX.Y.Z`) together on every release commit.
