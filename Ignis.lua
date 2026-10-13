--!strict
--[[
╔══════════════════════════════════════════════════════════════════╗
║  IGNIS  ·  v3.3.0  ·  Script UI Library                         ║
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
	-- Master / window
	MasterW                  = 1130, -- total width including both external sidebars
	MasterH                  = 670,  -- total height of the master container
	WindowW                  = 740,  -- CenterWindow width
	WindowH                  = 660,  -- CenterWindow height
	HeaderH                  = 64,
	-- External sidebars
	SidebarW                 = 175,  -- width of each external sidebar
	SidebarH                 = 580,  -- height of each external sidebar
	SidebarTopOffset         = 70,   -- Y offset of sidebar top from MasterContainer top
	SidebarXOffset           = 388,  -- horizontal offset from master center to sidebar anchor edge
	-- Bottom bar
	BottomBarH               = 54,
	-- Section accordion bar
	SectionBarH              = 38,   -- height of the collapsible section header bar
	-- Title / subtitle
	TitleSize                = 34,
	SubtitleSize             = 11,
	TitleStrokeW             = 2.2,
	HeaderBtnRightPad        = 10,   -- right margin from window edge to close button
	SubtitleBottomPad        = 8,
	-- Tabs
	TabAccentW               = 3,    -- width of red accent strip on active tabs
	TabH                     = 58,
	TabTextSize              = 24,   -- LuckiestGuy 24px on left tabs
	RightTabTextSize         = 22,   -- FredokaOne 22px on right/utility tabs
	TabListPad               = 10,   -- gap between left sidebar tabs
	RightTabListPad          = 14,   -- gap between right sidebar tabs
	-- Section / page
	SectionHeaderH           = 38,   -- alias kept for compat (same as SectionBarH)
	SectionHeaderTextSize    = 10,
	SectionLabelIndent       = 12,
	BevelSize                = 4,
	PageSectionGap           = 4,   -- gap between sections (invisible containers)
	PagePad                  = 6,
	RowListPad               = 7,   -- gap between rows in UIListLayout
	-- Row
	RowH                     = 64,
	RowHDesc                 = 78,
	RowHLabel                = 44,
	RowIndent                = 10,
	LabelPad                 = 6,
	ElemRightPad             = 10,
	-- Paragraph
	ParagraphItemGap         = 4,
	-- Slider
	SliderRowH               = 56,
	SliderRowHDesc           = 68,
	SliderTrackH             = 8,
	SliderKnobS              = 13,
	SliderTrackY             = 38,
	SliderTrackYD            = 50,
	SliderTrackRightPad      = 20,
	SliderValLabelW          = 64,
	SliderValLabelH          = 16,
	SliderValLabelY          = 2,
	-- Input
	InputRowH                = 56,
	InputRowHDesc            = 72,
	InputBoxH                = 22,
	InputBoxBottomPad        = 7,
	InputPadH                = 6,
	-- Toggle (SliderTrack style, matches template)
	ToggleW                  = 58,   -- track width
	ToggleH                  = 28,   -- track height
	ToggleKnobS              = 22,   -- knob size
	-- Dropdown
	DropdownOptH             = 28,
	DropdownOptPadL          = 10,
	DropdownChevronSize      = 10,
	DropdownChevronContainerS = 12,
	DropdownChevronRightPad  = 8,
	DropdownLabelH           = 14,
	DropdownLabelRightPad    = 22,
	-- Button chevron
	BtnChevronSize           = 18,
	BtnChevronW              = 16,
	BtnChevronH              = 20,
	-- Keybind pill
	KeybindPillW             = 72,
	KeybindPillH             = 22,
	-- Stroke widths
	StrokeRoot               = 3.6,
	StrokeHdr                = 3.6,
	StrokeClose              = 3.2,
	StrokeSidebar            = 3.6,
	StrokeTabBtn             = 3.2,
	StrokeSection            = 1.8,
	StrokeRow                = 2.0,
	StrokeToggle             = 1.6,
	StrokePanel              = 2.2,
	StrokeInput              = 1.0,
	StrokePage               = 2.6,  -- page ScrollingFrame border
	StrokeNotif              = 1.5,
	-- Fonts (Enum.Font members)
	FontTitle                = Enum.Font.LuckiestGuy,
	FontTab                  = Enum.Font.LuckiestGuy,
	FontUI                   = Enum.Font.GothamMedium,
	FontBold                 = Enum.Font.GothamBold,
	-- Element text sizes
	ElemNameSize             = 20,   -- row title (FredokaOne Regular)
	ElemDescSize             = 13,   -- row description (BuilderSans SemiBold Italic)
	ElemValueSize            = 15,   -- dropdown value label (FredokaOne Regular)
	-- Notification
	NotifW                   = 290,
	NotifH                   = 68,
	NotifGap                 = 6,
	NotifEdge                = 16,
	NotifBarW                = 3,
	NotifInnerPadL           = 12,
	NotifInnerPadR           = 2,
	NotifTitleY              = 10,
	NotifMsgGapY             = 2,
	NotifMsgBottomPad        = 4,
	-- Misc
	ScrollBarThick           = 6,
}

local _L_DEFAULTS: {[string]: any} = {}
do for k, v in pairs(L) do _L_DEFAULTS[k] = v end end

local _windowBuilt = false

-- Live-update refs: populated by CreateWindow, cleared by Destroy.
-- Structural tokens in _LIVE_TOKENS update these frames immediately when Set() is
-- called post-build. All other tokens still require a Destroy + CreateWindow cycle.
local _liveRefs: {[string]: any} = {}
local _LIVE_TOKENS: {[string]: true} = {
	WindowW=true, WindowH=true, HeaderH=true,
}
local function _applyLiveToken(key: string)
	local r = _liveRefs
	if not (r.root and r.root.Parent) then return end
	if key == "WindowW" or key == "WindowH" then
		r.root.Size = UDim2.fromOffset(L.WindowW, L.WindowH)
	elseif key == "HeaderH" then
		r.header.Size = UDim2.new(1, 0, 0, L.HeaderH)
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
	Text           = Color3.fromRGB(255,255,255),
	TextSub        = Color3.fromRGB(148,154,175),
	TextHint       = Color3.fromRGB(85,90,108),
	ToggleOn       = Color3.fromRGB(38,212,78),
	ToggleOnDark   = Color3.fromRGB(18,148,50),
	ToggleOff      = Color3.fromRGB(40,44,56),
	NotifSuccess   = Color3.fromRGB(38,185,75),
	NotifWarning   = Color3.fromRGB(220,155,20),
	NotifInfo      = Color3.fromRGB(55,145,230),
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
	Version    = "3.3.0",
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
local FONT_FREDOKA: Font; local FONT_DESC: Font
local function _refreshFonts()
	FONT_TITLE   = Font.fromEnum(L.FontTitle); FONT_TAB  = Font.fromEnum(L.FontTab)
	FONT_UI      = Font.fromEnum(L.FontUI);    FONT_BOLD = Font.fromEnum(L.FontBold)
	FONT_FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	FONT_DESC    = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Italic)
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
	local notifBarColor = opts.Type == "success" and T.NotifSuccess
		or opts.Type == "warning" and T.NotifWarning
		or opts.Type == "info"    and T.NotifInfo
		or T.NotifBar
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
		BackgroundColor3 = notifBarColor, Parent = card,
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
		BackgroundColor3 = notifBarColor, Parent = card,
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

	-- MasterContainer: transparent wrapper that positions all three panels
	local master = Creator.New("Frame", {
		Name = "MasterContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(L.MasterW, L.MasterH),
		BackgroundTransparency = 1, ClipsDescendants = false,
	}) :: Frame
	master.Parent = gui

	-- CenterWindow: opaque main panel
	local root = Creator.New("Frame", {
		Name = "CenterWindow",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(W, H),
		ClipsDescendants = false,
		ThemeTag = { BackgroundColor3 = "WinBg" },
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeRoot, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = root,
	})
	root.Parent = master

	-- HeaderBar
	local hdr = Creator.New("Frame", {
		Name = "HeaderBar", Size = UDim2.new(1, 0, 0, HDR_H),
		ThemeTag = { BackgroundColor3 = "HdrMid" }, Parent = root,
	}) :: Frame
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = hdr })
	Creator.New("UIStroke", {
		Thickness = L.StrokeHdr, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = hdr,
	})
	Creator.New("Frame", {
		Name = "LeftDarkAccent", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
	Creator.New("Frame", {
		Name = "BottomDarkAccent", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
	Creator.New("TextLabel", {
		Name = "TitleLabel", Text = title, FontFace = FONT_TITLE,
		TextSize = L.TitleSize, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "Text" }, Parent = hdr,
	}, {
		Creator.New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = L.TitleStrokeW,
			LineJoinMode = Enum.LineJoinMode.Miter }),
	})
	if subtitle ~= "" then
		Creator.New("TextLabel", {
			Name = "SubTitle", Text = subtitle, FontFace = FONT_UI,
			TextSize = L.SubtitleSize, TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -L.SubtitleBottomPad),
			Size = UDim2.new(0.6, 0, 0, L.SubtitleSize + L.LabelPad),
			BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "TextSub" }, Parent = hdr,
		})
	end

	-- Close button (X, top-right of header)
	local closeBtn = Creator.New("TextButton", {
		Name = "CloseButton", Text = "X", FontFace = FONT_TITLE, TextSize = 26,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -L.HeaderBtnRightPad, 0.5, 0),
		Size = UDim2.fromOffset(44, 44), AutoButtonColor = false, ZIndex = 4,
		ThemeTag = { BackgroundColor3 = "HdrMid", TextColor3 = "Text" }, Parent = hdr,
	}) :: TextButton
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = closeBtn })
	Creator.New("UIStroke", {
		Thickness = L.StrokeClose, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = closeBtn,
	})
	Creator.New("Frame", {
		Name = "LeftDarkAccent", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 5, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = closeBtn,
	})
	Creator.New("Frame", {
		Name = "BottomDarkAccent", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 5, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = closeBtn,
	})

	-- SectionHeader (collapsible accordion bar below HeaderBar)
	local sectionOpen = true
	local sectionHeader = Creator.New("TextButton", {
		Name = "SectionHeader",
		Position = UDim2.new(0, 0, 0, HDR_H + 2),
		Size = UDim2.new(1, 0, 0, L.SectionBarH),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 2, Parent = root,
	}) :: TextButton
	local secContent = Creator.New("Frame", {
		Name = "Content", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 240, 1, 0),
		BackgroundTransparency = 1, Parent = sectionHeader,
	}) :: Frame
	local secTitle = Creator.New("TextLabel", {
		Name = "SectionTitle", Text = "", FontFace = FONT_FREDOKA, TextSize = 23,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1, ZIndex = 3,
		ThemeTag = { TextColor3 = "Text" }, Parent = secContent,
	}) :: TextLabel
	Creator.New("UIStroke", {
		Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = secTitle,
	})
	local chevronFrame = Instance.new("Frame")
	chevronFrame.Name = "ChevronIcon"; chevronFrame.BackgroundTransparency = 1
	chevronFrame.AnchorPoint = Vector2.new(0, 0.5)
	chevronFrame.Position = UDim2.new(0, 0, 0.5, 0)
	chevronFrame.Size = UDim2.fromOffset(16, 16); chevronFrame.Parent = secContent
	local rotBox = Creator.New("Frame", {
		Name = "RotatedBox", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(12, 12),
		Rotation = 45, BorderSizePixel = 0, BackgroundTransparency = 1, Parent = chevronFrame,
	})
	Creator.New("Frame", {
		Name = "BottomBar", Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3),
		BorderSizePixel = 0, ThemeTag = { BackgroundColor3 = "Text" }, Parent = rotBox,
	})
	Creator.New("Frame", {
		Name = "RightBar", Position = UDim2.new(1, -3, 0, 0), Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0, ThemeTag = { BackgroundColor3 = "Text" }, Parent = rotBox,
	})

	-- PagesHolder (scrollable content area, between SectionHeader and BottomBar)
	local pagesTop = 108  -- HDR_H(64) + 2 + SectionBarH(38) + 4 = 108
	local pagesH   = H - pagesTop - L.BottomBarH
	local pagesHolder = Instance.new("Frame")
	pagesHolder.Name = "PagesHolder"
	pagesHolder.Position = UDim2.new(0, 12, 0, pagesTop)
	pagesHolder.Size = UDim2.new(1, -24, 0, pagesH)
	pagesHolder.BackgroundTransparency = 1; pagesHolder.ClipsDescendants = true
	pagesHolder.Parent = root

	-- BottomBar (search + resize grip)
	local bottomBar = Creator.New("Frame", {
		Name = "BottomBar",
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, L.BottomBarH),
		ThemeTag = { BackgroundColor3 = "SidebarBg" }, Parent = root,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeSidebar, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "SidebarBorder" }, Parent = bottomBar,
	})
	Creator.New("TextLabel", {
		Name = "SearchLabel", Text = "Search", FontFace = FONT_FREDOKA, TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(0, 80, 1, 0),
		BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" }, Parent = bottomBar,
	})
	local searchContainer = Instance.new("Frame")
	searchContainer.Name = "SearchFieldContainer"
	searchContainer.AnchorPoint = Vector2.new(0, 0)
	searchContainer.Position = UDim2.new(0, 105, 0.5, -17)
	searchContainer.Size = UDim2.new(1, -165, 0, 34)
	searchContainer.BackgroundColor3 = Color3.fromRGB(6, 8, 6)
	searchContainer.BackgroundTransparency = 0; searchContainer.BorderSizePixel = 0
	searchContainer.Parent = bottomBar
	Creator.New("UIStroke", {
		Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = searchContainer,
	})
	local searchInput = Creator.New("TextBox", {
		Name = "SearchInput", Text = "", PlaceholderText = (cfg and cfg.SearchPlaceholder) or "Filter features\226\128\166",
		FontFace = FONT_UI, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1,
		PlaceholderColor3 = Color3.fromRGB(130,135,140),
		ThemeTag = { TextColor3 = "Text" },
		Parent = searchContainer,
	}) :: TextBox

	-- LeftSidebar (external, to the left of CenterWindow)
	local leftSidebar = Instance.new("ScrollingFrame")
	leftSidebar.Name = "LeftSidebar"; leftSidebar.AnchorPoint = Vector2.new(1, 0)
	leftSidebar.Position = UDim2.new(0.5, -L.SidebarXOffset, 0, L.SidebarTopOffset)
	leftSidebar.Size = UDim2.fromOffset(SIDE_W, L.SidebarH)
	leftSidebar.BackgroundTransparency = 1; leftSidebar.BorderSizePixel = 0
	leftSidebar.ScrollBarThickness = 0; leftSidebar.ScrollingEnabled = false
	leftSidebar.AutomaticCanvasSize = Enum.AutomaticSize.None
	leftSidebar.Parent = master
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, L.TabListPad); leftLayout.Parent = leftSidebar

	-- RightSidebar (external, to the right of CenterWindow)
	local rightSidebar = Instance.new("ScrollingFrame")
	rightSidebar.Name = "RightSidebar"; rightSidebar.AnchorPoint = Vector2.new(0, 0)
	rightSidebar.Position = UDim2.new(0.5, L.SidebarXOffset, 0, L.SidebarTopOffset)
	rightSidebar.Size = UDim2.fromOffset(SIDE_W, L.SidebarH)
	rightSidebar.BackgroundTransparency = 1; rightSidebar.BorderSizePixel = 0
	rightSidebar.ScrollBarThickness = 0; rightSidebar.ScrollingEnabled = false
	rightSidebar.AutomaticCanvasSize = Enum.AutomaticSize.None
	rightSidebar.Parent = master
	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, L.RightTabListPad); rightLayout.Parent = rightSidebar

	-- Register frames for LayoutManager live updates
	_liveRefs = { root=root, header=hdr, master=master, pagesHolder=pagesHolder,
	              leftSidebar=leftSidebar, rightSidebar=rightSidebar, bottomBar=bottomBar }

	-- Drag (moves MasterContainer so all three panels move together)
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
			master.Position = UDim2.new(
				master.Position.X.Scale, master.Position.X.Offset + d.X,
				master.Position.Y.Scale, master.Position.Y.Offset + d.Y)
		end))
		maid:Give(UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end

	-- ReopenPill: shown when window is hidden, click to reopen
	local reopenPill = Creator.New("TextButton", {
		Name = "ReopenPill",
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(220, 44),
		Text = "OPEN " .. (title:upper()) .. "  [R-SHIFT]",
		FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextSize = 16, TextColor3 = Color3.fromRGB(255,255,255),
		AutoButtonColor = false, BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(224, 32, 32), ZIndex = 10, Visible = false,
		Parent = gui,
	}) :: TextButton
	Creator.New("UIStroke", {
		Thickness = 3.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = reopenPill,
	})
	Creator.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 52, 52)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 18, 18)),
		}), Rotation = 90, Parent = reopenPill,
	})

	-- Minimize (key shortcut hides window, shows ReopenPill)
	local minimised = false
	local function setMin(state: boolean)
		minimised = state
		master.Visible     = not state
		reopenPill.Visible = state
	end
	maid:Give(UserInputService.InputBegan:Connect(function(inp, gp)
		if not gp and inp.KeyCode == minKey then setMin(not minimised) end
	end))
	maid:Give(reopenPill.MouseButton1Click:Connect(function() setMin(false) end))

	-- Section accordion collapse
	maid:Give(sectionHeader.MouseButton1Click:Connect(function()
		sectionOpen = not sectionOpen
		pagesHolder.Visible = sectionOpen
		tw(rotBox, { Rotation = sectionOpen and 45 or 225 }, Anim.Default)
	end))

	-- Live search filter (filters row titles in the currently active page)
	maid:Give(searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchInput.Text:lower()
		for _, pg in ipairs(pagesHolder:GetChildren()) do
			if pg:IsA("ScrollingFrame") and pg.Visible then
				for _, sec in ipairs(pg:GetChildren()) do
				if sec:IsA("Frame") then
					local innerF = sec:FindFirstChild("Inner")
					if innerF then
						for _, row in ipairs(innerF:GetChildren()) do
							if row:IsA("Frame") then
								local t = row:FindFirstChildWhichIsA("TextLabel")
								if t then row.Visible = (q == "" or t.Text:lower():find(q, 1, true) ~= nil) end
							end
						end
					end
				end
				end
			end
		end
	end))

	-- Tab state: red accent strip + bright label for active; dark base + muted label for inactive
	local activeTab: any = nil
	local function activateTab(tab: any)
		if activeTab == tab then return end
		if activeTab then
			activeTab._page.Visible = false
			tw(activeTab._btn, { BackgroundColor3 = T.SidebarBg }, Anim.Tab)
			activeTab._accent.Visible = false
			activeTab._btnLabel.TextColor3 = T.TabText
			Creator.Reg[activeTab._btnLabel] = { TextColor3 = "TabText" }
		end
		activeTab = tab; tab._page.Visible = true
		tw(tab._btn, { BackgroundColor3 = T.TabActiveBg }, Anim.Tab)
		tab._accent.Visible = true
		tab._btnLabel.TextColor3 = T.TabTextActive
		Creator.Reg[tab._btnLabel] = { TextColor3 = "TabTextActive" }
		secTitle.Text = tab._label
	end

	local Window: any = { _gui = gui, _root = master, _maid = maid, _tabs = {} :: {any}, _utilTabs = {} :: {any} }

	function Window:Tab(tabLabel: string, opts_: {Side: string?}?): any
		local side = (opts_ and opts_.Side) or "left"
		local targetSidebar = (side == "right") and rightSidebar or leftSidebar
		local tabIdx = (side == "right") and (#self._utilTabs + 1) or (#self._tabs + 1)
		local pageName = (side == "right") and ("Page_Util" .. tabIdx) or ("Page_Tab" .. tabIdx)

		-- Tab button (dark sidebar base, red accent strip visible when active)
		local btn = Creator.New("TextButton", {
			Name = (side == "right") and ("Util_" .. tabIdx) or ("Tab_" .. tabIdx),
			Text = "", Size = UDim2.new(1, 0, 0, L.TabH),
			AutoButtonColor = false, LayoutOrder = tabIdx, ZIndex = 2,
			ThemeTag = { BackgroundColor3 = "SidebarBg" }, Parent = targetSidebar,
		}) :: TextButton
		Creator.New("UIStroke", {
			Thickness = L.StrokeTabBtn, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "SidebarBorder" }, Parent = btn,
		})
		local accent = Creator.New("Frame", {
			Name = "Accent", Size = UDim2.new(0, L.TabAccentW, 1, 0), BorderSizePixel = 0,
			Visible = false, ZIndex = 3,
			ThemeTag = { BackgroundColor3 = "TabActiveLeft" }, Parent = btn,
		})
		local isRight = (side == "right")
		local btnLabel = Creator.New("TextLabel", {
			Name = "Label", Text = tabLabel,
			FontFace = isRight and FONT_FREDOKA or FONT_TITLE,
			TextSize = isRight and L.RightTabTextSize or L.TabTextSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1, ZIndex = 3,
			ThemeTag = { TextColor3 = "TabText" }, Parent = btn,
		}) :: TextLabel

		local page = Creator.New("ScrollingFrame", {
			Name = pageName, Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = L.ScrollBarThick, ScrollBarImageColor3 = T.ScrollBar,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = pagesHolder,
		}) :: ScrollingFrame
		Creator.New("UIStroke", {
			Thickness = L.StrokePage, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = page,
		})
		local pageLayout = Instance.new("UIListLayout")
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Padding = UDim.new(0, L.PageSectionGap); pageLayout.Parent = page
		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingTop    = UDim.new(0, L.PagePad); pagePad.PaddingBottom = UDim.new(0, L.PagePad)
		pagePad.PaddingLeft   = UDim.new(0, L.PagePad); pagePad.PaddingRight  = UDim.new(0, L.PagePad)
		pagePad.Parent = page

		local Tab: any = { _btn=btn, _btnLabel=btnLabel, _accent=accent, _page=page, _label=tabLabel, _sections={} }
		maid:Give(btn.MouseButton1Click:Connect(function() activateTab(Tab) end))
		maid:Give(btn.MouseEnter:Connect(function()
			if activeTab ~= Tab then tw(btn, { BackgroundColor3 = T.TabHoverBg }, Anim.Tab) end
		end))
		maid:Give(btn.MouseLeave:Connect(function()
			if activeTab ~= Tab then tw(btn, { BackgroundColor3 = T.SidebarBg }, Anim.Tab) end
		end))
		if side == "right" then
			table.insert(self._utilTabs, Tab)
			if #self._utilTabs == 1 and not activeTab then activateTab(Tab) end
		else
			table.insert(self._tabs, Tab)
			if #self._tabs == 1 then activateTab(Tab) end
		end

		function Tab:Section(_sectionLabel: string?): any
				local secFrame = Creator.New("Frame", {
				Name = "Section", Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = #self._sections + 1,
				ThemeTag = { BackgroundColor3 = "SectionBg" }, Parent = page,
				}) :: Frame
				Creator.New("UIStroke", {
				Thickness = L.StrokeSection, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				ThemeTag = { Color = "RowBorderOuter" }, Parent = secFrame,
				})
				Creator.New("Frame", {
				Name = "BevelL", Size = UDim2.new(0, L.BevelSize, 1, 0),
				BorderSizePixel = 0, ZIndex = 3,
				ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
				})
				Creator.New("Frame", {
				Name = "BevelB", AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
				BorderSizePixel = 0, ZIndex = 3,
				ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
				})
				-- Optional colored section header strip
				local innerOffsetY = 0
				if _sectionLabel and _sectionLabel ~= "" then
				innerOffsetY = 26
				local hStrip = Creator.New("Frame", {
					Name = "SectionHeader", Size = UDim2.new(1, 0, 0, 26),
					ZIndex = 2, ThemeTag = { BackgroundColor3 = "SectionBevel" }, Parent = secFrame,
				})
				Creator.New("TextLabel", {
					Text = _sectionLabel:upper(), FontFace = FONT_UI, TextSize = L.SectionHeaderTextSize,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, L.SectionLabelIndent, 0, 0),
					Size = UDim2.new(1, -L.SectionLabelIndent, 1, 0),
					BackgroundTransparency = 1, ZIndex = 3,
					ThemeTag = { TextColor3 = "Text" }, Parent = hStrip,
				})
				end
				local inner = Instance.new("Frame")
				inner.Name = "Inner"
				inner.Position = UDim2.new(0, 0, 0, innerOffsetY)
				inner.Size = UDim2.new(1, 0, 0, 0); inner.AutomaticSize = Enum.AutomaticSize.Y
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
				if not el:IsDisabled() then
					tw(row, { BackgroundColor3 = T.RowBgHover }, Anim.Row)
				end
				end))
				maid:Give(row.MouseLeave:Connect(function()
				tw(row, { BackgroundColor3 = T.RowBg }, Anim.Row)
				end))
			end
			-- mkLabel: token="name" uses FredokaOne+UIStroke, token="desc" uses BuilderSans Italic
			local function mkLabel(txt: string, _size: number, token: string, parent: Instance, _bold: boolean?): TextLabel
				local isName = (token == "Text")
				local isDesc = (token == "TextSub")
				local l = Creator.New("TextLabel", {
				Text = txt,
				FontFace = isDesc and FONT_DESC or FONT_FREDOKA,
				TextSize = isName and L.ElemNameSize or L.ElemDescSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, (isName and L.ElemNameSize or L.ElemDescSize) + L.LabelPad),
				ThemeTag = { TextColor3 = token },
				}) :: TextLabel
				if isName then
				Creator.New("UIStroke", {
					Thickness = 1.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
					LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = l,
				})
				end
				l.Parent = parent; return l
			end

			-- ── Toggle ────────────────────────────────────────────────────
			function Section:Toggle(opts: {
				Id: string, Name: string, Default: boolean?,
				Description: string?, Callback: ((boolean) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local on  = opts.Default == true
				local hasDesc = opts.Description ~= nil
				local row = mkRow(hasDesc and L.RowHDesc or L.RowH)
				-- Name label: full-height for no-desc rows, top-positioned for desc rows
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
				end
				-- SliderTrack (template-style rectangular toggle)
				local TW = L.ToggleW; local TH = L.ToggleH; local KS = L.ToggleKnobS
				local OFF_POS = UDim2.new(0, 3, 0.5, 0)
				local ON_POS  = UDim2.new(1, -(KS + 3), 0.5, 0)  -- (1,-25,0.5,0) for KS=22
				local track = Creator.New("TextButton", {
				Name = "SliderTrack", AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(TW, TH),
				AutoButtonColor = false,
				BackgroundColor3 = on and T.ToggleOn or T.ToggleOff, Parent = row,
				}) :: TextButton
				Creator.New("UIStroke", {
				Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = track,
				})
				local knob = Creator.New("Frame", {
				Name = "SliderKnob", AnchorPoint = Vector2.new(0, 0.5),
				Position = on and ON_POS or OFF_POS,
				Size = UDim2.fromOffset(KS, KS),
				BackgroundColor3 = Color3.fromRGB(250, 250, 250), Parent = track,
				}) :: Frame
				Creator.New("UIStroke", {
				Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = knob,
				})
				Creator.New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(145,145,150)),
				}), Rotation = 90, Parent = knob,
				})
				local el = mkBase(opts.Id, on, row)
				function el:_apply(v: boolean)
				on = v
				tw(knob, { Position = v and ON_POS or OFF_POS }, Anim.Toggle)
				tw(track, { BackgroundColor3 = v and T.ToggleOn or T.ToggleOff }, Anim.ToggleTrack)
				if opts.Callback then
					local ok, e = xpcall(opts.Callback, debug.traceback, v)
					if not ok then warn("[Ignis] Toggle cb: " .. e) end
				end
				end
				maid:Give(track.MouseButton1Click:Connect(function()
				if not el:IsDisabled() then el:Set(not on) end
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
				local hasDesc = opts.Description ~= nil
				local row  = mkRow(hasDesc and L.SliderRowHDesc or L.SliderRowH)
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.6, 0, 0.55, 0)
				end
				local valL = Creator.New("TextLabel", {
				Text = tostring(val), FontFace = FONT_FREDOKA, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 0, 6),
				Size = UDim2.new(0, L.SliderValLabelW, 0, L.SliderValLabelH),
				BackgroundTransparency = 1, ThemeTag = { TextColor3 = "TextSub" }, Parent = row,
				}) :: TextLabel
				local TRY = hasDesc and L.SliderTrackYD or L.SliderTrackY
				local track = Creator.New("Frame", {
				Position = UDim2.new(0, 16, 0, TRY),
				Size = UDim2.new(1, -16 - L.SliderTrackRightPad, 0, L.SliderTrackH),
				ThemeTag = { BackgroundColor3 = "SliderTrack" }, Parent = row,
				}) :: Frame
				Creator.New("UICorner", { CornerRadius = UDim.new(0, L.SliderTrackH // 2), Parent = track })
				local pct0 = (val - opts.Min) / (opts.Max - opts.Min)
				local fill = Creator.New("Frame", {
				Size = UDim2.new(pct0, 0, 1, 0), ThemeTag = { BackgroundColor3 = "SliderFill" }, Parent = track,
				})
				Creator.New("UICorner", { CornerRadius = UDim.new(0, L.SliderTrackH // 2), Parent = fill })
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
				Id: string, Name: string, Description: string?,
				Style: string?, Callback: (() -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local isPrimary = opts.Style == "primary"
				local hasDesc = opts.Description ~= nil
				local row = mkRow(hasDesc and L.RowHDesc or L.RowH)
				-- Primary style: accent-filled row
				if isPrimary then
				row.BackgroundColor3 = T.SliderFill
				row.BackgroundTransparency = 0.1
				Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = row })
				end
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
				end
				Creator.New("TextLabel", {
				Text = "›", FontFace = FONT_BOLD, TextSize = L.BtnChevronSize,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
				Size = UDim2.fromOffset(L.BtnChevronW, L.BtnChevronH),
				BackgroundTransparency = 1, ThemeTag = { TextColor3 = isPrimary and "Text" or "TextSub" }, Parent = row,
				})
				local el = mkBase(opts.Id, nil, row)
				function el:_apply(_v: any) end
				el.Press = function()
				if el:IsDisabled() then return end
				if opts.Callback then
					local ok, e = xpcall(opts.Callback, debug.traceback)
					if not ok then warn("[Ignis] Button cb: " .. e) end
				end
				tw(row, { BackgroundColor3 = T.SliderFill, BackgroundTransparency = 0 }, Anim.Button)
				task.delay((Anim.ButtonOut :: TweenInfo).Time, function()
					if isPrimary then
						tw(row, { BackgroundColor3 = T.SliderFill, BackgroundTransparency = 0.1 }, Anim.ButtonOut)
					else
						tw(row, { BackgroundColor3 = T.RowBg, BackgroundTransparency = 0 }, Anim.ButtonOut)
					end
				end)
				el._fire(nil)
				end
				maid:Give(row.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then el.Press() end
				end))
				if isPrimary then
				-- Hover for primary: slight brightening
				maid:Give(row.MouseEnter:Connect(function()
					if not el:IsDisabled() then
						tw(row, { BackgroundTransparency = 0 }, Anim.Row)
					end
				end))
				maid:Give(row.MouseLeave:Connect(function()
					tw(row, { BackgroundTransparency = 0.1 }, Anim.Row)
				end))
				else
				rowHover(row, el)
				end
				return el
			end

			-- ── Dropdown ──────────────────────────────────────────────────
			function Section:Dropdown(opts: {
				Id: string, Name: string, Options: {string},
				Default: string?, Description: string?,
				Multi: boolean?, Callback: ((any) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local multi  = opts.Multi == true
				local cur    = opts.Default or opts.Options[1] or ""
				local mSel: {[string]: boolean} = {}
				local hasDesc = opts.Description ~= nil
				local rowH   = hasDesc and L.RowHDesc or L.RowH
				local isOpen = false
				local row = mkRow(rowH)
				-- Name label positioned like toggle
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
				end
				-- DropdownPill: 160×38, dark BG, AP=(1,0.5), offset from right
				local pill = Creator.New("TextButton", {
				Name = "DropdownPill",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(160, 38),
				Text = "", AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(6, 8, 6), Parent = row,
				}) :: TextButton
				Creator.New("UIStroke", {
				Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = pill,
				})
				local dispL = Creator.New("TextLabel", {
				Name = "ValueLabel", Text = cur,
				FontFace = FONT_FREDOKA, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -38, 1, 0),
				BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
				ThemeTag = { TextColor3 = "Text" }, Parent = pill,
				}) :: TextLabel
				Creator.New("UIStroke", {
				Thickness = 1.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = dispL,
				})
				-- Chevron (green RotatedBox)
				local chev = Instance.new("Frame")
				chev.Name = "ChevronIcon"; chev.BackgroundTransparency = 1
				chev.AnchorPoint = Vector2.new(1, 0.5)
				chev.Position = UDim2.new(1, -8, 0.5, 0)
				chev.Size = UDim2.fromOffset(14, 14); chev.Parent = pill
				local rBox = Instance.new("Frame")
				rBox.Name = "RotatedBox"; rBox.BackgroundTransparency = 1
				rBox.AnchorPoint = Vector2.new(0.5, 0.5)
				rBox.Position = UDim2.new(0.5, 0, 0.5, 0)
				rBox.Size = UDim2.fromOffset(10, 10); rBox.Rotation = 45; rBox.Parent = chev
				Creator.New("Frame", {
				Name = "BottomBar", Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = Color3.fromRGB(40,215,80), BorderSizePixel = 0, Parent = rBox,
				})
				Creator.New("Frame", {
				Name = "RightBar", Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0, 2, 1, 0),
				BackgroundColor3 = Color3.fromRGB(40,215,80), BorderSizePixel = 0, Parent = rBox,
				})
				-- DropdownMenu: frame anchored to bottom of pill, ZIndex=50
				local optH  = 32
				local menuH = math.min(#opts.Options * optH, 128)
				local menu = Creator.New("Frame", {
				Name = "DropdownMenu",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 1, 4),
				Size = UDim2.fromOffset(160, menuH),
				BackgroundColor3 = Color3.fromRGB(14, 18, 14),
				ZIndex = 50, Visible = false, Parent = row,
				}) :: Frame
				Creator.New("UIStroke", {
				Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = menu,
				})
				local mList = Instance.new("UIListLayout")
				mList.SortOrder = Enum.SortOrder.LayoutOrder; mList.Parent = menu
				for _, opt in ipairs(opts.Options) do
				local ob = Creator.New("TextButton", {
					Text = opt, FontFace = FONT_FREDOKA, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 0, optH), AutoButtonColor = true,
					ZIndex = 51, BackgroundColor3 = Color3.fromRGB(14,18,14),
					ThemeTag = { TextColor3 = "Text" }, Parent = menu,
				}) :: TextButton
				maid:Give(ob.MouseButton1Click:Connect(function()
					if multi then
						mSel[opt] = not mSel[opt]
						local sel: {string} = {}
						for _, o in ipairs(opts.Options) do if mSel[o] then table.insert(sel, o) end end
						dispL.Text = #sel > 0 and table.concat(sel, ", ") or "None"
						if opts.Callback then xpcall(opts.Callback, debug.traceback, sel) end
					else
						cur = opt; dispL.Text = opt
						menu.Visible = false; isOpen = false
						if opts.Callback then xpcall(opts.Callback, debug.traceback, opt) end
					end
				end))
				end
				local shield = Instance.new("TextButton")
				shield.Name = "Shield"; shield.Size = UDim2.new(1, 0, 1, 0)
				shield.BackgroundTransparency = 1; shield.Text = ""; shield.ZIndex = 49
				shield.Visible = false; shield.Parent = pagesHolder
				local function close()
				menu.Visible = false; shield.Visible = false; isOpen = false
				end
				maid:Give(pill.MouseButton1Click:Connect(function()
				isOpen = not isOpen; menu.Visible = isOpen; shield.Visible = isOpen
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
				local hasDesc = opts.Description ~= nil
				local row = mkRow(hasDesc and L.InputRowHDesc or L.InputRowH)
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
				end
				local ibg = Creator.New("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.new(0, 160, 0, L.InputBoxH),
				ThemeTag = { BackgroundColor3 = "InputBg" }, Parent = row,
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
				local hasDesc = opts.Description ~= nil
				local row = mkRow(hasDesc and L.RowHDesc or L.RowH)
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
				end
				local pill = Creator.New("TextButton", {
				Text = bound == Enum.KeyCode.Unknown and "None" or bound.Name,
				FontFace = FONT_UI, TextSize = L.ElemDescSize, AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
				Size = UDim2.fromOffset(L.KeybindPillW, L.KeybindPillH), ZIndex = 2,
				ThemeTag = { BackgroundColor3 = "InputBg", TextColor3 = "TextSub" }, Parent = row,
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
				local row = mkRow(L.RowHLabel)
				local nl = mkLabel(opts.Name, L.ElemValueSize, "TextSub", row)
				nl.Position = UDim2.new(0, 16, 0, 0)
				nl.Size = UDim2.new(0.5, 0, 1, 0)
				local vl = Creator.New("TextLabel", {
				Text = opts.Value or "", FontFace = FONT_UI, TextSize = L.ElemValueSize,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ThemeTag = { TextColor3 = opts.Color or "Text" }, Parent = row,
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

			-- ── ColorPicker ───────────────────────────────────────────────
			function Section:ColorPicker(opts: {
				Id: string, Name: string, Default: Color3?,
				Description: string?, Callback: ((Color3) -> ())?,
			}): any
				if Library.Options[opts.Id] then return Library.Options[opts.Id] end
				local col = opts.Default or Color3.fromRGB(255, 255, 255)
				local r_ = math.round(col.R * 255)
				local g_ = math.round(col.G * 255)
				local b_ = math.round(col.B * 255)
				local hasDesc = opts.Description ~= nil
				local row = mkRow(hasDesc and L.RowHDesc or L.RowH)
				local nameLabel = mkLabel(opts.Name, L.ElemNameSize, "Text", row, true)
				if hasDesc then
				nameLabel.Position = UDim2.new(0, 16, 0, 8)
				nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
				local dl = mkLabel(opts.Description :: string, L.ElemDescSize, "TextSub", row)
				dl.Position = UDim2.new(0, 16, 0, 42)
				dl.Size = UDim2.new(0.6, 0, 0, 22)
				else
				nameLabel.Position = UDim2.new(0, 16, 0, 0)
				nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
				end
				-- Color swatch
				local swatch = Creator.New("TextButton", {
				Name = "ColorSwatch", Text = "",
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(40, 24), AutoButtonColor = false,
				BackgroundColor3 = col, ZIndex = 2, Parent = row,
				}) :: TextButton
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = swatch })
				Creator.New("UIStroke", {
				Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = swatch,
				})
				-- Picker panel
				local PANEL_W = 200; local PANEL_H = 104
				local MS_H = 4; local MS_KNOB = 10
				local panel = Creator.New("Frame", {
				Name = "ColorPickerPanel",
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 1, 6),
				Size = UDim2.fromOffset(PANEL_W, PANEL_H),
				BackgroundColor3 = Color3.fromRGB(10, 13, 10),
				ZIndex = 50, Visible = false, ClipsDescendants = false, Parent = row,
				}) :: Frame
				Creator.New("UIStroke", {
				Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0,0,0), Parent = panel,
				})
				local preview = Instance.new("Frame")
				preview.Name = "Preview"; preview.Size = UDim2.new(1, 0, 0, 12)
				preview.BackgroundColor3 = col; preview.BorderSizePixel = 0; preview.ZIndex = 51
				preview.Parent = panel
				-- hexL reference held in a table so mini-sliders can update it after creation
				local hexRef: {l: TextLabel?} = { l = nil }
				local function rebuildColor()
				col = Color3.fromRGB(r_, g_, b_)
				swatch.BackgroundColor3 = col; preview.BackgroundColor3 = col
				if hexRef.l then hexRef.l.Text = string.format("#%02X%02X%02X", r_, g_, b_) end
				if opts.Callback then xpcall(opts.Callback, debug.traceback, col) end
				end
				-- Mini-slider builder (channel: 1=R 2=G 3=B, yOff: vertical offset in panel)
				local function mkMiniSlider(ch: number, yOff: number)
				local labels = {"R","G","B"}
				local getV = function(): number
					if ch == 1 then return r_ elseif ch == 2 then return g_ else return b_ end
				end
				local setV = function(v: number)
					if ch == 1 then r_ = v elseif ch == 2 then g_ = v else b_ = v end
				end
				local lbl = Instance.new("TextLabel")
				lbl.Text = labels[ch]; lbl.FontFace = FONT_UI; lbl.TextSize = 10
				lbl.TextColor3 = T.TextSub; lbl.BackgroundTransparency = 1; lbl.ZIndex = 52
				lbl.Position = UDim2.new(0, 8, 0, yOff); lbl.Size = UDim2.fromOffset(10, 14)
				lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = panel
				Creator.Reg[lbl :: any] = { TextColor3 = "TextSub" }
				local slTr = Creator.New("Frame", {
					Position = UDim2.new(0, 22, 0, yOff + 4),
					Size = UDim2.new(1, -22-30, 0, MS_H),
					BackgroundColor3 = Color3.fromRGB(26,33,26),
					ZIndex = 51, Parent = panel,
				}) :: Frame
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = slTr })
				local pct0 = getV() / 255
				local slFl = Creator.New("Frame", {
					Size = UDim2.new(pct0, 0, 1, 0),
					ThemeTag = { BackgroundColor3 = "SliderFill" }, ZIndex = 52, Parent = slTr,
				}) :: Frame
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = slFl })
				local slKn = Creator.New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(pct0, 0, 0.5, 0),
					Size = UDim2.fromOffset(MS_KNOB, MS_KNOB),
					BackgroundColor3 = Color3.fromRGB(255,255,255),
					ZIndex = 53, Parent = slTr,
				}) :: Frame
				Creator.New("UICorner", { CornerRadius = UDim.new(0, MS_KNOB // 2), Parent = slKn })
				local valL = Instance.new("TextLabel")
				valL.Text = tostring(getV()); valL.FontFace = FONT_UI; valL.TextSize = 10
				valL.TextColor3 = T.TextSub; valL.BackgroundTransparency = 1; valL.ZIndex = 52
				valL.AnchorPoint = Vector2.new(1, 0)
				valL.Position = UDim2.new(1, -4, 0, yOff); valL.Size = UDim2.fromOffset(24, 14)
				valL.TextXAlignment = Enum.TextXAlignment.Right; valL.Parent = panel
				Creator.Reg[valL :: any] = { TextColor3 = "TextSub" }
				local function fromX(x: number): number
					local ax = slTr.AbsolutePosition.X; local aw = slTr.AbsoluteSize.X
					return math.clamp(math.round(math.clamp((x-ax)/aw, 0, 1) * 255), 0, 255)
				end
				local function update(v: number)
					setV(v)
					local pct = v / 255
					slFl.Size = UDim2.new(pct, 0, 1, 0); slKn.Position = UDim2.new(pct, 0, 0.5, 0)
					valL.Text = tostring(v); rebuildColor()
				end
				local cpDrag = false
				maid:Give(slTr.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						cpDrag = true; update(fromX(inp.Position.X))
					end
				end))
				maid:Give(UserInputService.InputChanged:Connect(function(inp)
					if cpDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
						update(fromX(inp.Position.X))
					end
				end))
				maid:Give(UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then cpDrag = false end
				end))
				end
				mkMiniSlider(1, 16); mkMiniSlider(2, 40); mkMiniSlider(3, 64)
				-- Hex display
				local hexL = Instance.new("TextLabel")
				hexL.Text = string.format("#%02X%02X%02X", r_, g_, b_)
				hexL.FontFace = FONT_UI; hexL.TextSize = 10
				hexL.TextColor3 = T.TextHint; hexL.BackgroundTransparency = 1
				hexL.AnchorPoint = Vector2.new(0.5, 0); hexL.Position = UDim2.new(0.5, 0, 0, 88)
				hexL.Size = UDim2.new(0.9, 0, 0, 12)
				hexL.TextXAlignment = Enum.TextXAlignment.Center; hexL.ZIndex = 52; hexL.Parent = panel
				Creator.Reg[hexL :: any] = { TextColor3 = "TextHint" }
				hexRef.l = hexL
				-- Close shield
				local cpShield = Instance.new("TextButton")
				cpShield.Name = "CPShield"; cpShield.Size = UDim2.new(1, 0, 1, 0)
				cpShield.BackgroundTransparency = 1; cpShield.Text = ""; cpShield.ZIndex = 49
				cpShield.Visible = false; cpShield.Parent = pagesHolder
				local pickerOpen = false
				local function closeCP()
				panel.Visible = false; cpShield.Visible = false; pickerOpen = false
				end
				maid:Give(swatch.MouseButton1Click:Connect(function()
				pickerOpen = not pickerOpen
				panel.Visible = pickerOpen; cpShield.Visible = pickerOpen
				end))
				maid:Give(cpShield.MouseButton1Click:Connect(closeCP))
				local el = mkBase(opts.Id, col, row)
				function el:_apply(v: any)
				if typeof(v) == "Color3" then
					col = v :: Color3
					r_ = math.round(col.R * 255)
					g_ = math.round(col.G * 255)
					b_ = math.round(col.B * 255)
					swatch.BackgroundColor3 = col; preview.BackgroundColor3 = col
					if hexRef.l then hexRef.l.Text = string.format("#%02X%02X%02X", r_, g_, b_) end
				end
				if opts.Callback then xpcall(opts.Callback, debug.traceback, col) end
				end
				rowHover(row, el); return el
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

	-- Close button hides window (shows ReopenPill to reopen); Destroy() still available via API
	maid:Give(closeBtn.MouseButton1Click:Connect(function() setMin(true) end))

	Library.Window = Window
	return Window
end

-- ── getgenv registration ──────────────────────────────────────────────────
if typeof(getgenv) == "function" then
	pcall(function() getgenv().Ignis = Library end)
end

return Library
