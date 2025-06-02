LinkLuaModifier("modifier_legion_commander_press_the_attack_custom", "heroes/hero_legion_commander/legion_commander_press_the_attack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_press_the_attack_custom_aura", "heroes/hero_legion_commander/legion_commander_press_the_attack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_press_the_attack_custom_buff", "heroes/hero_legion_commander/legion_commander_press_the_attack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_press_the_attack_custom_buff_shard", "heroes/hero_legion_commander/legion_commander_press_the_attack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_press_the_attack_custom_cooldown", "heroes/hero_legion_commander/legion_commander_press_the_attack_custom", LUA_MODIFIER_MOTION_NONE)

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

legion_commander_press_the_attack_custom = class(ItemBaseClass)
modifier_legion_commander_press_the_attack_custom = class(legion_commander_press_the_attack_custom)
modifier_legion_commander_press_the_attack_custom_buff = class(ItemBaseClassBuff)
modifier_legion_commander_press_the_attack_custom_buff_shard = class(ItemBaseClassBuff)
modifier_legion_commander_press_the_attack_custom_aura = class(ItemBaseClassBuff)
modifier_legion_commander_press_the_attack_custom_cooldown = class(ItemBaseClassBuff)
-------------
function legion_commander_press_the_attack_custom:GetIntrinsicModifierName()
    return "modifier_legion_commander_press_the_attack_custom"
end

function legion_commander_press_the_attack_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
------------
function modifier_legion_commander_press_the_attack_custom:IsAura()
    return true
end

function modifier_legion_commander_press_the_attack_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_legion_commander_press_the_attack_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_legion_commander_press_the_attack_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_legion_commander_press_the_attack_custom:GetModifierAura()
    return "modifier_legion_commander_press_the_attack_custom_aura"
end

function modifier_legion_commander_press_the_attack_custom:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE 
end

function modifier_legion_commander_press_the_attack_custom:GetAuraEntityReject()
    return false
end
------------
function modifier_legion_commander_press_the_attack_custom_aura:OnCreated()
    if not IsServer() then return end 

    self.damageStored = 0
end

function modifier_legion_commander_press_the_attack_custom_aura:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_legion_commander_press_the_attack_custom_aura:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit or parent == event.attacker then return end 
    if parent:GetTeam() == event.attacker:GetTeam() then return end

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 
    if parent:HasModifier("modifier_legion_commander_press_the_attack_custom_buff") or parent:HasModifier("modifier_legion_commander_press_the_attack_custom_cooldown") then return end

    self.damageStored = self.damageStored + event.damage 

    local ability = self:GetAbility()

    local percentOfHealth = ability:GetSpecialValueFor("health_loss_trigger_pct")/100
    local lossPercent = self.damageStored / parent:GetMaxHealth()

    if lossPercent < percentOfHealth then return end 
    
    self.damageStored = 0

    local duration = ability:GetSpecialValueFor("duration")

    local buff = parent:FindModifierByName("modifier_legion_commander_press_the_attack_custom_buff")
    if not buff then
        buff = parent:AddNewModifier(self:GetCaster(), ability, "modifier_legion_commander_press_the_attack_custom_buff", { duration = duration })
    end

    if buff then
        buff:ForceRefresh()
    end

    parent:AddNewModifier(self:GetCaster(), ability, "modifier_legion_commander_press_the_attack_custom_cooldown", { duration = ability:GetSpecialValueFor("trigger_cooldown") })
end
------------
function modifier_legion_commander_press_the_attack_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }

    return funcs
end

function modifier_legion_commander_press_the_attack_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_press.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 2, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 3, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

    EmitSoundOn("Hero_LegionCommander.PressTheAttack", parent)

    parent:Purge(false, true, false, true, false)

    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("duration")

    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_item_aghanims_shard") then return end 
    
    local buff = parent:FindModifierByName("modifier_legion_commander_press_the_attack_custom_buff_shard")
    if not buff then
        buff = parent:AddNewModifier(self:GetCaster(), ability, "modifier_legion_commander_press_the_attack_custom_buff_shard", { duration = duration })
    end

    if buff then
        buff:ForceRefresh()
    end
end

function modifier_legion_commander_press_the_attack_custom_buff:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_legion_commander_press_the_attack_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_pct")
end

function modifier_legion_commander_press_the_attack_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_legion_commander_press_the_attack_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_increase_pct")
end
--------------
function modifier_legion_commander_press_the_attack_custom_buff_shard:GetModifierModelScale()
    return 130
end

function modifier_legion_commander_press_the_attack_custom_buff_shard:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_legion_commander_press_the_attack_custom_buff_shard:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE 
    }
end

function modifier_legion_commander_press_the_attack_custom_buff_shard:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("shard_magic_resistance")
end

function modifier_legion_commander_press_the_attack_custom_buff_shard:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("shard_status_resistance")
end
------------
function modifier_legion_commander_press_the_attack_custom_cooldown:IsHidden() return true end
function modifier_legion_commander_press_the_attack_custom_cooldown:RemoveOnDeath() return false end