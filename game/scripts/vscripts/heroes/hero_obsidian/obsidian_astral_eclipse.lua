LinkLuaModifier("modifier_obsidian_astral_eclipse", "heroes/hero_obsidian/obsidian_astral_eclipse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obsidian_astral_eclipse_emitter", "heroes/hero_obsidian/obsidian_astral_eclipse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obsidian_astral_eclipse_debuff", "heroes/hero_obsidian/obsidian_astral_eclipse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obsidian_astral_eclipse_debuff_slowed", "heroes/hero_obsidian/obsidian_astral_eclipse", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

obsidian_astral_eclipse = class(ItemBaseClass)
modifier_obsidian_astral_eclipse = class(obsidian_astral_eclipse)
modifier_obsidian_astral_eclipse_emitter = class(ItemBaseClass)
modifier_obsidian_astral_eclipse_debuff = class(ItemBaseClassDebuff)
modifier_obsidian_astral_eclipse_debuff_slowed = class(ItemBaseClassDebuff)
-------------
function obsidian_astral_eclipse:GetIntrinsicModifierName()
    return "modifier_obsidian_astral_eclipse"
end

function obsidian_astral_eclipse:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function obsidian_astral_eclipse:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Particle --
    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfx, 0, point)
    ParticleManager:SetParticleControl(vfx, 3, point)
    -- --

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_obsidian_astral_eclipse_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment.Cast")
    caster:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment")

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(vfx, true)
        ParticleManager:ReleaseParticleIndex(vfx)
        --emitter:Kill(nil, nil)
        UTIL_RemoveImmediate(emitter)
    end)
end
------------
function modifier_obsidian_astral_eclipse:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_obsidian_astral_eclipse:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_obsidian_astral_eclipse_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    self:StartIntervalThink(self.interval)
    self:OnIntervalThink()
end

function modifier_obsidian_astral_eclipse_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = self.damage + (caster:GetBaseIntellect() * (self.intToDamage/100)),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })

            if caster:HasModifier("modifier_item_aghanims_shard") then
                unit:AddNewModifier(caster, self:GetAbility(), "modifier_obsidian_astral_eclipse_debuff_slowed", {
                    duration = 1
                })
            end

            local debuff = unit:FindModifierByName("modifier_obsidian_astral_eclipse_debuff")
            if debuff == nil then
                debuff = unit:AddNewModifier(caster, self:GetAbility(), "modifier_obsidian_astral_eclipse_debuff", {
                    duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
                })
            end

            if debuff ~= nil then
                if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                    debuff:IncrementStackCount()
                end

                debuff:ForceRefresh()
            end
        end
    end

    self:PlayEffects(parent)
end

function modifier_obsidian_astral_eclipse_emitter:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(self.radius, self.radius, self.radius) )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector(self.radius, self.radius, self.radius) )
    ParticleManager:SetParticleControl( effect_cast, 3, Vector(self.radius, self.radius, self.radius) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( "Hero_ObsidianDestroyer.SanityEclipse.Cast", target )
    EmitSoundOn( "Hero_ObsidianDestroyer.SanityEclipse", target )
end

function modifier_obsidian_astral_eclipse_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_obsidian_astral_eclipse_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_obsidian_astral_eclipse_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }

    return funcs
end

function modifier_obsidian_astral_eclipse_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("resistance") * self:GetStackCount()
end

function modifier_obsidian_astral_eclipse_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
----
function modifier_obsidian_astral_eclipse_debuff_slowed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_obsidian_astral_eclipse_debuff_slowed:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end