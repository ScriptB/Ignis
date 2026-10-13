local function resolveModule(name: string): any
	local rOk, rMod = pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		local target = (shared and shared:FindFirstChild(name)) or rs:FindFirstChild(name)
		if target then return (require :: any)(target) end
		return nil
	end)
	if rOk and rMod then return rMod end
	local ok, mod = pcall(function()
		return (require :: any)("./" .. name)
	end)
	if ok and mod then
		return mod
	end
	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		local path = name .. ".lua"
		if isfile(path) then
			local readOk, content = pcall(readfile, path)
			if readOk and type(content) == "string" and content ~= "" then
				local chunk = loadstring(content)
				if chunk then
					return chunk()
				end
			end
		end
	end
	local url = "https://raw.githubusercontent.com/ScriptB/Ignis/main/" .. name .. ".lua"
	local fetchOk, fetched = pcall(function()
		return game:HttpGet(url)
	end)
	if fetchOk and type(fetched) == "string" and fetched ~= "" then
		local chunk = loadstring(fetched)
		if chunk then
			return chunk()
		end
	end
	error("Failed to load module: " .. name)
end

local Ignis = resolveModule("Ignis")
local AnimationManager = resolveModule("AnimationManager")(Ignis)
local ThemeManager = resolveModule("ThemeManager")(Ignis)
local SaveManager = resolveModule("SaveManager")(Ignis)
local LayoutManager = Ignis:GetLayoutManager()

local rng = typeof(Random) == "table" and rawget(Random, "new") and Random.new() or nil
local function ri(a: number, b: number): number
	if rng then
		return rng:NextInteger(a, b)
	end
	return math.random(a, b)
end

local function rf(): number
	if rng then
		return rng:NextNumber()
	end
	return math.random()
end

