LinkLuaModifier("modifier_pudge_rot_custom", "heroes/hero_pudge/rot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_rot_custom_aura", "heroes/hero_pudge/rot", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

pudge_rot_custom = class(ItemBaseClass)
modifier_pudge_rot_custom = class(pudge_rot_custom)
modifier_pudge_rot_custom_aura = class(ItemBaseClassDebuff)
-------------
function pudge_rot_custom:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_pudge_rot_custom", {})
    else
        caster:RemoveModifierByName("modifier_pudge_rot_custom")
    end
end

function pudge_rot_custom:GetAOERadius()
    local parent = self:GetCaster()
    local ability = self

    if parent:HasScepter() then
        return ability:GetSpecialValueFor("rot_radius_scepter")
    end

    return ability:GetSpecialValueFor("rot_radius")
end
-------------------------------------------
function modifier_pudge_rot_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("rot_radius")
    
    if parent:HasScepter() then
        self.radius = ability:GetSpecialValueFor("rot_radius_scepter")
    end

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector(self.radius,self.radius,self.radius) )

    EmitSoundOn("Hero_Pudge.Rot", parent)

    local interval = ability:GetSpecialValueFor("rot_tick")

    self:StartIntervalThink(interval)
end

function modifier_pudge_rot_custom:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    StopSoundOn("Hero_Pudge.Rot", parent)
end

function modifier_pudge_rot_custom:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local fleshHeapMultiplier = ability:GetSpecialValueFor("flesh_heap_multiplier")
    local fleshHeapStacks = caster:FindModifierByName("modifier_pudge_flesh_heap_custom")

    local bonusDamage = 0

    if fleshHeapStacks ~= nil then
        bonusDamage = fleshHeapStacks:GetStackCount() * fleshHeapMultiplier
    end

    local damage = ability:GetSpecialValueFor("rot_damage")

    if caster:HasScepter() then
        damage = ability:GetSpecialValueFor("rot_damage_scepter")
    end

    damage = damage + bonusDamage

    self.interval = ability:GetSpecialValueFor("rot_tick")
    self.damage = damage * self.interval

    self.damageTable = {
        attacker = caster,
        damage_type = ability:GetAbilityDamageType(),
        damage = self.damage,
        ability = ability,
    }

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        self.damageTable.victim = victim
        
        ApplyDamage(self.damageTable)

        local debuff = victim:FindModifierByName("modifier_pudge_rot_custom_aura")
        if not debuff then
            debuff = victim:AddNewModifier(parent, ability, "modifier_pudge_rot_custom_aura", {
                duration = 1
            })
        end

        if debuff then
            debuff:ForceRefresh()
        end
    end
end
-------------------------------
function modifier_pudge_rot_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
end

function modifier_pudge_rot_custom_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("rot_slow")
end

function modifier_pudge_rot_custom_aura:GetModifierHPRegenAmplify_Percentage()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("rot_degen_scepter")
    end
end

function modifier_pudge_rot_custom_aura:GetModifierLifestealRegenAmplify_Percentage()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("rot_degen_scepter")
    end
end

function modifier_pudge_rot_custom_aura:GetModifierSpellLifestealRegenAmplify_Percentage()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("rot_degen_scepter")
    end
end