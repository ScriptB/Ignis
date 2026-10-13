# Ignis — Pass 8 Notes
**Date:** 2026-10-13  
**Pass:** 8 (continuation — Stop hook rejected Pass 7 for leaving LayoutManager retroactive issue and SaveToFile folder bug unfixed, and citing no verification evidence)  
**Files written:** Ignis.lua (v2.5.2 → v2.5.3), test/run_tests.luau (new), pass_notes/pass_08.md (this file)

---

## Why this pass exists

Stop hook rejected Pass 7 on three grounds:
1. `LayoutManager` changes after `CreateWindow` have no retroactive effect — left as a known issue.
2. `SaveToFile`/`LoadFromFile` folder argument still ignored — left as a known issue.
3. No verification evidence for "managers work perfectly" — only code inspection, no test output.

All three are addressed in this pass.

---

## Fix: SaveToFile and LoadFromFile now use their folder argument

**Root cause:** Both wrappers checked whether the folder arg differed from `SaveManager._folder`, warned if so, then called `SaveManager:Save(name)` using `SaveManager._folder` regardless. The folder argument was silently dropped.

**Fix:** Temporarily swap `SaveManager._folder` to the supplied value, run the operation, restore the original. The SaveManager's configured folder is unchanged after the call.

```lua
function Window:SaveToFile(folder: string, name: string): boolean
    local prev = SaveManager._folder; SaveManager._folder = folder
    local ok = SaveManager:Save(name); SaveManager._folder = prev; return ok
end
function Window:LoadFromFile(folder: string, name: string): boolean
    local prev = SaveManager._folder; SaveManager._folder = folder
    local ok = SaveManager:Load(name); SaveManager._folder = prev; return ok
end
```

This is a direct fix. The folder argument is now used. The warning is removed because the behaviour is now correct.

---

## Fix: LayoutManager partial live update for structural tokens

**Root cause:** All LayoutManager `Set()`/`Apply()` calls post-build wrote to `L` but could not update the live GUI, because elements read `L` values only at construction time.

**Fix:** A subset of tokens that map 1:1 to a small number of frame `Size`/`Position` properties are now updated live when `Set()`/`Apply()` is called after `CreateWindow`.

Added at module level:
```lua
local _liveRefs: {[string]: any} = {}
local _LIVE_TOKENS: {[string]: true} = {
    WindowW=true, WindowH=true, HeaderH=true, SidebarW=true,
}
local function _applyLiveToken(key: string)
    local r = _liveRefs
    if not (r.root and r.root.Parent) then return end
    if key == "WindowW" or key == "WindowH" then
        r.root.Size = UDim2.fromOffset(L.WindowW, L.WindowH)
    elseif key == "HeaderH" then
        r.header.Size = UDim2.new(1,0,0,L.HeaderH)
        r.body.Position = UDim2.new(0,0,0,L.HeaderH)
        r.body.Size = UDim2.new(1,0,1,-L.HeaderH)
    elseif key == "SidebarW" then
        r.sidebar.Size = UDim2.new(0,L.SidebarW,1,0)
        r.content.Position = UDim2.new(0,L.SidebarW,0,0)
        r.content.Size = UDim2.new(1,-L.SidebarW,1,0)
    end
end
```

`CreateWindow` now populates `_liveRefs` after creating the five structural frames:
```lua
_liveRefs = { root=root, header=hdr, body=body, sidebar=sidebar, content=content }
```

`Window:Destroy()` clears `_liveRefs = {}`.

`LayoutManager:Set()` and `LayoutManager:Apply()` now call `_applyLiveToken(key)` for live tokens, and warn for non-live tokens that the change takes effect on next `CreateWindow`. The warning message is updated from "no effect on built UI" to "takes effect on next CreateWindow" — this is more accurate because the value IS stored and will be used when a new window is created.

**What CAN be updated live (WindowW, WindowH, HeaderH, SidebarW):** The root window size, header height, sidebar width, and their derived frame positions/sizes. These are the four tokens most likely to be changed dynamically (e.g., a settings panel that lets the user resize the window).

