--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                 IGNIS UI FRAMEWORK SHOWCASE                              ║
    ║                                   Complete Feature & Customization Tour                  ║
    ╚══════════════════════════════════════════════════════════════════════════════════════════╝

    Run directly via loadstring in any executor, or paste into Roblox Studio / command bar:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Ignis/main/Ignis.lua"))()
--]]

-- ── 1. Resilient Universal Loader ──────────────────────────────────────────────

local function loadRepo(file: string): any
	local src: string? = nil
	-- A. Executor game:HttpGet
	if typeof(game) == "table" or typeof(game) == "Instance" then
		local ok, res = pcall(function()
			return (game :: any):HttpGet("https://raw.githubusercontent.com/ScriptB/Ignis/main/" .. file)
		end)
		if ok and res and #res > 0 then
			src = res
		end
	end
	-- B. Studio HttpService fallback
	if not src and typeof(game) == "Instance" then
		pcall(function()
			local hs = game:GetService("HttpService")
			if hs then
				local ok, res = pcall(function()
					return hs:GetAsync("https://raw.githubusercontent.com/ScriptB/Ignis/main/" .. file)
				end)
				if ok and res and #res > 0 then
					src = res
				end
			end
		end)
	end
	-- C. Local executor / filesystem readfile fallback
	if not src and typeof(readfile) == "function" then
		for _, path in ipairs({ file, "D:/Project Nano/Ignis/" .. file }) do
			local okF, content = pcall(readfile, path)
			if okF and content and #content > 0 then
				src = content
				break
			end
		end
	end
	if src then
		local fn, err = loadstring(src)
		if fn then
			return fn()
		end
		warn("[Ignis Showcase] Compile error in " .. file .. ": " .. tostring(err))
	end
	return nil
end

local Ignis = (typeof(getgenv) == "function" and getgenv().Ignis) or loadRepo("Ignis.lua")
if not Ignis then
	error("[Ignis Showcase] Failed to load Ignis UI library via loadstring!")
end

-- Load Companion Managers
local AnimManagerFn = loadRepo("AnimationManager.lua")
if AnimManagerFn then pcall(AnimManagerFn, Ignis) end

local ThemeManagerFn = loadRepo("ThemeManager.lua")
if ThemeManagerFn then pcall(ThemeManagerFn, Ignis) end

local SaveManagerFn = loadRepo("SaveManager.lua")
if SaveManagerFn then pcall(SaveManagerFn, Ignis) end

-- ── 2. Clean Up Prior Active Session ──────────────────────────────────────────

if Ignis.Window then
	pcall(function() Ignis.Window:Destroy() end)
	Ignis.Window = nil
end

-- ── 3. Layout Configuration (Pre-CreateWindow Customization) ───────────────────

local Layout = Ignis:GetLayoutManager()
if Layout then
	-- Demonstrating LayoutManager runtime customization:
	-- Custom token sizing (e.g. adjust window proportions)
	Layout:Set("WindowW", 760)
	Layout:Set("WindowH", 500)
end

-- ── 4. Window Construction ─────────────────────────────────────────────────────

local Window = Ignis:CreateWindow({
	Title             = "IGNIS SHOWCASE",
	SubTitle          = "v3.4.0 · Complete Tour",
	Width             = 760,
	Height            = 500,
	Theme             = "Ignis Dark",               -- "Ignis Dark" | "Ignis Crimson" | "Ignis Ember"
	MinimizeKey       = Enum.KeyCode.RightShift,    -- Reopens from minimized pill
	SearchPlaceholder = "Search all showcase controls...",
})

-- ── 5. Setup SaveManager State ────────────────────────────────────────────────

local Save = Window:GetSaveManager()
if Save then
	Save:SetFolder("IgnisShowcaseConfigs")
	Save:SetKey("showcase_default")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LEFT SIDEBAR TABS (Primary Workflows)
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- TAB 1: CORE CONTROLS
-- ──────────────────────────────────────────────────────────────────────────────
local tabCore = Window:AddTab("Core Controls")

local secToggles = tabCore:AddSection("Toggles & Switches")

local tog1 = secToggles:AddToggle({
	Id          = "demo_toggle_basic",
	Name        = "Basic Toggle Switch",
	Description = "Standard 1:1 dark toggle track with sliding white knob",
	Default     = true,
	Callback    = function(state: boolean)
		Window:Notify({
			Title    = "Toggle Changed",
			Message  = "Basic toggle is now: " .. (state and "ENABLED" or "DISABLED"),
			Duration = 1.5,
			Type     = state and "success" or "warning",
		})
	end,
})

