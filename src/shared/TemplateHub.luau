--!strict
--[[
    TemplateHub UI Library
    Recreated 1:1 from TemplateHubGui
    Usable via loadstring() or require() across any script / executor / Roblox Studio.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Target parent detection (safe for both Studio and Executors)
local function GetSafeGuiParent(): Instance
    local gethui = (getgenv and getgenv().gethui) or nil
    if gethui then
        local success, hui = pcall(gethui)
        if success and hui then return hui end
    end
    
    if not RunService:IsStudio() then
        local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if success and coreGui then return coreGui end
    end

    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    return game:GetService("CoreGui")
end

-- ==========================================
-- DESIGN CONSTANTS & THEME TOKENS
-- ==========================================
local RED_PRIMARY = Color3.fromRGB(224, 32, 32)
local RED_DARK_ACCENT = Color3.fromRGB(115, 14, 14)
local RED_HOVER = Color3.fromRGB(240, 48, 48)

local BG_CENTER = Color3.fromRGB(18, 22, 18)
local BG_ROW = Color3.fromRGB(12, 16, 12)
local BG_BOTTOM = Color3.fromRGB(10, 12, 10)
local BG_SEARCH = Color3.fromRGB(6, 8, 6)
local BG_PILL = Color3.fromRGB(6, 8, 6)
local BG_MENU = Color3.fromRGB(14, 18, 14)
local BG_KNOB = Color3.fromRGB(250, 250, 250)

local ACCENT_GREEN = Color3.fromRGB(40, 215, 80)
local TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local TEXT_MUTED = Color3.fromRGB(180, 190, 185)
local TEXT_GRAY = Color3.fromRGB(110, 120, 110)

local STROKE_BLACK = Color3.fromRGB(0, 0, 0)
local STROKE_ROW = Color3.fromRGB(34, 40, 34)

local FONT_TITLE = Enum.Font.LuckiestGuy
local FONT_SUBTITLE = Enum.Font.FredokaOne
local FONT_BODY = Enum.Font.BuilderSans

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Red Bevel Gradient
local BUTTON_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(248, 55, 55)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(228, 22, 22)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(175, 14, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 10))
})

-- ==========================================
-- PROCEDURAL BUILDER HELPERS
-- ==========================================
local function New<T>(className: string, properties: {[string]: any}, children: {Instance}?): T
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        inst[k] = v
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst :: any
end

local function AddUIStroke(parent: Instance, thickness: number, color: Color3, mode: Enum.ApplyStrokeMode?): UIStroke
    return New("UIStroke", {
        Thickness = thickness,
        Color = color,
        ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function AddDarkBevelAccents(parent: Instance, leftWidth: number?, bottomHeight: number?)
    New("Frame", {
        Name = "LeftDarkAccent",
        BackgroundColor3 = RED_DARK_ACCENT,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, leftWidth or 4, 1, 0),
        ZIndex = parent.ZIndex + 1,
        Parent = parent
    })
    New("Frame", {
        Name = "BottomDarkAccent",
        BackgroundColor3 = RED_DARK_ACCENT,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, bottomHeight or 4),
        ZIndex = parent.ZIndex + 1,
        Parent = parent
    })
end

local function CreateChevron(parent: Instance, color: Color3, size: number, defaultRot: number?): Frame
    local icon = New("Frame", {
        Name = "ChevronIcon",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(size, size),
        Parent = parent
    })

    local rotBox = New("Frame", {
        Name = "RotatedBox",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -2),
        Size = UDim2.fromOffset(size - 4, size - 4),
        Rotation = defaultRot or 45,
        Parent = icon
    }, {
        New("Frame", {
            Name = "BottomBar",
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2)
        }),
        New("Frame", {
            Name = "RightBar",
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -2, 0, 0),
            Size = UDim2.new(0, 2, 1, 0)
        })
    })

    return icon
end

