LinkLuaModifier("modifier_viper_corrosive_skin_custom", "heroes/hero_viper/viper_corrosive_skin_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_viper_corrosive_skin_custom_debuff", "heroes/hero_viper/viper_corrosive_skin_custom.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

viper_corrosive_skin_custom = class(ItemBaseClass)
modifier_viper_corrosive_skin_custom = class(viper_corrosive_skin_custom)
modifier_viper_corrosive_skin_custom_debuff = class(ItemBaseClassDebuff)
-------------
function viper_corrosive_skin_custom:GetIntrinsicModifierName()
    return "modifier_viper_corrosive_skin_custom"
end
------------
function modifier_viper_corrosive_skin_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_viper_corrosive_skin_custom:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_viper_corrosive_skin_custom:OnCreated()
    if not IsServer() then return end 
end

function modifier_viper_corrosive_skin_custom:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local unit = event.unit 

    if parent ~= unit then return end 

    local attacker = event.attacker 

    if parent == attacker then return end

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end
    
    local ability = self:GetAbility()

    local maxStacks = ability:GetSpecialValueFor("max_stacks")

    if parent:HasModifier("modifier_item_aghanims_shard") then
        maxStacks = ability:GetSpecialValueFor("shard_max_stacks")
    end

    local debuff = attacker:FindModifierByName("modifier_viper_corrosive_skin_custom_debuff")
    if not debuff then
        debuff = attacker:AddNewModifier(parent, ability, "modifier_viper_corrosive_skin_custom_debuff", { duration = ability:GetSpecialValueFor("duration") })
        EmitSoundOn("hero_viper.CorrosiveSkin", attacker)
    end

    if debuff then
        if debuff:GetStackCount() < maxStacks then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
---------------
function modifier_viper_corrosive_skin_custom_debuff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_viper_corrosive_skin_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local damage = parent:GetHealth() * (ability:GetSpecialValueFor("current_hp_damage_pct")/100) * self:GetStackCount()

    if parent:IsMagicImmune() then return end

    if parent:HasModifier("modifier_viper_viper_strike_custom_debuff") and caster:HasScepter() then
        local viperStrike = caster:FindAbilityByName("viper_viper_strike_custom")
        if viperStrike ~= nil and viperStrike:GetLevel() > 0 then
            damage = damage * viperStrike:GetSpecialValueFor("damage_multiplier")
        end
    end

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NON_LETHAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)
end

function modifier_viper_corrosive_skin_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_viper_corrosive_skin_custom_debuff:GetModifierMagicalResistanceBonus()
    if self:GetParent():HasModifier("modifier_item_aghanims_shard") then
        return self:GetAbility():GetSpecialValueFor("shard_magic_resistance")
    end
end

function modifier_viper_corrosive_skin_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow") * self:GetStackCount()
end

function modifier_viper_corrosive_skin_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_slow") * self:GetStackCount()
end

function modifier_viper_corrosive_skin_custom_debuff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction") * self:GetStackCount()
end

function modifier_viper_corrosive_skin_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_viper/viper_corrosive_debuff.vpcf"
end