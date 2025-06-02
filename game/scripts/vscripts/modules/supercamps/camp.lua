SuperCamps = SuperCamps or class({})

LinkLuaModifier("modifier_supercamp_unit", "modules/supercamps/camp", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_supercamp_unit = class(BaseClass)

SuperCamps_CAMPS = {
    ["spawn_supercamp_1"] = {
        "npc_dota_creature_supercamp_1",
        "npc_dota_creature_supercamp_2",
        "npc_dota_creature_supercamp_1",
        "npc_dota_creature_supercamp_2",
    },
    ["spawn_supercamp_2"] = {
        "npc_dota_creature_supercamp_3",
        "npc_dota_creature_supercamp_4",
        "npc_dota_creature_supercamp_3",
        "npc_dota_creature_supercamp_4",
    },
    ["spawn_supercamp_3"] = {
        "npc_dota_creature_supercamp_5",
        "npc_dota_creature_supercamp_6",
        "npc_dota_creature_supercamp_5",
        "npc_dota_creature_supercamp_6",
    },
}

SuperCamps_DEATH_COUNTER = {}
SuperCamps_COMPLETION_COUNTER = {}

function SuperCamps:_init()
    for entName,camp in pairs(SuperCamps_CAMPS) do
        self:SpawnCamp(entName)
    end
end

function SuperCamps:SpawnCamp(campName)
    for _,unitName in pairs(SuperCamps_CAMPS[campName]) do
        local zone = Entities:FindByName(nil, campName)
        local index = zone:GetEntityIndex()
        local point = zone:GetAbsOrigin() + RandomVector(RandomFloat(0, 10))

        local zoneX = zone:GetOrigin().x
        local zoneY = zone:GetOrigin().y
        local zoneZ = zone:GetOrigin().z

        SuperCamps_DEATH_COUNTER[index] = SuperCamps_DEATH_COUNTER[index] or {}
        SuperCamps_DEATH_COUNTER[index] = #SuperCamps_CAMPS[campName]

        self:SpawnUnits(unitName, point, zoneX, zoneY, zoneZ, index, #SuperCamps_CAMPS[campName], campName)
    end
end

function SuperCamps:SpawnUnits(unitName, point, x, y, z, zoneIndex, campSize, zoneName)
    CreateUnitByNameAsync(unitName, point, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
        unit:AddNewModifier(unit, nil, "modifier_supercamp_unit", {
            posX = x,
            posY = y,
            posZ = z,
            name = unitName,
            zoneIndex = zoneIndex,
            zoneName = zoneName,
            campSize = campSize
        })
        
        if RollPercentage(5) then
            unit:SetRenderColor(255, 215, 0)
            unit:SetModelScale(unit:GetModelScale() * 1.4)
            unit:SetMaximumGoldBounty(unit:GetMaximumGoldBounty() * 3.0)
            unit:SetMinimumGoldBounty(unit:GetMaximumGoldBounty() * 3.0)
            unit:SetDeathXP(unit:GetDeathXP() * 3.0)
            local hp = unit:GetMaxHealth() * 1.50
            if hp > INT_MAX_LIMIT or hp <= 0 then
                hp = INT_MAX_LIMIT
            end

            unit:SetBaseMaxHealth(hp)
            unit:SetMaxHealth(hp)
            unit:SetHealth(hp)
        end
    end)
end

function modifier_supercamp_unit:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_supercamp_unit:OnCreated(kv)
    if not IsServer() then return end

    self.spawnPos = Vector(kv.posX, kv.posY, kv.posZ)
    self.unitName = kv.name
    self.unit = self:GetParent()
    self.campSize = kv.campSize
    self.zoneIndex = kv.zoneIndex
    self.zoneName = kv.zoneName

    SuperCamps_DEATH_COUNTER[self.zoneIndex] = SuperCamps_DEATH_COUNTER[self.zoneIndex] or self.campSize
    SuperCamps_COMPLETION_COUNTER[self.zoneIndex] = SuperCamps_COMPLETION_COUNTER[self.zoneIndex] or 0

    self.unit:CreatureLevelUp(SuperCamps_COMPLETION_COUNTER[self.zoneIndex])
end

function modifier_supercamp_unit:OnDeath(event)
    if not IsServer() then return end

    local creep = event.unit
    
    if creep ~= self:GetParent() then
        return
    end

    SuperCamps_DEATH_COUNTER[self.zoneIndex] = SuperCamps_DEATH_COUNTER[self.zoneIndex] - 1
    if SuperCamps_DEATH_COUNTER[self.zoneIndex] > 0 then return end

    SuperCamps_COMPLETION_COUNTER[self.zoneIndex] = SuperCamps_COMPLETION_COUNTER[self.zoneIndex] + 1

    local amountTime = 1

    Timers:CreateTimer(amountTime, function()
        SuperCamps:SpawnCamp(self.zoneName)
    end)
end

function modifier_supercamp_unit:GetModifierIncomingDamage_Percentage(event)
    function CalculateDamageReduction(base, deaths)
        local stacks = (1 - (base/100))

        for i = 1, deaths, 1 do
          stacks = stacks * ((1 - (base/100)))
        end

        stacks = 1 - (1 - stacks)

        return stacks
    end

    local levelDifference = event.target:GetLevel() - event.attacker:GetLevel()
    if levelDifference < 1 then levelDifference = 1 end

    local reduction = -(100-(CalculateDamageReduction(levelDifference, SuperCamps_COMPLETION_COUNTER[self.zoneIndex])*100))

    return reduction
end