-- ==========================================
-- LIBRARY DEFINITION
-- ==========================================
local Library = {
    Version = "1.0.0",
    Flags = {},
    ActiveWindow = nil,
    WindowMethods = {},
    TabMethods = {},
    SectionMethods = {}
}
Library.WindowMethods.__index = Library.WindowMethods
Library.TabMethods.__index = Library.TabMethods
Library.SectionMethods.__index = Library.SectionMethods

-- ----------------------------------------------------
-- NOTIFICATION TOAST SYSTEM
-- ----------------------------------------------------
function Library.WindowMethods:ShowToast(message: string, duration: number?)
    local toast = self.Toast
    local toastText = self.ToastText
    toastText.Text = message

    if self.ToastThread then task.cancel(self.ToastThread) end
    self.ToastThread = task.spawn(function()
        TweenService:Create(toast, TWEEN_BOUNCE, { Position = UDim2.new(0.5, 0, 1, -25) }):Play()
        task.wait(duration or 1.8)
        TweenService:Create(toast, TWEEN_FAST, { Position = UDim2.new(0.5, 0, 1, 70) }):Play()
    end)
end

-- ----------------------------------------------------
-- WINDOW METHODS
-- ----------------------------------------------------
function Library.WindowMethods:SetVisible(isVisible: boolean)
    self.Master.Visible = isVisible
    self.ReopenPill.Visible = not isVisible
    if not isVisible then
        self:ShowToast("Hub minimized. Press [R-SHIFT] to reopen.")
    end
end

function Library.WindowMethods:Toggle()
    self:SetVisible(not self.Master.Visible)
end

function Library.WindowMethods:CloseDropdown()
    if self.ActiveDropdownMenu then
        self.ActiveDropdownMenu.Visible = false
        if self.ActiveRow then self.ActiveRow.ZIndex = 1 end
        if self.ActiveChevronBox then
            TweenService:Create(self.ActiveChevronBox, TWEEN_FAST, { Rotation = 45 }):Play()
        end
        self.DropdownShield.Visible = false
        self.ActiveDropdownMenu = nil
        self.ActiveRow = nil
        self.ActiveChevronBox = nil
    end
end

function Library.WindowMethods:AddUtility(name: string, callback: () -> ())
    local window = self
    local rightSidebar = window.RightSidebar

    local btn = New("TextButton", {
        Name = "Util_" .. (#window.Utilities + 1),
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Text = "",
        Parent = rightSidebar
    }, {
        New("UIGradient", {
            Rotation = 90,
            Color = BUTTON_GRADIENT
        }),
        New("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = FONT_TITLE,
            Text = name,
            TextColor3 = TEXT_WHITE,
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        }, {
            New("UIStroke", {
                Thickness = 2.4,
                Color = STROKE_BLACK,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            })
        })
    })

    AddUIStroke(btn, 3.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    AddDarkBevelAccents(btn, 4, 4)

    -- Hover micro-interactions
    local origSize = btn.Size
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, {
            Size = UDim2.new(origSize.X.Scale, origSize.X.Offset + 4, origSize.Y.Scale, origSize.Y.Offset + 2)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, { Size = origSize }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        window:CloseDropdown()
        if callback then
            task.spawn(callback)
        end
    end)

    table.insert(window.Utilities, btn)
    return btn
end

function Library.WindowMethods:AddTab(name: string)
    local window = self
    local tabIdx = #window.Tabs + 1

    local Tab = {
        Window = window,
        Name = name,
        Index = tabIdx,
        Sections = {},
        Page = nil,
        Button = nil
    }

    -- 1. Tab Button in LeftSidebar
    local btn = New("TextButton", {
        Name = "Tab_" .. tabIdx,
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Text = "",
        Parent = window.LeftSidebar
    }, {
        New("UIGradient", {
            Rotation = 90,
            Color = BUTTON_GRADIENT
        }),
        New("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = FONT_TITLE,
            Text = name,
            TextColor3 = TEXT_WHITE,
            TextSize = 24,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        }, {
            New("UIStroke", {
                Thickness = 2.4,
                Color = STROKE_BLACK,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            })
        })
    })

    AddUIStroke(btn, 3.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    AddDarkBevelAccents(btn, 4, 4)

    local origSize = btn.Size
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, {
            Size = UDim2.new(origSize.X.Scale, origSize.X.Offset + 4, origSize.Y.Scale, origSize.Y.Offset + 2)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, { Size = origSize }):Play()
    end)

    -- 2. ScrollingFrame Page in PagesHolder
    local page = New("ScrollingFrame", {
        Name = "Page_Tab" .. tabIdx,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
        ScrollBarImageTransparency = 0.5,
        BorderSizePixel = 0,
        Visible = false,
        Parent = window.PagesHolder
    }, {
        AddUIStroke(nil, 2.6, STROKE_BLACK, Enum.ApplyStrokeMode.Border),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        }),
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 7),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    })

    Tab.Page = page
    Tab.Button = btn

    btn.MouseButton1Click:Connect(function()
        window:CloseDropdown()
        window:SwitchTab(Tab)
    end)

    table.insert(window.Tabs, Tab)

    if #window.Tabs == 1 then
        window:SwitchTab(Tab)
    end

    return setmetatable(Tab, Library.TabMethods)
