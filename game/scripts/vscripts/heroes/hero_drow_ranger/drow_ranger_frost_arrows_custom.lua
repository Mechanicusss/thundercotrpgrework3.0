LinkLuaModifier("modifier_drow_ranger_frost_arrows_custom", "heroes/hero_drow_ranger/drow_ranger_frost_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_frost_arrows_custom_debuff", "heroes/hero_drow_ranger/drow_ranger_frost_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff", "heroes/hero_drow_ranger/drow_ranger_frost_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )


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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

drow_ranger_frost_arrows_custom = class(ItemBaseClass)
modifier_drow_ranger_frost_arrows_custom = class(drow_ranger_frost_arrows_custom)
modifier_drow_ranger_frost_arrows_custom_debuff = class(ItemBaseClassDebuff)
modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff = class(ItemBaseClassDebuff)
-------------
function drow_ranger_frost_arrows_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

function drow_ranger_frost_arrows_custom:GetProjectileName()
    return "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf"
end

function drow_ranger_frost_arrows_custom:OnOrbFire(params)
    local caster = self:GetCaster()

    EmitSoundOn("Hero_DrowRanger.FrostArrows", caster)
end

function drow_ranger_frost_arrows_custom:OnOrbImpact(params)
    local target = params.target

    if target:IsMagicImmune() or target:IsInvulnerable() or not target:IsAlive() or target:HasModifier("modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff") then return end

    local ability = self
    local caster = self:GetCaster()

    local debuff = target:FindModifierByName("modifier_drow_ranger_frost_arrows_custom_debuff")
    if debuff == nil then
        debuff = target:AddNewModifier(caster, ability, "modifier_drow_ranger_frost_arrows_custom_debuff", { duration = ability:GetSpecialValueFor("stack_duration") })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100))

    if debuff then
        damage = damage * debuff:GetStackCount()
    end

    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    }

    ApplyDamage(damageTable)

    -- Find More Target If Shard --
    if caster:HasModifier("modifier_item_aghanims_shard") then
        local radius = ability:GetSpecialValueFor("radius")

        local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
                radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() and not victim:HasModifier("modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff") and victim ~= target then
                damageTable.victim = victim

                ApplyDamage(damageTable)

                local debuff = victim:FindModifierByName("modifier_drow_ranger_frost_arrows_custom_debuff")
                if debuff == nil then
                    debuff = victim:AddNewModifier(caster, ability, "modifier_drow_ranger_frost_arrows_custom_debuff", { duration = ability:GetSpecialValueFor("stack_duration") })
                end

                if debuff ~= nil then
                    if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                        debuff:IncrementStackCount()
                    end

                    debuff:ForceRefresh()
                end
            end
        end
    end
end
-----
function modifier_drow_ranger_frost_arrows_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    -- Visual Counter --
    self.vfxCounter = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_drow/drow_hypothermia_counter_stack.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        parent
    )

    ParticleManager:SetParticleControlEnt(self.vfxCounter, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

    self:SetVFXCounter(1)
end

function modifier_drow_ranger_frost_arrows_custom_debuff:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if self:GetStackCount() >= ability:GetSpecialValueFor("max_stacks") and not parent:HasModifier("modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff") then

        parent:RemoveModifierByName("modifier_drow_ranger_frost_arrows_custom_debuff")
        parent:AddNewModifier(caster, ability, "modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff", {
            duration = ability:GetSpecialValueFor("hypothermia_duration")
        })

        return
    end

    self:SetVFXCounter(self:GetStackCount())
end

function modifier_drow_ranger_frost_arrows_custom_debuff:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.vfxCounter, true)
    ParticleManager:ReleaseParticleIndex(self.vfxCounter)
end

function modifier_drow_ranger_frost_arrows_custom_debuff:SetVFXCounter(count)
    if not IsServer() then return end

    ParticleManager:SetParticleControl(self.vfxCounter, 1, Vector(0, count, 0))
end

function modifier_drow_ranger_frost_arrows_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_drow_ranger_frost_arrows_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow") * self:GetStackCount()
end

function modifier_drow_ranger_frost_arrows_custom_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_drow_frost_arrow.vpcf"
end

function modifier_drow_ranger_frost_arrows_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
---------
function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:IsStackable() return false end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    -- Hypothermia Effect --
    self.vfxHypothermia = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_drow/drow_hypothermia_counter_debuff.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        parent
    )

    ParticleManager:SetParticleControlEnt(self.vfxHypothermia, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    -- Explosion Effect --
    self.vfxExplosion = ParticleManager:CreateParticle(
        "particles/econ/items/drow/drow_arcana/drow_arcana_shard_hypo_blast.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        parent
    )

    ParticleManager:SetParticleControlEnt(self.vfxExplosion, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.vfxExplosion, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfxExplosion, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfxExplosion, 3, parent:GetAbsOrigin())

    --- Damage --
    local damage = parent:GetHealth() * (ability:GetSpecialValueFor("hypothermia_max_hp_damage")/100)

    local victims = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
                250, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })
    end

    EmitSoundOn("Ability.FrostNova", parent)
end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.vfxHypothermia, true)
    ParticleManager:ReleaseParticleIndex(self.vfxHypothermia)
end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,

    }

    return funcs
end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("hypothermia_move_slow_pct")
end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("hypothermia_attack_slow_pct")
end

function modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_drow_frost_arrow.vpcf"
end