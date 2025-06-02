LinkLuaModifier("modifier_enemy_difficulty_buff_steal_damage_10", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_steal_damage_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_steal_damage_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_steal_damage_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_steal_damage_10 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_steal_damage_10 = class(ItemBaseClass)

function enemy_difficulty_buff_steal_damage_10:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_steal_damage_10"
end

function modifier_enemy_difficulty_buff_steal_damage_10:GetTexture() return "arena/apocalypse_king_slayer" end
function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:GetTexture() return "arena/apocalypse_king_slayer" end
function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:GetTexture() return "arena/apocalypse_king_slayer" end

function modifier_enemy_difficulty_buff_steal_damage_10:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_enemy_difficulty_buff_steal_damage_10:OnCreated()
    if not IsServer() then return end
end

function modifier_enemy_difficulty_buff_steal_damage_10:OnAttackLanded(event)
    if not IsServer() then return end
    if event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    
    parent:AddNewModifier(parent, nil, "modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage", {
        duration = 3,
        damage = event.target:GetAverageTrueAttackDamage(event.target) * 0.10
    })

    event.target:AddNewModifier(parent, nil, "modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff", {
        duration = 3,
        damage = event.target:GetAverageTrueAttackDamage(event.target) * 0.10
    })
end
-------------
function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:DeclareFunctions()
   local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
   }
   return funcs 
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end
----
function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:DeclareFunctions()
   local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
   }
   return funcs 
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:GetModifierPreAttack_BonusDamage()
    return -self.fDamage
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_enemy_difficulty_buff_steal_damage_10_stolen_damage_debuff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end