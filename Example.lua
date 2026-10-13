--[[
    Ignis v3.2  ·  Random UI Showcase
    Generates a random window using every element type.
    Press the "Rebuild UI" button (or run the script again) to regenerate.
    Use this to visually spot layout, animation, or theming issues.
--]]

local Ignis = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Ignis/main/Ignis.lua"))()
-- local Ignis = loadstring(readfile("Ignis.lua"))()  -- local fallback

-- ── RNG helpers ──────────────────────────────────────────────────────────────
local rng = Random.new()
local function ri(a: number, b: number): number return rng:NextInteger(a, b) end
local function rf(): number return rng:NextNumber() end
local function pick(t: {any}): any return t[ri(1, #t)] end
local function maybe(p: number): boolean return rf() < p end

-- ── Vocabulary ───────────────────────────────────────────────────────────────
local TITLES      = { "NEXUS", "CIPHER", "VORTEX", "APEX", "PHANTOM", "IGNIS", "EMBER", "FLARE" }
local TAB_LEFT    = { "Combat", "Movement", "Visual", "Farming", "Misc", "Settings", "Exploit", "Tools", "Aimbot", "ESP", "Player" }
local TAB_RIGHT   = { "Config", "Credits", "Debug", "Info", "Utility" }
local SEC_LABELS  = { "Aimbot", "Movement", "Visual", "Misc", "Config", "Core", "Advanced", "Extras" }
local NAMES       = {
    "Speed Boost", "Auto Farm", "God Mode", "Fly Speed", "Jump Power",
    "Kill Aura", "ESP Range", "Walk Speed", "Inf Stamina", "Fast Attack",
    "Teleport", "No Clip", "Auto Click", "Aim Assist", "Hit Box",
    "Silent Aim", "Radar", "Bhop", "Triggerbot", "Fling",
}
local DESCS       = {
    "Enables the feature when active",
    "Adjusts the intensity level",
    "Only applies in game servers",
    "May cause detection — use with care",
    "Experimental — test carefully",
}
local OPT_SETS    = {
    { "Disabled", "Low", "Medium", "High", "Ultra" },
    { "Off", "On", "Auto" },
    { "Red", "Green", "Blue", "Yellow", "White" },
    { "1x", "2x", "5x", "10x", "50x" },
    { "Slow", "Normal", "Fast", "Instant" },
    { "None", "Players", "NPCs", "All" },
}
local KEYS        = {
    Enum.KeyCode.F1, Enum.KeyCode.F2, Enum.KeyCode.F3,
    Enum.KeyCode.Z,  Enum.KeyCode.X,  Enum.KeyCode.C, Enum.KeyCode.V,
    Enum.KeyCode.G,  Enum.KeyCode.H,  Enum.KeyCode.J,
}
local NOTIF_TYPES = { "success", "warning", "info", "error" }
local THEMES      = { "Ignis Dark", "Ignis Crimson", "Ignis Ember" }

-- ── Unique ID counter (persists across rebuilds so IDs never collide) ────────
local _idN = 0
local function uid(): string
    _idN += 1
    return "e" .. _idN
end

-- ── Forward declaration (rebuild calls buildRandom) ──────────────────────────
local rebuild: () -> ()

-- ── Random UI builder ────────────────────────────────────────────────────────
local function buildRandom()
    local title     = pick(TITLES)
    local theme     = pick(THEMES)
    local leftN     = ri(2, 5)
    local rightN    = ri(0, 3)

    local Window = Ignis:CreateWindow({
        Title       = title,
        SubTitle    = "v3.2 showcase",
        Theme       = theme,
        MinimizeKey = Enum.KeyCode.RightShift,
    })

    -- Left tabs
    local leftTabs: { any } = {}
    local usedNames: { [string]: boolean } = {}
    for i = 1, leftN do
        local name
        repeat name = pick(TAB_LEFT) until not usedNames[name]
        usedNames[name] = true
        leftTabs[i] = Window:Tab(name)
    end

    -- Right tabs with light content
    for i = 1, rightN do
        local rTab = Window:Tab(TAB_RIGHT[i] or ("Util " .. i), { Side = "right" })
        local rSec = rTab:Section()
        rSec:Label({ Id = uid(), Name = "Tab", Value = TAB_RIGHT[i] or ("Util " .. i) })
        rSec:Toggle({ Id = uid(), Name = "Feature " .. i, Default = maybe(0.5) })
        if maybe(0.5) then
            rSec:Slider({ Id = uid(), Name = "Level", Min = 0, Max = 100, Default = ri(0, 100) })
        end
    end

    -- Fill left tabs randomly using every element type
    for _, tab in ipairs(leftTabs) do
        local secN = ri(1, 3)
        for _ = 1, secN do
            -- 50 % chance of a visible section label
            local secLabel = maybe(0.5) and pick(SEC_LABELS) or nil
            local sec = tab:Section(secLabel)
            local elemN = ri(2, 8)
            for _ = 1, elemN do
                -- 9 element kinds: Toggle, Slider, Dropdown, Button (normal),
                -- Button (primary), Input, Keybind, Label, ColorPicker
                local kind = ri(1, 9)
                local name = pick(NAMES)
                local desc: string? = maybe(0.25) and pick(DESCS) or nil
                local id = uid()
                if kind == 1 then
                    sec:Toggle({ Id = id, Name = name, Description = desc, Default = maybe(0.5) })
                elseif kind == 2 then
                    local maxV = ri(10, 500)
                    sec:Slider({ Id = id, Name = name, Description = desc,
                        Min = 0, Max = maxV, Step = 1, Default = ri(0, maxV) })
                elseif kind == 3 then
                    local opts = pick(OPT_SETS)
                    sec:Dropdown({ Id = id, Name = name, Description = desc,
                        Options = opts, Default = opts[1], Multi = maybe(0.2) })
                elseif kind == 4 then
                    sec:Button({ Id = id, Name = name, Description = desc })
                elseif kind == 5 then
                    sec:Button({ Id = id, Name = name, Description = desc, Style = "primary" })
                elseif kind == 6 then
                    sec:Input({ Id = id, Name = name, Description = desc,
                        Placeholder = "Enter value…" })
                elseif kind == 7 then
                    sec:Keybind({ Id = id, Name = name, Description = desc,
                        Default = pick(KEYS) })
                elseif kind == 8 then
                    sec:Label({ Id = id, Name = name, Value = tostring(ri(0, 9999)) })
                else
                    sec:ColorPicker({ Id = id, Name = name, Description = desc,
                        Default = Color3.fromRGB(ri(0, 255), ri(0, 255), ri(0, 255)) })
                end
            end
        end
    end

    -- ── Test Controls section (always present, always in first left tab) ──────
    local ctrl = leftTabs[1]:Section("Test Controls")

    -- Build summary
    ctrl:Paragraph({
        Id    = uid(),
        Title = "This Build",
        Text  = string.format(
            "%d left tab%s · %d right tab%s · theme: %s. Each rebuild picks random tabs, sections, element types, and descriptions.",
            leftN, leftN ~= 1 and "s" or "",
            rightN, rightN ~= 1 and "s" or "",
            theme
        ),
    })

    -- Theme picker
    ctrl:Dropdown({
        Id       = uid(),
        Name     = "Theme",
        Options  = Ignis:GetThemeNames(),
        Default  = Ignis:GetTheme(),
        Callback = function(v: any) Window:SetTheme(tostring(v)) end,
    })

    -- Notification tester — cycles through all four types
    local _notifIdx = 0
    ctrl:Button({
        Id       = uid(),
        Name     = "Test Notification",
        Callback = function()
            _notifIdx = (_notifIdx % #NOTIF_TYPES) + 1
            local t = NOTIF_TYPES[_notifIdx]
            Window:Notify({
                Title    = "Type: " .. t,
                Message  = "This is a " .. t .. " notification.",
                Duration = 3,
                Type     = t,
            })
        end,
    })

    -- ColorPicker demo (always visible so it's always testable)
    ctrl:ColorPicker({
        Id       = uid(),
        Name     = "Color Demo",
        Default  = Color3.fromRGB(224, 32, 32),
        Callback = function(_c: Color3) end,
    })

    ctrl:ColorPicker({
        Id          = uid(),
        Name        = "With Description",
        Description = "Pick any color",
        Default     = Color3.fromRGB(40, 215, 80),
        Callback    = function(_c: Color3) end,
    })

    -- Toggle disabled state demo
    local disabledDemo = ctrl:Toggle({
        Id      = uid(),
        Name    = "Disabled Toggle",
        Default = true,
    })
    disabledDemo:SetDisabled(true)

    -- Rebuild button — primary style so it stands out
    ctrl:Button({
        Id       = uid(),
        Name     = "Rebuild UI",
        Style    = "primary",
        Callback = function()
            Window:Notify({ Title = "Rebuilding…", Duration = 0.5 })
            task.defer(function()
                Window:Destroy()
                task.wait(0.1)
                rebuild()
            end)
        end,
    })

    -- Load notification
    Window:Notify({
        Title    = title .. " loaded",
        Message  = leftN .. "L + " .. rightN .. "R tabs  ·  " .. theme,
        Duration = 3,
        Type     = "success",
    })
end

rebuild = buildRandom

buildRandom()
