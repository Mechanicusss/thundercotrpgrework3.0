LinkLuaModifier("modifier_season_death", "modifiers/seasons/modifier_season_death", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_season_death = class(ItemBaseClass)

function modifier_season_death:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
end

function modifier_season_death:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_season_death:OnIntervalThink()
    self.agility = self:GetParent():GetBaseAgility() * -0.3
    self.strength = self:GetParent():GetBaseStrength() * -0.3
    self.intellect = self:GetParent():GetBaseIntellect() * -0.3

    self:InvokeAttr()
end

function modifier_season_death:AddCustomTransmitterData()
    return
    {
        agility = self.fAgility,
        strength = self.fStrength,
        intellect = self.fIntellect,
    }
end

function modifier_season_death:HandleCustomTransmitterData(data)
    if data.agility ~= nil and data.strength ~= nil and data.intellect ~= nil then
        self.fAgility = tonumber(data.agility)
        self.fStrength = tonumber(data.strength)
        self.fIntellect = tonumber(data.intellect)
    end
end

function modifier_season_death:InvokeAttr()
    if IsServer() == true then
        self.fAgility = self.agility
        self.fStrength = self.strength
        self.fIntellect = self.intellect

        self:SendBuffRefreshToClients()
    end
end

function modifier_season_death:GetModifierBonusStats_Agility()
    return self.fAgility
end

function modifier_season_death:GetModifierBonusStats_Intellect()
    return self.fIntellect
end

function modifier_season_death:GetModifierBonusStats_Strength()
    return self.fStrength
end

function modifier_season_death:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 

    local ability = event.ability
    local cooldown = ability:GetEffectiveCooldown(ability:GetLevel())

    if cooldown <= 0 then return end 

    ability:EndCooldown()
    ability:StartCooldown(cooldown*1.5)
end

function modifier_season_death:GetTexture() return "mortal" end
function modifier_season_death:GetPriority() return 9999 end