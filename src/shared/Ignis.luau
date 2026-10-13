--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

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

local function _getGenv(): any
	return (typeof(getgenv) == "function" and getgenv()) or {}
end
local function SafeParentGui(gui: ScreenGui)
	gui.DisplayOrder = 999; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local genv = _getGenv()
	local protect = rawget(genv, "protectgui") or (rawget(genv, "syn") and (genv.syn :: any).protect_gui)
	if protect then pcall(protect, gui) end
	local gh = rawget(genv, "gethui")
	if gh then
		local ok, hui = pcall(gh)
		if ok and hui then gui.Parent = hui; return end
	end
	local ok, cg = pcall(game.GetService, game, "CoreGui")
	if ok and cg then pcall(function() gui.Parent = cg end) end
	if not gui.Parent then
		pcall(function() gui.Parent = game:GetService("StarterGui") end)
	end
end


local L = {
	MasterW                  = 1130,
	MasterH                  = 670,
	WindowW                  = 740,
	WindowH                  = 660,
	HeaderH                  = 64,
	SidebarW                 = 175,
	SidebarH                 = 580,
	SidebarTopOffset         = 70,
	SidebarXOffset           = 388,
	BottomBarH               = 54,
	SectionBarH              = 38,
	TitleSize                = 34,
	SubtitleSize             = 11,
	TitleStrokeW             = 3.2,
	HeaderBtnRightPad        = 10,
	SubtitleBottomPad        = 8,
	TabAccentW               = 3,
	TabH                     = 58,
	TabTextSize              = 24,
	RightTabTextSize         = 22,
	TabListPad               = 10,
	RightTabListPad          = 14,
	SectionHeaderH           = 38,
	SectionHeaderTextSize    = 10,
	SectionLabelIndent       = 12,
	BevelSize                = 4,
	PageSectionGap           = 4,
	PagePad                  = 6,
	RowListPad               = 7,
	RowH                     = 64,
	RowHDesc                 = 78,
	RowHLabel                = 44,
	RowIndent                = 10,
	LabelPad                 = 6,
	ElemRightPad             = 10,
	ParagraphItemGap         = 4,
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
	InputRowH                = 56,
	InputRowHDesc            = 72,
	InputBoxH                = 22,
	InputBoxBottomPad        = 7,
	InputPadH                = 6,
	ToggleW                  = 58,
	ToggleH                  = 28,
	ToggleKnobS              = 22,
	DropdownOptH             = 28,
	DropdownOptPadL          = 10,
	DropdownChevronSize      = 10,
	DropdownChevronContainerS = 12,
	DropdownChevronRightPad  = 8,
	DropdownLabelH           = 14,
	DropdownLabelRightPad    = 22,
	BtnChevronSize           = 18,
	BtnChevronW              = 16,
	BtnChevronH              = 20,
	KeybindPillW             = 72,
	KeybindPillH             = 22,
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
	StrokePage               = 2.6,
	StrokeNotif              = 1.5,
	FontTitle                = Enum.Font.LuckiestGuy,
	FontTab                  = Enum.Font.LuckiestGuy,
	FontUI                   = Enum.Font.GothamMedium,
	FontBold                 = Enum.Font.GothamBold,
	ElemNameSize             = 20,
	ElemDescSize             = 13,
	ElemValueSize            = 15,
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
	ScrollBarThick           = 6,
}

local _L_DEFAULTS: {[string]: any} = {}
do for k, v in pairs(L) do _L_DEFAULTS[k] = v end end

local _windowBuilt = false

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

local Library: any = {
	Window = nil,
	Options = {},
	Version = "3.4.0",
	_theme = "Ignis Dark",
	_themeSubs = {},
}
Library.__index = Library

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

local Anim: any = setmetatable({}, {
	__index = function(_, k)
		return Library.Anim and Library.Anim[k]
	end,
})

local function tw(inst: Instance, props: {[string]: any}, info: TweenInfo?)
	if Library._tw then
		Library._tw(inst, props, info)
		return
	end
	for k, v in pairs(props) do
		pcall(function()
			(inst :: any)[k] = v
		end)
	end
end

local BASE: {[string]: Color3} = {
	WinBg          = Color3.fromRGB(18,22,18),
	HdrTop         = Color3.fromRGB(248,55,55),
	HdrMid         = Color3.fromRGB(224,32,32),
	HdrBot         = Color3.fromRGB(110,10,10),
	HdrBevel       = Color3.fromRGB(115,14,14),
	HdrBorder      = Color3.fromRGB(0,0,0),
	SidebarBg      = Color3.fromRGB(10,12,10),
	SidebarBorder  = Color3.fromRGB(0,0,0),
	TabHoverBg     = Color3.fromRGB(248,55,55),
	TabActiveBg    = Color3.fromRGB(224,32,32),
	TabActiveLeft  = Color3.fromRGB(115,14,14),
	TabText        = Color3.fromRGB(255,255,255),
	TabTextActive  = Color3.fromRGB(255,255,255),
	ContentBg      = Color3.fromRGB(10,14,10),
	SectionBg      = Color3.fromRGB(10,14,10),
	SectionBorder  = Color3.fromRGB(0,0,0),
	SectionBevel   = Color3.fromRGB(115,14,14),
	RowBg          = Color3.fromRGB(12,16,12),
	RowBgHover     = Color3.fromRGB(18,24,18),
	RowBorder      = Color3.fromRGB(34,40,34),
	RowBorderOuter = Color3.fromRGB(0,0,0),
	Text           = Color3.fromRGB(255,255,255),
	TextSub        = Color3.fromRGB(180,190,185),
	TextHint       = Color3.fromRGB(110,120,110),
	ToggleOn       = Color3.fromRGB(38,212,78),
	ToggleOnDark   = Color3.fromRGB(18,148,50),
	ToggleOff      = Color3.fromRGB(10,14,10),
	NotifSuccess   = Color3.fromRGB(38,185,75),
	NotifWarning   = Color3.fromRGB(220,155,20),
	NotifInfo      = Color3.fromRGB(55,145,230),
	ToggleKnob     = Color3.fromRGB(250,250,250),
	SliderTrack    = Color3.fromRGB(10,14,10),
	SliderFill     = Color3.fromRGB(224,32,32),
	SliderKnob     = Color3.fromRGB(250,250,250),
	InputBg        = Color3.fromRGB(8,11,8),
	InputBorder    = Color3.fromRGB(0,0,0),
	InputText      = Color3.fromRGB(255,255,255),
	NotifBg        = Color3.fromRGB(15,18,15),
	NotifBorder    = Color3.fromRGB(0,0,0),
	NotifBar       = Color3.fromRGB(224,32,32),
	ScrollBar      = Color3.fromRGB(70,80,70),
}
local T: {[string]: Color3} = {}
for k, v in pairs(BASE) do
	T[k] = v
end
Library.T = T

local Creator = {
	Reg = {} :: {[Instance]: {[string]: string}},
	Grad = {} :: {[Instance]: true},
	UpdateTheme = function() end,
}
Library.Creator = Creator

local function _applyToken(inst: Instance, prop: string, token: string)
	local val = T[token]
	if val then
		pcall(function()
			(inst :: any)[prop] = val
		end)
	end
end

local function _applyGrad(inst: UIGradient)
	inst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.HdrTop),
		ColorSequenceKeypoint.new(0.25, T.HdrMid),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(175, 14, 14)),
		ColorSequenceKeypoint.new(1, T.HdrBot),
	})
end

function Creator.New(cls: string, props: {[string]: any}, children: {Instance}?): any
	local inst = Instance.new(cls) :: any
	if inst:IsA("GuiObject") and props.BorderSizePixel == nil then
		inst.BorderSizePixel = 0
	end
	local tag = props.ThemeTag
	local grad = props.GradTag
	for k, v in pairs(props) do
		if k ~= "ThemeTag" and k ~= "GradTag" then
			inst[k] = v
		end
	end
	if tag then
		Creator.Reg[inst] = tag
		for p, tk in pairs(tag) do
			_applyToken(inst, p, tk)
		end
	end
	if grad then
		Creator.Grad[inst] = true
		_applyGrad(inst)
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	return inst
end

function Creator.UpdateTheme()
	if Library._updateTheme then
		Library._updateTheme()
		return
	end
	for inst, tag in pairs(Creator.Reg) do
		if inst.Parent then
			for p, tk in pairs(tag) do
				_applyToken(inst, p, tk)
			end
		end
	end
	for inst in pairs(Creator.Grad) do
		if inst.Parent then
			_applyGrad(inst :: UIGradient)
		end
	end
end

function Library:SetTheme(name: string)
	if Library.ThemeManager then
		return Library.ThemeManager:SetTheme(name)
	end
	warn("[Ignis] ThemeManager not loaded; cannot switch to " .. tostring(name))
end

function Library:GetTheme(): string
	if Library.ThemeManager then
		return Library.ThemeManager:GetTheme()
	end
	return Library._theme or "Ignis Dark"
end

function Library:GetThemeNames(): {string}
	if Library.ThemeManager then
		return Library.ThemeManager:GetThemes()
	end
	return { "Ignis Dark" }
