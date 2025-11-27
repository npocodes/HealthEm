--[[
	Fill Bar Script
	Emskipo
	11/25/2023
	
	This script handles the visual fx of the fill bar automatically.
	When the fill size is changed the script automatically handles
	fx based on custom attribute settings. These attribute values can be 
	changed via script as well.
	
		BarColors - Allows you to set what color/colors are displayed based on fill amount using a color sequence.
		ColorIsGradient - Treats the sequence as a gradient instead of using hard points set by keysequences
		GainColor - Sets the color to use for the UIStroke flash effect when the fill bar "fills", ie gain health
		LossColor - Sets the color to use for the UIStroke flash effect when the fill bar "drains", ie lose health
		MaxUnits - Sets the maximum value of the bar so that a FULL fill can equal more than 100, ie 200HealthPoints or 1000XP
		ShowText - Toggles whether the text value of the fill is always shown, or shown only when changed/interacted with.
		UseUnits - Toggles whether to display a percentage value 0 - 100 or unit value x/maxUnits
		VerticalFill - Toggles whether the fill operates on the X or Y axis.
--]]
local RunServ = game:GetService("RunService")
local TweenServ = game:GetService("TweenService")

local bar = script.Parent
local defaultStrokeColors = {
	Gain = bar:GetAttribute("GainColor") or Color3.fromRGB(0, 255, 0),
	Loss = bar:GetAttribute("LossColor") or Color3.fromRGB(255, 0, 0),
}

local label = bar.Text.TextLabel
local fill = bar.Fill
local defaultFillColors = {
	Ok = Color3.fromRGB(85, 170, 0),
	Caution = Color3.fromRGB(170, 164, 0),
	Danger = Color3.fromRGB(170, 40, 0)
}

local verticalFill = bar:GetAttribute("VerticalFill")
local barColors = bar:GetAttribute("BarColors")
local showText = bar:GetAttribute("ShowText")
label.Visible = (showText) --default visibility
local showTextConns = {}
local useUnits = bar:GetAttribute("UseUnits")
local maxUnits = bar:GetAttribute("MaxUnits") or 100
local units = bar:GetAttribute("Units") or maxUnits
maxUnits = tonumber(maxUnits)
units = tonumber(units)

local defaultTransparency = bar.UIStroke.Transparency
local defaultColor = bar.UIStroke.Color
local lastValue = (verticalFill) and fill.Size.Y.Scale or fill.Size.X.Scale

local borderTweens = {}