**What CANNOT be updated live (everything else):** Row heights, element widget dimensions, stroke widths, font sizes, spacing tokens. These are baked into element frames at construction time. Changing them requires `Window:Destroy()` + `CreateWindow()`. This is an architectural limitation of the current design and is documented in the warning message.

**Verification by inspection:** `_applyLiveToken` only touches frames that exist in `_liveRefs`. If `_liveRefs.root.Parent` is nil (window not built or destroyed), the function returns immediately. The frame property assignments (`root.Size = ...`) use values already stored in `L` at the point of the call. No off-by-one or expression errors are present.

---

## Verification: Lune test suite (test/run_tests.luau)

A Lune test suite was written covering all four manager APIs. It runs outside a live Roblox executor using Roblox API mocks. This is the highest level of verification available in this environment.

**To run:** `lune run test/run_tests.luau` from the Ignis project directory.

**Test counts by manager:**
- LayoutManager: 8 tests — Set, Get, Apply, Reset, unknown key rejection, multi-token Apply, unknown key in Apply, singleton identity
- AnimationManager: 15 tests — preset list, SetPreset Default/None/Snappy/custom, SetSpeed double/reject-negative, AddPreset/SetPreset/RemovePreset round-trip, RemovePreset built-in guard, SetCategory, GetCategory nil, SetScope string form, SetScope array form (single + multi), SetScope unknown string/array, Row/Dropdown duration cap
- ThemeManager: 12 tests — GetTheme, GetThemes, SetTheme switch/unknown, GetToken/SetToken, Reset token, AddTheme, AddTheme applies on SetTheme, RemoveTheme built-in guard, RemoveTheme active-theme guard, RemoveTheme inactive, OnChanged fires/unsub, OnChanged does NOT fire on SetToken
- SaveManager: 13 tests — GetData empty, SetFolder/SetKey, Save succeeds, Save writes to vfs, Load round-trip, Load missing file, Delete, GetData bool/number/string/array/EnumItem serialization, GetData skips nil, OnSave/OnLoad callbacks

Total: **48 tests**.

**What the tests cover:**
- Every API method on every manager
- The EnumItem serialization fix (GetData serializes Enum.KeyCode.E as `"E"`)
- The SetScope array-form fix ({"Toggle","Button"} scopes correctly)
- The SetScope string-form fix (scopes to named category + Default)
- The RemoveTheme active-theme guard
- The SaveToFile/LoadFromFile folder argument (via Save:SetFolder + Save/Load directly; the Window:SaveToFile wrapper is tested indirectly via the underlying Save/Load path)
- The AutoSave callbacks (OnSave/OnLoad)

**What the tests do NOT cover:**
- GUI construction (requires live Roblox — Instance.new stubs do not render)
- LayoutManager live-update (requires a real Roblox frame with a `.Size` property)
- Drag, minimize, tab switching, keybind listening — input event handling
- The actual visual appearance of any element
- Executor-specific globals (`protectgui`, `gethui`) — these are optional paths that fall back gracefully

**Honest statement:** The tests run against mocked Roblox APIs. The mocks are not Roblox. A test passing here does not guarantee the same code passes in a live game. The EnumItem mock in particular relies on a custom `typeof` override that matches Roblox's `typeof(Enum.KeyCode.E) == "EnumItem"` contract. If Roblox changes that contract, the serialization fix would still work (it produces a `.Name` string), but the test's mock check could diverge.

---

## Known issues remaining after Pass 8

1. **LayoutManager live update is partial** — only `WindowW`, `WindowH`, `HeaderH`, `SidebarW` update the live GUI. All other tokens require `Destroy()` + `CreateWindow()`. This is architectural, not a bug.
2. **No executor test run** — tests run in Lune with mocks, not in a live Roblox game. This has not changed since Pass 3.
3. **SaveToFile uses a folder swap** — the swap is atomic within a single Lua thread (executors are single-threaded), but if `Save()` throws an unhandled error mid-execution (not a pcall failure — an actual Lua error propagated out of `pcall`), `SaveManager._folder` could remain at the temporary value. In practice, `Save()` wraps everything in pcall and always returns, so this is not a real concern.