end

function Library:GetThemeManager(): any
	return Library.ThemeManager
end

function Library:GetAnimationManager(): any
	return Library.AnimationManager
end

function Library:GetSaveManager(): any
	return Library.SaveManager
end

function Library:GetLayoutManager(): any
	return LayoutManager
end

local FONT_TITLE: Font
local FONT_TAB: Font
local FONT_UI: Font
local FONT_BOLD: Font
local FONT_FREDOKA: Font
local FONT_FREDOKA_BOLD: Font
local FONT_DESC: Font
local FONT_HEAVY: Font

local function _refreshFonts()
	FONT_TITLE = Font.fromEnum(L.FontTitle)
	FONT_TAB = Font.fromEnum(L.FontTab)
	FONT_UI = Font.fromEnum(L.FontUI)
	FONT_BOLD = Font.fromEnum(L.FontBold)
	FONT_FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	FONT_FREDOKA_BOLD = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	FONT_DESC = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Italic)
	FONT_HEAVY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
end
_refreshFonts()
Library._refreshFonts = _refreshFonts

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

local function _buildNotifCard(opts: NotifOpts, col: Color3): (Frame, Frame)
	local card = Creator.New("Frame", {
		Size = UDim2.new(1, 0, 0, L.NotifH), ClipsDescendants = true,
		ThemeTag = { BackgroundColor3 = "NotifBg" }, Parent = _nHolder,
	}) :: Frame
	Creator.New("UIStroke", { Thickness = L.StrokeNotif, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "NotifBorder" }, Parent = card })
	Creator.New("Frame", { Size = UDim2.new(0, L.NotifBarW, 1, 0), BorderSizePixel = 0, BackgroundColor3 = col, Parent = card })
	local inner = Instance.new("Frame")
	inner.Position = UDim2.new(0, L.NotifInnerPadL, 0, 0); inner.Size = UDim2.new(1, -(L.NotifInnerPadL + L.NotifInnerPadR), 1, 0)
	inner.BackgroundTransparency = 1; inner.Parent = card
	local tl = Instance.new("TextLabel")
	tl.Text = opts.Title; tl.FontFace = FONT_BOLD; tl.TextSize = L.ElemNameSize; tl.TextColor3 = T.Text; tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.BackgroundTransparency = 1; tl.Position = UDim2.new(0, 0, 0, L.NotifTitleY); tl.Size = UDim2.new(1, 0, 0, L.ElemNameSize + L.LabelPad); tl.Parent = inner
	Creator.Reg[tl :: any] = { TextColor3 = "Text" }
	if opts.Message then
		local msgY = L.NotifTitleY + L.ElemNameSize + L.LabelPad + L.NotifMsgGapY
		local ml = Instance.new("TextLabel")
		ml.Text = opts.Message; ml.FontFace = FONT_UI; ml.TextSize = L.ElemDescSize; ml.TextColor3 = T.TextSub; ml.TextXAlignment = Enum.TextXAlignment.Left
		ml.TextWrapped = true; ml.BackgroundTransparency = 1; ml.Position = UDim2.new(0, 0, 0, msgY); ml.Size = UDim2.new(1, 0, 0, L.NotifH - msgY - L.NotifMsgBottomPad); ml.Parent = inner
		Creator.Reg[ml :: any] = { TextColor3 = "TextSub" }
	end
	local bar = Creator.New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, BackgroundColor3 = col, Parent = card }) :: Frame
	return card, bar
end

local function _animateNotifCard(card: Frame, bar: Frame, dur: number)
	card.Position = UDim2.new(1.1, 0, 0, 0)
	tw(card, { Position = UDim2.new(0, 0, 0, 0) }, Anim.Notif)
	if _animEnabled then
		TweenService:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
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

function Library:Notify(opts: NotifOpts)
	_ensureNotifGui()
	local dur = opts.Duration or 3.5
	local col = opts.Type == "success" and T.NotifSuccess or opts.Type == "warning" and T.NotifWarning or opts.Type == "info" and T.NotifInfo or T.NotifBar
	local card, bar = _buildNotifCard(opts, col)
	_animateNotifCard(card, bar, dur)
end

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
	if id then Library.Options[id] = self end
	return self
end

export type WindowCfg = {
	Title: string?, SubTitle: string?, Width: number?, Height: number?,
	Theme: string?, MinimizeKey: Enum.KeyCode?, SearchPlaceholder: string?,
}

local _activeDrop: { menu: Frame, row: Frame, rotBox: Frame?, shield: TextButton }? = nil

local function _closeActiveDropdown()
	if _activeDrop then
		_activeDrop.menu.Visible = false
		_activeDrop.row.ZIndex = 1
		if _activeDrop.rotBox then tw(_activeDrop.rotBox, { Rotation = 45 }, Anim.Fast) end
		_activeDrop.shield.Visible = false
		_activeDrop = nil
	end
end

local function _newToastFrame(gui: ScreenGui)
	local toast = Creator.New("Frame", {
		Name = "Toast", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 70), Size = UDim2.fromOffset(360, 46),
		BackgroundColor3 = Color3.fromRGB(15, 18, 15), Parent = gui,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = 2.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = toast,
	})
	local lbl = Creator.New("TextLabel", {
		Name = "ToastText", Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "", FontFace = FONT_HEAVY,
		TextSize = 16, TextColor3 = Color3.new(1, 1, 1), Parent = toast,
	})
	return toast, lbl
end

local function _buildToastRunner(toast: Frame, lbl: TextLabel)
	local thread: thread? = nil
	return function(msg: string)
		lbl.Text = msg
		if thread then task.cancel(thread) end
		thread = task.spawn(function()
			tw(toast, { Position = UDim2.new(0.5, 0, 1, -25) }, Anim.Bounce or TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
			task.wait(1.8)
			tw(toast, { Position = UDim2.new(0.5, 0, 1, 70) }, Anim.Fast or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		end)
	end
end

local function _bindBtnHover(btn: TextButton, maid: any)
	local orig = btn.Size
	maid:Give(btn.MouseEnter:Connect(function()
		tw(btn, { Size = UDim2.new(orig.X.Scale, orig.X.Offset + 4, orig.Y.Scale, orig.Y.Offset + 2) }, Anim.Fast)
	end))
	maid:Give(btn.MouseLeave:Connect(function()
		tw(btn, { Size = orig }, Anim.Fast)
	end))
end

local function _buildHeaderAccents(hdr: Frame)
	Creator.New("Frame", {
		Name = "LeftDarkAccent", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
	Creator.New("Frame", {
		Name = "BottomDarkAccent", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = hdr,
	})
end

local function _buildHeaderLabels(hdr: Frame, title: string, subtitle: string)
	local titleLbl = Creator.New("TextLabel", {
		Name = "TitleLabel", Text = title, FontFace = FONT_TITLE,
		TextSize = L.TitleSize, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "Text" }, Parent = hdr,
	})
	Creator.New("UIStroke", {
		Color = Color3.new(0, 0, 0), Thickness = L.TitleStrokeW,
		LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = titleLbl,
	})
	if subtitle ~= "" then
		Creator.New("TextLabel", {
			Name = "SubTitle", Text = subtitle, FontFace = FONT_UI,
			TextSize = L.SubtitleSize, TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -L.SubtitleBottomPad),
			Size = UDim2.new(0.6, 0, 0, L.SubtitleSize + L.LabelPad),
			BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "TextSub" }, Parent = hdr,
		})
	end
end

local function _buildHeader(root: Frame, title: string, subtitle: string)
	local hdr = Creator.New("Frame", {
		Name = "HeaderBar", Size = UDim2.new(1, 0, 0, L.HeaderH),
		ThemeTag = { BackgroundColor3 = "HdrMid" }, Parent = root,
	}) :: Frame
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = hdr })
	Creator.New("UIStroke", {
		Thickness = L.StrokeHdr, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = hdr,
	})
	_buildHeaderAccents(hdr)
	_buildHeaderLabels(hdr, title, subtitle)
	return hdr
end

local function _buildCloseAccents(btn: TextButton)
	Creator.New("Frame", {
		Name = "LeftDarkAccent", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 5, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = btn,
	})
	Creator.New("Frame", {
		Name = "BottomDarkAccent", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 5, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = btn,
	})
end

local function _buildCloseButton(hdr: Frame)
	local closeBtn = Creator.New("TextButton", {
		Name = "CloseButton", Text = "X", FontFace = FONT_TITLE, TextSize = 26,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -L.HeaderBtnRightPad, 0.5, 0),
		Size = UDim2.fromOffset(44, 44), AutoButtonColor = false, ZIndex = 4,
		ThemeTag = { BackgroundColor3 = "HdrMid", TextColor3 = "Text" }, Parent = hdr,
	}) :: TextButton
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = closeBtn })
	Creator.New("UIStroke", {
		Thickness = L.StrokeClose, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = closeBtn,
	})
	Creator.New("UIStroke", {
		Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round, Color = Color3.new(0, 0, 0), Parent = closeBtn,
	})
	_buildCloseAccents(closeBtn)
	return closeBtn
end