--Shows the text of the fill bar when player taps or mouseover
local function TextShowConnect()
	if(not(showText))then
		label.Visible = false
		--Show only during interaction
		showTextConns[#showTextConns+1] = bar.MouseEnter:Connect(function() label.Visible = true end)
		showTextConns[#showTextConns+1] = bar.MouseLeave:Connect(function() label.Visible = false end)
		showTextConns[#showTextConns+1] = bar.TouchTap:Connect(function() label.Visible = not(label.Visible) end)--Toggle
	else
		for i, conn in showTextConns do
			if(conn)then conn:Disconnect() end
		end
	end
end
TextShowConnect()

local function GetSequenceColor(sequence: ColorSequence, time: number)
	-- If time is 0 or 1, return the first or last value respectively
	if time == 0 then
		return sequence.Keypoints[1].Value
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	-- Otherwise, step through each sequential pair of keypoints
	for i = 1, #sequence.Keypoints - 1 do
		local thisKeypoint = sequence.Keypoints[i]
		local nextKeypoint = sequence.Keypoints[i + 1]
		if time >= thisKeypoint.Time and time < nextKeypoint.Time then
			-- Calculate how far alpha lies between the points
			local alpha = (time - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time)
			-- Evaluate the real value between the points using alpha
			return Color3.new(
				(nextKeypoint.Value.R - thisKeypoint.Value.R) * alpha + thisKeypoint.Value.R,
				(nextKeypoint.Value.G - thisKeypoint.Value.G) * alpha + thisKeypoint.Value.G,
				(nextKeypoint.Value.B - thisKeypoint.Value.B) * alpha + thisKeypoint.Value.B
			)
		end
	end
end

local function GetSequenceColorAtTime(time: number)
	if(not(barColors))then return end
	local timePoints = {}--TimePoints at which a color is set
	for i = 1, #barColors.Keypoints do
		--if(time == barColors.Keypoints[i].Time)then return  barColors.Keypoints[i].Value end --Direct time match
		timePoints[#timePoints+1] = barColors.Keypoints[i].Time
	end
	--No direct time match was found.. use comparisons
	local retColor
	for i = 1, #timePoints do
		if(time > timePoints[i])then
			retColor = barColors.Keypoints[i].Value
		end
	end
	return retColor
end


--Handles the flash effects when losing points (ex damage)
local function lossFlash()
	if(borderTweens[1] and borderTweens[1].PlaybackState == Enum.PlaybackState.Playing)then borderTweens[1]:Cancel() end
	if(borderTweens[2] and borderTweens[2].PlaybackState == Enum.PlaybackState.Playing)then borderTweens[2]:Cancel() end
	task.spawn(function()
		
		borderTweens[1] = TweenServ:Create(bar.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Bounce), {
			Color = defaultStrokeColors.Loss,
			Transparency = 0
		})
		borderTweens[2] = TweenServ:Create(bar.UIStroke, TweenInfo.new(1), {
			Color = defaultColor,
			Transparency = defaultTransparency
		})
		borderTweens[1]:Play()
		label.Visible = true
		borderTweens[1].Completed:Wait()
		borderTweens[2]:Play()
		label.Visible = showText
	end)
end

--Handle flash effects when gaining points (ex healing)
local function gainFlash()
	if(borderTweens[1] and borderTweens[1].PlaybackState == Enum.PlaybackState.Playing)then borderTweens[1]:Cancel() end
	if(borderTweens[2] and borderTweens[2].PlaybackState == Enum.PlaybackState.Playing)then borderTweens[2]:Cancel() end
	task.spawn(function() 
		borderTweens[1] = TweenServ:Create(bar.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Back), {
			Color = defaultStrokeColors.Gain,
			Transparency = 0
		})
		borderTweens[2] = TweenServ:Create(bar.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Bounce), {
			Color = defaultColor,
			Transparency = defaultTransparency
		})
		borderTweens[1]:Play()
		label.Visible = true
		borderTweens[1].Completed:Wait()
		label.Visible = showText
		borderTweens[2]:Play()
	end)
end

--Update the fill bar to reflect the current points/maxpoints
local function updateFillBar()
	if(lastValue > units)then
		lossFlash()
	elseif(lastValue < units)then
		gainFlash()
	end
	lastValue = units

	local percent = math.floor((units/maxUnits) * 100)/100
	percent = math.max(0, percent)
	percent = math.min(1, percent)
	local strPercent = math.floor(percent*100)

	label.Text = if(useUnits)then units.." / "..maxUnits else (strPercent.."%")
	if(showText)then label.Visible = true end

	local newColor
	if(barColors)then
		if(bar:GetAttribute("ColorIsGradient"))then
			newColor = GetSequenceColor(barColors, percent)
		else
			newColor = GetSequenceColorAtTime(percent)
		end
	end

	if(not(newColor))then
		newColor = (percent > .5) and defaultFillColors.Ok or defaultFillColors.Caution
		newColor = (percent > .25) and newColor or defaultFillColors.Danger
	end
	fill.BackgroundColor3 = newColor

	fill.Size = if(verticalFill)then UDim2.fromScale(fill.Size.X.Scale, percent) else UDim2.fromScale(percent, fill.Size.Y.Scale)
end

--Connect to custom attributes and monitor them for changes
--Update the bar to relect new settings

bar:GetAttributeChangedSignal("MaxUnits"):Connect(function()
	maxUnits = bar:GetAttribute("MaxUnits") or 100
	updateFillBar()
end)

bar:GetAttributeChangedSignal("Units"):Connect(function()
	units = bar:GetAttribute("Units") or maxUnits
	updateFillBar()
end)

bar:GetAttributeChangedSignal("UseUnits"):Connect(function()
	useUnits = bar:GetAttribute("UseUnits")
	updateFillBar()
end)

bar:GetAttributeChangedSignal("ShowText"):Connect(function()
	showText = bar:GetAttribute("ShowText")
	TextShowConnect()
	updateFillBar()
end)

bar:GetAttributeChangedSignal("BarColors"):Connect(function()
	barColors = bar:GetAttribute("BarColors")
	updateFillBar()
end)

bar:GetAttributeChangedSignal("VerticalFill"):Connect(function()
	verticalFill = bar:GetAttribute("VerticalFill")
end)

updateFillBar()