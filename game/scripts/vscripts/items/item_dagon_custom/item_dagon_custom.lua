LinkLuaModifier("modifier_item_dagon_custom", "items/item_dagon_custom/item_dagon_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_dagon_custom = class(ItemBaseClass)
item_dagon_custom_2 = item_dagon_custom
item_dagon_custom_3 = item_dagon_custom
item_dagon_custom_4 = item_dagon_custom
item_dagon_custom_5 = item_dagon_custom
item_dagon_custom_6 = item_dagon_custom
item_dagon_custom_7 = item_dagon_custom
modifier_item_dagon_custom = class(item_dagon_custom)
-------------
function item_dagon_custom:GetIntrinsicModifierName()
    return "modifier_item_dagon_custom"
end

function item_dagon_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_dagon_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        local ethereal = victim:HasModifier("modifier_item_ethereal_blade_ethereal")
        local damageType = DAMAGE_TYPE_MAGICAL
        
        if ethereal then
            damageType = DAMAGE_TYPE_PURE
        end

        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = self:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100)),
            damage_type = damageType,
            ability = self
        })

        self:PlayEffects(caster, victim)
    end
end

function item_dagon_custom:PlayEffects(caster, target)
    local particle_cast = "particles/econ/events/ti7/dagon_ti7.vpcf"
    local sound_cast = "DOTA_Item.Dagon.Activate"

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
    EmitSoundOn(sound_cast, caster)
    EmitSoundOn("DOTA_Item.Dagon.Target", target)
end

function modifier_item_dagon_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
    }

    return funcs
end

function modifier_item_dagon_custom:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats") + self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_dagon_custom:GetModifierBonusStats_Agility()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagon_custom:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats") + self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_dagon_custom:GetModifierSpellAmplify_Percentage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end


function modifier_item_dagon_custom:GetModifierPhysicalArmorBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_dagon_custom:GetModifierMoveSpeedBonus_Constant()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end