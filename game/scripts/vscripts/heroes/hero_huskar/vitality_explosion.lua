LinkLuaModifier("modifier_huskar_vitality_explosion_custom", "heroes/hero_huskar/vitality_explosion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_huskar_vitality_explosion_custom_debuff", "heroes/hero_huskar/vitality_explosion", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier( "modifier_huskar_burning_spear_custom", "heroes/hero_huskar/burning_spear_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_huskar_burning_spear_custom_stack", "heroes/hero_huskar/burning_spear_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )

local tempTable = require("libraries/tempTable")

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassDeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

huskar_vitality_explosion_custom = class(ItemBaseClass)
modifier_huskar_vitality_explosion_custom = class(huskar_vitality_explosion_custom)
modifier_huskar_vitality_explosion_custom_debuff = class(ItemBaseClassDeBuff)
-------------
function huskar_vitality_explosion_custom:GetIntrinsicModifierName()
    return "modifier_huskar_vitality_explosion_custom"
end

function huskar_vitality_explosion_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function huskar_vitality_explosion_custom:OnSpellStart()
    local caster = self:GetCaster()

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local damage = (caster:GetMaxHealth() - caster:GetHealth()) * self:GetSpecialValueFor("missing_hp_damage_point")

    if caster:HasModifier("modifier_item_aghanims_shard") then
        caster:Heal((damage+self:GetSpecialValueFor("base_damage")), self)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, (damage+self:GetSpecialValueFor("base_damage")), nil)
    end

    EmitSoundOn("Hero_Huskar.Inner_Fire.Cast", caster)
    self:PlayEffects(caster)

    ---

    local mayhem = caster:FindAbilityByName("huskar_mayhem_custom")
    if mayhem and mayhem:GetLevel() > 0 then
        damage = ((caster:GetMaxHealth() * (mayhem:GetSpecialValueFor("max_hp_threshold") / 100)) - caster:GetHealth()) * self:GetSpecialValueFor("missing_hp_damage_point")
    end

    local applySpear = false
    local burningSpear = caster:FindAbilityByName("huskar_burning_spear_custom")
    if burningSpear and burningSpear:GetLevel() > 0 then
        applySpear = true
    end

    for _,victim in ipairs(victims) do
        if victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = damage + self:GetSpecialValueFor("base_damage"), 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })

        if victim:HasModifier("modifier_huskar_vitality_explosion_custom_debuff") then
            victim:RemoveModifierByName("modifier_huskar_vitality_explosion_custom_debuff")
        end

        victim:AddNewModifier(caster, self, "modifier_huskar_vitality_explosion_custom_debuff", { duration = self:GetSpecialValueFor("disarm_duration") })

        if applySpear then
            if not victim:HasModifier("modifier_huskar_burning_spear_custom") then
                local tmod = victim:AddNewModifier(
                    caster, -- player source
                    burningSpear, -- ability source
                    "modifier_huskar_burning_spear_custom", -- modifier name
                    { duration = burningSpear:GetSpecialValueFor("AbilityDuration") } -- kv
                )

                local mod = victim:AddNewModifier(
                    caster, -- player source
                    burningSpear, -- ability source
                    "modifier_huskar_burning_spear_custom_stack", -- modifier name
                    {
                        duration = burningSpear:GetSpecialValueFor("AbilityDuration"),
                        modifier = tempTable:AddATValue(tmod)
                    } -- kv
                )

                if tmod ~= nil then
                    tmod:SetStackCount(self:GetSpecialValueFor("burning_spear_stacks"))
                end
            else
                local mod = victim:FindModifierByName("modifier_huskar_burning_spear_custom")
                if not mod or mod == nil then break end

                local count = mod:GetStackCount()+self:GetSpecialValueFor("burning_spear_stacks")
                mod:SetStackCount(count)
            end
        end
    end
end

function huskar_vitality_explosion_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_huskar/huskar_inner_fire.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------
function modifier_huskar_vitality_explosion_custom_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end
----------
function modifier_huskar_vitality_explosion_custom:OnCreated()
    if not IsServer() then return end
    
    self:StartIntervalThink(FrameTime())
end

function modifier_huskar_vitality_explosion_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetAutoCastState() and not parent:IsSilenced() and ability:GetManaCost(-1) <= parent:GetMana() and ability:IsCooldownReady() then 
        SpellCaster:Cast(ability, self:GetParent(), true)
    end
end