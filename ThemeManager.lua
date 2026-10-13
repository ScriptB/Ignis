local BASE: {[string]: Color3} = {
	WinBg          = Color3.fromRGB(14, 12, 18),
	HdrTop         = Color3.fromRGB(255, 108, 22),
	HdrMid         = Color3.fromRGB(230, 72, 15),
	HdrBot         = Color3.fromRGB(135, 28, 6),
	HdrBevel       = Color3.fromRGB(165, 38, 8),
	HdrBorder      = Color3.fromRGB(18, 8, 5),
	SidebarBg      = Color3.fromRGB(10, 8, 14),
	SidebarBorder  = Color3.fromRGB(30, 22, 45),
	TabHoverBg     = Color3.fromRGB(255, 108, 22),
	TabActiveBg    = Color3.fromRGB(230, 72, 15),
	TabActiveLeft  = Color3.fromRGB(135, 28, 6),
	TabText        = Color3.fromRGB(255, 255, 255),
	TabTextActive  = Color3.fromRGB(255, 255, 255),
	ContentBg      = Color3.fromRGB(11, 9, 16),
	SectionBg      = Color3.fromRGB(13, 11, 18),
	SectionBorder  = Color3.fromRGB(32, 26, 50),
	SectionBevel   = Color3.fromRGB(165, 38, 8),
	RowBg          = Color3.fromRGB(16, 13, 22),
	RowBgHover     = Color3.fromRGB(22, 18, 32),
	RowBorder      = Color3.fromRGB(40, 32, 60),
	RowBorderOuter = Color3.fromRGB(8, 6, 12),
	Text           = Color3.fromRGB(255, 255, 255),
	TextSub        = Color3.fromRGB(182, 176, 200),
	TextHint       = Color3.fromRGB(108, 98, 130),
	ToggleOn       = Color3.fromRGB(38, 212, 78),
	ToggleOnDark   = Color3.fromRGB(18, 148, 50),
	ToggleOff      = Color3.fromRGB(11, 9, 16),
	NotifSuccess   = Color3.fromRGB(38, 185, 75),
	NotifWarning   = Color3.fromRGB(220, 155, 20),
	NotifInfo      = Color3.fromRGB(55, 145, 230),
	ToggleKnob     = Color3.fromRGB(250, 250, 250),
	SliderTrack    = Color3.fromRGB(11, 9, 16),
	SliderFill     = Color3.fromRGB(230, 72, 15),
	SliderKnob     = Color3.fromRGB(250, 250, 250),
	InputBg        = Color3.fromRGB(9, 7, 14),
	InputBorder    = Color3.fromRGB(32, 26, 50),
	InputText      = Color3.fromRGB(255, 255, 255),
	NotifBg        = Color3.fromRGB(14, 12, 18),
	NotifBorder    = Color3.fromRGB(32, 26, 50),
	NotifBar       = Color3.fromRGB(230, 72, 15),
	ScrollBar      = Color3.fromRGB(75, 60, 105),
	DropdownBg     = Color3.fromRGB(18, 15, 26),
}

local THEME_PRESETS: {[string]: {[string]: Color3}} = {
	["Ignis Dark"] = {},
	["Ignis Crimson"] = {
		HdrTop        = Color3.fromRGB(235, 35, 70),
		HdrMid        = Color3.fromRGB(210, 20, 50),
		HdrBot        = Color3.fromRGB(95, 6, 22),
		HdrBevel      = Color3.fromRGB(95, 8, 24),
		TabActiveBg   = Color3.fromRGB(210, 20, 50),
		TabHoverBg    = Color3.fromRGB(235, 35, 70),
		TabActiveLeft = Color3.fromRGB(210, 20, 50),
		SectionBevel  = Color3.fromRGB(95, 8, 24),
		SliderFill    = Color3.fromRGB(210, 20, 50),
		NotifBar      = Color3.fromRGB(210, 20, 50),
		WinBg         = Color3.fromRGB(14, 12, 16),
		SidebarBg     = Color3.fromRGB(11, 9, 13),
		ContentBg     = Color3.fromRGB(15, 13, 18),
	},
	["Ignis Ember"] = {
		HdrTop        = Color3.fromRGB(255, 135, 30),
		HdrMid        = Color3.fromRGB(248, 98, 22),
		HdrBot        = Color3.fromRGB(160, 45, 8),
		HdrBevel      = Color3.fromRGB(195, 55, 10),
		TabActiveBg   = Color3.fromRGB(248, 98, 22),
		TabHoverBg    = Color3.fromRGB(255, 135, 30),
		TabActiveLeft = Color3.fromRGB(160, 45, 8),
		SectionBevel  = Color3.fromRGB(195, 55, 10),
		SliderFill    = Color3.fromRGB(248, 98, 22),
		NotifBar      = Color3.fromRGB(248, 98, 22),
	},
}

