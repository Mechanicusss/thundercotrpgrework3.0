LinkLuaModifier("modifier_item_prince_knife", "items/item_prince_knife/item_prince_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_prince_knife_hexed", "items/item_prince_knife/item_prince_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_prince_knife_proc", "items/item_prince_knife/item_prince_knife", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassProc = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_prince_knife = class(ItemBaseClass)
modifier_item_prince_knife = class(item_prince_knife)
modifier_item_prince_knife_hexed = class(ItemBaseClassDebuff)
modifier_item_prince_knife_proc = class(ItemBaseClassProc)
-------------
function item_prince_knife:GetIntrinsicModifierName()
    return "modifier_item_prince_knife"
end

function modifier_item_prince_knife:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, --GetModifierProjectileSpeedBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }
    return funcs
end

function modifier_item_prince_knife:GetModifierProjectileSpeedBonus()
    return self:GetAbility():GetSpecialValueFor("proj_speed")
end

function modifier_item_prince_knife:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_prince_knife:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_prince_knife:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_prince_knife:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_prince_knife:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_prince_knife:OnCreated()
    self.parent = self:GetParent()
end

function modifier_item_prince_knife:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() then
        return
    end

    local ability = self:GetAbility()

    if not IsBossTCOTRPG(victim) then
        local chance = ability:GetSpecialValueFor("kill_chance")
        if RollPercentage(chance) then
            --if IsBossTCOTRPG(victim) then
                --unit:AddNewModifier(unit, ability, "modifier_item_prince_knife_proc", {})
            --end
            
            victim:Kill(ability, unit)
            return
        end
    end

    if not ability:IsCooldownReady() then return end

    local duration = ability:GetSpecialValueFor("duration")

    victim:AddNewModifier(caster, ability, "modifier_item_prince_knife_hexed", {
        duration = duration
    })

    EmitSoundOn("Hero_Lion.Voodoo", victim)
    EmitSoundOn("Hero_Lion.Hex.Fishstick", victim)
    EmitSoundOn("Hero_Lion.Hex.Fishstick.Target", victim)
    EmitSoundOn("General.Fish_flap", victim)

    ability:UseResources(false, false, false, true)
end
----------------
function modifier_item_prince_knife_hexed:GetModifierModelChange( params )
    return "models/items/hex/fish_hex/fish_hex.vmdl"
end

function modifier_item_prince_knife_hexed:DeclareFunctions()
    local funcs =
    {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_item_prince_knife_hexed:GetModifierMoveSpeedBonus_Percentage( params )
    return -90
end

function modifier_item_prince_knife_hexed:GetModifierIncomingDamage_Percentage( params )
    return self:GetAbility():GetSpecialValueFor("damage_amp")
end

function modifier_item_prince_knife_hexed:CheckState()
    local state =
    {
        [ MODIFIER_STATE_SILENCED ] = true,
        [ MODIFIER_STATE_MUTED ] = true,
        [ MODIFIER_STATE_DISARMED ] = true,
        [ MODIFIER_STATE_HEXED ] = true,
    }

    return state
end