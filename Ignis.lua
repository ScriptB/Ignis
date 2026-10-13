--!strict
--[[
╔══════════════════════════════════════════════════════════════════╗
║  IGNIS  ·  v2.5.3  ·  Script UI Library                         ║
║  Successor to Ember. Built for live Roblox environments.         ║
║  Architecture: Library → Window → Tab → Section → Element       ║
║  Managers: AnimationManager · ThemeManager · LayoutManager       ║
║             SaveManager (window-scoped)                          ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ── Services ──────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

-- ── Maid ──────────────────────────────────────────────────────────────────
local Maid = {}
Maid.__index = Maid
function Maid.new()
	return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end
local function _cleanTask(t: any)
	local k = typeof(t)
	if k == "function"                then t()
	elseif k == "RBXScriptConnection" then t:Disconnect()
	elseif k == "Instance"            then if t.Parent then t:Destroy() end
	elseif k == "Tween"               then t:Cancel()
	end
end
function Maid:Give(task: any): any
	if self._destroyed then _cleanTask(task); return task end
	table.insert(self._tasks, task); return task
end
function Maid:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for i = #self._tasks, 1, -1 do _cleanTask(self._tasks[i]); self._tasks[i] = nil :: any end
end

-- ── Security ──────────────────────────────────────────────────────────────
local function _getGenv(): any
	return (typeof(getgenv) == "function" and getgenv()) or {}
end
local function SafeParentGui(gui: ScreenGui)
	gui.DisplayOrder = 999; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local genv    = _getGenv()
	local protect = rawget(genv, "protectgui")
		or (rawget(genv, "syn") and (genv.syn :: any).protect_gui)
	if protect then pcall(protect, gui) end
	local gh = rawget(genv, "gethui")
	if gh then
		local ok, hui = pcall(gh)
		if ok and hui then gui.Parent = hui; return end
	end
	local ok, cg = pcall(game.GetService, game, "CoreGui")
	if ok and cg then pcall(function() gui.Parent = cg end) end
end

-- ── LayoutManager ─────────────────────────────────────────────────────────
-- All structural constants live here. Elements read L.* at construction time.
-- Set/Apply warn if called after CreateWindow — changes won't affect built UI.

local L = {
	-- Window
	WindowW                  = 620,
	WindowH                  = 460,
	HeaderH                  = 52,
	SidebarW                 = 140,
	TitleSize                = 28,
	SubtitleSize             = 11,
	TitleStrokeW             = 2.2,
	HeaderBtnSize            = 28,   -- close / minimize button square side
	HeaderBtnRightPad        = 10,   -- right margin from window edge to close button
	HeaderBtnGap             = 6,    -- gap between close and minimize button
	HeaderTitlePadL          = 16,   -- left margin of title text in header
	SubtitlePadL             = 18,   -- left margin of subtitle text in header
	SubtitleBottomPad        = 8,    -- subtitle Y offset above header bottom edge
	CloseIconSize            = 14,
	MinIconSize              = 12,
	-- Sidebar / tabs
	TabH                     = 36,
	TabTextSize              = 13,
	TabAccentW               = 3,
	TabLabelIndent           = 12,   -- left indent of text label inside a tab button
	TabListPad               = 2,
	SidebarPadTop            = 6,
	SidebarPadH              = 4,
	-- Section / page
	SectionHeaderH           = 26,
	SectionHeaderTextSize    = 10,
	SectionLabelIndent       = 12,   -- left indent of text inside the section header strip
	BevelSize                = 4,
	PageSectionGap           = 6,
	PagePad                  = 8,
	RowListPad               = 1,
	-- Row
	RowH                     = 44,
	RowHDesc                 = 56,
	RowHLabel                = 36,
	RowIndent                = 10,
	LabelPad                 = 6,    -- added to text size to get label frame height
	ElemRightPad             = 10,   -- right margin for right-anchored element widgets (toggle, pill, value label, chevron, etc.)
	-- Paragraph
	ParagraphItemGap         = 4,    -- UIListLayout gap between title and body inside a Paragraph
	-- Slider
	SliderRowH               = 56,
	SliderRowHDesc           = 68,
	SliderTrackH             = 6,
	SliderKnobS              = 13,
	SliderTrackY             = 38,
	SliderTrackYD            = 50,
	SliderTrackRightPad      = 20,   -- pixels trimmed from slider track right edge (leaves room for value label)
	SliderValLabelW          = 64,   -- width of the value readout label on the right
	SliderValLabelH          = 16,   -- height of the value readout label
	SliderValLabelY          = 2,    -- Y offset of the value readout label from rowInner top
	-- Input
	InputRowH                = 56,
	InputRowHDesc            = 72,
	InputBoxH                = 22,
	InputBoxBottomPad        = 7,    -- pixels from rowInner bottom to input box bottom
	InputPadH                = 6,
	-- Toggle
	ToggleW                  = 46,
	ToggleH                  = 22,
	ToggleKnobS              = 16,
	ToggleKnobMargin         = 3,    -- pixels between knob edge and track wall at either end
	-- Dropdown
	DropdownOptH             = 28,
	DropdownOptPadL          = 10,   -- left padding inside each dropdown option button
	DropdownChevronSize      = 10,   -- ∨ text size
	DropdownChevronContainerS = 12,  -- ∨ container square side
	DropdownChevronRightPad  = 8,    -- right margin of ∨ from rowInner right edge
	DropdownLabelH           = 14,   -- height of the current-value display label
	DropdownLabelRightPad    = 22,   -- right margin of current-value display label
	-- Button chevron
	BtnChevronSize           = 18,   -- › text size
	BtnChevronW              = 16,   -- › container width
	BtnChevronH              = 20,   -- › container height
	-- Keybind pill
	KeybindPillW             = 72,
	KeybindPillH             = 22,
	-- Stroke widths
	StrokeRoot               = 2.8,
	StrokeHdr                = 2.8,
	StrokeClose              = 1.8,
	StrokeSidebar            = 1.5,
	StrokeTabBtn             = 1.2,
	StrokeSection            = 1.8,
	StrokeRow                = 1.0,
	StrokeToggle             = 1.4,
	StrokePanel              = 1.2,
	StrokeInput              = 1.0,
	StrokeNotif              = 1.5,
	-- Fonts (Enum.Font members)
	FontTitle                = Enum.Font.LuckiestGuy,
	FontTab                  = Enum.Font.FredokaOne,
	FontUI                   = Enum.Font.GothamMedium,
	FontBold                 = Enum.Font.GothamBold,
	-- Element text sizes
	ElemNameSize             = 13,
	ElemDescSize             = 11,
	ElemValueSize            = 12,
	-- Notification
	NotifW                   = 290,
	NotifH                   = 68,
	NotifGap                 = 6,
	NotifEdge                = 16,
	NotifBarW                = 3,
	NotifInnerPadL           = 12,
	NotifInnerPadR           = 2,    -- right padding of notification inner frame
	NotifTitleY              = 10,   -- Y offset of title text within notification card
	NotifMsgGapY             = 2,    -- vertical gap between title and message text
	NotifMsgBottomPad        = 4,    -- bottom padding of message label within card
	-- Misc
	ScrollBarThick           = 4,
}

local _L_DEFAULTS: {[string]: any} = {}
do for k, v in pairs(L) do _L_DEFAULTS[k] = v end end

local _windowBuilt = false

-- Live-update refs: populated by CreateWindow, cleared by Destroy.
-- Structural tokens in _LIVE_TOKENS update these frames immediately when Set() is
-- called post-build. All other tokens still require a Destroy + CreateWindow cycle.
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
		r.header.Size = UDim2.new(1, 0, 0, L.HeaderH)
		r.body.Position = UDim2.new(0, 0, 0, L.HeaderH)
		r.body.Size = UDim2.new(1, 0, 1, -L.HeaderH)
	elseif key == "SidebarW" then
		r.sidebar.Size = UDim2.new(0, L.SidebarW, 1, 0)
		r.content.Position = UDim2.new(0, L.SidebarW, 0, 0)
		r.content.Size = UDim2.new(1, -L.SidebarW, 1, 0)
	end
end

local LayoutManager: any = {}

function LayoutManager:Set(key: string, value: any)
	assert(L[key] ~= nil, "[Ignis:Layout] Unknown key: " .. tostring(key))
	L[key] = value
	if _windowBuilt then
		if _LIVE_TOKENS[key] then
			_applyLiveToken(key)
		else
			warn("[Ignis:Layout] Set('" .. key .. "') after CreateWindow — takes effect on next CreateWindow")
		end
	end
end
function LayoutManager:Get(key: string): any return L[key] end
function LayoutManager:Apply(overrides: {[string]: any})
	for k, v in pairs(overrides) do
		if L[k] ~= nil then
			L[k] = v
			if _windowBuilt then
				if _LIVE_TOKENS[k] then
					_applyLiveToken(k)
				else
					warn("[Ignis:Layout] Apply: '" .. k .. "' takes effect on next CreateWindow")
				end
			end
		else
			warn("[Ignis:Layout] Unknown key ignored: " .. tostring(k))
		end
	end
end
function LayoutManager:Reset()
	for k, v in pairs(_L_DEFAULTS) do L[k] = v end
end

-- ── Animation layer ───────────────────────────────────────────────────────
local _animEnabled = true

local _DEF_DUR: {[string]: number} = {
	Toggle = 0.28, ToggleTrack = 0.14, Slider = 0.00,
	Button = 0.10, ButtonOut = 0.12,   Tab    = 0.14,
	Row    = 0.10, Window    = 0.22,   Notif  = 0.28,
	NotifOut = 0.20, Keybind = 0.14, Dropdown = 0.10, Default = 0.14,
}
local _DEF_STYLE: {[string]: {any}} = {
	Toggle      = { Enum.EasingStyle.Back,   Enum.EasingDirection.Out },
	ToggleTrack = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Slider      = { Enum.EasingStyle.Linear, Enum.EasingDirection.Out },
	Button      = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	ButtonOut   = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Tab         = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Row         = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Window      = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Notif       = { Enum.EasingStyle.Back,   Enum.EasingDirection.Out },
	NotifOut    = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Keybind     = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Dropdown    = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
	Default     = { Enum.EasingStyle.Quad,   Enum.EasingDirection.Out },
}
local _ANIM_PRESETS: {[string]: {[string]: any}} = {
	Default = {},
	Snappy  = {
		Toggle      = { dur = 0.15, style = Enum.EasingStyle.Back },
		ToggleTrack = { dur = 0.08 }, Button  = { dur = 0.07 }, ButtonOut = { dur = 0.08 },
		Tab         = { dur = 0.08 }, Row     = { dur = 0.06 }, Window    = { dur = 0.14 },
		Notif       = { dur = 0.16, style = Enum.EasingStyle.Back }, NotifOut = { dur = 0.12 },
		Keybind     = { dur = 0.08 }, Dropdown = { dur = 0.06 }, Default  = { dur = 0.08 },
	},
	Smooth  = {
		Toggle      = { dur = 0.40, style = Enum.EasingStyle.Sine },
		ToggleTrack = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Button      = { dur = 0.16, style = Enum.EasingStyle.Sine },
		ButtonOut   = { dur = 0.20, style = Enum.EasingStyle.Sine },
		Tab         = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Row         = { dur = 0.12, style = Enum.EasingStyle.Sine },
		Window      = { dur = 0.32, style = Enum.EasingStyle.Sine },
		Notif       = { dur = 0.38, style = Enum.EasingStyle.Sine },
		NotifOut    = { dur = 0.28, style = Enum.EasingStyle.Sine },
		Keybind     = { dur = 0.22, style = Enum.EasingStyle.Sine },
		Dropdown    = { dur = 0.12, style = Enum.EasingStyle.Sine },
		Default     = { dur = 0.22, style = Enum.EasingStyle.Sine },
	},
	Bounce  = {
		Toggle = { dur = 0.40, style = Enum.EasingStyle.Bounce },
		Button = { dur = 0.20, style = Enum.EasingStyle.Bounce },
		Notif  = { dur = 0.36, style = Enum.EasingStyle.Bounce },
	},
	None    = {},
}
local Anim: {[string]: TweenInfo} = {}
local function _rebuildAnim(preset: string, speed: number, scope: any)
	local overrides  = _ANIM_PRESETS[preset] or {}
	local everywhere = scope == "everywhere"
	for cat, defDur in pairs(_DEF_DUR) do
		local inScope = everywhere
			or (type(scope) == "table" and (scope :: {string})[cat] ~= nil)
			or (type(scope) == "string" and not everywhere and cat == scope)
			or cat == "Default"
		local dur   = defDur
		local sArr  = _DEF_STYLE[cat] or { Enum.EasingStyle.Quad, Enum.EasingDirection.Out }
		local style = sArr[1]; local dir = sArr[2]
		if inScope and overrides[cat] then
			local ov = overrides[cat]
			if ov.dur   then dur   = ov.dur  end
			if ov.style then style = ov.style end
			if ov.dir   then dir   = ov.dir   end
		end
		if cat == "Row" or cat == "Dropdown" then dur = math.min(dur, 0.12) end
		Anim[cat] = TweenInfo.new(dur * speed, style, dir)
	end
end
_rebuildAnim("Default", 1.0, "everywhere")

local function tw(inst: Instance, props: {[string]: any}, info: TweenInfo?)
	if not _animEnabled then
		for k, v in pairs(props) do pcall(function() (inst :: any)[k] = v end) end
		return
	end
	TweenService:Create(inst, info or Anim.Default, props):Play()
end

-- ── Theme tokens ──────────────────────────────────────────────────────────
local BASE: {[string]: Color3} = {
	WinBg          = Color3.fromRGB(13,14,16),
	HdrTop         = Color3.fromRGB(255,60,60),
	HdrMid         = Color3.fromRGB(224,32,32),
	HdrBot         = Color3.fromRGB(110,10,10),
	HdrBevel       = Color3.fromRGB(100,12,12),
	HdrBorder      = Color3.fromRGB(0,0,0),
	SidebarBg      = Color3.fromRGB(10,11,14),
	SidebarBorder  = Color3.fromRGB(0,0,0),
	TabHoverBg     = Color3.fromRGB(22,24,30),
	TabActiveBg    = Color3.fromRGB(26,28,36),
	TabActiveLeft  = Color3.fromRGB(224,32,32),
	TabText        = Color3.fromRGB(140,144,164),
	TabTextActive  = Color3.fromRGB(235,238,248),
	ContentBg      = Color3.fromRGB(14,15,18),
	SectionBg      = Color3.fromRGB(18,20,25),
	SectionBorder  = Color3.fromRGB(0,0,0),
	SectionBevel   = Color3.fromRGB(100,12,12),
	RowBg          = Color3.fromRGB(15,17,21),
	RowBgHover     = Color3.fromRGB(20,22,28),
	RowBorder      = Color3.fromRGB(30,34,44),
	RowBorderOuter = Color3.fromRGB(0,0,0),
	Text           = Color3.fromRGB(232,236,248),
	TextSub        = Color3.fromRGB(148,154,175),
	TextHint       = Color3.fromRGB(85,90,108),
	ToggleOn       = Color3.fromRGB(38,212,78),
	ToggleOnDark   = Color3.fromRGB(18,148,50),
	ToggleOff      = Color3.fromRGB(40,44,56),
	ToggleKnob     = Color3.fromRGB(255,255,255),
	SliderTrack    = Color3.fromRGB(26,29,38),
	SliderFill     = Color3.fromRGB(224,32,32),
	SliderKnob     = Color3.fromRGB(255,255,255),
	InputBg        = Color3.fromRGB(8,9,12),
	InputBorder    = Color3.fromRGB(34,38,50),
	InputText      = Color3.fromRGB(218,222,238),
	NotifBg        = Color3.fromRGB(18,20,25),
	NotifBorder    = Color3.fromRGB(0,0,0),
	NotifBar       = Color3.fromRGB(224,32,32),
	ScrollBar      = Color3.fromRGB(48,52,66),
}
local THEME_PRESETS: {[string]: {[string]: Color3}} = {
	["Ignis Dark"]    = {},
	["Ignis Crimson"] = {
		HdrTop        = Color3.fromRGB(235,35,70),  HdrMid   = Color3.fromRGB(210,20,50),
		HdrBot        = Color3.fromRGB(95,6,22),    HdrBevel = Color3.fromRGB(95,8,24),
		TabActiveLeft = Color3.fromRGB(210,20,50),  SectionBevel = Color3.fromRGB(95,8,24),
		SliderFill    = Color3.fromRGB(210,20,50),  NotifBar     = Color3.fromRGB(210,20,50),
		WinBg         = Color3.fromRGB(14,12,16),   SidebarBg    = Color3.fromRGB(11,9,13),
		ContentBg     = Color3.fromRGB(15,13,18),
	},
	["Ignis Ember"]   = {
		HdrTop        = Color3.fromRGB(255,100,40), HdrMid   = Color3.fromRGB(230,70,20),
		HdrBot        = Color3.fromRGB(120,30,5),   HdrBevel = Color3.fromRGB(110,28,8),
		TabActiveLeft = Color3.fromRGB(230,70,20),  SectionBevel = Color3.fromRGB(110,28,8),
		SliderFill    = Color3.fromRGB(230,70,20),  NotifBar     = Color3.fromRGB(230,70,20),
	},
}
local T: {[string]: Color3} = {}
do for k, v in pairs(BASE) do T[k] = v end end

-- ── Creator ───────────────────────────────────────────────────────────────
local Creator = {
	Reg  = {} :: {[Instance]: {[string]: string}},
	Grad = {} :: {[Instance]: true},
}
local function _applyToken(inst: Instance, prop: string, token: string)
	local val = T[token]
	if val then pcall(function() (inst :: any)[prop] = val end) end
end
local function _applyGrad(inst: UIGradient)
	inst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   T.HdrTop),
		ColorSequenceKeypoint.new(0.3, T.HdrMid),
		ColorSequenceKeypoint.new(1,   T.HdrBot),
	})