local function pick(t: {any}): any
	return t[ri(1, #t)]
end

local function maybe(p: number): boolean
	return rf() < p
end

local TITLES = { "NEXUS", "CIPHER", "VORTEX", "APEX", "PHANTOM", "IGNIS", "EMBER", "FLARE" }
local SUBTITLES = { "fuzzer", "v3.4.0", "automated", "stress-test", "sandbox" }
local TAB_LEFT = { "Combat", "Movement", "Visual", "Farming", "Misc", "Settings", "Exploit", "Tools", "Aimbot", "ESP", "Player" }
local TAB_RIGHT = { "Config", "Credits", "Debug", "Info", "Utility" }
local SEC_LABELS = { "Aimbot", "Movement", "Visual", "Misc", "Config", "Core", "Advanced", "Extras" }
local NAMES = {
	"Speed Boost", "Auto Farm", "God Mode", "Fly Speed", "Jump Power",
	"Kill Aura", "ESP Range", "Walk Speed", "Inf Stamina", "Fast Attack",
	"Teleport", "No Clip", "Auto Click", "Aim Assist", "Hit Box",
	"Silent Aim", "Radar", "Bhop", "Triggerbot", "Fling",
}
local DESCS = {
	"Enables the feature when active",
	"Adjusts the intensity level",
	"Only applies in game servers",
	"May cause detection — use with care",
	"Experimental — test carefully",
}
local OPT_SETS = {
	{ "Disabled", "Low", "Medium", "High", "Ultra" },
	{ "Off", "On", "Auto" },
	{ "Red", "Green", "Blue", "Yellow", "White" },
	{ "1x", "2x", "5x", "10x", "50x" },
	{ "Slow", "Normal", "Fast", "Instant" },
	{ "None", "Players", "NPCs", "All" },
}
local KEYS = {
	Enum.KeyCode.F1, Enum.KeyCode.F2, Enum.KeyCode.F3,
	Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V,
	Enum.KeyCode.G, Enum.KeyCode.H, Enum.KeyCode.J,
}
local NOTIF_TYPES = { "success", "warning", "info", "error" }
local EASING_STYLES = {
	Enum.EasingStyle.Quad, Enum.EasingStyle.Sine,
	Enum.EasingStyle.Back, Enum.EasingStyle.Bounce,
}

local idCounter = 0
local function uid(): string
	idCounter += 1
	return "fz" .. idCounter
end

local function fuzzLayout()
	LayoutManager:Reset()
	if maybe(0.6) then
		LayoutManager:Set("WindowW", ri(680, 800))
		LayoutManager:Set("WindowH", ri(600, 720))
	end
	if maybe(0.4) then
		LayoutManager:Set("RowH", ri(54, 70))
		LayoutManager:Set("SidebarW", ri(160, 200))
	end
	if maybe(0.3) then
		LayoutManager:Set("HeaderH", ri(56, 72))
	end
	Ignis._refreshFonts()
end

local function fuzzAnimation()
	local presets = AnimationManager:GetPresetNames()
	local chosenPreset = pick(presets)
	AnimationManager:SetPreset(chosenPreset)
	AnimationManager:SetSpeed(0.5 + rf() * 1.5)
	if maybe(0.3) then
		local curve = TweenInfo.new(0.08 + rf() * 0.2, pick(EASING_STYLES), Enum.EasingDirection.Out)
		AnimationManager:SetCurve("Button", curve)
	end
	if maybe(0.3) then
		AnimationManager:SetScope(pick({ "everywhere", "Toggle", "Button", { "Toggle", "Slider" } }))
	end
end

local function fuzzTheme(): string
	if maybe(0.4) then
		local customName = "FuzzPreset" .. ri(1, 999)
		ThemeManager:NewPreset(customName, {
			WinBg = Color3.fromRGB(ri(10, 25), ri(10, 25), ri(15, 30)),
			SliderFill = Color3.fromRGB(ri(180, 255), ri(20, 80), ri(20, 80)),
			RowBg = Color3.fromRGB(ri(14, 22), ri(16, 24), ri(20, 30)),
		})
		ThemeManager:SetTheme(customName)
		return customName
	end
	local themes = ThemeManager:GetThemes()
	local chosenTheme = pick(themes)
	ThemeManager:SetTheme(chosenTheme)
	if maybe(0.3) then
		ThemeManager:Set("SliderFill", Color3.fromRGB(ri(180, 255), ri(20, 100), ri(20, 100)))
	end
	return chosenTheme
end

local function buildRandomToggle(sec: any)
	local id = uid()
	local name = pick(NAMES)
	local desc = maybe(0.3) and pick(DESCS) or nil
	local el = sec:Toggle({
		Id = id,
		Name = name,
		Description = desc,
		Default = maybe(0.5),
		Callback = function(v: boolean)
		end,
	})
	if maybe(0.2) then
		el:Set(not el:Get())
	end
	if maybe(0.15) then
		el:SetDisabled(true)
	end
	return el
end

local function buildRandomSlider(sec: any)
	local id = uid()
	local maxVal = ri(20, 200)
	local defVal = ri(0, maxVal)
	local el = sec:Slider({
		Id = id,
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Min = 0,
		Max = maxVal,
		Step = 1,
		Default = defVal,
		Callback = function(v: number)
		end,
	})
	if maybe(0.2) then
		el:Set(ri(0, maxVal))
	end
	return el
end

local function buildRandomDropdown(sec: any)
	local id = uid()
	local opts = pick(OPT_SETS)
	local isMulti = maybe(0.25)
	local defVal = isMulti and { opts[1] } or opts[1]
	local el = sec:Dropdown({
		Id = id,
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Options = opts,
		Default = defVal,
		Multi = isMulti,
		Callback = function(v: any)
		end,
	})
	if maybe(0.2) then
		el:Set(isMulti and { opts[2] } or opts[2])
	end
	return el
end

local function buildRandomButton(sec: any, isPrimary: boolean)
	return sec:Button({
		Id = uid(),
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Style = isPrimary and "primary" or "normal",
		Callback = function()
		end,
	})
end

local function buildRandomInput(sec: any)
	local id = uid()
	local el = sec:Input({
		Id = id,
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Placeholder = "Enter value...",
		Callback = function(text: string)
		end,
	})
	if maybe(0.2) then
		el:Set("FuzzerValue" .. ri(1, 100))
	end
	return el
end

local function buildRandomKeybind(sec: any)
	local id = uid()
	local el = sec:Keybind({
		Id = id,
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Default = pick(KEYS),
		Callback = function(k: Enum.KeyCode)
		end,
	})
	if maybe(0.2) then
		el:Set(pick(KEYS))
	end
	return el
end

local function buildRandomColorPicker(sec: any)
	local id = uid()
	local el = sec:ColorPicker({
		Id = id,
		Name = pick(NAMES),
		Description = maybe(0.3) and pick(DESCS) or nil,
		Default = Color3.fromRGB(ri(0, 255), ri(0, 255), ri(0, 255)),
		Callback = function(c: Color3)
		end,
	})
	if maybe(0.2) then
		el:Set(Color3.fromRGB(ri(0, 255), ri(0, 255), ri(0, 255)))
	end
	return el
end

local function populateSectionElements(sec: any)
	local count = ri(2, 6)
	for _ = 1, count do
		local kind = ri(1, 9)
		if kind == 1 then
			buildRandomToggle(sec)
		elseif kind == 2 then
			buildRandomSlider(sec)
		elseif kind == 3 then
			buildRandomDropdown(sec)
		elseif kind == 4 then
			buildRandomButton(sec, false)
		elseif kind == 5 then
			buildRandomButton(sec, true)
		elseif kind == 6 then
			buildRandomInput(sec)
		elseif kind == 7 then
			buildRandomKeybind(sec)
		elseif kind == 8 then
			sec:Label({ Id = uid(), Name = pick(NAMES), Value = tostring(ri(10, 9999)) })
		else
			buildRandomColorPicker(sec)
		end
	end
end

local function fuzzSaveSystem(Window: any)
	SaveManager:SetFolder("IgnisFuzzerConfigs")
	local slotKey = "fuzz_slot_" .. ri(1, 5)
	SaveManager:SetKey(slotKey)
	SaveManager:Save()
	local configs = SaveManager:ListConfigs()
	if #configs > 0 and maybe(0.5) then
		SaveManager:Load(pick(configs))
	end
	if maybe(0.3) then
		local data = Window:SaveSettings()
		if type(data) == "table" then
			Window:LoadSettings(data)
		end
	end
end

local rebuildFunction: () -> ()

local function buildControlsSection(tab: any, Window: any, activeTheme: string, leftN: number, rightN: number)
	local ctrl = tab:Section("Fuzzer Controls")
	ctrl:Paragraph({
		Id = uid(),
		Title = "Status",
		Text = string.format("%d Left · %d Right · Theme: %s · Speed: %.1f", leftN, rightN, activeTheme, AnimationManager._speed or 1.0),
	})
	ctrl:Dropdown({
		Id = uid(),
		Name = "Switch Theme",
		Options = ThemeManager:GetThemes(),
		Default = ThemeManager:GetTheme(),
		Callback = function(t: any)
			Window:SetTheme(tostring(t))
		end,
	})
	ctrl:Dropdown({
		Id = uid(),
		Name = "Animation Preset",
		Options = AnimationManager:GetPresetNames(),
		Default = AnimationManager._preset or "Default",
		Callback = function(p: any)
			AnimationManager:SetPreset(tostring(p))
		end,
	})
	local notifIdx = 0
	ctrl:Button({
		Id = uid(),
		Name = "Trigger Notification",
		Callback = function()
			notifIdx = (notifIdx % #NOTIF_TYPES) + 1
			local nType = NOTIF_TYPES[notifIdx]
			Window:Notify({
				Title = "Type: " .. nType,
				Message = "Fuzzer notification dispatch test.",
				Duration = 2.5,
				Type = nType,
			})
		end,
	})
	ctrl:Button({
		Id = uid(),
		Name = "Save Config",
		Callback = function()
			SaveManager:Save("user_slot")
			Window:Notify({ Title = "Config Saved", Duration = 2, Type = "success" })
		end,
	})
	ctrl:Button({
		Id = uid(),
		Name = "Rebuild UI",
		Style = "primary",
		Callback = function()
			Window:Notify({ Title = "Rebuilding...", Duration = 0.5 })
			task.defer(function()
				Window:Destroy()
				task.wait(0.1)
				rebuildFunction()
			end)
		end,
	})
end

local function buildRandomUi()
	if Ignis.Window then
		Ignis.Window:Destroy()
	end
	fuzzLayout()
	fuzzAnimation()
	local activeTheme = fuzzTheme()

	local title = pick(TITLES)
	local leftCount = ri(2, 4)
	local rightCount = ri(1, 2)

	local Window = Ignis:CreateWindow({
		Title = title,
		SubTitle = pick(SUBTITLES),
		Theme = activeTheme,
		MinimizeKey = Enum.KeyCode.RightShift,
	})

	local leftTabs = {}
	local usedTabs = {}
	for i = 1, leftCount do
		local tabName
		repeat
			tabName = pick(TAB_LEFT)
		until not usedTabs[tabName]
		usedTabs[tabName] = true
		leftTabs[i] = Window:Tab(tabName)
	end

	for i = 1, rightCount do
		local rName = TAB_RIGHT[i] or ("Util " .. i)
		local rTab = Window:Tab(rName, { Side = "right" })
		local rSec = rTab:Section(maybe(0.5) and "Settings" or nil)
		buildRandomToggle(rSec)
		buildRandomSlider(rSec)
	end

	for _, tab in ipairs(leftTabs) do
		local secCount = ri(1, 2)
		for _ = 1, secCount do
			local secLabel = maybe(0.6) and pick(SEC_LABELS) or nil
			local sec = tab:Section(secLabel)
			populateSectionElements(sec)
		end
	end

	buildControlsSection(leftTabs[1], Window, activeTheme, leftCount, rightCount)
	fuzzSaveSystem(Window)

	Window:Notify({
		Title = title .. " Ready",
		Message = string.format("%d Left, %d Right tabs initialized.", leftCount, rightCount),
		Duration = 2.0,
		Type = "success",
	})
	return Window
end

rebuildFunction = buildRandomUi
buildRandomUi()
return buildRandomUi
