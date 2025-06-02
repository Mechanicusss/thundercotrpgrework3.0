LinkLuaModifier("modifier_zuus_transcendence_custom", "heroes/hero_zeus/zuus_transcendence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_transcendence_descend_custom", "heroes/hero_zeus/zuus_transcendence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_transcendence_custom_transport", "heroes/hero_zeus/zuus_transcendence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_transcendence_custom_debuff", "heroes/hero_zeus/zuus_transcendence_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassTransport = {
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

zuus_transcendence_custom = class(ItemBaseClass)
zuus_transcendence_custom_descend = class(ItemBaseClass)
modifier_zuus_transcendence_descend_custom = class(zuus_transcendence_custom_descend)
modifier_zuus_transcendence_custom = class(zuus_transcendence_custom)
modifier_zuus_transcendence_custom_transport = class(ItemBaseClassTransport)
modifier_zuus_transcendence_custom_debuff = class(ItemBaseClassDebuff)
-------------
function CreateLightningBolt(target, pos)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt"

    -- Create Particle
    local effect = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, target)

    ParticleManager:SetParticleControl(effect, 0, Vector(pos.x, pos.y, pos.z))
    ParticleManager:SetParticleControl(effect, 1, Vector(pos.x, pos.y, 2000))
    ParticleManager:SetParticleControl(effect, 2, Vector(pos.x, pos.y, pos.z))

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
-------------
function zuus_transcendence_custom_descend:GetIntrinsicModifierName()
    return "modifier_zuus_transcendence_descend_custom"
end

function zuus_transcendence_custom_descend:GetAOERadius()
    return 300
end

function zuus_transcendence_custom_descend:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local pos = self:GetCursorPosition()
    self.effect_cast = nil

    local mod = caster:FindModifierByName("modifier_zuus_transcendence_custom_transport")
    if mod == nil then return end

    local damage = self:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))
    local debuffDuration = self:GetSpecialValueFor("debuff_duration")
    local reduction = self:GetSpecialValueFor("magic_shred")
    local ability = self

    self:CreateNimbusCircle(caster)
    caster:SetAbsOrigin(pos)

    Timers:CreateTimer(0.15, function()
        caster:RemoveModifierByName("modifier_zuus_transcendence_custom_transport")
        
        CreateLightningBolt(caster, pos)
        local victims = FindUnitsInRadius(caster:GetTeam(), pos, nil,
            300, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            ApplyDamage({
                victim = victim, 
                attacker = caster, 
                damage = damage, 
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })

            victim:AddNewModifier(caster, ability, "modifier_zuus_transcendence_custom_debuff", {
                duration = debuffDuration,
                reduction = reduction
            })
        end

        EmitSoundOn("Hero_Zuus.GodsWrath.Target", caster)

        Timers:CreateTimer(0.15, function()
            ParticleManager:DestroyParticle(self.effect_cast, true)
            ParticleManager:ReleaseParticleIndex(self.effect_cast)

            caster:SwapAbilities(
                "zuus_transcendence_custom",
                "zuus_transcendence_custom_descend",
                true,
                false
            )

            if caster:HasAbility("zuus_transcendence_custom_descend") then
                caster:RemoveAbility("zuus_transcendence_custom_descend")
            end
        end)
    end)
end

function zuus_transcendence_custom_descend:CreateNimbusCircle(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zeus/zeus_cloud_2.vpcf"
    local sound_cast = "Hero_Zuus.Cloud.Cast"

    self.particlePosition = target:GetAbsOrigin()

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_CENTER_FOLLOW, target)

    ParticleManager:SetParticleControl(self.effect_cast, 0, self.particlePosition)
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(300,300,300))
    ParticleManager:SetParticleControl(self.effect_cast, 2, self.particlePosition)
    ParticleManager:SetParticleControl(self.effect_cast, 5, self.particlePosition)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
-------------
function zuus_transcendence_custom:GetIntrinsicModifierName()
    return "modifier_zuus_transcendence_custom"
end

function zuus_transcendence_custom:GetAOERadius()
    return 300
end

function zuus_transcendence_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")

    caster:AddNoDraw()
    EmitSoundOn("Hero_Zuus.GodsWrath.PreCast", caster)

    local descent = caster:AddAbility("zuus_transcendence_custom_descend")
    descent:SetLevel(1)

    caster:SwapAbilities(
        "zuus_transcendence_custom",
        "zuus_transcendence_custom_descend",
        false,
        true
    )

    CreateLightningBolt(caster, caster:GetAbsOrigin())
    
    caster:AddNewModifier(caster, self, "modifier_zuus_transcendence_custom_transport", { duration = duration })
end
----------
function modifier_zuus_transcendence_custom_transport:OnCreated()
    if not IsServer() then return end
end

function modifier_zuus_transcendence_custom_transport:OnRemoved()
    if not IsServer() then return end
end

function modifier_zuus_transcendence_custom_transport:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveNoDraw()

    if self:GetParent():HasAbility("zuus_transcendence_custom_descend") then
        self:GetParent():SwapAbilities(
            "zuus_transcendence_custom",
            "zuus_transcendence_custom_descend",
            true,
            false
        )

        self:GetParent():RemoveAbility("zuus_transcendence_custom_descend")
    end
end

function modifier_zuus_transcendence_custom_transport:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }

    return state
end

function modifier_zuus_transcendence_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_zuus_transcendence_custom_debuff:OnCreated(params)
    self.reduction = params.reduction
end

function modifier_zuus_transcendence_custom_debuff:GetModifierMagicalResistanceBonus()
    return -50
end