local togDisabled = secToggles:AddToggle({
	Id          = "demo_toggle_disabled",
	Name        = "Disabled State Demo",
	Description = "Demonstrates programmatic :SetDisabled(true)",
	Default     = false,
})
togDisabled:SetDisabled(true)

local secSliders = tabCore:AddSection("Sliders & Steppers")

local lblSpeedVal: any = nil

local slider1 = secSliders:AddSlider({
	Id          = "demo_slider_walk",
	Name        = "WalkSpeed Multiplier",
	Description = "Snaps dynamically to 1-unit intervals",
	Min         = 16,
	Max         = 250,
	Step        = 1,
	Default     = 32,
	Callback    = function(val: number)
		if lblSpeedVal then
			lblSpeedVal:Set(string.format("%d studs/sec", val))
		end
	end,
})

local sliderSmooth = secSliders:AddSlider({
	Id          = "demo_slider_smooth",
	Name        = "Smoothing Factor",
	Description = "Precise fine-grained step increments",
	Min         = 0.1,
	Max         = 5.0,
	Step        = 0.1,
	Default     = 1.5,
})

local secDropdowns = tabCore:AddSection("Dropdown Selectors")

local dropSingle = secDropdowns:AddDropdown({
	Id          = "demo_drop_single",
	Name        = "Target Hitbox",
	Description = "Single-select dropdown with animated chevron",
	Values      = { "Head", "UpperTorso", "HumanoidRootPart", "Random Part" },
	Default     = "Head",
	Callback    = function(selected: string)
		Window:Notify({
			Title    = "Target Updated",
			Message  = "Selected target: " .. selected,
			Duration = 1.5,
			Type     = "info",
		})
	end,
})