local function _buildAccordionChevron(content: Frame)
	local chFrame = Instance.new("Frame")
	chFrame.Name = "ChevronIcon"; chFrame.BackgroundTransparency = 1
	chFrame.AnchorPoint = Vector2.new(0, 0.5); chFrame.Position = UDim2.new(0, 0, 0.5, 0)
	chFrame.Size = UDim2.fromOffset(16, 16); chFrame.Parent = content
	local rotBox = Creator.New("Frame", {
		Name = "RotatedBox", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(12, 12),
		Rotation = 45, BorderSizePixel = 0, BackgroundTransparency = 1, Parent = chFrame,
	})
	Creator.New("Frame", {
		Name = "BottomBar", Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3),
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = rotBox,
	})
	Creator.New("Frame", {
		Name = "RightBar", Position = UDim2.new(1, -3, 0, 0), Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = rotBox,
	})
	return rotBox
end

local function _buildAccordion(root: Frame)
	local secBtn = Creator.New("TextButton", {
		Name = "SectionHeader", Position = UDim2.new(0, 0, 0, 66),
		Size = UDim2.new(1, 0, 0, L.SectionBarH),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 1, Parent = root,
	}) :: TextButton
	local secContent = Creator.New("Frame", {
		Name = "Content", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 240, 1, 0),
		BackgroundTransparency = 1, Parent = secBtn,
	}) :: Frame
	local secTitle = Creator.New("TextLabel", {
		Name = "SectionTitle", Text = "", FontFace = FONT_FREDOKA, TextSize = 23,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "Text" }, Parent = secContent,
	}) :: TextLabel
	Creator.New("UIStroke", {
		Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = secTitle,
	})
	local rotBox = _buildAccordionChevron(secContent)
	return secBtn, secTitle, rotBox
end

local function _buildSearchContainer(bar: Frame, placeholder: string?)
	local cont = Instance.new("Frame")
	cont.Name = "SearchFieldContainer"; cont.Position = UDim2.new(0, 105, 0.5, -17)
	cont.Size = UDim2.new(1, -165, 0, 34); cont.BackgroundColor3 = Color3.fromRGB(6, 8, 6); cont.BorderSizePixel = 0; cont.Parent = bar
	Creator.New("UIStroke", {
		Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = cont,
	})
	local inp = Creator.New("TextBox", {
		Name = "SearchInput", Text = "", PlaceholderText = placeholder or "Filter features...",
		FontFace = FONT_UI, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1, PlaceholderColor3 = Color3.fromRGB(130, 135, 140),
		ThemeTag = { TextColor3 = "Text" }, Parent = cont,
	}) :: TextBox
	return inp
end

local function _buildSearchLabel(bar: Frame)
	local sl = Creator.New("TextLabel", {
		Name = "SearchLabel", Text = "Search", FontFace = FONT_FREDOKA, TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(0, 80, 1, 0),
		BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" }, Parent = bar,
	})
	Creator.New("UIStroke", {
		Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = sl,
	})
end

local function _buildBottomBar(root: Frame, placeholder: string?)
	local bar = Creator.New("Frame", {
		Name = "BottomBar", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, L.BottomBarH),
		ThemeTag = { BackgroundColor3 = "SidebarBg" }, Parent = root,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeSidebar, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "SidebarBorder" }, Parent = bar,
	})
	_buildSearchLabel(bar)
	local inp = _buildSearchContainer(bar, placeholder)
	Creator.New("TextLabel", {
		Name = "ResizeGrip", Text = "◢", FontFace = FONT_BOLD, TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -8, 1, -6), Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(110, 120, 110), Parent = bar,
	})
	return bar, inp
end

local function _buildSidebar(master: Frame, name: string, isRight: boolean)
	local sb = Instance.new("ScrollingFrame")
	sb.Name = name
	sb.AnchorPoint = Vector2.new(isRight and 0 or 1, 0)
	sb.Position = UDim2.new(0.5, isRight and L.SidebarXOffset or -L.SidebarXOffset, 0, L.SidebarTopOffset)
	sb.Size = UDim2.fromOffset(L.SidebarW, L.SidebarH)
	sb.BackgroundTransparency = 1; sb.BorderSizePixel = 0
	sb.ScrollBarThickness = 0; sb.ScrollingEnabled = false
	sb.AutomaticCanvasSize = Enum.AutomaticSize.None
	sb.Parent = master
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, isRight and L.RightTabListPad or L.TabListPad)
	layout.Parent = sb
	return sb
end

local function _buildTabAccents(btn: TextButton)
	Creator.New("Frame", {
		Name = "LeftDarkAccent", Size = UDim2.new(0, L.BevelSize, 1, 0), BorderSizePixel = 0,
		ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = btn,
	})
	Creator.New("Frame", {
		Name = "BottomDarkAccent", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, L.BevelSize),
		BorderSizePixel = 0, ZIndex = 2, ThemeTag = { BackgroundColor3 = "HdrBevel" }, Parent = btn,
	})
end

local function _buildTabButton(sidebar: ScrollingFrame, name: string, label: string, idx: number, isRight: boolean)
	local btn = Creator.New("TextButton", {
		Name = name, Text = "", Size = UDim2.new(1, 0, 0, L.TabH),
		AutoButtonColor = false, LayoutOrder = idx, ZIndex = 2,
		ThemeTag = { BackgroundColor3 = "HdrMid" }, Parent = sidebar,
	}) :: TextButton
	Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = btn })
	Creator.New("UIStroke", {
		Thickness = L.StrokeTabBtn, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = btn,
	})
	_buildTabAccents(btn)
	local btnLabel = Creator.New("TextLabel", {
		Name = "Label", Text = label,
		FontFace = isRight and FONT_FREDOKA or FONT_TITLE,
		TextSize = isRight and L.RightTabTextSize or L.TabTextSize,
		TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, ZIndex = 3, ThemeTag = { TextColor3 = "Text" }, Parent = btn,
	}) :: TextLabel
	Creator.New("UIStroke", {
		Thickness = 2.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = btnLabel,
	})
	return btn, btnLabel
end

local function _buildReopenPill(gui: ScreenGui, title: string)
	local reopen = Creator.New("TextButton", {
		Name = "ReopenPill", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(220, 44),
		Text = "OPEN " .. (title:upper()) .. " [R-SHIFT]",
		FontFace = FONT_FREDOKA, TextSize = 16, TextColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false, BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(224, 32, 32), ZIndex = 1, Visible = false, Parent = gui,
	}) :: TextButton
	Creator.New("UIStroke", {
		Thickness = 3.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = reopen,
	})
	Creator.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 52, 52)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 18, 18)),
		}), Rotation = 90, Parent = reopen,
	})
	return reopen
end

local function _buildPage(pagesHolder: Frame, name: string)
	local page = Creator.New("ScrollingFrame", {
		Name = name, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0.45,
		BackgroundColor3 = Color3.fromRGB(10, 14, 10),
		BorderSizePixel = 0,
		ScrollBarThickness = L.ScrollBarThick, ScrollBarImageColor3 = T.ScrollBar,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = pagesHolder,
	}) :: ScrollingFrame
	Creator.New("UIStroke", {
		Thickness = L.StrokePage, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = page,
	})
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 7); layout.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = page
	return page
end

local function _buildMasterAndRoot(gui: ScreenGui, W: number, H: number)
	local master = Creator.New("Frame", {
		Name = "MasterContainer", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(L.MasterW, L.MasterH),
		BackgroundTransparency = 1, ClipsDescendants = false, Parent = gui,
	}) :: Frame
	local sc = Instance.new("UISizeConstraint")
	sc.MinSize = Vector2.new(880, 560); sc.MaxSize = Vector2.new(1350, 820); sc.Parent = master
	local root = Creator.New("Frame", {
		Name = "CenterWindow", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(W, H),
		ClipsDescendants = false, BackgroundTransparency = 0.28,
		ThemeTag = { BackgroundColor3 = "WinBg" }, Parent = master,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = L.StrokeRoot, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "HdrBorder" }, Parent = root,
	})
	local shield = Instance.new("TextButton")
	shield.Name = "DropdownShield"; shield.Size = UDim2.new(1, 0, 1, 0)
	shield.Position = UDim2.new(0, 0, 0, 0); shield.BackgroundTransparency = 1
	shield.Text = ""; shield.ZIndex = 40; shield.Visible = false; shield.Parent = root
	return master, root, shield
end

local function _buildPagesHolder(root: Frame, H: number)
	local pagesTop = 108
	local pagesH = H - pagesTop - L.BottomBarH - 14
	local holder = Instance.new("Frame")
	holder.Name = "PagesHolder"
	holder.Position = UDim2.new(0, 12, 0, pagesTop)
	holder.Size = UDim2.new(1, -24, 0, pagesH)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Parent = root
	return holder
end

