LinkLuaModifier("modifier_drow_ranger_camouflage", "heroes/hero_drow_ranger/drow_ranger_camouflage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_camouflage_buff", "heroes/hero_drow_ranger/drow_ranger_camouflage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_camouflage_debuff", "heroes/hero_drow_ranger/drow_ranger_camouflage", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
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

drow_ranger_camouflage = class(ItemBaseClass)
modifier_drow_ranger_camouflage = class(drow_ranger_camouflage)
modifier_drow_ranger_camouflage_buff = class(ItemBaseClassBuff)
modifier_drow_ranger_camouflage_debuff = class(ItemBaseClassDebuff)
-------------
function drow_ranger_camouflage:GetIntrinsicModifierName()
    return "modifier_drow_ranger_camouflage"
end

function drow_ranger_camouflage:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("DOTA_Item.ShadowAmulet.Activate", caster)

    local vfx = ParticleManager:CreateParticle(
        "particles/econ/items/drow/drow_arcana/drow_arcana_revenge_kill_effect_caster.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        caster
    )

    ParticleManager:SetParticleControlEnt(vfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(vfx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(vfx, 1, caster:GetAbsOrigin())

    caster:AddNewModifier(caster, self, "modifier_drow_ranger_camouflage_buff", {
        duration = self:GetSpecialValueFor("duration")
    })
end
---------
function modifier_drow_ranger_camouflage_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_drow_ranger_camouflage_buff:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = self:GetModifierInvisibilityLevel() == 1.0
    }

    return state
end

function modifier_drow_ranger_camouflage_buff:GetModifierInvisibilityLevel(params)
    return math.min(self:GetElapsedTime() / 0.3, 1.0)
end

function modifier_drow_ranger_camouflage_buff:OnAbilityExecuted(event)
    if event.unit == self:GetParent() then
        self:Destroy()
    end
end

function modifier_drow_ranger_camouflage_buff:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then
        return
    end

    if not attacker:IsAlive() then
        return
    end

    local ability = self:GetAbility()
    
    local vfx = ParticleManager:CreateParticle(
        "particles/econ/items/drow/drow_arcana/drow_arcana_revenge_kill_effect_target.vpcf", 
        PATTACH_POINT_FOLLOW, 
        victim
    )

    ParticleManager:SetParticleControlEnt(vfx, 0, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(vfx, 0, victim:GetAbsOrigin())
    ParticleManager:SetParticleControl(vfx, 1, victim:GetAbsOrigin())

    EmitSoundOn("Hero_DrowRanger.Multishot.Channel", victim)
    EmitSoundOn("Hero_DrowRanger.Multishot.Attack", victim)

    local victims = FindUnitsInRadius(attacker:GetTeam(), victim:GetAbsOrigin(), nil,
                ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

    for _,player in ipairs(victims) do
        ApplyDamage({
            victim = player,
            attacker = attacker,
            damage = attacker:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100),
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })

        player:AddNewModifier(player, ability, "modifier_drow_ranger_camouflage_debuff", {
            duration = ability:GetSpecialValueFor("debuff_duration")
        })
    end

    self:Destroy()
end
-------------
function modifier_drow_ranger_camouflage_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end

function modifier_drow_ranger_camouflage_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_drow_ranger_camouflage_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_increase")
end