
--[[
	11/26/2025 - Emskipo

    This is a test script that simulates using the Health system by
    randomly damaging anything tagged as a "Target". Player characters are
    automatically tagged by the Health system.
--]]

local TagServ = game:GetService("CollectionService")
local HealthServ = require(script.Parent.Health)

local attackActive = {}
local attackSpeedMax = 10
local attackSpeedMin = 1
local attackDmgMax = 25
local attackDmgMin = 5

local function StartAttackTarget(target)
    task.spawn(function()
        if(attackActive[target])then return end
        attackActive[target] = true
		repeat
			task.wait(math.random(attackSpeedMin, attackSpeedMax))
            if(not(target) or not(attackActive[target]))then attackActive[target] = nil break end
			HealthServ.AddDamage(target, -math.random(attackDmgMin, attackDmgMax)) --Damage the Player
		until not(attackActive[target])
    end)
end

for i, target in TagServ:GetTagged("Target") do
    StartAttackTarget(target)
end

TagServ:GetInstanceAddedSignal("Target"):Connect(function(target)
    StartAttackTarget(target)
end)

TagServ:GetInstanceRemovedSignal("Target"):Connect(function(target)
    attackActive[target] = nil
end)

HealthServ.Death:Connect(function(target)
    attackActive[target] = nil --Stop attacking this target, it died.
    task.wait(20)
    HealthServ.AddDamage(target, 1000)--Full Heal! lol
    StartAttackTarget(target) --Attack them again
end)