local function _bindDragging(maid: any, master: Frame, hdr: Frame)
	local dragging = false
	local lastMouse = Vector2.zero
	maid:Give(hdr.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastMouse = UserInputService:GetMouseLocation()
		end
	end))
	maid:Give(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local m = UserInputService:GetMouseLocation()
			local d = m - lastMouse
			lastMouse = m
			master.Position = UDim2.new(master.Position.X.Scale, master.Position.X.Offset + d.X, master.Position.Y.Scale, master.Position.Y.Offset + d.Y)
		end
	end))
	maid:Give(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function _wireWindowSignals(maid: any, master: Frame, closeBtn: TextButton, reopenPill: TextButton, minKey: Enum.KeyCode, showToast: (string) -> ())
	_bindBtnHover(closeBtn, maid)
	_bindBtnHover(reopenPill, maid)
	local function setMin(state: boolean)
		master.Visible = not state
		reopenPill.Visible = state
		if state then showToast("Hub minimized. Press [R-SHIFT] to reopen.") end
	end
	maid:Give(closeBtn.MouseButton1Click:Connect(function() setMin(true) end))
	maid:Give(reopenPill.MouseButton1Click:Connect(function() setMin(false) end))
	maid:Give(UserInputService.InputBegan:Connect(function(inp, gp)
		if not gp and inp.KeyCode == minKey then setMin(master.Visible) end
	end))
end

local function _wireAccordion(maid: any, secBtn: TextButton, pagesHolder: Frame, rotBox: Frame, showToast: (string) -> ())
	local sectionOpen = true
	maid:Give(secBtn.MouseButton1Click:Connect(function()
		_closeActiveDropdown()
		sectionOpen = not sectionOpen
		pagesHolder.Visible = sectionOpen
		tw(rotBox, { Rotation = sectionOpen and 45 or 225 }, Anim.Fast)
		showToast(sectionOpen and "Section Expanded" or "Section Collapsed")
	end))
end

local function _bindSearch(maid: any, searchInput: TextBox, pagesHolder: Frame)
	maid:Give(searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		_closeActiveDropdown()
		local q = searchInput.Text:lower()
		for _, pg in ipairs(pagesHolder:GetChildren()) do
			if pg:IsA("ScrollingFrame") and pg.Visible then
				for _, sec in ipairs(pg:GetChildren()) do
					if sec:IsA("Frame") then
						local innerF = sec:FindFirstChild("Inner") or sec
						for _, row in ipairs(innerF:GetChildren()) do
							if row:IsA("Frame") then
								local t = row:FindFirstChild("Title") or row:FindFirstChildWhichIsA("TextLabel")
								if t then row.Visible = (q == "" or t.Text:lower():find(q, 1, true) ~= nil) end
							end
						end
					end
				end
			end
		end
	end))
end

local function _mkRow(Section: any, inner: Instance, height: number): Frame
	Section._rows += 1
	local r = Creator.New("Frame", {
		Name = "Row_" .. Section._rows,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = Section._rows,
		BackgroundTransparency = 0.35,
		ThemeTag = { BackgroundColor3 = "RowBg" },
		Parent = inner,
	}) :: Frame
	Creator.New("UIStroke", {
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
		ThemeTag = { Color = "RowBorder" },
		Parent = r,
	})
	return r
end

local function _mkLabel(txt: string, token: string, parent: Instance): TextLabel
	local isName = token == "Text"
	local l = Creator.New("TextLabel", {
		Name = isName and "Title" or "Description",
		Text = txt,
		FontFace = isName and FONT_FREDOKA or FONT_DESC,
		TextSize = isName and L.ElemNameSize or L.ElemDescSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, (isName and L.ElemNameSize or L.ElemDescSize) + L.LabelPad),
		ThemeTag = { TextColor3 = token },
	}) :: TextLabel
	if isName then
		Creator.New("UIStroke", {
			Thickness = 1.4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Color = Color3.new(0, 0, 0),
			Parent = l,
		})
	end
	l.Parent = parent
	return l
end

local function _positionLabels(nameLabel: TextLabel, descLabel: TextLabel?)
	if descLabel then
		nameLabel.Position = UDim2.new(0, 16, 0, 8)
		nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
		descLabel.Position = UDim2.new(0, 16, 0, 42)
		descLabel.Size = UDim2.new(0.6, 0, 0, 22)
	else
		nameLabel.Position = UDim2.new(0, 16, 0, 0)
		nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	end
end

local function _bindRowHover(row: Frame, el: any, maid: any)
	maid:Give(row.MouseEnter:Connect(function()
		if not el:IsDisabled() then
			tw(row, { BackgroundColor3 = T.RowBgHover }, Anim.Row)
		end
	end))
	maid:Give(row.MouseLeave:Connect(function()
		tw(row, { BackgroundColor3 = T.RowBg }, Anim.Row)
	end))
end

local function _buildToggleTrack(row: Frame, on: boolean)
	local TW, TH, KS = L.ToggleW, L.ToggleH, L.ToggleKnobS
	local OFF_POS = UDim2.new(0, 3, 0.5, 0)
	local ON_POS = UDim2.new(1, -(KS + 3), 0.5, 0)
	local track = Creator.New("TextButton", {
		Name = "SliderTrack", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(TW, TH),
		AutoButtonColor = false, BackgroundColor3 = T.ToggleOff, Parent = row,
	}) :: TextButton
	Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = track })
	local knob = Creator.New("Frame", {
		Name = "SliderKnob", AnchorPoint = Vector2.new(0, 0.5),
		Position = on and ON_POS or OFF_POS, Size = UDim2.fromOffset(KS, KS),
		BackgroundColor3 = Color3.fromRGB(250, 250, 250), Parent = track,
	}) :: Frame
	Creator.New("UIStroke", { Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = knob })
	Creator.New("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(145, 145, 150)) }), Rotation = 90, Parent = knob })
	return track, knob, ON_POS, OFF_POS
end

local function _buildToggleRow(Section: any, inner: Instance, maid: any, opts: any, showToast: (string) -> ()): any
	local on = opts.Default == true
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	local nl = _mkLabel(opts.Name, "Text", row)
	local dl = opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local track, knob, ON_POS, OFF_POS = _buildToggleTrack(row, on)
	local el = mkBase(opts.Id, on, row)
	function el:_apply(v: boolean)
		on = v
		tw(knob, { Position = v and ON_POS or OFF_POS }, Anim.Toggle)
		if opts.Callback then xpcall(opts.Callback, debug.traceback, v) end
	end
	maid:Give(track.MouseButton1Click:Connect(function()
		if not el:IsDisabled() then
			el:Set(not on)
			showToast(opts.Name .. (on and " Enabled" or " Disabled"))
		end
	end))
	_bindRowHover(row, el, maid)
	return el
end

local function _buildDropdownPill(row: Frame, cur: string)
	local pill = Creator.New("TextButton", {
		Name = "DropdownPill", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(160, 38),
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(6, 8, 6), Parent = row,
	}) :: TextButton
	Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = pill })
	local dispL = Creator.New("TextLabel", {
		Name = "ValueLabel", Text = cur, FontFace = FONT_FREDOKA, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -38, 1, 0),
		BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, ThemeTag = { TextColor3 = "Text" }, Parent = pill,
	}) :: TextLabel
	Creator.New("UIStroke", { Thickness = 1.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = dispL })
	local chev = Instance.new("Frame")
	chev.Name = "ChevronIcon"; chev.BackgroundTransparency = 1; chev.AnchorPoint = Vector2.new(1, 0.5)
	chev.Position = UDim2.new(1, -8, 0.5, 0); chev.Size = UDim2.fromOffset(14, 14); chev.Parent = pill
	local rBox = Instance.new("Frame")
	rBox.Name = "RotatedBox"; rBox.BackgroundTransparency = 1; rBox.AnchorPoint = Vector2.new(0.5, 0.5); rBox.Position = UDim2.new(0.5, 0, 0.5, 0); rBox.Size = UDim2.fromOffset(10, 10); rBox.Rotation = 45; rBox.Parent = chev
	Creator.New("Frame", { Name = "BottomBar", Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(40, 215, 80), BorderSizePixel = 0, Parent = rBox })
	Creator.New("Frame", { Name = "RightBar", Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 215, 80), BorderSizePixel = 0, Parent = rBox })
	return pill, dispL, rBox
end