end
function Creator.New(cls: string, props: {[string]: any}, children: {Instance}?): any
	local inst = Instance.new(cls) :: any
	local tag  = props.ThemeTag; local grad = props.GradTag
	for k, v in pairs(props) do if k ~= "ThemeTag" and k ~= "GradTag" then inst[k] = v end end
	if tag  then Creator.Reg[inst] = tag; for p, tk in pairs(tag) do _applyToken(inst, p, tk) end end
	if grad then Creator.Grad[inst] = true; _applyGrad(inst) end
	if children then for _, c in ipairs(children) do c.Parent = inst end end
	return inst
end
function Creator.UpdateTheme()
	for inst, tag in pairs(Creator.Reg) do
		if inst.Parent then for p, tk in pairs(tag) do _applyToken(inst, p, tk) end end
	end
	for inst in pairs(Creator.Grad) do
		if inst.Parent then _applyGrad(inst :: UIGradient) end
	end
end

-- ── Library ───────────────────────────────────────────────────────────────
local Library = {
	Window     = nil :: any,
	Options    = {} :: {[string]: any},
	Version    = "2.5.3",
	_theme     = "Ignis Dark",
	_themeSubs = {} :: {(string) -> ()},
}
Library.__index = Library

local function _applyTheme(name: string): boolean
	local preset = THEME_PRESETS[name]; if not preset then return false end
	Library._theme = name
	for k, v in pairs(BASE)   do T[k] = v end
	for k, v in pairs(preset) do T[k] = v end
	Creator.UpdateTheme()
	for _, fn in ipairs(Library._themeSubs) do xpcall(fn, debug.traceback, name) end
	return true
