LinkLuaModifier("modifier_nevermore_ultimate_raze", "heroes/hero_nevermore/ultraze.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_ultimate_raze_debuff", "heroes/hero_nevermore/ultraze.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

nevermore_ultimate_raze = class(ItemBaseClass)
modifier_nevermore_ultimate_raze = class(nevermore_ultimate_raze)
modifier_nevermore_ultimate_raze_debuff = class(ItemBaseClassDebuff)
-------------
function modifier_nevermore_ultimate_raze_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_nevermore_ultimate_raze_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("dmg_reduce_pct")
end
-------------
function nevermore_ultimate_raze:GetIntrinsicModifierName()
    return "modifier_nevermore_ultimate_raze"
end

function modifier_nevermore_ultimate_raze:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_nevermore_ultimate_raze:OnCreated()
    self.parent = self:GetParent()
end

function modifier_nevermore_ultimate_raze:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if unit:IsIllusion() then return end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    if victim:IsMagicImmune() then return end

    local raze = caster:FindAbilityByName("nevermore_shadowraze1_custom")

    if raze == nil or raze:GetLevel() < 1 or not raze:IsCooldownReady() then
        raze = caster:FindAbilityByName("nevermore_shadowraze2_custom")
    end

    if raze == nil or raze:GetLevel() < 1 or not raze:IsCooldownReady() then
        raze = caster:FindAbilityByName("nevermore_shadowraze3_custom")
    end

    if raze == nil or raze:GetLevel() < 1 then return end

    if raze:GetManaCost(-1) > parent:GetMana() then return end

    if raze:IsCooldownReady() and caster:HasScepter() then
        SpellCaster:Cast(raze, victim, true)
    end

    local necromasteryStacks = caster:FindModifierByNameAndCaster("modifier_nevermore_necromastery_custom", caster)
    local necromasteryMultiplier = 0

    if necromasteryStacks ~= nil then
        necromasteryMultiplier = necromasteryStacks:GetStackCount()
    end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        raze:GetSpecialValueFor("shadowraze_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

        -- Place raze debuff --
        local razeDebuff = enemy:FindModifierByNameAndCaster("modifier_nevermore_shadowraze_debuff", caster)
        if razeDebuff == nil or not razeDebuff then
            razeDebuff = enemy:AddNewModifier(caster, raze, "modifier_nevermore_shadowraze_debuff", {
                duration = raze:GetSpecialValueFor("duration")
            })
        end

        razeDebuff:IncrementStackCount()
        razeDebuff:ForceRefresh()

        -- Get raze multiplier --
        local shadowrazeCounter = enemy:FindModifierByNameAndCaster("modifier_nevermore_shadowraze_debuff", caster)
        local shadowrazeMultiplier = 0

        if shadowrazeCounter ~= nil then
            shadowrazeMultiplier = shadowrazeCounter:GetStackCount()
        end

        ApplyDamage({
            victim = enemy, 
            attacker = caster, 
            damage = (necromasteryMultiplier * ability:GetSpecialValueFor("necromastery_multiplier")) + raze:GetSpecialValueFor("shadowraze_damage") + (raze:GetSpecialValueFor("stack_bonus_damage") * shadowrazeMultiplier), 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })

        if caster:HasScepter() then
            enemy:AddNewModifier(caster, ability, "modifier_nevermore_ultimate_raze_debuff", { duration = ability:GetSpecialValueFor("duration") })
        end
    end

    parent:SpendMana(raze:GetManaCost(-1), self:GetAbility())
    
    self:PlayEffects(victim)

    ability:UseResources(true, false, false, true)
end

function modifier_nevermore_ultimate_raze:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf"
    local sound_cast = "Hero_Nevermore.Shadowraze"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