local function _buildDropdownMenu(row: Frame, opts: any, optH: number, onSelect: (string) -> ())
	local menuH = math.min(#opts.Options * optH, 128)
	local menu = Creator.New("Frame", {
		Name = "DropdownMenu", AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 1, 4), Size = UDim2.fromOffset(160, menuH),
		BackgroundColor3 = Color3.fromRGB(14, 18, 14), ZIndex = 50, Visible = false, Parent = row,
	}) :: Frame
	Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = menu })
	local mList = Instance.new("UIListLayout")
	mList.SortOrder = Enum.SortOrder.LayoutOrder; mList.Parent = menu
	for idx, opt in ipairs(opts.Options) do
		local ob = Creator.New("TextButton", {
			Name = "Opt_" .. idx, Text = opt, FontFace = FONT_FREDOKA, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, optH), AutoButtonColor = true,
			ZIndex = 51, BackgroundColor3 = Color3.fromRGB(14, 18, 14), ThemeTag = { TextColor3 = "Text" }, Parent = menu,
		}) :: TextButton
		Creator.New("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.fromRGB(34, 40, 34), Parent = ob })
		ob.MouseButton1Click:Connect(function() onSelect(opt) end)
	end
	return menu
end

local function _wireDropdownEl(el: any, multi: boolean, mSel: any, opts: any, dispL: TextLabel, cur: string)
	function el:Get(): any
		if multi then
			local s = {}
			for _, o in ipairs(opts.Options) do if mSel[o] then table.insert(s, o) end end
			return s
		end
		return cur
	end
	function el:_apply(v: any)
		if multi and type(v) == "table" then
			table.clear(mSel)
			local sel = {}
			for _, o in ipairs(v) do mSel[o] = true; table.insert(sel, o) end
			dispL.Text = #sel > 0 and table.concat(sel, ", ") or "None"
		else
			cur = tostring(v); dispL.Text = cur
		end
	end
end

local function _wireDropdownSelection(opts: any, multi: boolean, mSel: any, dispL: TextLabel, showToast: (string) -> (), setCur: (string) -> (), closeMenu: () -> ())
	return function(opt: string)
		if multi then
			mSel[opt] = not mSel[opt]
			local sel = {}
			for _, o in ipairs(opts.Options) do if mSel[o] then table.insert(sel, o) end end
			dispL.Text = #sel > 0 and table.concat(sel, ", ") or "None"
			if opts.Callback then xpcall(opts.Callback, debug.traceback, sel) end
		else
			setCur(opt); dispL.Text = opt; closeMenu()
			if opts.Callback then xpcall(opts.Callback, debug.traceback, opt) end
			showToast("Selected: " .. opt)
		end
	end
end

local function _toggleDropdown(menu: Frame, row: Frame, rotBox: Frame?, shield: TextButton)
	local opening = not menu.Visible
	_closeActiveDropdown()
	if opening then
		menu.Visible = true; row.ZIndex = 45; shield.Visible = true
		_activeDrop = { menu = menu, row = row, rotBox = rotBox, shield = shield }
		if rotBox then tw(rotBox, { Rotation = 225 }, Anim.Fast) end
	end
end

local function _buildDropdownRow(Section: any, inner: Instance, maid: any, opts: any, showToast: (string) -> (), pagesHolder: Frame): any
	opts.Options = opts.Options or opts.Values or {}
	local multi, rawDef = opts.Multi == true, opts.Default or opts.Options[1] or ""
	local cur = type(rawDef) == "table" and rawDef[1] or rawDef
	local mSel = {}
	if multi and type(rawDef) == "table" then for _, o in ipairs(rawDef) do mSel[o] = true end end
	local dispText = multi and type(rawDef) == "table" and (#rawDef > 0 and table.concat(rawDef, ", ") or "None") or tostring(cur)
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	local nl, dl = _mkLabel(opts.Name, "Text", row), opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local pill, dispL, rotBox = _buildDropdownPill(row, dispText)
	local el = mkBase(opts.Id, multi and rawDef or cur, row)
	local menu: Frame
	local selFn = _wireDropdownSelection(opts, multi, mSel, dispL, showToast, function(v) cur = v end, _closeActiveDropdown)
	menu = _buildDropdownMenu(row, opts, 32, selFn)
	local shield = pagesHolder.Parent and pagesHolder.Parent:FindFirstChild("DropdownShield") :: TextButton
	maid:Give(pill.MouseButton1Click:Connect(function() if shield then _toggleDropdown(menu, row, rotBox, shield) else menu.Visible = not menu.Visible end end))
	_wireDropdownEl(el, multi, mSel, opts, dispL, cur)
	_bindRowHover(row, el, maid)
	return el
end

local function _buildInputBox(row: Frame, val: string, ph: string)
	local ibg = Creator.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, 160, 0, L.InputBoxH), BackgroundColor3 = Color3.fromRGB(8, 11, 8), Parent = row,
	}) :: Frame
	local stroke = Creator.New("UIStroke", {
		Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = ibg,
	})
	local box = Instance.new("TextBox")
	box.Name = "ValueInput"; box.FontFace = FONT_FREDOKA; box.TextSize = 17
	box.TextColor3 = Color3.new(1, 1, 1); box.PlaceholderText = ph
	box.PlaceholderColor3 = T.TextHint; box.Text = val; box.TextXAlignment = Enum.TextXAlignment.Center
	box.BackgroundTransparency = 1; box.ClearTextOnFocus = false; box.Size = UDim2.new(1, 0, 1, 0); box.Parent = ibg
	pcall(function() box.Focused:Connect(function() tw(stroke, { Color = Color3.fromRGB(40, 215, 80) }, Anim.Fast) end) end)
	pcall(function() box.FocusLost:Connect(function() tw(stroke, { Color = Color3.new(0, 0, 0) }, Anim.Fast) end) end)
	return ibg, box
end

local function _buildInputRow(Section: any, inner: Instance, maid: any, opts: any): any
	local val = opts.Default or ""
	local row = _mkRow(Section, inner, opts.Description and L.InputRowHDesc or L.InputRowH)
	local nl = _mkLabel(opts.Name, "Text", row)
	local dl = opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local _, box = _buildInputBox(row, val, opts.Placeholder or "")
	maid:Give(box.FocusLost:Connect(function()
		local t = opts.MaxLength and box.Text:sub(1, opts.MaxLength) or box.Text
		box.Text = t; val = t
		if opts.Callback then xpcall(opts.Callback, debug.traceback, t) end
	end))
	local el = mkBase(opts.Id, val, row)
	function el:_apply(v: any) val = tostring(v); box.Text = val end
	_bindRowHover(row, el, maid)
	return el
end