end
function Library:SetTheme(name: string)
	if not _applyTheme(name) then warn("[Ignis] Unknown theme: " .. name) end
end
function Library:GetTheme(): string return Library._theme end
function Library:GetThemeNames(): {string}
	local n = {}; for k in pairs(THEME_PRESETS) do table.insert(n, k) end
	table.sort(n); return n
end

-- ── Fonts ─────────────────────────────────────────────────────────────────
-- Resolved from L at load time. Call Library._refreshFonts() after any
-- LayoutManager:Set("Font*", ...) and before CreateWindow.
local FONT_TITLE: Font; local FONT_TAB: Font; local FONT_UI: Font; local FONT_BOLD: Font
local function _refreshFonts()
	FONT_TITLE = Font.fromEnum(L.FontTitle); FONT_TAB  = Font.fromEnum(L.FontTab)
	FONT_UI    = Font.fromEnum(L.FontUI);    FONT_BOLD = Font.fromEnum(L.FontBold)
end
_refreshFonts()
Library._refreshFonts = _refreshFonts

-- ── AnimationManager ──────────────────────────────────────────────────────
local AnimationManager: any = {
	_preset = "Default", _speed = 1.0, _enabled = true, _scope = "everywhere",
}
function AnimationManager:SetEnabled(b: boolean)  _animEnabled = b; self._enabled = b end
function AnimationManager:SetSpeed(s: number)
	assert(type(s) == "number" and s > 0, "[Ignis:Anim] Speed must be positive")
	self._speed = s; _rebuildAnim(self._preset, s, self._scope)
end
function AnimationManager:SetScope(scope: any)
	local resolved = scope
	if type(scope) == "table" then
		-- Normalize array form {"Toggle","Slider"} to keyed {Toggle=true,Slider=true}
		-- so _rebuildAnim's table check (scope[cat] ~= nil) works for both forms.
		local hasNumKey = false
		for k in pairs(scope) do if type(k) == "number" then hasNumKey = true; break end end
		if hasNumKey then
			local keyed: {[string]: boolean} = {}
			for _, v in ipairs(scope :: any) do
				local s = tostring(v)
				if not _DEF_DUR[s] then warn("[Ignis:Anim] SetScope: unknown category '" .. s .. "'") end
				keyed[s] = true
			end
			resolved = keyed
		end
	elseif type(scope) == "string" and scope ~= "everywhere" then
		if not _DEF_DUR[scope] then
			warn("[Ignis:Anim] SetScope: unknown category '" .. scope .. "'")
		end
	end
	self._scope = resolved; _rebuildAnim(self._preset, self._speed, resolved)
end
function AnimationManager:SetPreset(name: string)
	if name == "None" then _animEnabled = false; self._enabled = false; self._preset = name; return end
	local preset = _ANIM_PRESETS[name]
	if not preset then warn("[Ignis:Anim] Unknown preset: " .. name); return end
	_animEnabled = true; self._enabled = true; self._preset = name
	_rebuildAnim(name, self._speed, self._scope)
end
function AnimationManager:AddPreset(name: string, cats: {[string]: any})
	assert(type(name) == "string", "[Ignis:Anim] Name must be a string")
	_ANIM_PRESETS[name] = cats
end
function AnimationManager:RemovePreset(name: string)
	local locked = { Default=true, Snappy=true, Smooth=true, Bounce=true, None=true }
	if locked[name] then warn("[Ignis:Anim] Cannot remove built-in preset"); return end
	_ANIM_PRESETS[name] = nil
end
function AnimationManager:GetPresetNames(): {string}
	local n = {}; for k in pairs(_ANIM_PRESETS) do table.insert(n, k) end; table.sort(n); return n
end
function AnimationManager:SetCategory(cat: string, info: TweenInfo) Anim[cat] = info end
function AnimationManager:GetCategory(cat: string): TweenInfo?       return Anim[cat] end
function Library:GetAnimationManager(): any return AnimationManager end

-- ── ThemeManager ──────────────────────────────────────────────────────────
local ThemeManager: any = {}
function ThemeManager:SetTheme(name: string)
	if not _applyTheme(name) then warn("[Ignis:Theme] Unknown theme: " .. name) end
end
function ThemeManager:GetTheme(): string return Library._theme end
function ThemeManager:GetThemes(): {string}
	local n = {}; for k in pairs(THEME_PRESETS) do table.insert(n, k) end; table.sort(n); return n
end
function ThemeManager:AddTheme(name: string, overrides: {[string]: Color3})
	assert(type(name) == "string", "[Ignis:Theme] Name must be a string")
	THEME_PRESETS[name] = overrides
end
function ThemeManager:RemoveTheme(name: string)
	local locked = { ["Ignis Dark"]=true, ["Ignis Crimson"]=true, ["Ignis Ember"]=true }
	if locked[name] then warn("[Ignis:Theme] Cannot remove built-in theme"); return end
	if Library._theme == name then
		warn("[Ignis:Theme] Cannot remove active theme '" .. name .. "'; call SetTheme() with a different theme first")
		return
	end
	THEME_PRESETS[name] = nil
end
function ThemeManager:GetToken(t: string): Color3?       return T[t] end
function ThemeManager:SetToken(t: string, c: Color3)     T[t] = c; Creator.UpdateTheme() end
function ThemeManager:Reset()                             _applyTheme(Library._theme) end
function ThemeManager:OnChanged(fn: (string) -> ()): () -> ()
	table.insert(Library._themeSubs, fn)
	return function()
		for i, f in ipairs(Library._themeSubs) do
			if f == fn then table.remove(Library._themeSubs, i); break end
		end
	end
end
function Library:GetThemeManager(): any  return ThemeManager  end
function Library:GetLayoutManager(): any return LayoutManager end

-- ── Notification system ───────────────────────────────────────────────────
local _nGui: ScreenGui? = nil; local _nHolder: Frame? = nil
local function _ensureNotifGui()
	if _nGui and _nGui.Parent then return end
	local g = Instance.new("ScreenGui")
	g.Name = "IgnisNotif"; g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; g.DisplayOrder = 1000
	local genv = _getGenv(); local gh = rawget(genv, "gethui")
	if gh then local ok, h = pcall(gh); if ok and h then g.Parent = h end
	else local ok, cg = pcall(game.GetService, game, "CoreGui")
		if ok then pcall(function() g.Parent = cg end) end end
	local holder = Instance.new("Frame")
	holder.Name = "Holder"; holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -L.NotifEdge, 1, -L.NotifEdge)
	holder.Size = UDim2.new(0, L.NotifW, 1, -L.NotifEdge * 2)
	holder.BackgroundTransparency = 1; holder.Parent = g
	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lay.Padding = UDim.new(0, L.NotifGap); lay.Parent = holder
	_nGui = g; _nHolder = holder
