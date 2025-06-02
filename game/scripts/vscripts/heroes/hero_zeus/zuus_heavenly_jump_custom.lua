LinkLuaModifier("modifier_zuus_heavenly_jump_custom", "heroes/hero_zeus/zuus_heavenly_jump_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_heavenly_jump_custom_debuff", "heroes/hero_zeus/zuus_heavenly_jump_custom", LUA_MODIFIER_MOTION_NONE)

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

zuus_heavenly_jump_custom = class(ItemBaseClass)
modifier_zuus_heavenly_jump_custom = class(zuus_heavenly_jump_custom)
modifier_zuus_heavenly_jump_custom_debuff = class(ItemBaseClassDebuff)
-------------
function zuus_heavenly_jump_custom:GetIntrinsicModifierName()
    return "modifier_zuus_heavenly_jump_custom"
end

function zuus_heavenly_jump_custom:GetAOERadius()
    return self:GetSpecialValueFor("hop_distance")
end

function zuus_heavenly_jump_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_zuus_transcendence_custom_transport") then
        self:EndCooldown()
        return
    end

    EmitSoundOn("Hero_Zuus.StaticField", caster)

    local distance = self:GetSpecialValueFor("hop_distance")
    local duration = self:GetSpecialValueFor("hop_duration") 
    local height = self:GetSpecialValueFor("hop_height")
    local damage = self:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))
    local radius = self:GetSpecialValueFor("range")
    local superchargeStun = self:GetSpecialValueFor("static_field_stun")
    
    caster:AddNewModifier(caster, nil, "modifier_invulnerable", {
        duration = duration
    })

    local knockback = caster:AddNewModifier(
        caster,
        self,
        "modifier_generic_knockback_lua", 
        {
            distance = distance,
            height = height,
            duration = duration,
            direction_x = caster:GetForwardVector().x,
            direction_y = caster:GetForwardVector().y,
            IsStun = true,
        } 
    )

    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        caster:GetAbsOrigin(),    -- point, center point
        nil,
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    for _,target in ipairs(targets) do
        if not target:IsAlive() or target:IsMagicImmune() or target:IsInvulnerable() or not caster:CanEntityBeSeenByMyTeam(target) then break end
        
        self:CreateLightning(caster, target)

        target:AddNewModifier(caster, self, "modifier_zuus_heavenly_jump_custom_debuff", { duration = self:GetSpecialValueFor("duration") })

        ApplyDamage({
            victim = target, 
            attacker = caster, 
            damage = damage, 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

        -- Supercharge --
        self.superchargeStacks = caster:FindModifierByName("modifier_zuus_static_field_custom_stacks")
        if self.superchargeStacks ~= nil then
            local superchargesNeeded = self:GetSpecialValueFor("static_field_charges")
            if self.superchargeStacks:GetAbility():GetToggleState() and superchargesNeeded <= self.superchargeStacks:GetStackCount() then 
                target:AddNewModifier(caster, nil, "modifier_stunned", {
                    duration = superchargeStun
                })

                self.superchargeStacks:SetStackCount(self.superchargeStacks:GetStackCount()-superchargesNeeded)
            end
        end
        --
    end
end

function zuus_heavenly_jump_custom:CreateLightning(caster, target)
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_shard.vpcf"
    local sound_cast = "Hero_Zuus.ArcLightning.Cast"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:ReleaseParticleIndex(effect_cast)

    --ParticleManager:SetParticleControl(effect_cast, 0, pos) -- Who it bounces to
    --ParticleManager:SetParticleControl(effect_cast, 1, originalPos) -- Where it bounces from

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_zuus_heavenly_jump_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
    }

    return funcs
end

function modifier_zuus_heavenly_jump_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_shred")
end

function modifier_zuus_heavenly_jump_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("aspd_slow")
end

function modifier_zuus_heavenly_jump_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_zuus_heavenly_jump_custom_debuff:GetModifierProvidesFOWVision()
    return 1
end