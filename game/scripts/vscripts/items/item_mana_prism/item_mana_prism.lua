LinkLuaModifier("modifier_item_mana_prism", "items/item_mana_prism/item_mana_prism", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mana_prism_casting", "items/item_mana_prism/item_mana_prism", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mana_prism_debuff", "items/item_mana_prism/item_mana_prism", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCasting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_mana_prism = class(ItemBaseClass)
modifier_item_mana_prism = class(item_mana_prism)
modifier_item_mana_prism_casting = class(ItemBaseClassCasting)
modifier_item_mana_prism_debuff = class(ItemBaseClassDebuff)
-------------
function item_mana_prism:GetIntrinsicModifierName()
    return "modifier_item_mana_prism"
end

function item_mana_prism:GetChannelTime()
    return 100/self:GetSpecialValueFor("drain_per_sec_pct")
end

function item_mana_prism:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_item_mana_prism_casting", {
        x = point.x,
        y = point.y,
        z = point.z
    })
end

function item_mana_prism:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_item_mana_prism_casting")
end

function item_mana_prism:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    local caster = self:GetCaster()

    hTarget:AddNewModifier(caster, self, "modifier_item_mana_prism_debuff", {})
end
-----------
function modifier_item_mana_prism_casting:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")
    local maxDistance = ability:GetSpecialValueFor("distance")
    local point = Vector(params.x, params.y, params.z)
    local distance = (parent:GetAbsOrigin()-point):Length2D()

    if distance > maxDistance then
        distance = maxDistance
    end

    print(distance)

    local proj = {
        vSpawnOrigin = parent:GetAbsOrigin(),
        vVelocity = 0,
        fMaxSpeed = 0,
        fDistance = distance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/econ/items/phoenix/phoenix_solar_forge/phoenix_sunray_solar_forge.vpcf",
        Ability = ability,
        Source = parent,
    }

    ProjectileManager:CreateLinearProjectile(proj)
end
--------
function modifier_item_mana_prism_debuff:GetEffectName()
    return "particles/econ/items/phoenix/phoenix_solar_forge/phoenix_sunray_solar_forge_tgt.vpcf"
end