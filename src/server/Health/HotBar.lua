--[[
    11/25/2025 - Emskipo

    This class holds the custom HotBar object used for player HUD
    This class utilizes the custom FillBar class.
--]]

--{ SERVICES }--

local RepStor = game:GetService("ReplicatedStorage")


--{ REQUIRED }--

local FillBar = require(script.Parent.FillBar)


--( Module )--

local HotBar = {}
HotBar.__index = HotBar


--Make the base HotBar Object Template
local HotBarTpl = Instance.new("ScreenGui")
HotBarTpl.Name = "HotBarGui"

--Make the "Main" frame of the HotBar
local mainFrame = Instance.new("Frame") --The Main instance is a GUI Frame
mainFrame.Name = "Main"
mainFrame.AnchorPoint = Vector2.new(.5, 1)
mainFrame.Position = UDim2.fromScale(.5, .99)
mainFrame.Size = UDim2.fromScale(.7, .065)
mainFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
mainFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = HotBarTpl

--Make the "Info" frame
local infoFrame = Instance.new("Frame")
infoFrame.Name = "Info"
infoFrame.AnchorPoint = Vector2.new(0, 1)
infoFrame.Position = UDim2.fromScale(0, 1)
infoFrame.Size = UDim2.fromScale(1, 1)
infoFrame.SizeConstraint = Enum.SizeConstraint.RelativeXY
infoFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(.2, 0)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayout.Parent = infoFrame

--Create the HP fillbar
local hpBar = FillBar.New(false, true)
hpBar.Name = "HealthBar"
hpBar.Size = UDim2.fromScale(1, .33)
hpBar.AnchorPoint = Vector2.zero
hpBar.SizeConstraint = Enum.SizeConstraint.RelativeXY
hpBar.LayoutOrder = 100 --Bottom of the stack
hpBar.Parent = infoFrame


--{ PUBLIC FUNCTIONS }--

function HotBar.New()
    return HotBarTpl:Clone()
end


--( RETURN )--
return HotBar