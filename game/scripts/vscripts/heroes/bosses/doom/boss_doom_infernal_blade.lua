LinkLuaModifier("modifier_boss_doom_infernal_blade", "heroes/bosses/doom/boss_doom_infernal_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_doom_infernal_blade_debuff", "heroes/bosses/doom/boss_doom_infernal_blade", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_doom_infernal_blade = class(ItemBaseClass)
modifier_boss_doom_infernal_blade = class(boss_doom_infernal_blade)
modifier_boss_doom_infernal_blade_debuff = class(ItemBaseClassDebuff)
-------------
function boss_doom_infernal_blade:GetIntrinsicModifierName()
    return "modifier_boss_doom_infernal_blade"
end
-------------
function modifier_boss_doom_infernal_blade:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_boss_doom_infernal_blade:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    if parent:PassivesDisabled() then return end

    local target = event.target 

    if not target or target:IsNull() or not target:IsAlive() then return end 

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("duration")

    local debuff = target:FindModifierByName("modifier_boss_doom_infernal_blade_debuff")
    if not debuff then
        EmitSoundOn("Hero_DoomBringer.InfernalBlade.PreAttack", parent)
        debuff = target:AddNewModifier(parent, ability, "modifier_boss_doom_infernal_blade_debuff", {
            duration = duration
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
--------------
function modifier_boss_doom_infernal_blade_debuff:OnCreated()
    if not IsServer() then return end 

    EmitSoundOn("Hero_DoomBringer.InfernalBlade.Target", self:GetParent())

    self:StartIntervalThink(1)
end

function modifier_boss_doom_infernal_blade_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("dps_from_atk_pct")/100) * self:GetStackCount(),
        damage_type = ability:GetAbilityDamageType(),
        abiltiy = ability
    })
end

function modifier_boss_doom_infernal_blade_debuff:GetEffectName()
    return "particles/econ/items/doom/doom_2021_immortal_weapon/doom_2021_immortal_weapon_infernalblade_debuff.vpcf"
end