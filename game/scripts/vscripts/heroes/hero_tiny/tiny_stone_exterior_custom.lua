LinkLuaModifier("modifier_tiny_stone_exterior_custom", "heroes/hero_tiny/tiny_stone_exterior_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tiny_stone_exterior_custom = class(ItemBaseClass)
modifier_tiny_stone_exterior_custom = class(tiny_stone_exterior_custom)
-------------
function tiny_stone_exterior_custom:GetIntrinsicModifierName()
    return "modifier_tiny_stone_exterior_custom"
end

function tiny_stone_exterior_custom:OnProjectileHit(hTarget, hLocation)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self 

    local damage = caster:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_damage_pct")/100)

    ApplyDamage({
        attacker = caster,
        victim = hTarget,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })

    hTarget:AddNewModifier(caster, nil, "modifier_stunned", {
        duration = ability:GetSpecialValueFor("stun_duration")
    })

    EmitSoundOn("Hero_Tiny.CraggyExterior.Stun", hTarget)
end
-------------
function modifier_tiny_stone_exterior_custom:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_tiny_stone_exterior_custom:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_tiny_stone_exterior_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_tiny_stone_exterior_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:HasScepter() then
        if parent ~= event.attacker and parent ~= event.target then return end
    else
        if parent ~= event.target then return end
    end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end

    local attacker = event.attacker

    local target = attacker

    if parent:HasScepter() then
        if parent == event.attacker and parent ~= event.target then
            target = event.target
        end
    end

    -- load data
    local projectile_name = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree__2proj.vpcf"
    local projectile_speed = ability:GetSpecialValueFor("projectile_speed")

    -- create projectile
    local info = {
        Target = target,
        Source = parent,
        Ability = ability, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true,                           -- Optional
    }
    ProjectileManager:CreateTrackingProjectile(info)

    EmitSoundOn("Hero_Tiny.CraggyExterior", parent)
end