end

type NotifOpts = { Title: string, Message: string?, Duration: number?, Type: string? }

function Library:Notify(opts: NotifOpts)
	_ensureNotifGui()
	local dur = opts.Duration or 3.5
	local card = Creator.New("Frame", {
		Size = UDim2.new(1, 0, 0, L.NotifH), ClipsDescendants = true,
		ThemeTag = { BackgroundColor3 = "NotifBg" }, Parent = _nHolder,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeNotif, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "NotifBorder" }, Parent = card,
	})
	Creator.New("Frame", {
		Size = UDim2.new(0, L.NotifBarW, 1, 0), BorderSizePixel = 0,
		ThemeTag = { BackgroundColor3 = "NotifBar" }, Parent = card,
	})
	local inner = Instance.new("Frame")
	inner.Position = UDim2.new(0, L.NotifInnerPadL, 0, 0)
	inner.Size = UDim2.new(1, -(L.NotifInnerPadL + L.NotifInnerPadR), 1, 0)
	inner.BackgroundTransparency = 1; inner.Parent = card
	local tl = Instance.new("TextLabel")
	tl.Text = opts.Title; tl.FontFace = FONT_BOLD; tl.TextSize = L.ElemNameSize
	tl.TextColor3 = T.Text; tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.BackgroundTransparency = 1
	tl.Position = UDim2.new(0, 0, 0, L.NotifTitleY)
	tl.Size = UDim2.new(1, 0, 0, L.ElemNameSize + L.LabelPad); tl.Parent = inner
	Creator.Reg[tl :: any] = { TextColor3 = "Text" }
	if opts.Message then
		local msgY = L.NotifTitleY + L.ElemNameSize + L.LabelPad + L.NotifMsgGapY
		local ml = Instance.new("TextLabel")
		ml.Text = opts.Message; ml.FontFace = FONT_UI; ml.TextSize = L.ElemDescSize
		ml.TextColor3 = T.TextSub; ml.TextXAlignment = Enum.TextXAlignment.Left
		ml.TextWrapped = true; ml.BackgroundTransparency = 1
		ml.Position = UDim2.new(0, 0, 0, msgY)
		ml.Size = UDim2.new(1, 0, 0, L.NotifH - msgY - L.NotifMsgBottomPad)
		ml.Parent = inner; Creator.Reg[ml :: any] = { TextColor3 = "TextSub" }
	end
	local bar = Creator.New("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0,
		ThemeTag = { BackgroundColor3 = "NotifBar" }, Parent = card,
	}) :: Frame
	card.Position = UDim2.new(1.1, 0, 0, 0)
	tw(card, { Position = UDim2.new(0, 0, 0, 0) }, Anim.Notif)
	if _animEnabled then
		TweenService:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear),
			{ Size = UDim2.new(0, 0, 0, 2) }):Play()
	else
		task.delay(dur, function() if bar.Parent then bar.Size = UDim2.new(0, 0, 0, 2) end end)
	end
	task.delay(dur, function()
		if card.Parent then
			tw(card, { Position = UDim2.new(1.1, 0, 0, 0) }, Anim.NotifOut)
			task.delay((Anim.NotifOut :: TweenInfo).Time + 0.05, function()
				if card.Parent then card:Destroy() end
			end)
		end
	end)
end

-- ── Element base factory ──────────────────────────────────────────────────
-- Set(v): value=v first, then _apply(v) (may call _raw to normalize), then fire(value).
local function mkBase(id: string, initial: any, frame: Frame): any
	local value = initial
	local subs: {(any) -> ()} = {}
	local disabled = false
	local function fire(v: any)
		for _, fn in ipairs(subs) do
			local ok, e = xpcall(fn, debug.traceback, v)
			if not ok then warn("[Ignis] Changed cb (" .. id .. "): " .. tostring(e)) end
		end
	end
	local self: any = { Id = id, _frame = frame, _fire = fire }
	function self:Get(): any   return value end
	function self:_raw(v: any) value = v   end
	function self:Set(v: any)
		value = v
		if self._apply then self:_apply(v) end
		fire(value)
	end
	function self:Changed(fn: (any) -> ()): () -> ()
		table.insert(subs, fn)
		return function()
			for i, f in ipairs(subs) do
				if f == fn then table.remove(subs, i); break end
			end
		end
	end
	function self:SetDisabled(b: boolean)
		disabled = b; frame.BackgroundTransparency = b and 0.6 or 0
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("TextLabel") then (d :: TextLabel).TextTransparency = b and 0.5 or 0 end
		end
	end
	function self:SetVisible(b: boolean) frame.Visible = b end
	function self:IsDisabled(): boolean  return disabled   end
	Library.Options[id] = self
	return self
end

-- ── Window ────────────────────────────────────────────────────────────────
export type WindowCfg = {
	Title: string?, SubTitle: string?, Width: number?, Height: number?,
	Theme: string?, MinimizeKey: Enum.KeyCode?,
}

