LinkLuaModifier("modifier_techies_go_nuclear", "heroes/hero_techies/techies_go_nuclear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_go_nuclear_buff", "heroes/hero_techies/techies_go_nuclear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_go_nuclear_debuff_stunned", "heroes/hero_techies/techies_go_nuclear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_go_nuclear_debuff_silenced", "heroes/hero_techies/techies_go_nuclear", LUA_MODIFIER_MOTION_NONE)

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

techies_go_nuclear = class(ItemBaseClass)
modifier_techies_go_nuclear = class(techies_go_nuclear)
modifier_techies_go_nuclear_buff = class(ItemBaseClassBuff)
modifier_techies_go_nuclear_debuff_stunned = class(ItemBaseClassDebuff)
modifier_techies_go_nuclear_debuff_silenced = class(ItemBaseClassDebuff)
-------------
function techies_go_nuclear:GetIntrinsicModifierName()
    return "modifier_techies_go_nuclear"
end

function techies_go_nuclear:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function techies_go_nuclear:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Refresh Techies abilities in case they're on cooldown
    local abilities = {
        "techies_sticky_bomb_passive_proc",
        "techies_stasis_trap_custom",
        "techies_land_mines_custom",
        "techies_sticky_bomb",
        "techies_explosive_attacks_custom",
    }

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)

        if abil ~= nil then
            local pass = false

            for _,v in ipairs(abilities) do
                if abil:GetAbilityName() == v then pass = true end
            end

            if pass then
                abil:EndCooldown()
            end
        end
    end
    
    caster:AddNewModifier(caster, ability, "modifier_techies_go_nuclear_buff", { duration = duration })
end
------------
function modifier_techies_go_nuclear_buff:DeclareFunctions()
    local funcs = {
         MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
    }

    return funcs
end

function modifier_techies_go_nuclear_buff:OnAbilityFullyCast(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then
        return
    end

    local ability = event.ability
    if ability:GetAbilityName() ~= "techies_explosive_attacks_custom" and ability:GetAbilityName() ~= "techies_sticky_bomb_passive_proc" and ability:GetAbilityName() ~= "techies_sticky_bomb" and ability:GetAbilityName() ~= "techies_stasis_trap_custom" and ability:GetAbilityName() ~= "techies_land_mines_custom" then return end

    ability:EndCooldown()
end

function modifier_techies_go_nuclear_buff:OnCreated(props)
    if not IsServer() then return end

    local unit = self:GetParent()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_tazer.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(self.particle, 0, unit:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, unit:GetOrigin())
end

function modifier_techies_go_nuclear_buff:OnRemoved(event)
    if not IsServer() then return end

    local unit = self:GetParent()

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)

    ApplyDamage({
        victim = unit,
        attacker = unit,
        damage = unit:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_hp_damage")/100),
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })

    unit:AddNewModifier(unit, self:GetAbility(), "modifier_techies_go_nuclear_debuff_stunned", {
        duration = self:GetAbility():GetSpecialValueFor("stun_duration")
    })

    unit:AddNewModifier(unit, self:GetAbility(), "modifier_techies_go_nuclear_debuff_silenced", {
        duration = self:GetAbility():GetSpecialValueFor("silence_duration")
    })

    EmitSoundOn("Hero_Techies.Suicide", unit)
    local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_suicide.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(explosion, 0, unit:GetOrigin())
    ParticleManager:SetParticleControl(explosion, 1, unit:GetOrigin())
    ParticleManager:SetParticleControl(explosion, 2, unit:GetOrigin())
    ParticleManager:ReleaseParticleIndex(explosion)
end
--------
--
function modifier_techies_go_nuclear_debuff_stunned:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end

function modifier_techies_go_nuclear_debuff_silenced:CheckState()
    local state = {
        [MODIFIER_STATE_SILENCED] = true
    }

    return state
end