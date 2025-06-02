LinkLuaModifier("modifier_spawn_healing", "modifiers/modifier_spawn_healing", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spawn_healing_aura", "modifiers/modifier_spawn_healing", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}


spawn_healing = class(ItemBaseClass)
modifier_spawn_healing = class(spawn_healing)
modifier_spawn_healing_aura = class(ItemBaseAura)

function modifier_spawn_healing_aura:GetTexture() return "fountain" end
-----------------
function spawn_healing:GetIntrinsicModifierName()
    return "modifier_spawn_healing"
end

function modifier_spawn_healing:OnCreated()
    if not IsServer() then return end
end

function modifier_spawn_healing:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_spawn_healing:IsAura()
  return true
end

function modifier_spawn_healing:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_spawn_healing:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_spawn_healing:GetAuraRadius()
  return 700
end

function modifier_spawn_healing:GetModifierAura()
    return "modifier_spawn_healing_aura"
end

function modifier_spawn_healing:GetAuraEntityReject(ent) 
    return false
end
-----------
function modifier_spawn_healing_aura:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_spawn_healing_aura:OnIntervalThink()
    local parent = self:GetParent()
    if parent:HasModifier("modifier_item_mom_custom_toggle") then return end

    local amountHP = parent:GetMaxHealth() * 5 * 0.1
    local amountMana = parent:GetMaxMana() * 6 * 0.1

    parent:GiveMana(amountMana)
    parent:Heal(amountHP, nil)
end

function modifier_spawn_healing_aura:GetEffectName()
    return "particles/generic_gameplay/radiant_fountain_regen.vpcf"
end