local function _buildCompoundRow(Section: any, inner: Instance, maid: any, opts: any, showToast: (string) -> ()): any
	local units = opts.Units or opts.Values or { "Unit", "x1", "x10", "Max" }
	local uIdx = 1
	local curUnit = opts.DefaultUnit or units[1]
	local curVal = opts.DefaultValue or opts.Default or "0"
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	local nl, dl = _mkLabel(opts.Name, "Text", row), opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local grp = Instance.new("Frame")
	grp.Name = "ControlGroup"; grp.BackgroundTransparency = 1; grp.AnchorPoint = Vector2.new(1, 0.5)
	grp.Position = UDim2.new(1, -16, 0.5, 0); grp.Size = UDim2.fromOffset(165, 38); grp.Parent = row
	local pill = Creator.New("TextButton", {
		Name = "UnitPill", BackgroundColor3 = Color3.fromRGB(6, 8, 6),
		Size = UDim2.new(0, 105, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		Text = "", AutoButtonColor = false, Parent = grp,
	}) :: TextButton
	Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = pill })
	local uLbl = Creator.New("TextLabel", {
		Name = "UnitLabel", Text = curUnit, FontFace = FONT_FREDOKA, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -32, 1, 0),
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(40, 215, 80), Parent = pill,
	})
	Creator.New("UIStroke", { Thickness = 1.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = uLbl })
	local chev = Instance.new("Frame")
	chev.Name = "ChevronIcon"; chev.BackgroundTransparency = 1; chev.AnchorPoint = Vector2.new(1, 0.5)
	chev.Position = UDim2.new(1, -8, 0.5, 0); chev.Size = UDim2.fromOffset(14, 14); chev.Parent = pill
	local rBox = Instance.new("Frame")
	rBox.Name = "RotatedBox"; rBox.BackgroundTransparency = 1; rBox.AnchorPoint = Vector2.new(0.5, 0.5); rBox.Position = UDim2.new(0.5, 0, 0.5, 0); rBox.Size = UDim2.fromOffset(10, 10); rBox.Rotation = 45; rBox.Parent = chev
	Creator.New("Frame", { Name = "BottomBar", Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(40, 215, 80), BorderSizePixel = 0, Parent = rBox })
	Creator.New("Frame", { Name = "RightBar", Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 215, 80), BorderSizePixel = 0, Parent = rBox })
	local vBox = Creator.New("TextBox", {
		Name = "ValueInput", BackgroundColor3 = Color3.fromRGB(8, 11, 8),
		Position = UDim2.new(0, 111, 0, 0), Size = UDim2.new(0, 54, 1, 0),
		FontFace = FONT_FREDOKA, Text = curVal, TextColor3 = Color3.new(1, 1, 1), TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, Parent = grp,
	}) :: TextBox
	local vStroke = Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = vBox })
	maid:Give(vBox.Focused:Connect(function() tw(vStroke, { Color = Color3.fromRGB(40, 215, 80) }, Anim.Fast) end))
	maid:Give(vBox.FocusLost:Connect(function()
		tw(vStroke, { Color = Color3.new(0, 0, 0) }, Anim.Fast)
		curVal = vBox.Text
		if opts.Callback then xpcall(opts.Callback, debug.traceback, curUnit, curVal) end
	end))
	maid:Give(pill.MouseButton1Click:Connect(function()
		uIdx = (uIdx % #units) + 1
		curUnit = units[uIdx]
		uLbl.Text = curUnit
		showToast("Unit set to: " .. curUnit)
		if opts.Callback then xpcall(opts.Callback, debug.traceback, curUnit, curVal) end
	end))
	local el = mkBase(opts.Id, { Unit = curUnit, Value = curVal }, row)
	function el:_apply(v: any)
		if type(v) == "table" then
			if v.Unit then curUnit = tostring(v.Unit); uLbl.Text = curUnit end
			if v.Value then curVal = tostring(v.Value); vBox.Text = curVal end
		end
	end
	function el:Get(): any return { Unit = curUnit, Value = curVal } end
	_bindRowHover(row, el, maid)
	return el
end

local function _buildSliderTrack(row: Frame, pct0: number)
	local track = Creator.New("Frame", {
		Position = UDim2.new(0, 16, 0, L.SliderTrackY),
		Size = UDim2.new(1, -16 - L.SliderTrackRightPad, 0, L.SliderTrackH),
		ThemeTag = { BackgroundColor3 = "SliderTrack" }, Parent = row,
	}) :: Frame
	Creator.New("UICorner", { CornerRadius = UDim.new(0, L.SliderTrackH // 2), Parent = track })
	local fill = Creator.New("Frame", {
		Size = UDim2.new(pct0, 0, 1, 0), ThemeTag = { BackgroundColor3 = "SliderFill" }, Parent = track,
	})
	Creator.New("UICorner", { CornerRadius = UDim.new(0, L.SliderTrackH // 2), Parent = fill })
	local knob = Creator.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3, Position = UDim2.new(pct0, 0, 0.5, 0),
		Size = UDim2.fromOffset(L.SliderKnobS, L.SliderKnobS), ThemeTag = { BackgroundColor3 = "SliderKnob" }, Parent = track,
	})
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, L.SliderKnobS // 2); kc.Parent = knob
	return track, fill, knob
end

local function _wireSliderDrag(track: Frame, el: any, opts: any, snap: (number) -> number, maid: any)
	local dragging = false
	local function fromX(x: number): number
		local ax, aw = track.AbsolutePosition.X, track.AbsoluteSize.X
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
end

local function _buildSliderRow(Section: any, inner: Instance, maid: any, opts: any): any
	local step = opts.Step or 1
	local val = math.clamp(opts.Default or opts.Min, opts.Min, opts.Max)
	local row = _mkRow(Section, inner, opts.Description and L.SliderRowHDesc or L.SliderRowH)
	local nl = _mkLabel(opts.Name, "Text", row)
	local dl = opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local valL = Creator.New("TextLabel", {
		Text = tostring(val), FontFace = FONT_FREDOKA, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 6), Size = UDim2.new(0, L.SliderValLabelW, 0, L.SliderValLabelH),
		BackgroundTransparency = 1, ThemeTag = { TextColor3 = "TextSub" }, Parent = row,
	}) :: TextLabel
	local pct0 = (val - opts.Min) / (opts.Max - opts.Min)
	local track, fill, knob = _buildSliderTrack(row, pct0)
	local function snap(raw: number): number return math.clamp(math.round((raw - opts.Min) / step) * step + opts.Min, opts.Min, opts.Max) end
	local el = mkBase(opts.Id, val, row)
	function el:_apply(v: number)
		val = snap(v); self:_raw(val); local pct = (val - opts.Min) / (opts.Max - opts.Min)
		fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0); valL.Text = tostring(val)
		if opts.Callback then xpcall(opts.Callback, debug.traceback, val) end
	end
	_wireSliderDrag(track, el, opts, snap, maid)
	_bindRowHover(row, el, maid)
	return el
end

local function _wireButtonPress(el: any, row: Frame, isPrimary: boolean, opts: any)
	el.Press = function()
		if el:IsDisabled() then return end
		if opts.Callback then xpcall(opts.Callback, debug.traceback) end
		tw(row, { BackgroundColor3 = T.SliderFill, BackgroundTransparency = 0 }, Anim.Button)
		task.delay((Anim.ButtonOut :: TweenInfo).Time, function() tw(row, { BackgroundColor3 = isPrimary and T.SliderFill or T.RowBg, BackgroundTransparency = isPrimary and 0.1 or 0 }, Anim.ButtonOut) end)
		el._fire(nil)
	end
end

local function _buildButtonRow(Section: any, inner: Instance, maid: any, opts: any): any
	local isPrimary = opts.Style == "primary"
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	if isPrimary then
		row.BackgroundColor3 = T.SliderFill; row.BackgroundTransparency = 0.1
		Creator.New("UIGradient", { Rotation = 90, GradTag = true, Parent = row })
	end
	local nl, dl = _mkLabel(opts.Name, "Text", row), opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	Creator.New("TextLabel", {
		Text = "›", FontFace = FONT_BOLD, TextSize = L.BtnChevronSize, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0), Size = UDim2.fromOffset(L.BtnChevronW, L.BtnChevronH),
		BackgroundTransparency = 1, ThemeTag = { TextColor3 = isPrimary and "Text" or "TextSub" }, Parent = row,
	})
	local el = mkBase(opts.Id, nil, row)
	function el:_apply(_v: any) end
	_wireButtonPress(el, row, isPrimary, opts)
	maid:Give(row.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then el.Press() end end))
	_bindRowHover(row, el, maid)
	return el
end

local function _wireKeybindEvents(el: any, pill: TextButton, bound: Enum.KeyCode, opts: any, maid: any)
	local listening = false
	local function applyKey(k: Enum.KeyCode)
		bound = k; listening = false
		pill.Text = k == Enum.KeyCode.Unknown and "None" or k.Name
		Creator.Reg[pill] = { BackgroundColor3 = "InputBg", TextColor3 = "TextSub" }
		tw(pill, { BackgroundColor3 = T.InputBg }, Anim.Keybind)
		el:_raw(k)
		if opts.Callback then xpcall(opts.Callback, debug.traceback, k) end
	end
	function el:_apply(v: any)
		if typeof(v) == "EnumItem" then applyKey(v)
		elseif type(v) == "string" then
			local ok, kc = pcall(function() return (Enum.KeyCode :: any)[v] end)
			if ok and kc then applyKey(kc) end
		end
	end
	maid:Give(pill.MouseButton1Click:Connect(function()
		if el:IsDisabled() then return end
		listening = true; pill.Text = "..."; tw(pill, { BackgroundColor3 = T.SliderFill }, Anim.Keybind)
	end))
	maid:Give(UserInputService.InputBegan:Connect(function(inp, gp)
		if not listening or gp or inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		applyKey(inp.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or inp.KeyCode)
	end))
end

local function _buildKeybindRow(Section: any, inner: Instance, maid: any, opts: any): any
	local bound = opts.Default or Enum.KeyCode.Unknown
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	local nl = _mkLabel(opts.Name, "Text", row)
	local dl = opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local pill = Creator.New("TextButton", {
		Text = bound == Enum.KeyCode.Unknown and "None" or bound.Name, FontFace = FONT_UI, TextSize = L.ElemDescSize,
		AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0),
		Size = UDim2.fromOffset(L.KeybindPillW, L.KeybindPillH), ZIndex = 2,
		ThemeTag = { BackgroundColor3 = "InputBg", TextColor3 = "TextSub" }, Parent = row,
	}) :: TextButton
	Creator.New("UIStroke", { Thickness = L.StrokeInput, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, ThemeTag = { Color = "InputBorder" }, Parent = pill })
	local el = mkBase(opts.Id, bound, row)
	_wireKeybindEvents(el, pill, bound, opts, maid)
	_bindRowHover(row, el, maid)
	return el
end

local function _buildLabelRow(Section: any, inner: Instance, opts: any): any
	local row = _mkRow(Section, inner, L.RowHLabel)
	local nl = _mkLabel(opts.Name, "TextSub", row)
	nl.Position = UDim2.new(0, 16, 0, 0); nl.Size = UDim2.new(0.5, 0, 1, 0)
	local vl = Creator.New("TextLabel", {
		Text = opts.Value or "", FontFace = FONT_UI, TextSize = L.ElemValueSize,
		TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -L.ElemRightPad, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = { TextColor3 = opts.Color or "Text" }, Parent = row,
	}) :: TextLabel
	local el = mkBase(opts.Id, opts.Value or "", row)
	function el:_apply(v: any) vl.Text = tostring(v) end
	return el
end

local function _buildParagraphRow(Section: any, inner: Instance, opts: any): any
	local row = _mkRow(Section, inner, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, L.RowIndent); pad.PaddingRight = UDim.new(0, L.RowIndent)
	pad.PaddingTop = UDim.new(0, L.PagePad); pad.PaddingBottom = UDim.new(0, L.PagePad); pad.Parent = row
	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Padding = UDim.new(0, L.ParagraphItemGap); lay.Parent = row
	if opts.Title then
		local tl = Instance.new("TextLabel")
		tl.Text = opts.Title; tl.FontFace = FONT_BOLD; tl.TextSize = L.ElemNameSize
		tl.TextColor3 = T.Text; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.BackgroundTransparency = 1
		tl.Size = UDim2.new(1, 0, 0, L.ElemNameSize + L.LabelPad); tl.LayoutOrder = 1; tl.Parent = row
		Creator.Reg[tl :: any] = { TextColor3 = "Text" }
	end
	local bl = Instance.new("TextLabel")
	bl.Text = opts.Text; bl.FontFace = FONT_UI; bl.TextSize = L.ElemValueSize; bl.TextColor3 = T.TextSub
	bl.TextXAlignment = Enum.TextXAlignment.Left; bl.BackgroundTransparency = 1; bl.TextWrapped = true
	bl.Size = UDim2.new(1, 0, 0, 0); bl.AutomaticSize = Enum.AutomaticSize.Y; bl.LayoutOrder = 2; bl.Parent = row
	Creator.Reg[bl :: any] = { TextColor3 = "TextSub" }
	local el = mkBase(opts.Id, opts.Text, row)
	function el:_apply(v: any) bl.Text = tostring(v) end
	return el
