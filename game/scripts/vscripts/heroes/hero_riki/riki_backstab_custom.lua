-- Thanks to the Dota IMBA team for parts of the code: https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_riki.lua
LinkLuaModifier("modifier_riki_backstab_custom", "heroes/hero_riki/riki_backstab_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_backstab_custom_translation", "heroes/hero_riki/riki_backstab_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_backstab_custom_debuff", "heroes/hero_riki/riki_backstab_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

riki_backstab_custom = class(BaseClass)
modifier_riki_backstab_custom = class(riki_backstab_custom)
modifier_riki_backstab_custom_translation = class(riki_backstab_custom)
modifier_riki_backstab_custom_debuff = class(BaseClassDebuff)
-------------------------------
function riki_backstab_custom:GetIntrinsicModifierName()
    return "modifier_riki_backstab_custom"
end
-------------------------------
function modifier_riki_backstab_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_riki_backstab_custom:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local damageMultiplier = ability:GetSpecialValueFor("damage_multiplier")
    local maimChance = ability:GetSpecialValueFor("chance")
    local maimDuration = ability:GetSpecialValueFor("duration")

    -- Find targets back
    local victim_angle = target:GetAnglesAsVector().y
    local origin_difference = target:GetAbsOrigin() - parent:GetAbsOrigin()
    local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
    origin_difference_radian = origin_difference_radian * 180

    local attacker_angle = origin_difference_radian / math.pi

    -- For some reason Dota mechanics read the result as 30 degrees anticlockwise, need to adjust it down to appropriate angles for backstabbing.
    attacker_angle = attacker_angle + 180.0 + 30.0

    local result_angle = attacker_angle - victim_angle
    result_angle = math.abs(result_angle)

    if parent:HasModifier("tricks_of_the_trade_custom_buff") or (result_angle >= (180 - (ability:GetSpecialValueFor("backstab_angle") / 2)) and result_angle <= (180 + (ability:GetSpecialValueFor("backstab_angle") / 2))) then
        -- Play sound and particle
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)
        EmitSoundOn("Hero_Riki.Backstab", target)

        local damage = parent:GetAverageTrueAttackDamage(parent) + (parent:GetAgility() * damageMultiplier)

        if IsBossTCOTRPG(target) and parent:HasModifier("modifier_item_aghanims_shard") then
            damage = damage * 2
        end

        ApplyDamage({
            victim = target, 
            attacker = parent, 
            damage = damage, 
            damage_type = ability:GetAbilityDamageType(),
            ability = ability,
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
        })

        parent:AddNewModifier(parent, ability, "modifier_riki_backstab_custom_translation", {duration = parent:GetAttacksPerSecond(false)})

        if RollPercentage(ability, maimChance) then
            target:AddNewModifier(parent, ability, "modifier_riki_backstab_custom_debuff", { duration = maimDuration })
            EmitSoundOn("DOTA_Item.Maim", target)
        end
    end
end
--------------------------------
modifier_riki_backstab_custom_translation = modifier_riki_backstab_custom_translation or class({})
function modifier_riki_backstab_custom_translation:IsPurgable() return false end
function modifier_riki_backstab_custom_translation:IsDebuff() return false end
function modifier_riki_backstab_custom_translation:IsHidden()	return true end

function modifier_riki_backstab_custom_translation:DeclareFunctions()
	local funcs = { MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS, }
	return funcs
end

function modifier_riki_backstab_custom_translation:GetActivityTranslationModifiers()
	if self:GetParent():GetName() == "npc_dota_hero_riki" then
		return "backstab"
	end
	return 0
end
---------------------------------
function modifier_riki_backstab_custom_debuff:GetEffectName()
    return "particles/items2_fx/sange_maim.vpcf"
end

function modifier_riki_backstab_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_riki_backstab_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_riki_backstab_custom_debuff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_reduction")
end