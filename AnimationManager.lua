local TweenService = game:GetService("TweenService")

local _DEF_DUR: {[string]: number} = {
	Toggle = 0.28,
	ToggleTrack = 0.14,
	Slider = 0.00,
	Button = 0.10,
	ButtonOut = 0.12,
	Tab = 0.14,
	Row = 0.10,
	Window = 0.22,
	Notif = 0.28,
	NotifOut = 0.20,
	Keybind = 0.14,
	Dropdown = 0.10,
	Default = 0.14,
}

local _DEF_STYLE: {[string]: {any}} = {
	Toggle = { Enum.EasingStyle.Back, Enum.EasingDirection.Out },
	ToggleTrack = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Slider = { Enum.EasingStyle.Linear, Enum.EasingDirection.Out },
	Button = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	ButtonOut = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Tab = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Row = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Window = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Notif = { Enum.EasingStyle.Back, Enum.EasingDirection.Out },
	NotifOut = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Keybind = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Dropdown = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
	Default = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
}

local _ANIM_PRESETS: {[string]: {[string]: any}} = {
	Default = {},
	Snappy = {
		Toggle = { dur = 0.15, style = Enum.EasingStyle.Back },
		ToggleTrack = { dur = 0.08 },
		Button = { dur = 0.07 },
		ButtonOut = { dur = 0.08 },
		Tab = { dur = 0.08 },
		Row = { dur = 0.06 },
		Window = { dur = 0.14 },
		Notif = { dur = 0.16, style = Enum.EasingStyle.Back },
		NotifOut = { dur = 0.12 },
		Keybind = { dur = 0.08 },
		Dropdown = { dur = 0.06 },
		Default = { dur = 0.08 },
	},
	Smooth = {
		Toggle = { dur = 0.40, style = Enum.EasingStyle.Sine },
		ToggleTrack = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Button = { dur = 0.16, style = Enum.EasingStyle.Sine },
		ButtonOut = { dur = 0.20, style = Enum.EasingStyle.Sine },
		Tab = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Row = { dur = 0.12, style = Enum.EasingStyle.Sine },
		Window = { dur = 0.32, style = Enum.EasingStyle.Sine },
		Notif = { dur = 0.38, style = Enum.EasingStyle.Sine },
		NotifOut = { dur = 0.28, style = Enum.EasingStyle.Sine },
		Keybind = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Dropdown = { dur = 0.12, style = Enum.EasingStyle.Sine },
		Default = { dur = 0.22, style = Enum.EasingStyle.Sine },
	},
	Bounce = {
		Toggle = { dur = 0.40, style = Enum.EasingStyle.Bounce },
		Button = { dur = 0.20, style = Enum.EasingStyle.Bounce },
		Notif = { dur = 0.36, style = Enum.EasingStyle.Bounce },
	},
	None = {},
}

local function normalizeScope(scope: any): any
	if type(scope) ~= "table" then
		if type(scope) == "string" and scope ~= "everywhere" and not _DEF_DUR[scope] then
			warn("[Ignis:Anim] SetScope: unknown category '" .. scope .. "'")
		end
		return scope
	end
	local hasNumericKey = false
	for k in pairs(scope) do
		if type(k) == "number" then
			hasNumericKey = true
			break
		end
	end
	if not hasNumericKey then
		return scope
	end
	local keyed: {[string]: boolean} = {}
	for _, v in ipairs(scope) do
		local str = tostring(v)
		if not _DEF_DUR[str] then
			warn("[Ignis:Anim] SetScope: unknown category '" .. str .. "'")
		end
		keyed[str] = true
	end
	return keyed
end

local function computeCategoryTween(cat: string, defDur: number, preset: string, speed: number, scope: any): TweenInfo
	local overrides = _ANIM_PRESETS[preset] or {}
	local everywhere = scope == "everywhere"
	local inScope = everywhere
		or (type(scope) == "table" and scope[cat] ~= nil)
		or (type(scope) == "string" and not everywhere and cat == scope)
		or cat == "Default"
	local dur = defDur
	local styleArr = _DEF_STYLE[cat] or { Enum.EasingStyle.Quad, Enum.EasingDirection.Out }
	local style = styleArr[1]
	local dir = styleArr[2]
	if inScope and overrides[cat] then
		local ov = overrides[cat]
		if ov.dur then dur = ov.dur end
		if ov.style then style = ov.style end
		if ov.dir then dir = ov.dir end
	end
	if cat == "Row" or cat == "Dropdown" then
		dur = math.min(dur, 0.12)
	end
	return TweenInfo.new(dur * speed, style, dir)
end

return function(Library: any)
	local Anim: {[string]: TweenInfo} = Library.Anim or {}
	Library.Anim = Anim

	local AnimationManager: any = {
		_preset = "Default",
		_speed = 1.0,
		_enabled = true,
		_scope = "everywhere",
	}

	local function rebuildAnim(preset: string, speed: number, scope: any)
		for cat, defDur in pairs(_DEF_DUR) do
			Anim[cat] = computeCategoryTween(cat, defDur, preset, speed, scope)
		end
	end

	local function executeTween(inst: Instance, props: {[string]: any}, info: TweenInfo?)
		if not AnimationManager._enabled then
			for k, v in pairs(props) do
				pcall(function()
					(inst :: any)[k] = v
				end)
			end
			return
		end
		TweenService:Create(inst, info or Anim.Default, props):Play()
	end

	function AnimationManager:SetEnabled(enabled: boolean)
		self._enabled = enabled
	end

	function AnimationManager:SetSpeed(speed: number)
		assert(type(speed) == "number" and speed > 0, "[Ignis:Anim] Speed must be positive")
		self._speed = speed
		rebuildAnim(self._preset, speed, self._scope)
	end

	function AnimationManager:SetScope(scope: any)
		local resolved = normalizeScope(scope)
		self._scope = resolved
		rebuildAnim(self._preset, self._speed, resolved)
	end

	function AnimationManager:SetPreset(name: string)
		if name == "None" then
			self._enabled = false
			self._preset = name
			return
		end
		local preset = _ANIM_PRESETS[name]
		if not preset then
			warn("[Ignis:Anim] Unknown preset: " .. name)
			return
		end
		self._enabled = true
		self._preset = name
		rebuildAnim(name, self._speed, self._scope)
	end

	function AnimationManager:AddPreset(name: string, cats: {[string]: any})
		assert(type(name) == "string", "[Ignis:Anim] Name must be a string")
		_ANIM_PRESETS[name] = cats
	end

	function AnimationManager:RemovePreset(name: string)
		local locked = { Default = true, Snappy = true, Smooth = true, Bounce = true, None = true }
		if locked[name] then
			warn("[Ignis:Anim] Cannot remove built-in preset")
			return
		end
		_ANIM_PRESETS[name] = nil
	end

	function AnimationManager:GetPresetNames(): {string}
		local names = {}
		for k in pairs(_ANIM_PRESETS) do
			table.insert(names, k)
		end
		table.sort(names)
		return names
	end

	function AnimationManager:SetCategory(cat: string, info: TweenInfo)
		Anim[cat] = info
	end

	function AnimationManager:SetCurve(cat: string, info: TweenInfo)
		Anim[cat] = info
	end

	function AnimationManager:GetCategory(cat: string): TweenInfo?
		return Anim[cat]
	end

	rebuildAnim("Default", 1.0, "everywhere")

	Library._tw = executeTween
	Library.AnimationManager = AnimationManager
	function Library:GetAnimationManager(): any
		return AnimationManager
	end

	return AnimationManager
end
