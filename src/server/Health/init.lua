--[[
	11/25/2025 - Emskipo

    This module provides custom health functionality for characters and objects.
    Supports health for humanoids, models and baseparts. To add health to non-humanoid
    instances, simply add the "Target" tag to the instance or call the AddTarget() function
    in this class.
--]]

--{ SERVICES }--

local PlayerServ = game:GetService("Players")
local RepStor = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")
local TagServ = game:GetService("CollectionService")
local TweenServ = game:GetService("TweenService")
local DebrisServ = game:GetService("Debris")

--{ REQUIREMENT }--

local FillBar = require(script.FillBar)
local HotBarGui = require(script.HotBar)


--( MODULE )--

local Health = {}


--{ CLASS EVENTS }--

--Fires when a target reaches 0% HP
local DeathEvent = Instance.new("BindableEvent")
Health.Death = DeathEvent.Event

--Fires when a target reaches 100% HP
local HealedEvent = Instance.new("BindableEvent")
Health.Healed = HealedEvent.Event

local MendEvent = Instance.new("BindableEvent")
Health.Mended = MendEvent.Event


--{ PRIVATE }--

local mendData = {} --[target] = {Timer, Conn}
local mendRate = {Amount = 5, Period = 5}

--Begins the HP mending routine
local function Mend(target)
	if(not(mendData[target]))then mendData[target] = {} end --Add to mend data

	--Its possible to retrieve specific mend rate data from the HealthBar object..
	--Otherwise can use default mendRate information from this class

	--Check for stale connections
	if(mendData[target].Conn)then
		mendData[target].Conn:Disconnect()--Cancel current connection
		mendData[target].Timer = nil --Clear the timer
	end

	--Set new connection
	mendData[target].Conn = RunServ.Heartbeat:Connect(function()
		if(not(mendData[target].Timer))then
			mendData[target].Timer = tick() + mendRate.Period --Set the timer
			return --Don't heal this time, wait the mendRate period first
		end

		if(mendData[target].Timer >= tick())then return end --Not time yet
		mendData[target].Timer = tick() + mendRate.Period --Reset the timer
		MendEvent:Fire(target)
		Health.AddDamage(target, mendRate.Amount)--Heal the player by the mendRate amount
	end)
end

--Adds the provided object as a target, by providing it with a HealthBar
--If target is a player character, their HPBar Tag is hidden from them.
--They will have the own GUI HUD HealthBar
local function AddTarget(object)

	--Create a new HP bar tag for this target
	local newHPBar_tag = FillBar.New(true)
	newHPBar_tag.Name = "_HPBar"
	newHPBar_tag.Adornee = object
	newHPBar_tag.Parent = object

	--Check for a player character
	if(not(object:FindFirstChildWhichIsA("Humanoid", true)))then return end

	local player = PlayerServ:GetPlayerFromCharacter(object)
	if(not(player))then return end

	--This is a player character, they should have a HPBar Tag too
	--But we want to hide it from them. Its for others to see.
	newHPBar_tag.PlayerToHideFrom = player

	--Give the Player an HPBar HUD
	local newScreenGui = HotBarGui.New()
	newScreenGui.Name = "HotBarGui"
	newScreenGui.Parent = player.PlayerGui

	--Lets also give the player an XPbar
	local xpBar = FillBar.New(false, true) --Scripted for client
	xpBar.Name = "XPBar"
	xpBar.LayoutOrder = 2
	xpBar.Size = UDim2.fromScale(.75, .2)
	xpBar.AnchorPoint = Vector2.zero
	xpBar.SizeConstraint = Enum.SizeConstraint.RelativeXY
	xpBar:SetAttribute("BarColors", ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 127)),
		ColorSequenceKeypoint.new(.5, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255)),
	}))
	xpBar:SetAttribute("ColorIsGradient", true)
	xpBar:SetAttribute("GainColor", Color3.fromRGB(0, 170, 255))
	xpBar:SetAttribute("LossColor", Color3.fromRGB(0, 0, 127))
	xpBar.Parent = newScreenGui.Main.Info
end


--{ PUBLIC FUNCTIONS }--

