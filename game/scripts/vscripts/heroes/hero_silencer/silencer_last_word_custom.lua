LinkLuaModifier("modifier_silencer_last_word_custom", "heroes/hero_silencer/silencer_last_word_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_last_word_custom_debuff", "heroes/hero_silencer/silencer_last_word_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
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

silencer_last_word_custom = class(ItemBaseClass)
modifier_silencer_last_word_custom = class(silencer_last_word_custom)
modifier_silencer_last_word_custom_debuff = class(ItemBaseClassDebuff)
-------------
function silencer_last_word_custom:GetIntrinsicModifierName()
    return "modifier_silencer_last_word_custom"
end

function modifier_silencer_last_word_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_silencer_last_word_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.target 

    if event.attacker ~= parent or victim == parent then return end
    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")
    local damage = ability:GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (ability:GetSpecialValueFor("int_mult")))

    if not RollPercentage(ability, chance) then return end

    local debuff = victim:FindModifierByName("modifier_silencer_last_word_custom_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(parent, ability, "modifier_silencer_last_word_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })

        EmitSoundOn("Hero_Silencer.LastWord.Cast", victim)
        return
    end

    if debuff then
        ApplyDamage({
            victim = victim,
            attacker = parent,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })
    
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)

        EmitSoundOn("Hero_Silencer.LastWord.Damage", victim)
    end
end
-------------
function modifier_silencer_last_word_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_silencer_last_word_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_silencer_last_word_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_silencer_last_word_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf"
end

function modifier_silencer_last_word_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.vfx = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_silenced.vpcf", PATTACH_OVERHEAD_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.vfx, 0, parent:GetAbsOrigin() )

    EmitSoundOn("Hero_Silencer.LastWord.Target", parent)
end

function modifier_silencer_last_word_custom_debuff:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Silencer.LastWord.Damage", parent)

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_silencer/silencer_last_word_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    local ability = self:GetAbility()
    local damage = ability:GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (ability:GetSpecialValueFor("int_mult")))

    ApplyDamage({
        victim = parent,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage, nil)

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end