local function applyTokenToInstance(inst: Instance, prop: string, token: string, tokens: {[string]: Color3})
	local val = tokens[token]
	if val then
		pcall(function()
			(inst :: any)[prop] = val
		end)
	end
end

local function applyGradientColor(inst: UIGradient, tokens: {[string]: Color3})
	inst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tokens.HdrTop),
		ColorSequenceKeypoint.new(0.25, tokens.HdrMid),
		ColorSequenceKeypoint.new(0.75, tokens.HdrBevel),
		ColorSequenceKeypoint.new(1, tokens.HdrBot),
	})
end

return function(Library: any)
	local T = Library.T or {}
	Library.T = T
	for k, v in pairs(BASE) do
		if T[k] == nil then
			T[k] = v
		end
	end

	local ThemeManager: any = {
		_current = (THEME_PRESETS[Library._theme or ""] and Library._theme) or "Ignis Dark",
	}

	local function repaintAll()
		local reg = Library.Creator and Library.Creator.Reg or {}
		local grad = Library.Creator and Library.Creator.Grad or {}
		for inst, tag in pairs(reg) do
			if inst.Parent then
				for p, tk in pairs(tag) do
					applyTokenToInstance(inst, p, tk, T)
				end
			end
		end
		for inst in pairs(grad) do
			if inst.Parent then
				applyGradientColor(inst :: UIGradient, T)
			end
		end
	end

	local function notifySubscribers(name: string)
		for _, fn in ipairs(Library._themeSubs or {}) do
			xpcall(fn, debug.traceback, name)
		end
	end

	local _customTokens: {[string]: Color3} = {}

	local function applyTheme(name: string): boolean
		local preset = THEME_PRESETS[name]
		if not preset then
			return false
		end
		ThemeManager._current = name
		Library._theme = name
		for k, v in pairs(BASE) do
			T[k] = v
		end
		for k, v in pairs(preset) do
			T[k] = v
		end
		for k, v in pairs(_customTokens) do
			T[k] = v
		end
		repaintAll()
		notifySubscribers(name)
		return true
	end

	function ThemeManager:SetTheme(name: string)
		if not applyTheme(name) then
			warn("[Ignis:Theme] Unknown theme: " .. name)
		end
	end

	function ThemeManager:GetTheme(): string
		return ThemeManager._current
	end

	function ThemeManager:GetThemes(): {string}
		local names = {}
		for k in pairs(THEME_PRESETS) do
			table.insert(names, k)
		end
		table.sort(names)
		return names
	end

	function ThemeManager:GetThemeNames(): {string}
		return self:GetThemes()
	end

	function ThemeManager:AddTheme(name: string, overrides: {[string]: Color3})
		assert(type(name) == "string", "[Ignis:Theme] Name must be a string")
		THEME_PRESETS[name] = overrides
	end

	function ThemeManager:NewPreset(name: string, overrides: {[string]: Color3})
		self:AddTheme(name, overrides)
	end

	function ThemeManager:RemoveTheme(name: string)
		local locked = { ["Ignis Dark"] = true, ["Ignis Crimson"] = true, ["Ignis Ember"] = true }
		if locked[name] then
			warn("[Ignis:Theme] Cannot remove built-in theme")
			return
		end
		if ThemeManager._current == name then
			warn("[Ignis:Theme] Cannot remove active theme '" .. name .. "'; call SetTheme() with a different theme first")
			return
		end
		THEME_PRESETS[name] = nil
	end

	function ThemeManager:GetToken(token: string): Color3?
		return T[token]
	end

	function ThemeManager:SetToken(token: string, color: Color3)
		_customTokens[token] = color
		T[token] = color
		repaintAll()
	end

	function ThemeManager:Set(token: string, color: Color3)
		self:SetToken(token, color)
	end

	function ThemeManager:Reset()
		local target = THEME_PRESETS[ThemeManager._current] and ThemeManager._current or "Ignis Dark"
		applyTheme(target)
	end

	function ThemeManager:OnChanged(fn: (string) -> ()): () -> ()
		Library._themeSubs = Library._themeSubs or {}
		table.insert(Library._themeSubs, fn)
		return function()
			for i, f in ipairs(Library._themeSubs) do
				if f == fn then
					table.remove(Library._themeSubs, i)
					break
				end
			end
		end
	end

	if Library.Creator then
		Library.Creator.UpdateTheme = repaintAll
	end

	Library._updateTheme = repaintAll
	Library.ThemeManager = ThemeManager
	function Library:GetThemeManager(): any
		return ThemeManager
	end
	function Library:SetTheme(name: string)
		return ThemeManager:SetTheme(name)
	end
	function Library:GetTheme(): string
		return ThemeManager:GetTheme()
	end
	function Library:GetThemeNames(): {string}
		return ThemeManager:GetThemes()
	end

	return ThemeManager
end
