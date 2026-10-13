--[[
    TemplateHub UI Library - Example Usage Script
    This script demonstrates how to create a window, tabs, utility buttons,
    toggles, dropdowns, compound unit inputs, standalone textboxes, and buttons.
]]

-- If loading via GitHub / loadstring in an executor:
-- local TemplateHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/.../TemplateHub.lua"))()

-- In local environment or Studio:
local TemplateHub = loadfile("TemplateHub.lua") and loadfile("TemplateHub.lua")() or require(script.Parent.TemplateHub)

-- 1. Create the Main Window
local Window = TemplateHub:CreateWindow({
    Title = "TEMPLATE TITLE",
    Keybind = Enum.KeyCode.RightShift -- Toggle visibility with Right Shift
})

-- 2. Add Left Sidebar Tabs
local Tab1 = Window:AddTab("TAB 1")
local Tab2 = Window:AddTab("TAB 2")
local Tab3 = Window:AddTab("TAB 3")
local Tab4 = Window:AddTab("TAB 4")
local Tab5 = Window:AddTab("TAB 5")
local Tab6 = Window:AddTab("TAB 6")

-- 3. Add Right Sidebar Utility Buttons
Window:AddUtility("Utility 1", function()
    Window:ShowToast("Utility 1 Executed!")
end)

Window:AddUtility("Utility 2", function()
    Window:ShowToast("Utility 2 Executed!")
end)

Window:AddUtility("Utility 3", function()
    Window:ShowToast("Utility 3 Executed!")
end)

Window:AddUtility("Utility 4", function()
    Window:ShowToast("Utility 4 Executed!")
end)

-- 4. Add Section to Tab 1
local Section1 = Tab1:AddSection("Template Section")

-- Feature 1: Animated Toggle Switch
local Toggle1 = Section1:AddToggle("Feature1", {
    Title = "Template Feature 1",
    Default = true,
    Callback = function(state)
        print("Feature 1 changed:", state)
    end
})

-- Feature 2: Dropdown Menu
local Dropdown1 = Section1:AddDropdown("Feature2", {
    Title = "Template Feature 2",
    Values = {"Option Alpha", "Option Beta", "Option Gamma"},
    Default = "Option Alpha",
    Callback = function(selected)
        print("Feature 2 selected:", selected)
    end
})

-- Feature 3: Dropdown with Description
local Dropdown2 = Section1:AddDropdown("Feature3", {
    Title = "Template Feature 3",
    Description = "Template description text goes here",
    Values = {"Default Choice", "Custom Mode", "High Priority"},
    Default = "Default Choice",
    Callback = function(selected)
        print("Feature 3 selected:", selected)
    end
})

-- Feature 4: Compound Control (Unit Selector Pill + Value TextBox Input)
local Compound1 = Section1:AddCompound("Feature4", {
    Title = "Template Feature 4",
    Description = "Template description text goes here",
    Units = {"Unit", "x1", "x10", "Max"},
    DefaultUnit = "Unit",
    DefaultValue = "0",
    Callback = function(unit, value)
        print("Feature 4 changed - Unit:", unit, "Value:", value)
    end
})

-- Feature 5: Dropdown with Description
local Dropdown3 = Section1:AddDropdown("Feature5", {
    Title = "Template Feature 5",
    Description = "Template description text goes here",
    Values = {"All", "Selected Only", "Inverse"},
    Default = "All",
    Callback = function(selected)
        print("Feature 5 selected:", selected)
    end
})

-- Feature 6: Animated Toggle Switch
local Toggle2 = Section1:AddToggle("Feature6", {
    Title = "Template Feature 6",
    Default = false,
    Callback = function(state)
        print("Feature 6 changed:", state)
    end
})

-- Additional controls supported by the library:
Section1:AddInput("CustomInput", {
    Title = "Custom Text Input",
    Description = "Enter a custom player name or target",
    Placeholder = "Username...",
    Default = "",
    Callback = function(text)
        print("Input updated:", text)
    end
})

Section1:AddButton({
    Title = "Execute Action",
    Description = "Triggers a server/client action",
    ButtonText = "Run",
    Callback = function()
        Window:ShowToast("Action successfully run!")
    end
})

Window:ShowToast("TemplateHub Initialized Successfully!", 2.5)