end

function Library.WindowMethods:SwitchTab(tab: any)
    self.CurrentTab = tab
    self.SectionTitleLabel.Text = tab.Name .. " Section"
    self.SearchInput.Text = ""

    for _, t in ipairs(self.Tabs) do
        local isCurrent = (t == tab)
        t.Page.Visible = isCurrent
        if isCurrent then
            t.Page.CanvasPosition = Vector2.zero
        end
    end
    self:ShowToast("Navigated to: " .. tab.Name)
end

function Library.WindowMethods:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- ----------------------------------------------------
-- TAB METHODS
-- ----------------------------------------------------
function Library.TabMethods:AddSection(title: string)
    local Section = {
        Tab = self,
        Title = title,
        Rows = {}
    }

    return setmetatable(Section, Library.SectionMethods)
end

-- ----------------------------------------------------
-- SECTION METHODS (Interactive Rows)
-- ----------------------------------------------------
local function CreateBaseRow(container: Instance, title: string, desc: string?, height: number?): (Frame, TextLabel)
    local h = height or (desc and 78 or 64)

    local row = New("Frame", {
        Name = "Row_" .. title:gsub("%s+", ""),
        BackgroundColor3 = BG_ROW,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h),
        Parent = container
    }, {
        AddUIStroke(nil, 2, STROKE_ROW, Enum.ApplyStrokeMode.Border)
    })

    local titleLbl = New("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, desc and 8 or 0),
        Size = UDim2.new(0.6, 0, 0, desc and 28 or h),
        Font = FONT_SUBTITLE,
        Text = title,
        TextColor3 = TEXT_WHITE,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = row
    }, {
        New("UIStroke", {
            Thickness = 1.4,
            Color = STROKE_BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    })

    if desc and desc ~= "" then
        New("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 42),
            Size = UDim2.new(0.6, 0, 0, 22),
            Font = FONT_BODY,
            Text = desc,
            TextColor3 = TEXT_MUTED,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = row
        })
    end

    return row, titleLbl
end

