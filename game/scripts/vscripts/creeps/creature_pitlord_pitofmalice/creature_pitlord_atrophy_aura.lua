LinkLuaModifier("modifier_creature_pitlord_atrophy_aura", "creeps/creature_pitlord_pitofmalice/creature_pitlord_atrophy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creature_pitlord_atrophy_aura_aura", "creeps/creature_pitlord_pitofmalice/creature_pitlord_atrophy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creature_pitlord_atrophy_aura_buff", "creeps/creature_pitlord_pitofmalice/creature_pitlord_atrophy_aura", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

creature_pitlord_atrophy_aura = class(ItemBaseClass)
modifier_creature_pitlord_atrophy_aura = class(creature_pitlord_atrophy_aura)
modifier_creature_pitlord_atrophy_aura_aura = class(ItemBaseClassDebuff)
modifier_creature_pitlord_atrophy_aura_buff = class(ItemBaseClassBuff)
-------------
function creature_pitlord_atrophy_aura:GetIntrinsicModifierName()
    return "modifier_creature_pitlord_atrophy_aura"
end

function modifier_creature_pitlord_atrophy_aura:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
end

function modifier_creature_pitlord_atrophy_aura:OnRemoved()
    if not IsServer() then return end 
end

function modifier_creature_pitlord_atrophy_aura:IsAura()
	return true
end

function modifier_creature_pitlord_atrophy_aura:GetModifierAura()
	return "modifier_creature_pitlord_atrophy_aura_aura"
end

function modifier_creature_pitlord_atrophy_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_creature_pitlord_atrophy_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_creature_pitlord_atrophy_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_creature_pitlord_atrophy_aura:GetAuraEntityReject( hEntity )
    return false
end

function modifier_creature_pitlord_atrophy_aura:RemoveOnDeath() return true end
----------
function modifier_creature_pitlord_atrophy_aura_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_creature_pitlord_atrophy_aura_aura:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("attack_damage_reduction")
end

function modifier_creature_pitlord_atrophy_aura_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local penalty = math.abs(self:GetAbility():GetSpecialValueFor("attack_damage_reduction"))/100

    local shared = (parent:GetAverageTrueAttackDamage(parent) * (1/penalty)) * penalty
    
    if self.amount ~= shared then
        self.added = false
    end

    if not self.added then
        self.amount = shared
    end

    local buff = caster:FindModifierByName("modifier_creature_pitlord_atrophy_aura_buff")
    if not buff then
        buff = caster:AddNewModifier(caster, self:GetAbility(), "modifier_creature_pitlord_atrophy_aura_buff", {})
    end

    if buff and not self.added then
        if buff.damage ~= nil then
            buff.damage = buff.damage + self.amount

            self.added = true
        end
        
        buff:ForceRefresh()
    end
end

function modifier_creature_pitlord_atrophy_aura_aura:OnCreated()
    if not IsServer() then return end 

    self.added = false

    self:OnIntervalThink()

    self:StartIntervalThink(1)
end

function modifier_creature_pitlord_atrophy_aura_aura:OnRemoved()
    if not IsServer() then return end 

    self:StartIntervalThink(-1)

    local caster = self:GetCaster()
    local parent = self:GetParent()

    local buff = caster:FindModifierByName("modifier_creature_pitlord_atrophy_aura_buff")

    if buff then
        if buff.damage ~= nil then
            buff.damage = buff.damage - self.amount
        end

        buff:ForceRefresh()
    end
end
-----------------
function modifier_creature_pitlord_atrophy_aura_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_creature_pitlord_atrophy_aura_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_creature_pitlord_atrophy_aura_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.damage = 0
end

function modifier_creature_pitlord_atrophy_aura_buff:OnRefresh()
    if not IsServer() then return end 

    self:InvokeBonusDamage()
end

function modifier_creature_pitlord_atrophy_aura_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_creature_pitlord_atrophy_aura_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_creature_pitlord_atrophy_aura_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end