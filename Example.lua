--[[
    Ignis v3.2  ·  Example Script
    Static reference showing the full API surface:
    Window → Tab → Section → every element type + manager APIs.
--]]

local Ignis = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Ignis/main/Ignis.lua"))()
-- local Ignis = loadstring(readfile("Ignis.lua"))()

-- ── Optional: configure layout before CreateWindow ────────────────────────────
-- These values are read once at construction time — call before CreateWindow.
-- local Layout = Ignis:GetLayoutManager()
-- Layout:Set("SidebarW", 160)
-- Layout:Set("RowH", 48)
-- Ignis._refreshFonts()   -- required after changing any Font* token

-- ── Optional: animation preset ───────────────────────────────────────────────
-- local Anim = Ignis:GetAnimationManager()
-- Anim:SetPreset("Snappy")   -- "Default" | "Snappy" | "Smooth" | "Bounce" | "None"
-- Anim:SetSpeed(1.2)

local Window = Ignis:CreateWindow({
    Title       = "IGNIS",
    SubTitle    = "v3.2",
    Theme       = "Ignis Dark",   -- "Ignis Dark" | "Ignis Crimson" | "Ignis Ember"
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- ── Tab: Combat ───────────────────────────────────────────────────────────────
local tabCombat = Window:Tab("Combat")

local secAim = tabCombat:Section("Aimbot")

secAim:Toggle({
    Id       = "aimbot_enabled",
    Name     = "Aimbot",
    Default  = false,
    Callback = function(v: boolean) print("Aimbot:", v) end,
})

secAim:Slider({
    Id       = "aimbot_smooth",
    Name     = "Smoothness",
    Min      = 1, Max = 100, Default = 30, Step = 1,
    Callback = function(v: number) print("Smooth:", v) end,
})

secAim:Dropdown({
    Id      = "aimbot_target",
    Name    = "Target Part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(v: any) print("Target:", v) end,
})

secAim:Keybind({
    Id      = "aimbot_key",
    Name    = "Hold Key",
    Default = Enum.KeyCode.E,
    Callback = function(k: Enum.KeyCode) print("Aim key:", k.Name) end,
})

local secMisc = tabCombat:Section("Misc")

secMisc:Toggle({
    Id          = "silent_aim",
    Name        = "Silent Aim",
    Description = "Routes bullets without moving the camera",
    Default     = false,
})

secMisc:Toggle({ Id = "auto_fire", Name = "Auto Fire", Default = false })

-- ── Tab: Player ───────────────────────────────────────────────────────────────
local tabPlayer = Window:Tab("Player")

local secMove = tabPlayer:Section("Movement")

secMove:Slider({
    Id      = "walk_speed",
    Name    = "WalkSpeed",
    Min     = 16, Max = 250, Default = 16, Step = 2,
    Callback = function(v: number)
        local lp = game:GetService("Players").LocalPlayer
        if lp.Character then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

secMove:Slider({ Id = "jump_power", Name = "JumpPower", Min = 50, Max = 400, Default = 50, Step = 10 })
secMove:Toggle({ Id = "noclip", Name = "Noclip", Default = false })

local secVisual = tabPlayer:Section("Visual")

secVisual:Toggle({ Id = "esp_enabled", Name = "Player ESP", Default = false })

secVisual:Dropdown({
    Id      = "esp_color",
    Name    = "ESP Color",
    Options = { "White", "Red", "Green", "Blue", "Rainbow" },
    Default = "White",
})

secVisual:ColorPicker({
    Id       = "esp_custom_color",
    Name     = "Custom Color",
    Default  = Color3.fromRGB(255, 255, 255),
    Callback = function(c: Color3) print("Color:", c) end,
})

-- ── Tab: Settings ─────────────────────────────────────────────────────────────
local tabSettings = Window:Tab("Settings")

local secTheme = tabSettings:Section("Theme")

secTheme:Dropdown({
    Id       = "theme",
    Name     = "Theme",
    Options  = Ignis:GetThemeNames(),
    Default  = "Ignis Dark",
    Callback = function(v: any) Window:SetTheme(tostring(v)) end,
})

local secNotif = tabSettings:Section("Notifications")

secNotif:Button({
    Id       = "notif_success",
    Name     = "Success Notify",
    Callback = function()
        Window:Notify({ Title = "Success", Message = "Operation completed.", Duration = 3, Type = "success" })
    end,
})
secNotif:Button({
    Id       = "notif_warning",
    Name     = "Warning Notify",
    Callback = function()
        Window:Notify({ Title = "Warning", Message = "Proceed with caution.", Duration = 3, Type = "warning" })
    end,
})
secNotif:Button({
    Id       = "notif_info",
    Name     = "Info Notify",
    Callback = function()
        Window:Notify({ Title = "Info", Message = "Here is some information.", Duration = 3, Type = "info" })
    end,
})
secNotif:Button({
    Id       = "notif_error",
    Name     = "Error Notify",
    Style    = "primary",
    Callback = function()
        Window:Notify({ Title = "Error", Message = "Something went wrong.", Duration = 3, Type = "error" })
    end,
})

local secConfig = tabSettings:Section("Config")

local inpCfgName = secConfig:Input({
    Id          = "config_name",
    Name        = "Config Name",
    Default     = "default",
    Placeholder = "my_config",
})

local Save = Window:GetSaveManager()
Save:SetFolder("ignis_configs")

secConfig:Button({
    Id       = "save_cfg",
    Name     = "Save Config",
    Callback = function()
        local ok = Save:Save(tostring(inpCfgName:Get()))
        Window:Notify({ Title = ok and "Saved" or "Save Failed", Duration = 2, Type = ok and "success" or "error" })
    end,
})
secConfig:Button({
    Id       = "load_cfg",
    Name     = "Load Config",
    Callback = function()
        local ok = Save:Load(tostring(inpCfgName:Get()))
        Window:Notify({ Title = ok and "Loaded" or "Load Failed", Duration = 2, Type = ok and "success" or "error" })
    end,
})

local secInfo = tabSettings:Section()

secInfo:Label({ Id = "version_label", Name = "Library Version", Value = "v" .. Ignis.Version })

secInfo:Paragraph({
    Id    = "info_para",
    Title = "About Ignis",
    Text  = "Window → Tab → Section → Element hierarchy. All elements expose :Get(), :Set(), :Changed(), :SetDisabled(), :SetVisible(). Layout is configurable via LayoutManager before window creation.",
})

-- ── Right utility tab ─────────────────────────────────────────────────────────
local tabUtil = Window:Tab("Info", { Side = "right" })
local secUtil = tabUtil:Section()
secUtil:Label({ Id = "util_version", Name = "Version", Value = "v" .. Ignis.Version })
secUtil:Label({ Id = "util_theme",   Name = "Theme",   Value = Ignis:GetTheme() })

-- ── Startup notification ──────────────────────────────────────────────────────
task.delay(0.5, function()
    Window:Notify({ Title = "Ignis loaded", Message = "Press RightShift to minimise.", Duration = 3, Type = "success" })
end)