-- 1. TOGGLE
function Library.SectionMethods:AddToggle(id: string, config: {
    Title: string,
    Description: string?,
    Default: boolean?,
    Callback: ((boolean) -> ())?
})
    local tab = self.Tab
    local window = tab.Window
    local row = CreateBaseRow(tab.Page, config.Title, config.Description, config.Description and 78 or 64)

    local isEnabled = config.Default or false
    Library.Flags[id] = isEnabled

    local track = New("TextButton", {
        Name = "SliderTrack",
        BackgroundColor3 = Color3.fromRGB(10, 14, 10),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(58, 28),
        Text = "",
        Parent = row
    }, {
        AddUIStroke(nil, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local knob = New("Frame", {
        Name = "SliderKnob",
        BackgroundColor3 = BG_KNOB,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = isEnabled and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        Parent = track
    }, {
        AddUIStroke(nil, 1.6, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local Toggle = {
        Value = isEnabled,
        Changed = nil
    }

    function Toggle:SetValue(val: boolean)
        Toggle.Value = val
        Library.Flags[id] = val
        local targetPos = val and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        TweenService:Create(knob, TWEEN_SLIDE, { Position = targetPos }):Play()
        if config.Callback then task.spawn(config.Callback, val) end
        if Toggle.Changed then task.spawn(Toggle.Changed, val) end
    end

    function Toggle:GetValue(): boolean
        return Toggle.Value
    end

    function Toggle:OnChanged(func: (boolean) -> ())
        Toggle.Changed = func
    end

    track.MouseButton1Click:Connect(function()
        window:CloseDropdown()
        Toggle:SetValue(not Toggle.Value)
        window:ShowToast(config.Title .. (Toggle.Value and ": Enabled" or ": Disabled"))
    end)

    return Toggle
end

-- 2. DROPDOWN
function Library.SectionMethods:AddDropdown(id: string, config: {
    Title: string,
    Description: string?,
    Values: {string},
    Default: string?,
    Callback: ((string) -> ())?
})
    local tab = self.Tab
    local window = tab.Window
    local row = CreateBaseRow(tab.Page, config.Title, config.Description, config.Description and 78 or 64)

    local currentVal = config.Default or (config.Values and config.Values[1] or "Select...")
    Library.Flags[id] = currentVal

    local pill = New("TextButton", {
        Name = "DropdownPill",
        BackgroundColor3 = BG_PILL,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(160, 38),
        Text = "",
        Parent = row
    }, {
        AddUIStroke(nil, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local valLabel = New("TextLabel", {
        Name = "ValueLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = FONT_SUBTITLE,
        Text = currentVal,
        TextColor3 = TEXT_WHITE,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = pill
    }, {
        New("UIStroke", {
            Thickness = 1.4,
            Color = STROKE_BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    })

    local chIcon = CreateChevron(pill, ACCENT_GREEN, 14, 45)
    local rotBox = chIcon:WaitForChild("RotatedBox") :: Frame

    local menu = New("Frame", {
        Name = "DropdownMenu",
        BackgroundColor3 = BG_MENU,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 1, 4),
        Size = UDim2.fromOffset(160, math.min(#config.Values * 32, 160)),
        ZIndex = 50,
        Visible = false,
        Parent = row
    }, {
        AddUIStroke(nil, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border),
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0)
        })
    })

    local Dropdown = {
        Value = currentVal,
        Values = config.Values or {},
        Changed = nil
    }

    local function RebuildOptions()
        for _, c in ipairs(menu:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        menu.Size = UDim2.fromOffset(160, math.min(#Dropdown.Values * 32, 160))

        for idx, optName in ipairs(Dropdown.Values) do
            local optBtn = New("TextButton", {
                Name = "Opt_" .. idx,
                BackgroundColor3 = BG_MENU,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32),
                Font = FONT_SUBTITLE,
                Text = optName,
                TextColor3 = TEXT_WHITE,
                TextSize = 14,
                ZIndex = 51,
                LayoutOrder = idx,
                Parent = menu
            }, {
                New("UIStroke", {
                    Thickness = 1,
                    Color = STROKE_ROW,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                })
            })

            optBtn.MouseButton1Click:Connect(function()
                Dropdown:SetValue(optName)
                window:CloseDropdown()
                window:ShowToast("Selected: " .. optName)
            end)
        end
    end

    function Dropdown:SetValue(val: string)
        Dropdown.Value = val
        Library.Flags[id] = val
        valLabel.Text = val
        if config.Callback then task.spawn(config.Callback, val) end
        if Dropdown.Changed then task.spawn(Dropdown.Changed, val) end
    end

    function Dropdown:SetValues(newVals: {string})
        Dropdown.Values = newVals
        RebuildOptions()
    end

    function Dropdown:GetValue(): string
        return Dropdown.Value
    end

    function Dropdown:OnChanged(func: (string) -> ())
        Dropdown.Changed = func
    end

    pill.MouseButton1Click:Connect(function()
        local opening = not menu.Visible
        window:CloseDropdown()
        if opening then
            menu.Visible = true
            row.ZIndex = 45
            window.DropdownShield.Visible = true
            window.ActiveDropdownMenu = menu
            window.ActiveRow = row
            window.ActiveChevronBox = rotBox
            TweenService:Create(rotBox, TWEEN_FAST, { Rotation = 225 }):Play()
        end
    end)

    RebuildOptions()
    return Dropdown
end

-- 3. COMPOUND (Unit Cycler Pill + Value Input TextBox)
function Library.SectionMethods:AddCompound(id: string, config: {
    Title: string,
    Description: string?,
    Units: {string}?,
    DefaultUnit: string?,
    DefaultValue: string?,
    Callback: ((string, string) -> ())?
})
    local tab = self.Tab
    local window = tab.Window
    local row = CreateBaseRow(tab.Page, config.Title, config.Description, 78)

    local units = config.Units or {"Unit", "x1", "x10", "Max"}
    local uIdx = 1
    local currentUnit = config.DefaultUnit or units[1]
    local currentVal = config.DefaultValue or "0"

    Library.Flags[id .. "_Unit"] = currentUnit
    Library.Flags[id .. "_Value"] = currentVal

    local group = New("Frame", {
        Name = "ControlGroup",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(165, 38),
        Parent = row
    })

    local unitPill = New("TextButton", {
        Name = "UnitPill",
        BackgroundColor3 = BG_PILL,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 105, 1, 0),
        Text = "",
        Parent = group
    }, {
        AddUIStroke(nil, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local unitLabel = New("TextLabel", {
        Name = "UnitLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Font = FONT_SUBTITLE,
        Text = currentUnit,
        TextColor3 = ACCENT_GREEN,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = unitPill
    }, {
        New("UIStroke", {
            Thickness = 1.4,
            Color = STROKE_BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    })

    CreateChevron(unitPill, ACCENT_GREEN, 14, 45)

    local valBox = New("TextBox", {
        Name = "ValueInput",
        BackgroundColor3 = Color3.fromRGB(8, 11, 8),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 111, 0, 0),
        Size = UDim2.new(0, 54, 1, 0),
        Font = FONT_SUBTITLE,
        Text = currentVal,
        PlaceholderText = "0",
        TextColor3 = TEXT_WHITE,
        TextSize = 17,
        ClearTextOnFocus = false,
        Parent = group
    })
    local valStroke = AddUIStroke(valBox, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)

    valBox.Focused:Connect(function()
        valStroke.Color = ACCENT_GREEN
    end)
    valBox.FocusLost:Connect(function()
        valStroke.Color = STROKE_BLACK
        currentVal = valBox.Text
        Library.Flags[id .. "_Value"] = currentVal
        if config.Callback then task.spawn(config.Callback, currentUnit, currentVal) end
    end)

    unitPill.MouseButton1Click:Connect(function()
        window:CloseDropdown()
        uIdx = (uIdx % #units) + 1
        currentUnit = units[uIdx]
        unitLabel.Text = currentUnit
        Library.Flags[id .. "_Unit"] = currentUnit
        window:ShowToast("Unit set to: " .. currentUnit)
        if config.Callback then task.spawn(config.Callback, currentUnit, currentVal) end
    end)

    local Compound = {
        Unit = currentUnit,
        Value = currentVal
    }
    return Compound
end

-- 4. INPUT (Standalone Textbox)
function Library.SectionMethods:AddInput(id: string, config: {
    Title: string,
    Description: string?,
    Placeholder: string?,
    Default: string?,
    Callback: ((string) -> ())?
})
    local tab = self.Tab
    local window = tab.Window
    local row = CreateBaseRow(tab.Page, config.Title, config.Description, config.Description and 78 or 64)

    local currentVal = config.Default or ""
    Library.Flags[id] = currentVal

    local boxContainer = New("Frame", {
        Name = "InputContainer",
        BackgroundColor3 = BG_SEARCH,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(160, 36),
        Parent = row
    })
    local stroke = AddUIStroke(boxContainer, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)

    local box = New("TextBox", {
        Name = "InputBox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = currentVal,
        PlaceholderText = config.Placeholder or "Enter value...",
        TextColor3 = TEXT_WHITE,
        TextSize = 14,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = boxContainer
    })

    box.Focused:Connect(function()
        stroke.Color = ACCENT_GREEN
    end)
    box.FocusLost:Connect(function()
        stroke.Color = STROKE_BLACK
        currentVal = box.Text
        Library.Flags[id] = currentVal
        if config.Callback then task.spawn(config.Callback, currentVal) end
    end)

    return {
        SetValue = function(_, v: string)
            box.Text = v
            currentVal = v
            Library.Flags[id] = v
        end,
        GetValue = function() return currentVal end
    }
end

-- 5. BUTTON
function Library.SectionMethods:AddButton(config: {
    Title: string,
    Description: string?,
    ButtonText: string?,
    Callback: (() -> ())?
})
    local tab = self.Tab
    local window = tab.Window
    local row = CreateBaseRow(tab.Page, config.Title, config.Description, config.Description and 78 or 64)

    local btn = New("TextButton", {
        Name = "ActionButton",
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(130, 36),
        Text = "",
        Parent = row
    }, {
        New("UIGradient", { Rotation = 90, Color = BUTTON_GRADIENT }),
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = FONT_SUBTITLE,
            Text = config.ButtonText or "Execute",
            TextColor3 = TEXT_WHITE,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        }, {
            New("UIStroke", { Thickness = 1.4, Color = STROKE_BLACK, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
        })
    })

    AddUIStroke(btn, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    AddDarkBevelAccents(btn, 3, 3)

    btn.MouseButton1Click:Connect(function()
        window:CloseDropdown()
        if config.Callback then task.spawn(config.Callback) end
    end)

    return btn
end

-- 6. PARAGRAPH
function Library.SectionMethods:AddParagraph(config: {
    Title: string,
    Content: string
})
    local tab = self.Tab
    CreateBaseRow(tab.Page, config.Title, config.Content, 78)
end

-- ==========================================
-- CREATE WINDOW (PRIMARY FACTORY ENTRYPOINT)
-- ==========================================
function Library:CreateWindow(config: {
    Title: string?,
    Keybind: Enum.KeyCode?
})
    local titleText = config.Title or "TEMPLATE TITLE"
    local toggleKey = config.Keybind or Enum.KeyCode.RightShift

    local ScreenGui = New("ScreenGui", {
        Name = "TemplateHubGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = GetSafeGuiParent()
    })

    -- Toast notification
    local toast = New("Frame", {
        Name = "Toast",
        BackgroundColor3 = Color3.fromRGB(15, 18, 15),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 70),
        Size = UDim2.fromOffset(360, 46),
        Parent = ScreenGui
    }, {
        AddUIStroke(nil, 2.4, RED_PRIMARY, Enum.ApplyStrokeMode.Border)
    })

    local toastText = New("TextLabel", {
        Name = "ToastText",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = FONT_SUBTITLE,
        Text = "",
        TextColor3 = TEXT_WHITE,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = toast
    })

    -- Reopen Pill (shows when window is minimized)
    local reopenPill = New("TextButton", {
        Name = "ReopenPill",
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.fromOffset(220, 44),
        Text = "",
        Visible = false,
        Parent = ScreenGui
    }, {
        New("UIGradient", { Rotation = 90, Color = BUTTON_GRADIENT }),
        AddUIStroke(nil, 3.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border),
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = FONT_TITLE,
            Text = "REOPEN HUB",
            TextColor3 = TEXT_WHITE,
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        }, {
            New("UIStroke", { Thickness = 2, Color = STROKE_BLACK, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
        })
    })
    AddDarkBevelAccents(reopenPill, 4, 4)

    -- Master Container
    local master = New("Frame", {
        Name = "MasterContainer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(1130, 670),
        Parent = ScreenGui
    }, {
        New("UISizeConstraint", {
            MinSize = Vector2.new(880, 560),
            MaxSize = Vector2.new(1350, 820)
        })
    })

    -- Center Window
    local centerWindow = New("Frame", {
        Name = "CenterWindow",
        BackgroundColor3 = BG_CENTER,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(740, 660),
        Parent = master
    }, {
        AddUIStroke(nil, 3.6, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    -- Header Bar
    local headerBar = New("Frame", {
        Name = "HeaderBar",
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 64),
        Parent = centerWindow
    }, {
        AddUIStroke(nil, 3.6, STROKE_BLACK, Enum.ApplyStrokeMode.Border),
        New("UIGradient", { Rotation = 90, Color = BUTTON_GRADIENT })
    })
    AddDarkBevelAccents(headerBar, 4, 4)

    local titleLabel = New("TextLabel", {
        Name = "TitleLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Font = FONT_TITLE,
        Text = titleText,
        TextColor3 = TEXT_WHITE,
        TextSize = 34,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = headerBar
    }, {
        New("UIStroke", {
            Thickness = 3.2,
            Color = STROKE_BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    })

    local closeButton = New("TextButton", {
        Name = "CloseButton",
        BackgroundColor3 = RED_PRIMARY,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        Font = FONT_TITLE,
        Text = "X",
        TextColor3 = TEXT_WHITE,
        TextSize = 26,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = headerBar
    }, {
        New("UIGradient", { Rotation = 90, Color = BUTTON_GRADIENT }),
        AddUIStroke(nil, 3.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border),
        New("UIStroke", { Thickness = 2, Color = STROKE_BLACK, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
    })
    AddDarkBevelAccents(closeButton, 4, 4)

    -- Section Accordion Header
    local sectionHeader = New("TextButton", {
        Name = "SectionHeader",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 66),
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        Parent = centerWindow
    })

    local sectionContent = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(240, 38),
        Parent = sectionHeader
    })

    local sectionChevron = CreateChevron(sectionContent, TEXT_WHITE, 16, 45)
    sectionChevron.AnchorPoint = Vector2.new(0, 0.5)
    sectionChevron.Position = UDim2.new(0, 0, 0.5, 0)
    local sectionRotBox = sectionChevron:WaitForChild("RotatedBox") :: Frame

    local sectionTitle = New("TextLabel", {
        Name = "SectionTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Font = FONT_SUBTITLE,
        Text = "Template Section",
        TextColor3 = TEXT_WHITE,
        TextSize = 23,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = sectionContent
    }, {
        New("UIStroke", {
            Thickness = 2.2,
            Color = STROKE_BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    })

    -- Pages Container Holder
    local pagesHolder = New("Frame", {
        Name = "PagesHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 108),
        Size = UDim2.new(1, -24, 0, 484),
        Parent = centerWindow
    })

    -- Click-shield for dismissing dropdowns
    local dropdownShield = New("TextButton", {
        Name = "DropdownShield",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 40,
        Visible = false,
        Text = "",
        Parent = centerWindow
    })

    -- Bottom Bar (Search Filter & Resize Grip)
    local bottomBar = New("Frame", {
        Name = "BottomBar",
        BackgroundColor3 = BG_BOTTOM,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 54),
        Parent = centerWindow
    }, {
        AddUIStroke(nil, 3.6, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local searchLabel = New("TextLabel", {
        Name = "SearchLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 0),
        Size = UDim2.new(0, 80, 1, 0),
        Font = FONT_SUBTITLE,
        Text = "Search",
        TextColor3 = TEXT_WHITE,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = bottomBar
    }, {
        New("UIStroke", { Thickness = 2, Color = STROKE_BLACK, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
    })

    local searchContainer = New("Frame", {
        Name = "SearchFieldContainer",
        BackgroundColor3 = BG_SEARCH,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 105, 0.5, -17),
        Size = UDim2.new(1, -165, 0, 34),
        Parent = bottomBar
    }, {
        AddUIStroke(nil, 2.2, STROKE_BLACK, Enum.ApplyStrokeMode.Border)
    })

    local searchInput = New("TextBox", {
        Name = "SearchInput",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = "",
        PlaceholderText = "Template filter features...",
        TextColor3 = TEXT_WHITE,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchContainer
    })

    local resizeGrip = New("TextLabel", {
        Name = "ResizeGrip",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -8, 1, -6),
        Size = UDim2.fromOffset(22, 22),
        Font = Enum.Font.GothamBold,
        Text = "◢",
        TextColor3 = TEXT_GRAY,
        TextSize = 18,
        Parent = bottomBar
    })

    -- Left Sidebar (Tabs)
    local leftSidebar = New("ScrollingFrame", {
        Name = "LeftSidebar",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(0.5, -388, 0, 70),
        Size = UDim2.fromOffset(175, 580),
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = master
    }, {
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
    })

    -- Right Sidebar (Utilities)
    local rightSidebar = New("ScrollingFrame", {
        Name = "RightSidebar",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0.5, 388, 0, 70),
        Size = UDim2.fromOffset(175, 580),
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = master
    }, {
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
    })

    -- Window Object
    local Window = {
        ScreenGui = ScreenGui,
        Master = master,
        CenterWindow = centerWindow,
        HeaderBar = headerBar,
        CloseButton = closeButton,
        SectionTitleLabel = sectionTitle,
        PagesHolder = pagesHolder,
        DropdownShield = dropdownShield,
        SearchInput = searchInput,
        LeftSidebar = leftSidebar,
        RightSidebar = rightSidebar,
        ReopenPill = reopenPill,
        Toast = toast,
        ToastText = toastText,
        ToastThread = nil,
        Tabs = {},
        Utilities = {},
        CurrentTab = nil,
        ActiveDropdownMenu = nil,
        ActiveRow = nil,
        ActiveChevronBox = nil
    }
    setmetatable(Window, Library.WindowMethods)

    -- Window Dragging Logic
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = master.Position

    headerBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = master.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            master.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Window Minimize / Reopen
    closeButton.MouseButton1Click:Connect(function() Window:SetVisible(false) end)
    reopenPill.MouseButton1Click:Connect(function() Window:SetVisible(true) end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            Window:Toggle()
        end
    end)

    -- Dropdown shield dismiss
    dropdownShield.MouseButton1Click:Connect(function()
        Window:CloseDropdown()
    end)

    -- Accordion Collapsing
    local isSectionOpen = true
    sectionHeader.MouseButton1Click:Connect(function()
        Window:CloseDropdown()
        isSectionOpen = not isSectionOpen
        pagesHolder.Visible = isSectionOpen
        TweenService:Create(sectionRotBox, TWEEN_FAST, { Rotation = isSectionOpen and 45 or 225 }):Play()
        Window:ShowToast(isSectionOpen and "Section Expanded" or "Section Collapsed")
    end)

    -- Live Search Filter
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        Window:CloseDropdown()
        local query = searchInput.Text:lower()
        if Window.CurrentTab and Window.CurrentTab.Page then
            for _, row in ipairs(Window.CurrentTab.Page:GetChildren()) do
                if row:IsA("Frame") then
                    local tLbl = row:FindFirstChild("Title")
                    if tLbl and tLbl:IsA("TextLabel") then
                        row.Visible = (query == "" or tLbl.Text:lower():find(query, 1, true) ~= nil)
                    end
                end
            end
        end
    end)

    Library.ActiveWindow = Window
    return Window
end

return Library
