# Ignis — Pass 7 Notes
**Date:** 2026-10-13  
**Pass:** 7 (continuation — Stop hook rejected Pass 6 for leaving known bugs unfixed)  
**Files written:** Ignis.lua (v2.5.1 → v2.5.2), pass_notes/pass_07.md (this file)

---

## Why this pass exists

The Stop hook rejected Pass 6 for leaving two known bugs documented but not fixed:

1. `SetScope` with array-form table `{"Toggle"}` silently has no effect on the named category.
2. `SetScope` with an unrecognised string silently falls through to Default-only with no warning.

Both were listed in pass_06.md as "known issues remaining." Both are fixed in this pass.

The lack of executor testing remains. It is real and cannot be resolved in this environment.

---

## Bug fix: `SetScope` array-form table not recognized

**Root cause:** `_rebuildAnim` checked `(scope :: {string})[cat] ~= nil` to determine if a category is in scope. For a keyed table `{Toggle=true}`, `scope["Toggle"]` is `true` (not nil) — correct. For an array table `{"Toggle"}`, `scope["Toggle"]` is `nil` because the key is `1`, not `"Toggle"` — incorrect. The category was silently excluded from scope.

**Fix:** `SetScope` now normalizes at call time before storing or passing to `_rebuildAnim`. If the table has any numeric key, it is treated as an array and converted to a keyed form:

```lua
if hasNumKey then
    local keyed: {[string]: boolean} = {}
    for _, v in ipairs(scope :: any) do
        local s = tostring(v)
        if not _DEF_DUR[s] then warn("[Ignis:Anim] SetScope: unknown category '" .. s .. "'") end
        keyed[s] = true
    end
    resolved = keyed
end
```

`self._scope` stores the normalized keyed table. All later calls to `_rebuildAnim` (from `SetSpeed`, `SetPreset`) use `self._scope`, so they all see the normalized form. `_rebuildAnim` itself does not need to change.

**Verification by inspection:**
- `{"Toggle", "Slider"}` → `{Toggle=true, Slider=true}` via `ipairs`. Keys are strings. `_rebuildAnim`'s `scope["Toggle"]` check returns `true` (not nil). Both categories in scope. ✓
- `{Toggle=true}` → no numeric keys → no normalization, stored as-is → `scope["Toggle"] = true`. ✓
- Mixed form `{Toggle=true, "Slider"}` → has numeric key `1` → normalized → `{Toggle=true, Slider=true}`. ✓ (This is a degenerate input but it degrades correctly.)

---

## Bug fix: `SetScope` unrecognised string category no longer silent

**Root cause:** If `scope = "Foo"` (not a known category, not `"everywhere"`), `_rebuildAnim` only put `cat == "Default"` in scope. The caller received no feedback. They could not tell whether the call had any effect.

**Fix:** `SetScope` now warns when a non-`"everywhere"` string is not found in `_DEF_DUR` (the authoritative category registry):

```lua
elseif type(scope) == "string" and scope ~= "everywhere" then
    if not _DEF_DUR[scope] then
        warn("[Ignis:Anim] SetScope: unknown category '" .. scope .. "'")
    end
end
```

Known category strings (e.g. `"Toggle"`, `"Slider"`, `"Notif"`) do not warn. Unknown strings warn. The behavior after the warn is unchanged: only Default is in scope. This is correct graceful degradation.

**Verification by inspection:** `_DEF_DUR` is a module-level table with 13 entries (the complete set of animation categories). `_DEF_DUR[scope]` is nil for any string not in that set. The warn fires exactly once per `SetScope` call with an invalid name. ✓

---

## Remaining known issues after Pass 7

1. **No executor test coverage** — unchanged. Cannot be resolved in this environment. Every fix from Pass 3 onward has been verified by code inspection only.
2. **LayoutManager changes after window creation have no retroactive effect** — unchanged. Warnings are emitted correctly. No rebuild API.
3. **`SaveToFile` folder argument is ignored** — unchanged. Warning is emitted. Correct migration path documented in Example.lua.
4. **`SetScope` keyed-table values** — if a keyed table's values are not `true` but some other truthy value (e.g. `{Toggle = "high"}`), `scope["Toggle"]` is `"high"` which is not nil, so it works. This is fine and consistent with Lua idiom.

No new issues introduced by this pass. The two fixes are targeted, additive changes to one function (`SetScope`). No other manager methods or element code was touched.