end

local function _buildColorSwatch(row: Frame, col: Color3)
	local swatch = Creator.New("TextButton", {
		Name = "ColorSwatch", Text = "", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(40, 24),
		AutoButtonColor = false, BackgroundColor3 = col, ZIndex = 2, Parent = row,
	}) :: TextButton
	Creator.New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = swatch })
	Creator.New("UIStroke", { Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = swatch })
	return swatch
end

local function _buildMiniSlider(panel: Frame, ch: number, yOff: number, val: number, onUpdate: (number) -> (), maid: any)
	local labels = { "R", "G", "B" }
	local lbl = Instance.new("TextLabel")
	lbl.Text = labels[ch]; lbl.FontFace = FONT_UI; lbl.TextSize = 10; lbl.TextColor3 = T.TextSub; lbl.BackgroundTransparency = 1; lbl.ZIndex = 52
	lbl.Position = UDim2.new(0, 8, 0, yOff); lbl.Size = UDim2.fromOffset(10, 14); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = panel
	Creator.Reg[lbl :: any] = { TextColor3 = "TextSub" }
	local slTr = Creator.New("Frame", { Position = UDim2.new(0, 22, 0, yOff + 4), Size = UDim2.new(1, -52, 0, 4), BackgroundColor3 = Color3.fromRGB(26, 33, 26), ZIndex = 51, Parent = panel }) :: Frame
	Creator.New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = slTr })
	local pct0 = val / 255
	local slFl = Creator.New("Frame", { Size = UDim2.new(pct0, 0, 1, 0), ThemeTag = { BackgroundColor3 = "SliderFill" }, ZIndex = 52, Parent = slTr }) :: Frame
	Creator.New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = slFl })
	local slKn = Creator.New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(pct0, 0, 0.5, 0), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 53, Parent = slTr }) :: Frame
	Creator.New("UICorner", { CornerRadius = UDim.new(0, 5), Parent = slKn })
	local valL = Instance.new("TextLabel")
	valL.Text = tostring(val); valL.FontFace = FONT_UI; valL.TextSize = 10; valL.TextColor3 = T.TextSub; valL.BackgroundTransparency = 1; valL.ZIndex = 52; valL.AnchorPoint = Vector2.new(1, 0); valL.Position = UDim2.new(1, -4, 0, yOff); valL.Size = UDim2.fromOffset(24, 14); valL.TextXAlignment = Enum.TextXAlignment.Right; valL.Parent = panel
	Creator.Reg[valL :: any] = { TextColor3 = "TextSub" }
	local function update(v: number) local pct = v / 255; slFl.Size = UDim2.new(pct, 0, 1, 0); slKn.Position = UDim2.new(pct, 0, 0.5, 0); valL.Text = tostring(v); onUpdate(v) end
	local cpDrag = false
	maid:Give(slTr.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then cpDrag = true; update(math.clamp(math.round(math.clamp((inp.Position.X - slTr.AbsolutePosition.X) / slTr.AbsoluteSize.X, 0, 1) * 255), 0, 255)) end end))
	maid:Give(UserInputService.InputChanged:Connect(function(inp) if cpDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then update(math.clamp(math.round(math.clamp((inp.Position.X - slTr.AbsolutePosition.X) / slTr.AbsoluteSize.X, 0, 1) * 255), 0, 255)) end end))
	maid:Give(UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then cpDrag = false end end))
end