function Library:CreateWindow(cfg: WindowCfg?)
	if Library.Window then error("[Ignis] Only one Window per session.", 2) end
	_windowBuilt = true
	cfg = cfg or {}
	local title    = cfg.Title       or "IGNIS"
	local subtitle = cfg.SubTitle    or ""
	local W        = cfg.Width       or L.WindowW
	local H        = cfg.Height      or L.WindowH
	local minKey   = cfg.MinimizeKey or Enum.KeyCode.RightShift
	local SIDE_W   = L.SidebarW
	local HDR_H    = L.HeaderH

	if cfg.Theme then Library:SetTheme(cfg.Theme) end

	local maid = Maid.new()
	local gui  = Instance.new("ScreenGui")
	gui.Name = "IgnisUI"; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SafeParentGui(gui)

	local root = Creator.New("Frame", {
		Name = "IgnisRoot", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(W, H),
		ClipsDescendants = false, ThemeTag = { BackgroundColor3 = "WinBg" },
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeRoot, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = root,
	})
	root.Parent = gui

	local hdr = Creator.New("Frame", {
		Name = "Header", Size = UDim2.new(1, 0, 0, HDR_H),
		ThemeTag = { BackgroundColor3 = "HdrMid" }, Parent = root,
	}) :: Frame
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = hdr })
	Creator.New("UIStroke", {
		Thickness = L.StrokeHdr, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = hdr,
	})
	Creator.New("Frame", {
		Name = "_hbevelL", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 3, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
	Creator.New("Frame", {
		Name = "_hbevelB", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 3, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
	-- Title right reserve accounts for both buttons plus gaps
	local titleRightPad = (L.HeaderBtnSize + L.HeaderBtnGap) * 2
	Creator.New("TextLabel", {
		Name = "Title", Text = title, FontFace = FONT_TITLE,
		TextSize = L.TitleSize, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, L.HeaderTitlePadL, 0, 0),
		Size = UDim2.new(1, -titleRightPad, 1, 0),
		BackgroundTransparency = 1, ZIndex = 4, ThemeTag = { TextColor3 = "Text" }, Parent = hdr,
	}, {
		Creator.New("UIStroke", { Color = Color3.new(0,0,0), Thickness = L.TitleStrokeW,
			LineJoinMode = Enum.LineJoinMode.Miter }),
	})
	if subtitle ~= "" then
		Creator.New("TextLabel", {
			Name = "SubTitle", Text = subtitle, FontFace = FONT_UI,
			TextSize = L.SubtitleSize, TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, L.SubtitlePadL, 1, -L.SubtitleBottomPad),
			Size = UDim2.new(0.6, 0, 0, L.SubtitleSize + L.LabelPad),
			BackgroundTransparency = 1, ZIndex = 4, ThemeTag = { TextColor3 = "TextSub" }, Parent = hdr,
		})
	end

	local BS = L.HeaderBtnSize
	local closeBtn = Creator.New("TextButton", {
		Name = "Close", Text = "✕", FontFace = FONT_BOLD, TextSize = L.CloseIconSize,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -L.HeaderBtnRightPad, 0.5, 0),
		Size = UDim2.fromOffset(BS, BS), AutoButtonColor = false, ZIndex = 4,
		ThemeTag = { BackgroundColor3 = "HdrBevel", TextColor3 = "Text" }, Parent = hdr,
	}) :: TextButton
	Creator.New("UIStroke", {
		Thickness = L.StrokeClose, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = closeBtn,
	})
	local minBtn = Creator.New("TextButton", {
		Name = "Minimize", Text = "—", FontFace = FONT_BOLD, TextSize = L.MinIconSize,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(L.HeaderBtnRightPad + BS + L.HeaderBtnGap), 0.5, 0),
		Size = UDim2.fromOffset(BS, BS), AutoButtonColor = false, ZIndex = 4,
		ThemeTag = { BackgroundColor3 = "HdrBevel", TextColor3 = "Text" }, Parent = hdr,
	}) :: TextButton
	Creator.New("UIStroke", {
		Thickness = L.StrokeClose, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = minBtn,
	})

	local body = Instance.new("Frame")
	body.Name = "Body"; body.Position = UDim2.new(0, 0, 0, HDR_H)
	body.Size = UDim2.new(1, 0, 1, -HDR_H)
	body.BackgroundTransparency = 1; body.ClipsDescendants = true; body.Parent = root

	local sidebar = Creator.New("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, SIDE_W, 1, 0),
		ThemeTag = { BackgroundColor3 = "SidebarBg" }, Parent = body,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeSidebar, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "SidebarBorder" }, Parent = sidebar,
	})
	Creator.New("Frame", {
		Name = "_bevelL", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 3, ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = sidebar,
	})
	Creator.New("Frame", {
		Name = "_bevelB", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 3, ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = sidebar,
	})
	local sideLayout = Instance.new("UIListLayout")
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Padding = UDim.new(0, L.TabListPad); sideLayout.Parent = sidebar
	local sidePad = Instance.new("UIPadding")
	sidePad.PaddingTop   = UDim.new(0, L.SidebarPadTop)
	sidePad.PaddingLeft  = UDim.new(0, L.SidebarPadH)
	sidePad.PaddingRight = UDim.new(0, L.SidebarPadH); sidePad.Parent = sidebar

	local content = Creator.New("Frame", {
		Name = "Content", Position = UDim2.new(0, SIDE_W, 0, 0),
		Size = UDim2.new(1, -SIDE_W, 1, 0), ClipsDescendants = true,
		ThemeTag = { BackgroundColor3 = "ContentBg" }, Parent = body,
	})

	-- Register structural frames for LayoutManager live updates
	_liveRefs = { root=root, header=hdr, body=body, sidebar=sidebar, content=content }

	-- Drag
	do
		local dragging = false; local lastMouse: Vector2
		maid:Give(hdr.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true; lastMouse = UserInputService:GetMouseLocation()
			end
		end))
		maid:Give(UserInputService.InputChanged:Connect(function(inp)
			if not dragging then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseMovement
				and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local m = UserInputService:GetMouseLocation(); local d = m - lastMouse; lastMouse = m
			root.Position = UDim2.new(
				root.Position.X.Scale, root.Position.X.Offset + d.X,
				root.Position.Y.Scale, root.Position.Y.Offset + d.Y)
		end))
		maid:Give(UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end

	-- Minimize
	local minimised = false
	local function setMin(state: boolean)
		minimised = state
		tw(root, { Size = UDim2.fromOffset(W, state and HDR_H or H) }, Anim.Window)
		body.Visible = not state
	end
	maid:Give(minBtn.MouseButton1Click:Connect(function() setMin(not minimised) end))
	maid:Give(UserInputService.InputBegan:Connect(function(inp, gp)
		if not gp and inp.KeyCode == minKey then setMin(not minimised) end
	end))

	-- Tab state
	local activeTab: any = nil
	local function activateTab(tab: any)
		if activeTab == tab then return end
		if activeTab then
			activeTab._page.Visible = false
			Creator.Reg[activeTab._btn] = { BackgroundColor3 = "SidebarBg" }
			tw(activeTab._btn, { BackgroundColor3 = T.SidebarBg }, Anim.Tab)
			activeTab._accent.Visible = false
			activeTab._btnLabel.TextColor3 = T.TabText
			Creator.Reg[activeTab._btnLabel] = { TextColor3 = "TabText" }
		end
		activeTab = tab; tab._page.Visible = true
		Creator.Reg[tab._btn] = { BackgroundColor3 = "TabActiveBg" }
		tw(tab._btn, { BackgroundColor3 = T.TabActiveBg }, Anim.Tab)
		tab._accent.Visible = true
		tab._btnLabel.TextColor3 = T.TabTextActive
		Creator.Reg[tab._btnLabel] = { TextColor3 = "TabTextActive" }
	end

	local Window: any = { _gui = gui, _root = root, _maid = maid, _tabs = {} :: {any} }

	function Window:Tab(tabLabel: string): any
		local tabIdx = #self._tabs + 1
		local btn = Creator.New("TextButton", {
			Name = "Tab_" .. tabIdx, Text = "",
			Size = UDim2.new(1, 0, 0, L.TabH), AutoButtonColor = false,
			LayoutOrder = tabIdx, ZIndex = 2,
			ThemeTag = { BackgroundColor3 = "SidebarBg" }, Parent = sidebar,
		}) :: TextButton
		Creator.New("UIStroke", {
			Thickness = L.StrokeTabBtn, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "SidebarBorder" }, Parent = btn,
		})
		local accent = Creator.New("Frame", {
			Size = UDim2.new(0, L.TabAccentW, 1, 0), BorderSizePixel = 0,
			Visible = false, ZIndex = 3, ThemeTag = { BackgroundColor3 = "TabActiveLeft" }, Parent = btn,
		})
		local btnLabel = Creator.New("TextLabel", {
			Text = tabLabel, FontFace = FONT_TAB, TextSize = L.TabTextSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, L.TabLabelIndent, 0, 0),
			Size = UDim2.new(1, -L.TabLabelIndent, 1, 0),
			BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "TabText" }, Parent = btn,
		}) :: TextLabel

		local page = Instance.new("ScrollingFrame")
		page.Name = "Page_" .. tabIdx; page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1; page.BorderSizePixel = 0
		page.ScrollBarThickness = L.ScrollBarThick; page.ScrollBarImageColor3 = T.ScrollBar
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new(0, 0, 0, 0); page.Visible = false; page.Parent = content
		local pageLayout = Instance.new("UIListLayout")
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Padding = UDim.new(0, L.PageSectionGap); pageLayout.Parent = page
		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingTop    = UDim.new(0, L.PagePad); pagePad.PaddingBottom = UDim.new(0, L.PagePad)
		pagePad.PaddingLeft   = UDim.new(0, L.PagePad); pagePad.PaddingRight  = UDim.new(0, L.PagePad)
		pagePad.Parent = page

		local Tab: any = { _btn=btn, _btnLabel=btnLabel, _accent=accent, _page=page, _sections={} }
		maid:Give(btn.MouseButton1Click:Connect(function() activateTab(Tab) end))
		maid:Give(btn.MouseEnter:Connect(function()
			if activeTab ~= Tab then tw(btn, { BackgroundColor3 = T.TabHoverBg }, Anim.Tab) end
		end))
		maid:Give(btn.MouseLeave:Connect(function()
			if activeTab ~= Tab then tw(btn, { BackgroundColor3 = T.SidebarBg }, Anim.Tab) end
		end))
		table.insert(self._tabs, Tab)
		if #self._tabs == 1 then activateTab(Tab) end

		function Tab:Section(sectionLabel: string?): any
			local secFrame = Creator.New("Frame", {
				Name = "Section", Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #self._sections + 1,
				ThemeTag = { BackgroundColor3 = "SectionBg" }, Parent = page,
			}) :: Frame
			Creator.New("UIStroke", {
				Thickness = L.StrokeSection, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "RowBorderOuter" }, Parent = secFrame,
			})
			Creator.New("Frame", {
				Name = "_bevelL", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
				ZIndex = 3, ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
			})
			Creator.New("Frame", {
				Name = "_bevelB", AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
				BorderSizePixel = 0, ZIndex = 3, ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
			})
			local hasLabel = sectionLabel and sectionLabel ~= ""
			if hasLabel then
				local hStrip = Creator.New("Frame", {
					Name = "SectionHeader", Size = UDim2.new(1, 0, 0, L.SectionHeaderH),
					ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
				})
				Creator.New("TextLabel", {
					Text = (sectionLabel :: string):upper(), FontFace = FONT_BOLD,
					TextSize = L.SectionHeaderTextSize, TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, L.SectionLabelIndent, 0, 0),
					Size = UDim2.new(1, -L.SectionLabelIndent, 1, 0),
					BackgroundTransparency = 1, ZIndex = 2, ThemeTag = { TextColor3 = "TextHint" }, Parent = hStrip,
				})
			end
			local inner = Instance.new("Frame")
			inner.Name = "Inner"
			inner.Position = UDim2.new(0, L.BevelSize, 0, hasLabel and L.SectionHeaderH or 0)
			inner.Size = UDim2.new(1, -L.BevelSize, 0, 0); inner.AutomaticSize = Enum.AutomaticSize.Y
			inner.BackgroundTransparency = 1; inner.Parent = secFrame
			local rowLayout = Instance.new("UIListLayout")
			rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rowLayout.Padding = UDim.new(0, L.RowListPad); rowLayout.Parent = inner

			local Section: any = { _frame = secFrame, _inner = inner, _rows = 0 }
			table.insert(self._sections, Section)

			local function mkRow(height: number): Frame
				Section._rows += 1
				local r = Creator.New("Frame", {
					Name = "Row_" .. Section._rows,
					Size = UDim2.new(1, 0, 0, height), LayoutOrder = Section._rows,
					ThemeTag = { BackgroundColor3 = "RowBg" }, Parent = inner,
				}) :: Frame
				Creator.New("UIStroke", {
					Thickness = L.StrokeRow, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "RowBorder" }, Parent = r,
				})
				return r
			end
			local function rowInner(row: Frame, indent: number?): Frame
				local f = Instance.new("Frame")
				f.Position = UDim2.new(0, indent or L.RowIndent, 0, 0)
				f.Size = UDim2.new(1, -(indent or L.RowIndent), 1, 0)
				f.BackgroundTransparency = 1; f.Parent = row; return f
			end
			local function rowHover(row: Frame, el: any)
				maid:Give(row.MouseEnter:Connect(function()
					if not el:IsDisabled() then tw(row, { BackgroundColor3 = T.RowBgHover }, Anim.Row) end
				end))
				maid:Give(row.MouseLeave:Connect(function()
					tw(row, { BackgroundColor3 = T.RowBg }, Anim.Row)
				end))
			end
			local function mkLabel(txt: string, size: number, token: string, parent: Instance, bold: boolean?): TextLabel
				local l = Creator.New("TextLabel", {
					Text = txt, FontFace = bold and FONT_BOLD or FONT_UI,
					TextSize = size, TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size + L.LabelPad),
					ThemeTag = { TextColor3 = token },
				}) :: TextLabel
				l.Parent = parent; return l
			end

			-- ── Toggle ────────────────────────────────────────────────────
			function Section:Toggle(opts: {
				Id: string, Name: string, Default: boolean?,
				Description: string?, Callback: ((boolean) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local on  = opts.Default == true
				local row = mkRow(opts.Description and L.RowHDesc or L.RowH); local ri = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				local TW = L.ToggleW; local TH = L.ToggleH; local KS = L.ToggleKnobS
				local KM = L.ToggleKnobMargin
				local track = Creator.New("Frame", {
					Name = "Track", AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
					Size = UDim2.fromOffset(TW, TH),
					ThemeTag = { BackgroundColor3 = on and "ToggleOn" or "ToggleOff" }, Parent = row,
				}) :: Frame
				Creator.New("UIStroke", {
					Thickness = L.StrokeToggle, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "RowBorderOuter" }, Parent = track,
				})
				local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, TH // 2); c.Parent = track
				local knob = Creator.New("Frame", {
					Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5),
					Position = on and UDim2.new(0, TW - KS//2 - KM, 0.5, 0)
					              or UDim2.new(0, KS//2 + KM, 0.5, 0),
					Size = UDim2.fromOffset(KS, KS),
					ThemeTag = { BackgroundColor3 = "ToggleKnob" }, Parent = track,
				})
				local ck = Instance.new("UICorner"); ck.CornerRadius = UDim.new(0, KS // 2); ck.Parent = knob
				local el = mkBase(opts.Id, on, row)
				function el:_apply(v: boolean)
					on = v; local token = v and "ToggleOn" or "ToggleOff"
					Creator.Reg[track] = { BackgroundColor3 = token }
					tw(track, { BackgroundColor3 = T[token] }, Anim.ToggleTrack)
					tw(knob, { Position = v and UDim2.new(0, TW - KS//2 - KM, 0.5, 0)
					                       or UDim2.new(0, KS//2 + KM, 0.5, 0) }, Anim.Toggle)
					if opts.Callback then
						local ok, e = xpcall(opts.Callback, debug.traceback, v)
						if not ok then warn("[Ignis] Toggle cb: " .. e) end
					end
				end
				maid:Give(track.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1
						and not el:IsDisabled() then el:Set(not on) end
				end))
				rowHover(row, el); return el
			end

			-- ── Slider ────────────────────────────────────────────────────
			function Section:Slider(opts: {
				Id: string, Name: string, Min: number, Max: number,
				Default: number?, Step: number?, Description: string?,
				Callback: ((number) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local step = opts.Step or 1
				local val  = math.clamp(opts.Default or opts.Min, opts.Min, opts.Max)
				local row  = mkRow(opts.Description and L.SliderRowHDesc or L.SliderRowH)
				local ri   = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				local valL = Creator.New("TextLabel", {
					Text = tostring(val), FontFace = FONT_UI, TextSize = L.ElemValueSize,
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -L.ElemRightPad, 0, L.SliderValLabelY),
					Size = UDim2.new(0, L.SliderValLabelW, 0, L.SliderValLabelH),
					BackgroundTransparency = 1, ThemeTag = { TextColor3 = "TextSub" }, Parent = ri,
				}) :: TextLabel
				local TRY = opts.Description and L.SliderTrackYD or L.SliderTrackY
				local track = Creator.New("Frame", {
					Position = UDim2.new(0, 0, 0, TRY),
					Size = UDim2.new(1, -L.SliderTrackRightPad, 0, L.SliderTrackH),
					ThemeTag = { BackgroundColor3 = "SliderTrack" }, Parent = ri,
				}) :: Frame
				Creator.New("UIStroke", {
					Thickness = L.StrokeRow, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "RowBorder" }, Parent = track,
				})
				local pct0 = (val - opts.Min) / (opts.Max - opts.Min)
				local fill = Creator.New("Frame", {
					Size = UDim2.new(pct0, 0, 1, 0), ThemeTag = { BackgroundColor3 = "SliderFill" }, Parent = track,
				})
				local knob = Creator.New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3,
					Position = UDim2.new(pct0, 0, 0.5, 0),
					Size = UDim2.fromOffset(L.SliderKnobS, L.SliderKnobS),
					ThemeTag = { BackgroundColor3 = "SliderKnob" }, Parent = track,
				})
				local kc = Instance.new("UICorner")
				kc.CornerRadius = UDim.new(0, L.SliderKnobS // 2); kc.Parent = knob
				local function snap(raw: number): number
					return math.clamp(
						math.round((raw - opts.Min) / step) * step + opts.Min, opts.Min, opts.Max)
				end
				local el = mkBase(opts.Id, val, row)
				function el:_apply(v: number)
					val = snap(v); self:_raw(val)
					local pct = (val - opts.Min) / (opts.Max - opts.Min)
					fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0)
					valL.Text = tostring(val)
					if opts.Callback then
						local ok, e = xpcall(opts.Callback, debug.traceback, val)
						if not ok then warn("[Ignis] Slider cb: " .. e) end
					end
				end
				local dragging = false
				local function fromX(x: number): number
					local ax = track.AbsolutePosition.X; local aw = track.AbsoluteSize.X
					return snap(opts.Min + math.clamp((x - ax) / aw, 0, 1) * (opts.Max - opts.Min))
				end
				maid:Give(track.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 and not el:IsDisabled() then
						dragging = true; el:Set(fromX(inp.Position.X))
					end
				end))
				maid:Give(UserInputService.InputChanged:Connect(function(inp)
					if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
						el:Set(fromX(inp.Position.X))
					end
				end))
				maid:Give(UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end))
				rowHover(row, el); return el
			end

			-- ── Button ────────────────────────────────────────────────────
			function Section:Button(opts: {
				Id: string, Name: string, Description: string?, Callback: (() -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local row = mkRow(opts.Description and L.RowHDesc or L.RowH); local ri = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				Creator.New("TextLabel", {
					Text = "›", FontFace = FONT_BOLD, TextSize = L.BtnChevronSize,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
					Size = UDim2.fromOffset(L.BtnChevronW, L.BtnChevronH),
					BackgroundTransparency = 1, ThemeTag = { TextColor3 = "TextSub" }, Parent = ri,
				})
				local el = mkBase(opts.Id, nil, row)
				function el:_apply(_v: any) end
				el.Press = function()
					if el:IsDisabled() then return end
					if opts.Callback then
						local ok, e = xpcall(opts.Callback, debug.traceback)
						if not ok then warn("[Ignis] Button cb: " .. e) end
					end
					tw(row, { BackgroundColor3 = T.SectionBevel }, Anim.Button)
					task.delay((Anim.ButtonOut :: TweenInfo).Time, function()
						tw(row, { BackgroundColor3 = T.RowBg }, Anim.ButtonOut)
					end)
					el._fire(nil)
				end
				maid:Give(row.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then el.Press() end
				end))
				rowHover(row, el); return el
			end

			-- ── Dropdown ──────────────────────────────────────────────────
			function Section:Dropdown(opts: {
				Id: string, Name: string, Options: {string},
				Default: string?, Description: string?,
				Multi: boolean?, Callback: ((any) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local multi = opts.Multi == true
				local cur   = opts.Default or opts.Options[1] or ""
				local mSel: {[string]: boolean} = {}
				local H      = opts.Description and L.SliderRowHDesc or L.SliderRowH
				local isOpen = false
				local row = mkRow(H); local ri = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				local dispL = Creator.New("TextLabel", {
					Text = cur, FontFace = FONT_UI, TextSize = L.ElemDescSize,
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.DropdownLabelRightPad, 0.5, 0),
					Size = UDim2.new(0.45, 0, 0, L.DropdownLabelH),
					BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
					ThemeTag = { TextColor3 = "TextSub" }, Parent = ri,
				}) :: TextLabel
				Creator.New("TextLabel", {
					Text = "∨", FontFace = FONT_BOLD, TextSize = L.DropdownChevronSize,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.DropdownChevronRightPad, 0.5, 0),
					Size = UDim2.fromOffset(L.DropdownChevronContainerS, L.DropdownChevronContainerS),
					BackgroundTransparency = 1, ThemeTag = { TextColor3 = "TextSub" }, Parent = ri,
				})
				local shield = Instance.new("TextButton")
				shield.Name = "Shield"; shield.Size = UDim2.new(1, 0, 1, 0)
				shield.BackgroundTransparency = 1; shield.Text = ""; shield.ZIndex = 9
				shield.Visible = false; shield.Parent = content
				local panel = Creator.New("Frame", {
					Position = UDim2.new(0, 0, 0, H), Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = false,
					ZIndex = 8, Visible = false,
					ThemeTag = { BackgroundColor3 = "InputBg" }, Parent = row,
				}) :: Frame
				Creator.New("UIStroke", {
					Thickness = L.StrokePanel, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "InputBorder" }, Parent = panel,
				})
				local pList = Instance.new("UIListLayout")
				pList.SortOrder = Enum.SortOrder.LayoutOrder; pList.Parent = panel
				for _, opt in ipairs(opts.Options) do
					local ob = Creator.New("TextButton", {
						Text = opt, FontFace = FONT_UI, TextSize = L.ElemValueSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, L.DropdownOptH), AutoButtonColor = false,
						ZIndex = 9, ThemeTag = { BackgroundColor3 = "RowBg", TextColor3 = "Text" }, Parent = panel,
					}) :: TextButton
					local op = Instance.new("UIPadding")
					op.PaddingLeft = UDim.new(0, L.DropdownOptPadL); op.Parent = ob
					maid:Give(ob.MouseEnter:Connect(function()
						tw(ob, { BackgroundColor3 = T.RowBgHover }, Anim.Dropdown)
					end))
					maid:Give(ob.MouseLeave:Connect(function()
						tw(ob, { BackgroundColor3 = T.RowBg }, Anim.Dropdown)
					end))
					maid:Give(ob.MouseButton1Click:Connect(function()
						if multi then
							mSel[opt] = not mSel[opt]
							local sel: {string} = {}
							for _, o in ipairs(opts.Options) do if mSel[o] then table.insert(sel, o) end end
							dispL.Text = #sel > 0 and table.concat(sel, ", ") or "None"
							if opts.Callback then xpcall(opts.Callback, debug.traceback, sel) end
						else
							cur = opt; dispL.Text = opt
							panel.Visible = false; shield.Visible = false; isOpen = false
							if opts.Callback then xpcall(opts.Callback, debug.traceback, opt) end
						end
					end))
				end
				local function close()
					panel.Visible = false; shield.Visible = false; isOpen = false
				end
				maid:Give(row.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						isOpen = not isOpen; panel.Visible = isOpen; shield.Visible = isOpen
					end
				end))
				maid:Give(shield.MouseButton1Click:Connect(close))
				local el = mkBase(opts.Id, cur, row)
				function el:Get(): any
					if multi then
						local s: {string} = {}
						for _, o in ipairs(opts.Options) do if mSel[o] then table.insert(s, o) end end
						return s
					end
					return cur
				end
				function el:_apply(v: any)
					if multi and type(v) == "table" then
						mSel = {}; local sel: {string} = {}
						for _, o in ipairs(v :: {string}) do mSel[o] = true; table.insert(sel, o) end
						dispL.Text = #sel > 0 and table.concat(sel, ", ") or "None"
					else cur = tostring(v); dispL.Text = cur end
				end
				rowHover(row, el); return el
			end

			-- ── Input ─────────────────────────────────────────────────────
			function Section:Input(opts: {
				Id: string, Name: string, Default: string?, Placeholder: string?,
				Description: string?, MaxLength: number?, Callback: ((string) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local val = opts.Default or ""
				local row = mkRow(opts.Description and L.InputRowHDesc or L.InputRowH)
				local ri  = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				local ibg = Creator.New("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, -L.InputBoxBottomPad),
					Size = UDim2.new(1, -L.ElemRightPad, 0, L.InputBoxH),
					ThemeTag = { BackgroundColor3 = "InputBg" }, Parent = ri,
				}) :: Frame
				Creator.New("UIStroke", {
					Thickness = L.StrokeInput, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "InputBorder" }, Parent = ibg,
				})
				local box = Instance.new("TextBox")
				box.FontFace = FONT_UI; box.TextSize = L.ElemValueSize
				box.TextColor3 = T.InputText; Creator.Reg[box :: any] = { TextColor3 = "InputText" }
				box.PlaceholderText = opts.Placeholder or ""; box.PlaceholderColor3 = T.TextHint
				box.Text = val; box.TextXAlignment = Enum.TextXAlignment.Left
				box.BackgroundTransparency = 1; box.ClearTextOnFocus = false
				box.Size = UDim2.new(1, 0, 1, 0); box.Parent = ibg
				local bp = Instance.new("UIPadding")
				bp.PaddingLeft = UDim.new(0, L.InputPadH); bp.PaddingRight = UDim.new(0, L.InputPadH)
				bp.Parent = box
				maid:Give(box.FocusLost:Connect(function()
					local t = opts.MaxLength and box.Text:sub(1, opts.MaxLength) or box.Text
					box.Text = t; val = t
					if opts.Callback then xpcall(opts.Callback, debug.traceback, t) end
				end))
				local el = mkBase(opts.Id, val, row)
				function el:_apply(v: any) val = tostring(v); box.Text = val end
				return el
			end

			-- ── Keybind ───────────────────────────────────────────────────
			function Section:Keybind(opts: {
				Id: string, Name: string, Default: Enum.KeyCode?,
				Description: string?, Callback: ((Enum.KeyCode) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local bound = opts.Default or Enum.KeyCode.Unknown; local listening = false
				local row = mkRow(opts.Description and L.RowHDesc or L.RowH); local ri = rowInner(row)
				mkLabel(opts.Name, L.ElemNameSize, "Text", ri, true)
				if opts.Description then
					local dl = mkLabel(opts.Description, L.ElemDescSize, "TextSub", ri)
					dl.Position = UDim2.new(0, 0, 0, L.ElemNameSize + L.LabelPad)
				end
				local pill = Creator.New("TextButton", {
					Text = bound == Enum.KeyCode.Unknown and "None" or bound.Name,
					FontFace = FONT_UI, TextSize = L.ElemDescSize, AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
					Size = UDim2.fromOffset(L.KeybindPillW, L.KeybindPillH), ZIndex = 2,
					ThemeTag = { BackgroundColor3 = "InputBg", TextColor3 = "TextSub" }, Parent = ri,
				}) :: TextButton
				Creator.New("UIStroke", {
					Thickness = L.StrokeInput, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "InputBorder" }, Parent = pill,
				})
				local el: any; el = mkBase(opts.Id, bound, row)
				local function applyKey(k: Enum.KeyCode)
					bound = k; listening = false
					pill.Text = k == Enum.KeyCode.Unknown and "None" or k.Name
					Creator.Reg[pill] = { BackgroundColor3 = "InputBg", TextColor3 = "TextSub" }
					tw(pill, { BackgroundColor3 = T.InputBg }, Anim.Keybind)
					el:_raw(k)
					if opts.Callback then xpcall(opts.Callback, debug.traceback, k) end
				end
				function el:_apply(v: any)
					if typeof(v) == "EnumItem" then
						applyKey(v :: Enum.KeyCode)
					elseif type(v) == "string" then
						-- Handle string KeyCode names saved by SaveManager:GetData()
						local ok2, kc = pcall(function() return (Enum.KeyCode :: any)[v] end)
						if ok2 and typeof(kc) == "EnumItem" then applyKey(kc :: Enum.KeyCode) end
					end
				end
				el.Clear = function() el:Set(Enum.KeyCode.Unknown) end
				maid:Give(pill.MouseButton1Click:Connect(function()
					if el:IsDisabled() then return end
					listening = true; pill.Text = "..."
					Creator.Reg[pill] = { BackgroundColor3 = "SectionBevel", TextColor3 = "Text" }
					tw(pill, { BackgroundColor3 = T.SectionBevel }, Anim.Keybind)
				end))
				maid:Give(UserInputService.InputBegan:Connect(function(inp, gp)
					if not listening then return end
					if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
					if inp.KeyCode == Enum.KeyCode.Escape then
						listening = false
						pill.Text = bound == Enum.KeyCode.Unknown and "None" or bound.Name
						tw(pill, { BackgroundColor3 = T.InputBg }, Anim.Keybind); return
					end
					el:Set(inp.KeyCode)
				end))
				rowHover(row, el); return el
			end

			-- ── Label ─────────────────────────────────────────────────────
			function Section:Label(opts: {Id: string, Name: string, Value: string?, Color: string?}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local row = mkRow(L.RowHLabel); local ri = rowInner(row)
				local nl = mkLabel(opts.Name, L.ElemValueSize, "TextSub", ri)
				nl.Size = UDim2.new(0.5, 0, 1, 0)
				local vl = Creator.New("TextLabel", {
					Text = opts.Value or "", FontFace = FONT_UI, TextSize = L.ElemValueSize,
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
					Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ThemeTag = { TextColor3 = opts.Color or "Text" }, Parent = ri,
				}) :: TextLabel
				local el = mkBase(opts.Id, opts.Value or "", row)
				function el:_apply(v: any) vl.Text = tostring(v) end
				return el
			end

			-- ── Paragraph ─────────────────────────────────────────────────
			function Section:Paragraph(opts: {Id: string, Title: string?, Text: string}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local row = mkRow(0); row.AutomaticSize = Enum.AutomaticSize.Y
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft   = UDim.new(0, L.RowIndent); pad.PaddingRight  = UDim.new(0, L.RowIndent)
				pad.PaddingTop    = UDim.new(0, L.PagePad);   pad.PaddingBottom = UDim.new(0, L.PagePad)
				pad.Parent = row
				local lay = Instance.new("UIListLayout")
				lay.SortOrder = Enum.SortOrder.LayoutOrder
				lay.Padding = UDim.new(0, L.ParagraphItemGap); lay.Parent = row
				if opts.Title then
					local tl = Instance.new("TextLabel")
					tl.Text = opts.Title; tl.FontFace = FONT_BOLD; tl.TextSize = L.ElemNameSize
					tl.TextColor3 = T.Text; tl.TextXAlignment = Enum.TextXAlignment.Left
					tl.BackgroundTransparency = 1
					tl.Size = UDim2.new(1, 0, 0, L.ElemNameSize + L.LabelPad)
					tl.LayoutOrder = 1; tl.Parent = row
					Creator.Reg[tl :: any] = { TextColor3 = "Text" }
				end
				local bl = Instance.new("TextLabel")
				bl.Text = opts.Text; bl.FontFace = FONT_UI; bl.TextSize = L.ElemValueSize
				bl.TextColor3 = T.TextSub; bl.TextXAlignment = Enum.TextXAlignment.Left
				bl.BackgroundTransparency = 1; bl.TextWrapped = true
				bl.Size = UDim2.new(1, 0, 0, 0); bl.AutomaticSize = Enum.AutomaticSize.Y
				bl.LayoutOrder = 2; bl.Parent = row
				Creator.Reg[bl :: any] = { TextColor3 = "TextSub" }
				local el = mkBase(opts.Id, opts.Text, row)
				function el:_apply(v: any) bl.Text = tostring(v) end
				return el
			end

			return Section
		end -- Tab:Section
		return Tab
	end -- Window:Tab

	-- ── SaveManager ───────────────────────────────────────────────────────
	local SaveManager: any = {
		_folder   = "IgnisConfigs", _key      = "default",
		_autoStop = nil :: any,
		_saveSubs = {} :: {() -> ()}, _loadSubs = {} :: {() -> ()},
	}
	function SaveManager:SetFolder(folder: string) self._folder = folder end
	function SaveManager:SetKey(key: string)       self._key    = key    end

	-- EnumItems (Keybind KeyCodes) are serialized as their .Name string so that
	-- HttpService:JSONEncode can encode them and SetData can restore them.
	function SaveManager:GetData(): {[string]: any}
		local out: {[string]: any} = {}
		for id, el in pairs(Library.Options) do
			local ok, v = pcall(function() return el:Get() end)
			if ok and v ~= nil then
				if typeof(v) == "EnumItem" then
					out[id] = (v :: EnumItem).Name
				else
					out[id] = v
				end
			end
		end
		return out
	end
	function SaveManager:SetData(data: {[string]: any})
		for id, v in pairs(data) do
			local el = Library.Options[id]
			if el and el.Set then pcall(function() el:Set(v) end) end
		end
		for _, fn in ipairs(self._loadSubs) do xpcall(fn, debug.traceback) end
	end
	function SaveManager:Save(key: string?): boolean
		local genv = _getGenv()
		local wf   = rawget(genv, "writefile"); if not wf then return false end
		local mf   = rawget(genv, "makefolder"); if mf then pcall(mf, self._folder) end
		local k    = key or self._key
		local ok, enc = pcall(function() return HttpService:JSONEncode(self:GetData()) end)
		if not ok then return false end
		local ok2 = pcall(wf, self._folder .. "/" .. k .. ".json", enc)
		if ok2 then
			for _, fn in ipairs(self._saveSubs) do xpcall(fn, debug.traceback) end
		end
		return ok2
	end
	function SaveManager:Load(key: string?): boolean
		local genv = _getGenv()
		local rf   = rawget(genv, "readfile"); if not rf then return false end
		local isf  = rawget(genv, "isfile")
		local k    = key or self._key
		local path = self._folder .. "/" .. k .. ".json"
		if isf then local ok, res = pcall(isf, path); if not ok or not res then return false end end
		local ok, raw = pcall(rf, path)
		if not ok or type(raw) ~= "string" or raw == "" then return false end
		local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok2 or type(data) ~= "table" then return false end
		self:SetData(data); return true
	end
	function SaveManager:Delete(key: string?): boolean
		local genv = _getGenv()
		local df   = rawget(genv, "delfile") or rawget(genv, "deletefile")
		if not df then return false end
		local k = key or self._key
		return pcall(df, self._folder .. "/" .. k .. ".json")
	end

	-- AutoSave: saves immediately on start, then every interval seconds.
	-- Stop lag is at most min(0.5, interval) — polls in small steps rather
	-- than sleeping a full interval before checking the stop flag.
	function SaveManager:AutoSave(interval: number)
		self:StopAutoSave()
		local running = true
		self._autoStop = function() running = false end
		task.spawn(function()
			while running do
				self:Save()
				local elapsed = 0
				local step    = math.min(0.5, interval)
				while running and elapsed < interval do
					task.wait(step); elapsed += step
				end
			end
		end)
	end
	function SaveManager:StopAutoSave()
		if self._autoStop then self._autoStop(); self._autoStop = nil end
	end
	function SaveManager:OnSave(fn: () -> ()): () -> ()
		table.insert(self._saveSubs, fn)
		return function()
			for i, f in ipairs(self._saveSubs) do
				if f == fn then table.remove(self._saveSubs, i); break end
			end
		end
	end
	function SaveManager:OnLoad(fn: () -> ()): () -> ()
		table.insert(self._loadSubs, fn)
		return function()
			for i, f in ipairs(self._loadSubs) do
				if f == fn then table.remove(self._loadSubs, i); break end
			end
		end
	end

	-- ── Window API ─────────────────────────────────────────────────────────
	function Window:GetSaveManager(): any   return SaveManager      end
	function Window:GetThemeManager(): any  return ThemeManager     end
	function Window:GetAnimManager(): any   return AnimationManager end
	function Window:GetLayoutManager(): any return LayoutManager    end

	function Window:SaveSettings(): {[string]: any}  return SaveManager:GetData() end
	function Window:LoadSettings(d: {[string]: any}) SaveManager:SetData(d)       end
	function Window:SaveToFile(folder: string, name: string): boolean
		local prev = SaveManager._folder; SaveManager._folder = folder
		local ok = SaveManager:Save(name); SaveManager._folder = prev; return ok
	end
	function Window:LoadFromFile(folder: string, name: string): boolean
		local prev = SaveManager._folder; SaveManager._folder = folder
		local ok = SaveManager:Load(name); SaveManager._folder = prev; return ok
	end
	function Window:Notify(opts: NotifOpts) Library:Notify(opts) end
	function Window:SetTheme(name: string)  Library:SetTheme(name) end
	function Window:Destroy()
		SaveManager:StopAutoSave(); maid:Destroy()
		if gui and gui.Parent then gui:Destroy() end
		Library.Window = nil; Library.Options = {}
		_windowBuilt = false; _liveRefs = {}
	end
	function Window:IsDestroyed(): boolean return gui == nil or not gui.Parent end

	-- Close button calls Window:Destroy() so _windowBuilt is reset consistently
	maid:Give(closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end))

	Library.Window = Window
	return Window
end

-- ── getgenv registration ──────────────────────────────────────────────────
if typeof(getgenv) == "function" then
	pcall(function() getgenv().Ignis = Library end)
end

return Library
