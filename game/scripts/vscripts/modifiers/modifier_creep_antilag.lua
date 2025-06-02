LinkLuaModifier("modifier_creep_antilag", "modifiers/modifier_creep_antilag", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_antilag_phased", "modifiers/modifier_creep_antilag", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_antilag_aura", "modifiers/modifier_creep_antilag", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

modifier_creep_antilag = class(ItemBaseClass)
modifier_creep_antilag_phased = class(ItemBaseClass)
modifier_creep_antilag_aura = class(ItemBaseClassAura)

modifier_creep_antilag.count = {}
-----------------
function modifier_creep_antilag:GetIntrinsicModifierName()
    return "modifier_creep_antilag"
end
-----------------
function modifier_creep_antilag:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:AddNewModifier(parent, nil, "modifier_creep_antilag_phased", {})
end

function modifier_creep_antilag:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_creep_antilag_phased")
end

function modifier_creep_antilag:IsAura()
  return true
end

function modifier_creep_antilag:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_creep_antilag:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_creep_antilag:GetAuraRadius()
  return 2100
end

function modifier_creep_antilag:GetModifierAura()
    return "modifier_creep_antilag_aura"
end

function modifier_creep_antilag:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_creep_antilag:GetAuraEntityReject(target)
    return false
end
----------------
function modifier_creep_antilag_aura:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if modifier_creep_antilag.count[caster:entindex()] == nil then
        modifier_creep_antilag.count[caster:entindex()] = modifier_creep_antilag.count[caster:entindex()] or 1
    else
        modifier_creep_antilag.count[caster:entindex()] = modifier_creep_antilag.count[caster:entindex()] + 1
    end

    if caster:HasModifier("modifier_creep_antilag_phased") then
        caster:RemoveModifierByName("modifier_creep_antilag_phased")
    end
end

function modifier_creep_antilag_aura:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if modifier_creep_antilag.count[caster:entindex()] ~= nil then
        modifier_creep_antilag.count[caster:entindex()] = modifier_creep_antilag.count[caster:entindex()] - 1

        if modifier_creep_antilag.count[caster:entindex()] < 1 then
            caster:AddNewModifier(caster, nil, "modifier_creep_antilag_phased", {})
        end
    end
end

function modifier_creep_antilag_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
----------------
function modifier_creep_antilag_phased:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:AddNoDraw()
end

function modifier_creep_antilag_phased:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveNoDraw()
end

function modifier_creep_antilag_phased:CheckState()
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
        [MODIFIER_STATE_OUT_OF_GAME] = true
    }   

    return state
end

