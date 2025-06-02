LinkLuaModifier("modifier_night_stalker_crippling_fear_custom", "heroes/hero_night_stalker/night_stalker_crippling_fear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_crippling_fear_custom_debuff", "heroes/hero_night_stalker/night_stalker_crippling_fear_custom", LUA_MODIFIER_MOTION_NONE)

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

night_stalker_crippling_fear_custom = class(ItemBaseClass)
modifier_night_stalker_crippling_fear_custom = class(night_stalker_crippling_fear_custom)
modifier_night_stalker_crippling_fear_custom_debuff = class(ItemBaseClassDebuff)

function night_stalker_crippling_fear_custom:GetIntrinsicModifierName()
    return "modifier_night_stalker_crippling_fear_custom"
end
-------------
function modifier_night_stalker_crippling_fear_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_night_stalker_crippling_fear_custom:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("duration")

    if not GameRules:IsDaytime() then
        duration = duration * 2
    end

    local debuff = target:FindModifierByName("modifier_night_stalker_crippling_fear_custom_debuff")
    if not debuff and ability:IsCooldownReady() then
        debuff = target:AddNewModifier(attacker, ability, "modifier_night_stalker_crippling_fear_custom_debuff", {
            duration = duration
        })
        EmitSoundOn("Hero_Nightstalker.Trickling_Fear", target)
        ability:UseResources(false,false,false,true)
    end
    --

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("max_hp_restore_pct")

    if not GameRules:IsDaytime() then
        lifestealAmount = lifestealAmount * 2
    end

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = target:GetMaxHealth() * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end
----------
function modifier_night_stalker_crippling_fear_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_night_stalker_crippling_fear_custom_debuff:GetModifierIncomingDamage_Percentage()
    if IsServer() then
        local amount = self:GetAbility():GetSpecialValueFor("increased_damage")

        if not GameRules:IsDaytime() then
            amount = amount * 2
        end

        return amount
    end
end

function modifier_night_stalker_crippling_fear_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true,
    }
end

function modifier_night_stalker_crippling_fear_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear.vpcf"
end

function modifier_night_stalker_crippling_fear_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_night_stalker_crippling_fear_custom_debuff:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.target == self:GetCaster() and self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return self:GetAbility():GetSpecialValueFor("shard_reduced_damage")
    end
end