--[[
    11/25/2025 - Emskipo

    This class holds the custom FillBar object used
    with the Health class. REQUIRES "BarScript" either local or client
    use local for NPC/NonHumanoid (Applied by Health Class)
--]]

--{ SERVICES }--

local RepStor = game:GetService("ReplicatedStorage")


--{ REQUIRED }--

--Server BarScript
local BarScript = script.Parent.BarScript
BarScript.Enabled = false

--Client BarScript
local ClientBarScript = RepStor.FillBarEm_Shared.BarScript
ClientBarScript.Enabled = false


--( Module )--

local FillBar = {}
FillBar.__index = FillBar


--Make the base FillBar Object Template
local fillBarTpl = Instance.new("Frame") --The Main instance is a GUI Frame
fillBarTpl.Name = "FillBar"
fillBarTpl.AnchorPoint = Vector2.new(.5, .5)
fillBarTpl.Position = UDim2.fromScale(.5, .5)
fillBarTpl.Size = UDim2.fromScale(.95, .1)
fillBarTpl.SizeConstraint = Enum.SizeConstraint.RelativeXX

fillBarTpl.BackgroundColor3 = Color3.fromRGB(0,0,0)
fillBarTpl.BackgroundTransparency = .5
fillBarTpl.Interactable = true

--{ CUSTOM ATTRIBUTES }--
--Set the custom bar colors Attribute
fillBarTpl:SetAttribute("BarColors", ColorSequence.new(
    {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(170,40,0)),
        ColorSequenceKeypoint.new(.25, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(85,255,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    }
))

--Set the ColorIsGradient boolean value
fillBarTpl:SetAttribute("ColorIsGradient", false)--default to false

--Heal/Damage indicator color attributes
fillBarTpl:SetAttribute("GainColor", Color3.fromRGB(85,255,0))
fillBarTpl:SetAttribute("LossColor", Color3.fromRGB(255,0,0))

--Set the MaxUnits attribute (Used to indicate maximum health points)
fillBarTpl:SetAttribute("MaxUnits", 150)
fillBarTpl:SetAttribute("Units", 150)
fillBarTpl:SetAttribute("ShowText", false)
fillBarTpl:SetAttribute("UseUnits", false) --Whether to show HP as units or pecentage
fillBarTpl:SetAttribute("UseYAxis", false) --Whether to fill using Y axis instead of X axis

--Add the UIStroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,0,0)
stroke.Thickness = 2
stroke.Transparency = .5
stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
stroke.Parent = fillBarTpl

--Add the UICorner
local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(.25, 0)
uicorner.Parent = fillBarTpl

--Add the Fill bar
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.AnchorPoint = Vector2.new(0, .5)
fill.Position = UDim2.fromScale(0, .5)
fill.Size = UDim2.fromScale(1, 1)
fill.Parent = fillBarTpl
local fillUICorner = uicorner:Clone()
fillUICorner.Parent = fill

--Add the text frame
local txtFrame = Instance.new("Frame")
txtFrame.Name = "Text"
txtFrame.BackgroundTransparency = 1
txtFrame.Size = UDim2.fromScale(1,1)
txtFrame.ZIndex = 2 --above the fill
txtFrame.Parent = fillBarTpl

--The text label
local txtLabel = Instance.new("TextLabel")
txtLabel.Visible = true
txtLabel.AnchorPoint = Vector2.new(.5, .5)
txtLabel.Position = UDim2.fromScale(.5, .5)
txtLabel.Size = UDim2.fromScale(1, 1.4)
txtLabel.TextYAlignment = Enum.TextYAlignment.Bottom
txtLabel.TextXAlignment =Enum.TextXAlignment.Center
txtLabel.BackgroundTransparency = 1
txtLabel.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
txtLabel.TextScaled = true
txtLabel.TextColor3 = Color3.fromRGB(255,255,255)
txtLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
txtLabel.TextStrokeTransparency = 0
txtLabel.Text = "75%"
txtLabel.Parent = txtFrame


--{ PUBLIC FUNCTIONS }--

function FillBar.New(asTag: boolean?, isClient: boolean?)
    local newFillBar = fillBarTpl:Clone()

    local newBarScript
    if(isClient)then
        newBarScript = ClientBarScript:Clone() --Handles Visual Changes
    else
        newBarScript = BarScript:Clone() --Handles Visual Changes
    end

    newBarScript.Parent = newFillBar
    newBarScript.Enabled = true

    if(asTag)then
        local newTag = Instance.new("BillboardGui")
        newTag.Name = "_FillBarTag"
        newTag.ExtentsOffsetWorldSpace = Vector3.new(0, 1.1, 0)
        newTag.Size = UDim2.fromScale(5, .75)
        newTag.ClipsDescendants = true
        newTag.AlwaysOnTop = true
        newFillBar.Parent = newTag
        newFillBar:SetAttribute("ShowText", true)
        return newTag
    end

    return newFillBar
end


--( RETURN )--
return FillBar