local function _buildColorPickerRow(Section: any, inner: Instance, maid: any, opts: any, pagesHolder: Frame): any
	local col = opts.Default or Color3.fromRGB(255, 255, 255)
	local r_, g_, b_ = math.round(col.R * 255), math.round(col.G * 255), math.round(col.B * 255)
	local row = _mkRow(Section, inner, opts.Description and L.RowHDesc or L.RowH)
	local nl = _mkLabel(opts.Name, "Text", row)
	local dl = opts.Description and _mkLabel(opts.Description, "TextSub", row) or nil
	_positionLabels(nl, dl)
	local swatch = _buildColorSwatch(row, col)
	local panel = Creator.New("Frame", { Name = "ColorPickerPanel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 1, 6), Size = UDim2.fromOffset(200, 104), BackgroundColor3 = Color3.fromRGB(10, 13, 10), ZIndex = 50, Visible = false, ClipsDescendants = false, Parent = row }) :: Frame
	Creator.New("UIStroke", { Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(0, 0, 0), Parent = panel })
	local prev = Instance.new("Frame"); prev.Name = "Preview"; prev.Size = UDim2.new(1, 0, 0, 12); prev.BackgroundColor3 = col; prev.BorderSizePixel = 0; prev.ZIndex = 51; prev.Parent = panel
	local hexL = Instance.new("TextLabel"); hexL.Text = string.format("#%02X%02X%02X", r_, g_, b_); hexL.FontFace = FONT_UI; hexL.TextSize = 10; hexL.TextColor3 = T.TextHint; hexL.BackgroundTransparency = 1; hexL.AnchorPoint = Vector2.new(0.5, 0); hexL.Position = UDim2.new(0.5, 0, 0, 88); hexL.Size = UDim2.new(0.9, 0, 0, 12); hexL.TextXAlignment = Enum.TextXAlignment.Center; hexL.ZIndex = 52; hexL.Parent = panel
	local function rebuild() col = Color3.fromRGB(r_, g_, b_); swatch.BackgroundColor3 = col; prev.BackgroundColor3 = col; hexL.Text = string.format("#%02X%02X%02X", r_, g_, b_); if opts.Callback then xpcall(opts.Callback, debug.traceback, col) end end
	_buildMiniSlider(panel, 1, 16, r_, function(v) r_ = v; rebuild() end, maid)
	_buildMiniSlider(panel, 2, 40, g_, function(v) g_ = v; rebuild() end, maid)
	_buildMiniSlider(panel, 3, 64, b_, function(v) b_ = v; rebuild() end, maid)
	maid:Give(swatch.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end))
	local el = mkBase(opts.Id, col, row)
	function el:_apply(v: any) if typeof(v) == "Color3" then col = v; r_, g_, b_ = math.round(col.R * 255), math.round(col.G * 255), math.round(col.B * 255); rebuild() end end
	_bindRowHover(row, el, maid)
	return el
end

local function _bindBasicControls(Section: any, inner: Instance, maid: any, showToast: (string) -> (), pagesHolder: Frame)
	function Section:Toggle(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildToggleRow(Section, inner, maid, opts, showToast)
	end
	function Section:Slider(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildSliderRow(Section, inner, maid, opts)
	end
	function Section:Button(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildButtonRow(Section, inner, maid, opts)
	end
	function Section:Dropdown(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildDropdownRow(Section, inner, maid, opts, showToast, pagesHolder)
	end
	function Section:Compound(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildCompoundRow(Section, inner, maid, opts, showToast)
	end
	Section.AddToggle = Section.Toggle
	Section.AddSlider = Section.Slider
	Section.AddButton = Section.Button
	Section.AddDropdown = Section.Dropdown
	Section.AddCompound = Section.Compound
end

local function _bindDisplayControls(Section: any, inner: Instance, maid: any, pagesHolder: Frame)
	function Section:Input(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildInputRow(Section, inner, maid, opts)
	end
	function Section:Keybind(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildKeybindRow(Section, inner, maid, opts)
	end
	function Section:Label(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildLabelRow(Section, inner, opts)
	end
	function Section:Paragraph(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildParagraphRow(Section, inner, opts)
	end
	function Section:ColorPicker(opts: any): any
		if Library.Options[opts.Id] then return Library.Options[opts.Id] end
		return _buildColorPickerRow(Section, inner, maid, opts, pagesHolder)
	end
	Section.AddInput = Section.Input
	Section.AddKeybind = Section.Keybind
	Section.AddLabel = Section.Label
	Section.AddParagraph = Section.Paragraph
	Section.AddColorPicker = Section.ColorPicker
end

local function _bindSectionControls(Section: any, inner: Instance, maid: any, showToast: (string) -> (), pagesHolder: Frame)
	_bindBasicControls(Section, inner, maid, showToast, pagesHolder)
	_bindDisplayControls(Section, inner, maid, pagesHolder)
end

local function _buildSection(tab: any, page: ScrollingFrame, secLabel: string?, maid: any, showToast: (string) -> (), pagesHolder: Frame): any
	if secLabel and secLabel ~= "" then
		tab._secLabel = secLabel
		if tab._secTitle then tab._secTitle.Text = secLabel end
	end
	local secFrame = Creator.New("Frame", {
		Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #tab._sections + 1, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = page,
	}) :: Frame
	local inner = Instance.new("Frame")
	inner.Name = "Inner"; inner.Position = UDim2.new(0, 0, 0, 0)
	inner.Size = UDim2.new(1, 0, 0, 0); inner.AutomaticSize = Enum.AutomaticSize.Y; inner.BackgroundTransparency = 1; inner.Parent = secFrame
	local rowLayout = Instance.new("UIListLayout"); rowLayout.SortOrder = Enum.SortOrder.LayoutOrder; rowLayout.Padding = UDim.new(0, L.RowListPad); rowLayout.Parent = inner
	local Section: any = { _frame = secFrame, _inner = inner, _rows = 0 }
	table.insert(tab._sections, Section)
	_bindSectionControls(Section, inner, maid, showToast, pagesHolder)
	return Section
end

local function _buildTabItem(window: any, tabLabel: string, opts_: any, leftSidebar: ScrollingFrame, rightSidebar: ScrollingFrame, pagesHolder: Frame, maid: any, activateTab: (any) -> (), getActiveTab: () -> any, showToast: (string) -> (), secTitle: TextLabel?): any
	local isRight = opts_ and type(opts_.Side) == "string" and opts_.Side:lower() == "right"
	local sidebar = isRight and rightSidebar or leftSidebar
	local tabList = isRight and window._utilTabs or window._tabs
	local tabIdx = #tabList + 1
	local btnName = (isRight and "Util_" or "Tab_") .. tabIdx
	local pageName = (isRight and "Page_Util" or "Page_Tab") .. tabIdx
	local btn, btnLabel = _buildTabButton(sidebar, btnName, tabLabel, tabIdx, isRight)
	_bindBtnHover(btn, maid)
	local page = _buildPage(pagesHolder, pageName)
	local Tab: any = { _btn = btn, _btnLabel = btnLabel, _page = page, _label = tabLabel, _sections = {}, _secTitle = secTitle }
	maid:Give(btn.MouseButton1Click:Connect(function() activateTab(Tab) end))
	table.insert(tabList, Tab)
	if isRight and #window._utilTabs == 1 and not getActiveTab() then
		activateTab(Tab)
	elseif not isRight and #window._tabs == 1 then
		activateTab(Tab)
	end
	function Tab:Section(secLabel: string?): any
		return _buildSection(self, page, secLabel, maid, showToast, pagesHolder)
	end
	Tab.AddSection = Tab.Section
	return Tab
end

local function _wireWindowMethods(Window: any, maid: any, gui: ScreenGui)
	function Window:GetSaveManager(): any return Library:GetSaveManager() end
	function Window:GetThemeManager(): any return Library:GetThemeManager() end
	function Window:GetAnimManager(): any return Library:GetAnimationManager() end
	function Window:GetLayoutManager(): any return Library:GetLayoutManager() end
	function Window:SaveSettings(): {[string]: any} return Library.SaveManager and Library.SaveManager:GetData() or {} end
	function Window:LoadSettings(d: {[string]: any}) if Library.SaveManager then Library.SaveManager:SetData(d) end end
	function Window:SaveToFile(folder: string, name: string): boolean
		if not Library.SaveManager then return false end
		local p = Library.SaveManager._folder; Library.SaveManager._folder = folder; local ok = Library.SaveManager:Save(name); Library.SaveManager._folder = p; return ok
	end
	function Window:LoadFromFile(folder: string, name: string): boolean
		if not Library.SaveManager then return false end
		local p = Library.SaveManager._folder; Library.SaveManager._folder = folder; local ok = Library.SaveManager:Load(name); Library.SaveManager._folder = p; return ok
	end
	function Window:Notify(opts: NotifOpts) Library:Notify(opts) end
	function Window:SetTheme(name: string) Library:SetTheme(name) end
	function Window:Destroy()
		if Library.SaveManager then Library.SaveManager:StopAutoSave() end
		maid:Destroy()
		if gui and gui.Parent then gui:Destroy() end
		Library.Window = nil; Library.Options = {}; _windowBuilt = false; _liveRefs = {}
	end
	function Window:IsDestroyed(): boolean return gui == nil or not gui.Parent end
end

local function _initWindowObj(gui: ScreenGui, master: Frame, maid: any, pagesHolder: Frame, leftSidebar: ScrollingFrame, rightSidebar: ScrollingFrame, secTitle: TextLabel, showToast: (string) -> ()): any
	local activeTab: any = nil
	local Window: any = { _gui = gui, _root = master, _maid = maid, _tabs = {} :: {any}, _utilTabs = {} :: {any} }
	local function activateTab(tab: any)
		if activeTab == tab then return end
		if activeTab then
			activeTab._page.Visible = false
			tw(activeTab._btn, { Size = UDim2.new(1, 0, 0, L.TabH) }, Anim.Tab)
			activeTab._btnLabel.TextColor3 = T.TabText
		end
		activeTab = tab
		tab._page.Visible = true
		tw(tab._btn, { Size = UDim2.new(1, 0, 0, L.TabH) }, Anim.Tab)
		tab._btnLabel.TextColor3 = T.TabTextActive
		secTitle.Text = tab._secLabel or (tab._label .. " Section")
		_closeActiveDropdown()
		showToast("Switched to " .. tab._label)
	end
	function Window:Tab(tabLabel: string, opts_: {Side: string?}?): any
		return _buildTabItem(self, tabLabel, opts_, leftSidebar, rightSidebar, pagesHolder, maid, activateTab, function() return activeTab end, showToast, secTitle)
	end
	Window.AddTab = Window.Tab
	_wireWindowMethods(Window, maid, gui)
	return Window
end

local function _buildWindowUi(gui: ScreenGui, cfg: WindowCfg, title: string, subtitle: string, W: number, H: number)
	local master, root, shield = _buildMasterAndRoot(gui, W, H)
	local toastFrame, toastLabel = _newToastFrame(gui)
	local showToast = _buildToastRunner(toastFrame, toastLabel)
	local hdr = _buildHeader(root, title, subtitle)
	local closeBtn = _buildCloseButton(hdr)
	local secHeader, secTitle, rotBox = _buildAccordion(root)
	local pagesHolder = _buildPagesHolder(root, H)
	local bottomBar, searchInput = _buildBottomBar(root, cfg.SearchPlaceholder)
	local leftSidebar = _buildSidebar(master, "LeftSidebar", false)
	local rightSidebar = _buildSidebar(master, "RightSidebar", true)
	local reopenPill = _buildReopenPill(gui, title)
	return master, root, hdr, closeBtn, reopenPill, secHeader, secTitle, rotBox, pagesHolder, bottomBar, searchInput, leftSidebar, rightSidebar, showToast, shield
end

local function _wireWindow(maid: any, refs: any, minKey: Enum.KeyCode)
	_liveRefs = { root=refs.root, header=refs.hdr, master=refs.master, pagesHolder=refs.pagesHolder, leftSidebar=refs.leftSidebar, rightSidebar=refs.rightSidebar, bottomBar=refs.bottomBar }
	_bindDragging(maid, refs.master, refs.hdr)
	_wireWindowSignals(maid, refs.master, refs.closeBtn, refs.reopenPill, minKey, refs.showToast)
	_wireAccordion(maid, refs.secHeader, refs.pagesHolder, refs.rotBox, refs.showToast)
	_bindSearch(maid, refs.searchInput, refs.pagesHolder)
	if refs.shield then maid:Give(refs.shield.MouseButton1Click:Connect(_closeActiveDropdown)) end
end

function Library:CreateWindow(cfg: WindowCfg?)
	if Library.Window then error("[Ignis] Only one Window per session.", 2) end
	_windowBuilt = true
	cfg = cfg or {}
	local title, subtitle = cfg.Title or "IGNIS", cfg.SubTitle or ""
	local W, H = cfg.Width or L.WindowW, cfg.Height or L.WindowH
	if cfg.Theme then Library:SetTheme(cfg.Theme) end
	local maid = Maid.new()
	local gui = Instance.new("ScreenGui")
	gui.Name = "IgnisUI"; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SafeParentGui(gui)
	local m, rt, hd, cb, rp, sh, st, rb, ph, bb, si, ls, rs, toast, shld = _buildWindowUi(gui, cfg, title, subtitle, W, H)
	local refs = { root=rt, hdr=hd, master=m, closeBtn=cb, reopenPill=rp, secHeader=sh, secTitle=st, rotBox=rb, pagesHolder=ph, bottomBar=bb, searchInput=si, leftSidebar=ls, rightSidebar=rs, showToast=toast, shield=shld }
	_wireWindow(maid, refs, cfg.MinimizeKey or Enum.KeyCode.RightShift)
	local Window = _initWindowObj(gui, m, maid, ph, ls, rs, st, toast)
	Library.Window = Window
	return Window
end

if typeof(getgenv) == "function" then
	pcall(function() getgenv().Ignis = Library end)
end

return Library