local dropMulti = secDropdowns:AddDropdown({
	Id          = "demo_drop_multi",
	Name        = "Active ESP Highlights",
	Description = "Multi-select dropdown with combined readout",
	Values      = { "Box 2D", "Nametags", "Tracers", "Healthbar", "Chams" },
	Default     = { "Box 2D", "Nametags" },
	Multi       = true,
	Callback    = function(selectedList: {string})
		print("[Showcase] ESP list:", table.concat(selectedList, ", "))
	end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- TAB 2: ADVANCED CONTROLS
-- ──────────────────────────────────────────────────────────────────────────────
local tabAdvanced = Window:AddTab("Advanced")

local secCompound = tabAdvanced:AddSection("Compound Inputs")

-- 1:1 Match to the original TemplateHub Feature 4!
local comp1 = secCompound:AddCompound({
	Id           = "demo_compound_1",
	Name         = "Compound Multiplier",
	Description  = "Cycles unit pill on click + accepts direct numeric text input",
	Units        = { "Unit", "x1", "x10", "Max", "%" },
	DefaultUnit  = "x1",
	DefaultValue = "25",
	Callback     = function(unit: string, value: string)
		Window:Notify({
			Title    = "Compound Updated",
			Message  = string.format("Unit: [%s] | Value: %s", unit, value),
			Duration = 2.0,
			Type     = "info",
		})
	end,
})

local compDelay = secCompound:AddCompound({
	Id           = "demo_compound_delay",
	Name         = "Action Cooldown",
	Description  = "Switch between seconds and milliseconds",
	Units        = { "s", "ms", "ticks" },
	DefaultUnit  = "s",
	DefaultValue = "5",
})

local secInputs = tabAdvanced:AddSection("Text Inputs")

local input1 = secInputs:AddInput({
	Id          = "demo_input_custom",
	Name        = "Custom Identifier",
	Description = "Input with border glow focus transition",
	Placeholder = "Enter player name or tag...",
	MaxLength   = 32,
	Callback    = function(text: string)
		print("[Showcase] Input submitted:", text)
	end,
})

local secKeybinds = tabAdvanced:AddSection("Keybinds")

local key1 = secKeybinds:AddKeybind({
	Id          = "demo_keybind_trigger",
	Name        = "Toggle Fly Key",
	Description = "Click pill to rebind; press Escape to clear",
	Default     = Enum.KeyCode.F,
	Callback    = function(k: Enum.KeyCode)
		Window:Notify({
			Title    = "Keybind Bound",
			Message  = "New key: " .. k.Name,
			Duration = 1.5,
			Type     = "info",
		})
	end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- TAB 3: DISPLAY & MEDIA
-- ──────────────────────────────────────────────────────────────────────────────
local tabDisplay = Window:AddTab("Display & Media")

local secColor = tabDisplay:AddSection("Color Pickers")

local cp1 = secColor:AddColorPicker({
	Id          = "demo_color_accent",
	Name        = "Theme Accent Color",
	Description = "Interactive RGB slider swatch with live Hex code",
	Default     = Color3.fromRGB(40, 215, 80),
	Callback    = function(c: Color3)
		print(string.format("[Showcase] Color picked: RGB(%d, %d, %d)", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)))
	end,
})

local secLabels = tabDisplay:AddSection("Dynamic Labels")

lblSpeedVal = secLabels:AddLabel({
	Id    = "lbl_walk_status",
	Name  = "Live WalkSpeed",
	Value = "32 studs/sec",
})

local lblTime = secLabels:AddLabel({
	Id    = "lbl_server_time",
	Name  = "Session Uptime",
	Value = "0s",
})

-- Live uptime counter demonstrating programmatic el:Set(v)
task.spawn(function()
	local elapsed = 0
	while Window and not Window:IsDestroyed() do
		task.wait(1)
		elapsed += 1
		local m = math.floor(elapsed / 60)
		local s = elapsed % 60
		lblTime:Set(string.format("%dm %02ds", m, s))
	end
end)

local secParagraphs = tabDisplay:AddSection("Rich Paragraphs")

local paraDoc = secParagraphs:AddParagraph({
	Id    = "demo_para_intro",
	Title = "Architecture Overview",
	Text  = "Ignis is engineered from scratch as a modular Luau UI library. It delivers 1:1 pixel accuracy to the original red-accented beveled Studio layout with zero external asset dependencies, zero top-level local bloat, and full multi-manager companion extensibility.",
})

-- ──────────────────────────────────────────────────────────────────────────────
-- TAB 4: ACTIONS & TRIGGERS
-- ──────────────────────────────────────────────────────────────────────────────
local tabActions = Window:AddTab("Action Triggers")

local secButtons = tabActions:AddSection("Button Styles")

secButtons:AddButton({
	Id          = "btn_standard_demo",
	Name        = "Standard Button",
	Description = "Micro-animates hover and click feedback",
	Callback    = function()
		Window:Notify({
			Title    = "Action Executed",
			Message  = "Standard button click handler was dispatched.",
			Duration = 2.0,
			Type     = "info",
		})
	end,
})

secButtons:AddButton({
	Id          = "btn_primary_demo",
	Name        = "Primary Accent Button",
	Description = "Highlighted with primary brand color styling",
	Style       = "primary",
	Callback    = function()
		Window:Notify({
			Title    = "Primary Action",
			Message  = "Primary trigger activated with glowing feedback!",
			Duration = 2.5,
			Type     = "success",
		})
	end,
})

local secNotifTour = tabActions:AddSection("Notification System")

secNotifTour:AddButton({
	Id       = "notif_btn_success",
	Name     = "Dispatch: Success Toast",
	Callback = function()
		Window:Notify({ Title = "Operation Complete", Message = "All items processed successfully.", Duration = 2.5, Type = "success" })
	end,
})

secNotifTour:AddButton({
	Id       = "notif_btn_warning",
	Name     = "Dispatch: Warning Toast",
	Callback = function()
		Window:Notify({ Title = "Low Energy Warning", Message = "Player energy is below 15%. Recharge soon.", Duration = 3.0, Type = "warning" })
	end,
})

secNotifTour:AddButton({
	Id       = "notif_btn_info",
	Name     = "Dispatch: Information Toast",
	Callback = function()
		Window:Notify({ Title = "New Update Available", Message = "Ignis UI v3.4 is active.", Duration = 2.5, Type = "info" })
	end,
})

secNotifTour:AddButton({
	Id       = "notif_btn_error",
	Name     = "Dispatch: Error Toast",
	Style    = "primary",
	Callback = function()
		Window:Notify({ Title = "Action Rejected", Message = "Target is outside interaction range.", Duration = 3.0, Type = "error" })
	end,
})


-- ══════════════════════════════════════════════════════════════════════════════
-- RIGHT SIDEBAR UTILITY TABS (Specialized Managers & Utilities)
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- UTILITY TAB 1: THEME MANAGER
-- ──────────────────────────────────────────────────────────────────────────────
local tabTheme = Window:AddTab("Theme", { Side = "right" })

local secThemeOpt = tabTheme:AddSection("Visual Appearance")

local TM = Window:GetThemeManager()
if TM then
	secThemeOpt:AddDropdown({
		Id       = "theme_preset_selector",
		Name     = "Active Theme",
		Values   = TM:GetThemes(),
		Default  = TM:GetTheme(),
		Callback = function(themeName: string)
			Window:SetTheme(themeName)
			Window:Notify({
				Title    = "Theme Changed",
				Message  = "Applied visual palette: " .. themeName,
				Duration = 2.0,
				Type     = "info",
			})
		end,
	})
else
	secThemeOpt:AddLabel({ Id = "lbl_no_tm", Name = "ThemeManager", Value = "Standalone Mode" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- UTILITY TAB 2: ANIMATIONS
-- ──────────────────────────────────────────────────────────────────────────────
local tabAnim = Window:AddTab("Animations", { Side = "right" })

local secAnimCtrl = tabAnim:AddSection("Tween Engine")

local AM = Window:GetAnimManager()
if AM then
	secAnimCtrl:AddDropdown({
		Id       = "anim_preset_selector",
		Name     = "Motion Preset",
		Values   = AM:GetPresetNames(),
		Default  = AM._preset or "Default",
		Callback = function(presetName: string)
			AM:SetPreset(presetName)
			Window:Notify({
				Title    = "Animation Preset",
				Message  = "Physics set to: " .. presetName,
				Duration = 1.8,
				Type     = "info",
			})
		end,
	})

	secAnimCtrl:AddSlider({
		Id       = "anim_speed_slider",
		Name     = "Animation Speed",
		Min      = 0.5,
		Max      = 3.0,
		Step     = 0.1,
		Default  = 1.0,
		Callback = function(spd: number)
			AM:SetSpeed(spd)
		end,
	})
else
	secAnimCtrl:AddLabel({ Id = "lbl_no_am", Name = "AnimationManager", Value = "Core Tween Mode" })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- UTILITY TAB 3: CONFIG / SAVE MANAGER
-- ──────────────────────────────────────────────────────────────────────────────
local tabConfig = Window:AddTab("Config", { Side = "right" })

local secProfiles = tabConfig:AddSection("Configuration Profiles")

local inpSlot = secProfiles:AddInput({
	Id          = "config_slot_name",
	Name        = "Profile Name",
	Default     = "my_profile",
	Placeholder = "Enter profile name...",
})

secProfiles:AddButton({
	Id       = "btn_save_profile",
	Name     = "Save Current Config",
	Style    = "primary",
	Callback = function()
		if Save then
			local slot = tostring(inpSlot:Get())
			local ok = Save:Save(slot)
			Window:Notify({
				Title    = ok and "Config Saved" or "Save Failed",
				Message  = ok and ("Written to: " .. slot) or "Could not serialize settings",
				Duration = 2.5,
				Type     = ok and "success" or "error",
			})
		else
			Window:Notify({ Title = "SaveManager Unavailable", Duration = 2, Type = "warning" })
		end
	end,
})

secProfiles:AddButton({
	Id       = "btn_load_profile",
	Name     = "Load Config",
	Callback = function()
		if Save then
			local slot = tostring(inpSlot:Get())
			local ok = Save:Load(slot)
			Window:Notify({
				Title    = ok and "Config Loaded" or "Profile Not Found",
				Message  = ok and ("Restored settings from: " .. slot) or "Specified file does not exist",
				Duration = 2.5,
				Type     = ok and "success" or "error",
			})
		else
			Window:Notify({ Title = "SaveManager Unavailable", Duration = 2, Type = "warning" })
		end
	end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- UTILITY TAB 4: ABOUT & CONTROLS
-- ──────────────────────────────────────────────────────────────────────────────
local tabAbout = Window:AddTab("About", { Side = "right" })

local secAbout = tabAbout:AddSection("Information")

secAbout:AddParagraph({
	Id    = "para_about_info",
	Title = "Ignis Framework v3.4.0",
	Text  = "Built for high performance, executor compatibility, and pixel-accurate visuals. Includes custom drag kinematics, accordion collapse, live search filtering, and modular companion managers.",
})

secAbout:AddButton({
	Id       = "btn_destroy_showcase",
	Name     = "Close & Unload Showcase",
	Style    = "primary",
	Callback = function()
		Window:Notify({ Title = "Unloading Showcase...", Duration = 1.0, Type = "info" })
		task.delay(0.5, function()
			Window:Destroy()
		end)
	end,
})

-- ── 6. Initial Welcome Toast Notification ─────────────────────────────────────

Window:Notify({
	Title    = "IGNIS SHOWCASE READY",
	Message  = "Loaded all controls. Press [Right-Shift] to minimize or reopen.",
	Duration = 3.5,
	Type     = "success",
})

return Window