--Takes aimData and applies damage/heals to target/s hit
function Health.Hit(aimData: {RaycastResult}, attacker)
	if(not(aimData))then return end
	--warn("Stuff got hit!")

	for hitNum, hitData in aimData do
		--print(hitData.Instance)
		--print("Hit #"..hitNum..":", hitData.Instance.Name)
		local mainModel = hitData.Instance:FindFirstAncestorOfClass("Model")
		if(not(mainModel))then 
			--print("Instance is not part of a model") 
			--Which means it can't be humanoid or a character rig
			--Assume object
			Health.AddDamage(hitData.Instance, hitData.Damage)
			continue
		end

		--It is part of a model
		local humanoid = mainModel:FindFirstChildWhichIsA("Humanoid")
		if(not(humanoid))then
			--print("Instance is part of a model but not a character")
			--Assume object model
			--print(mainModel.Name, "has taken damage:", hitData.Damage)
			Health.AddDamage(mainModel.PrimaryPart, hitData.Damage)
			continue
		end

		--It is a character!
		--print(mainModel.Name, "has taken damage:", hitData.Damage)
		local player = PlayerServ:GetPlayerFromCharacter(mainModel)
		if(not(player))then
			--NPC
			Health.AddDamage(mainModel.PrimaryPart, hitData.Damage)
		else
			--Player
			warn(player.Name, "hit:", hitData.Damage)
			Health.AddDamage(player, hitData.Damage)
		end
	end
end

--Set the fill amount for the specified targets healthbar
--damage can be +/-. Where + would indicate a heal.
--NEED TO MAKE SURE THIS ALSO UPDATES FOR PLAYER HOTBAR HP
function Health.AddDamage(target, damage: number)
	--print(target.Name, "has taken damage:", damage)

	--If target is a player, we need to also retrieve their HotBar HPBar
	local player = nil
	if(target:IsA("Player"))then
		player = target
		target = target.Character
	else
		player = PlayerServ:GetPlayerFromCharacter(target)
	end

	local hpBarTag = target:FindFirstChild("_HPBar", true)
	if(hpBarTag)then hpBarTag = hpBarTag.FillBar end

	local hpBar
	if(player)then
		hpBar = player.PlayerGui.HotBarGui:FindFirstChild("HealthBar", true)
		if(not(hpBar))then warn("Did not find HUD HpBar") end
	end
	if(not(hpBar) and not(hpBarTag))then return end--No HPBars found for this target
	local primaryBar = if(hpBarTag)then hpBarTag else hpBar

	local maxUnits = primaryBar:GetAttribute("MaxUnits") or 100
	local currentUnits = primaryBar:GetAttribute("Units") or 100
	local newUnits = math.max(0, currentUnits + damage)
	newUnits = math.min(maxUnits, newUnits)
	local newHPPercent = math.max(0, newUnits/maxUnits)
	newHPPercent = math.min(1, newHPPercent)

	--If the target lost HP then initiate Mending
	if(damage < 0)then
		Mend(target)
	end

	--Check for full HP or Death
	if(newHPPercent >= 1)then
		--Fully Healed!
		if(mendData[target])then
			--Stop mending, healed or dead
			if(mendData[target].Conn)then mendData[target].Conn:Disconnect() end
		end
		warn(target.Name, "is fully healed!")
		HealedEvent:Fire(target)
	end
	if(newHPPercent <= 0)then
		--This target/player has died!
		if(mendData[target])then
			--Stop mending, healed or dead
			if(mendData[target].Conn)then mendData[target].Conn:Disconnect() end
		end
		warn(target.Name, "has died!")
		DeathEvent:Fire(target)
	end

    --Adjust the HPBar
	if(hpBar)then
		--print("Updating Player HUD HPBar")
		hpBar:SetAttribute("Units", newUnits)
	end
	if(hpBarTag)then
		--print("Updating Target Tag HPBar")
		hpBarTag:SetAttribute("Units", newUnits)
	end
end

--Tags the provided instance as a "Target" to be seen by
--the Health System.
function Health.AddTarget(target: Instance)
    TagServ:AddTag(target, "Target")
end


--AutoRun Stuff when The class is required
TagServ:GetInstanceAddedSignal("Target"):Connect(function(object)
    warn("New Target Added:", object.Name)
	AddTarget(object)
end)

TagServ:GetInstanceRemovedSignal("Target"):Connect(function(object)
    warn("Target Removed:", object.Name)
end)

--Grab any pre-existing targets
for i, object in TagServ:GetTagged("Target") do
    print("Found Target:", object.Name)
	AddTarget(object)
end

--Grab players and Apply HPBar
PlayerServ.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		Health.AddTarget(char)
	end)
end)


--( RETURN )--
return Health