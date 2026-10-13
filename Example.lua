--[[
    Ignis v2.5  ·  Example Script
    Shows the full Window → Tab → Section → Element hierarchy,
    plus manager APIs (AnimationManager, ThemeManager, LayoutManager, SaveManager).
--]]

local Ignis = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Ignis/main/Ignis.lua"))()
-- local Ignis = loadstring(readfile("Ignis.lua"))()  -- local loader

-- ── Optional: configure layout before creating the window ──────────────────
-- LayoutManager changes MUST happen before CreateWindow — values are read once
-- at construction time and do not retroactively update existing UI.
local Layout = Ignis:GetLayoutManager()
-- Layout:Set("SidebarW", 160)             -- wider sidebar
-- Layout:Set("RowH", 48)                  -- taller standard rows
-- Layout:Set("FontUI", Enum.Font.Gotham)  -- different UI font
-- Ignis._refreshFonts()                   -- must call after changing Font* tokens

-- ── Optional: configure animation preset before building ───────────────────
local Anim = Ignis:GetAnimationManager()
-- Anim:SetPreset("Snappy")   -- "Default" | "Snappy" | "Smooth" | "Bounce" | "None"
-- Anim:SetSpeed(1.2)         -- multiplier applied to all durations

local Window = Ignis:CreateWindow({
    Title       = "IGNIS",
    SubTitle    = "v2.5 example",
    -- Width / Height override Layout's WindowW / WindowH for this window only:
    Width       = 620,
    Height      = 460,
    Theme       = "Ignis Dark",   -- "Ignis Dark" | "Ignis Crimson" | "Ignis Ember"
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- ── SaveManager setup ─────────────────────────────────────────────────────
local Save = Window:GetSaveManager()
Save:SetFolder("ignis_configs")   -- writefile folder
Save:SetKey("default")            -- default save slot name

-- ── Tab: Combat ────────────────────────────────────────────────────────────
local tabCombat = Window:Tab("Combat")

local secAim = tabCombat:Section("Aimbot")

local togAim = secAim:Toggle({
    Id       = "aimbot_enabled",
    Name     = "Aimbot",
    Default  = false,
    Callback = function(v: boolean)
        print("Aimbot:", v)
    end,
})

local sliSmooth = secAim:Slider({
    Id       = "aimbot_smooth",
    Name     = "Smoothness",
    Min      = 1,
    Max      = 100,
    Default  = 30,
    Step     = 1,
    Callback = function(v: number)
        print("Smooth:", v)
    end,
})

local ddTarget = secAim:Dropdown({
    Id      = "aimbot_target",
    Name    = "Target Part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(v: any)
        print("Target:", v)
    end,
})

local kbAim = secAim:Keybind({
    Id      = "aimbot_key",
    Name    = "Hold Key",
    Default = Enum.KeyCode.E,
    Callback = function(k: Enum.KeyCode)
        print("Aim key:", k.Name)
    end,
})

local secMisc = tabCombat:Section("Misc")

local togSilent = secMisc:Toggle({
    Id          = "silent_aim",
    Name        = "Silent Aim",
    Description = "Routes bullets without moving the camera",
    Default     = false,
})

local togAutoFire = secMisc:Toggle({
    Id      = "auto_fire",
    Name    = "Auto Fire",
    Default = false,
})

-- ── Tab: Player ────────────────────────────────────────────────────────────
local tabPlayer = Window:Tab("Player")

local secMove = tabPlayer:Section("Movement")

local sliSpeed = secMove:Slider({
    Id      = "walk_speed",
    Name    = "WalkSpeed",
    Min     = 16,
    Max     = 250,
    Default = 16,
    Step    = 2,
    Callback = function(v: number)
        local lp = game:GetService("Players").LocalPlayer
        if lp.Character then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

local sliJump = secMove:Slider({
    Id      = "jump_power",
    Name    = "JumpPower",
    Min     = 50,
    Max     = 400,
    Default = 50,
    Step    = 10,
})

local togNoclip = secMove:Toggle({
    Id      = "noclip",
    Name    = "Noclip",
    Default = false,
})

local secVisual = tabPlayer:Section("Visual")

local togEsp = secVisual:Toggle({
    Id      = "esp_enabled",
    Name    = "Player ESP",
    Default = false,
})

local ddEspColor = secVisual:Dropdown({
    Id      = "esp_color",
    Name    = "ESP Color",
    Options = { "White", "Red", "Green", "Blue", "Rainbow" },
    Default = "White",
})

-- ── Tab: Settings ──────────────────────────────────────────────────────────
local tabSettings = Window:Tab("Settings")

local secTheme = tabSettings:Section("Theme")

local ddTheme = secTheme:Dropdown({
    Id      = "theme",
    Name    = "Theme",
    Options = Ignis:GetThemeNames(),
    Default = "Ignis Dark",
    Callback = function(v: any)
        Window:SetTheme(tostring(v))
    end,
})

local secConfig = tabSettings:Section("Config")

local inpCfgName = secConfig:Input({
    Id          = "config_name",
    Name        = "Config Name",
    Default     = "default",
    Placeholder = "my_config",
})

secConfig:Button({
    Id       = "save_cfg",
    Name     = "Save Config",
    Callback = function()
        local name = tostring(inpCfgName:Get())
        -- SaveManager has SetFolder("ignis_configs") from setup above.
        -- Window:SaveToFile(folder, name) ignores the folder arg — use SaveManager directly
        -- for custom folder control: Window:GetSaveManager():SetFolder(folder):Save(name)
        local ok = Save:Save(name)
        Window:Notify({
            Title    = ok and "Saved" or "Save Failed",
            Message  = ok and ("Wrote ignis_configs/" .. name .. ".json") or "writefile not available",
            Duration = 2.5,
        })
    end,
})

secConfig:Button({
    Id       = "load_cfg",
    Name     = "Load Config",
    Callback = function()
        local name = tostring(inpCfgName:Get())
        local ok = Save:Load(name)
        Window:Notify({
            Title    = ok and "Loaded" or "Load Failed",
            Message  = ok and ("Read ignis_configs/" .. name .. ".json") or "File not found",
            Duration = 2.5,
        })
    end,
})

local secLayout = tabSettings:Section("Layout Info")

secLayout:Label({
    Id    = "layout_sidebar_w",
    Name  = "Sidebar Width",
    Value = tostring(Layout:Get("SidebarW")) .. "px",
})

secLayout:Label({
    Id    = "layout_row_h",
    Name  = "Row Height",
    Value = tostring(Layout:Get("RowH")) .. "px",
})

local secInfo = tabSettings:Section()

secInfo:Label({
    Id    = "version_label",
    Name  = "Library Version",
    Value = "v" .. Ignis.Version,
})

secInfo:Paragraph({
    Id    = "info_para",
    Title = "About Ignis",
    Text  = "Ignis is a professional executor UI library. Successor to EmberUI. All elements expose :Get(), :Set(), :Changed(), :SetDisabled() and :SetVisible(). Layout is fully configurable via LayoutManager before window creation.",
})

-- ── Programmatic control ───────────────────────────────────────────────────
-- Every element is registered in Ignis.Options by Id:
--   Ignis.Options.aimbot_enabled:Get()        → boolean
--   Ignis.Options.aimbot_enabled:Set(true)    → fires Changed + visual update
--   local unsub = Ignis.Options.walk_speed:Changed(function(v) print(v) end)
--   unsub()  → unsubscribes
--   Ignis.Options.aimbot_key:Clear()          → resets keybind to Unknown
--   Ignis.Options.noclip:SetDisabled(true)    → greys out the row

-- ── Notifications (can call anywhere) ─────────────────────────────────────
task.delay(1, function()
    Window:Notify({
        Title    = "Ignis loaded",
        Message  = "Press RightShift to minimise.",
        Duration = 3,
    })
end)
