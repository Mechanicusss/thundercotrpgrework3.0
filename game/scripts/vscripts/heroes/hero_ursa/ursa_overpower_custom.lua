LinkLuaModifier("modifier_ursa_overpower_custom", "heroes/hero_ursa/ursa_overpower_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_overpower_custom_buff", "heroes/hero_ursa/ursa_overpower_custom", LUA_MODIFIER_MOTION_NONE)

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

ursa_overpower_custom = class(ItemBaseClass)
modifier_ursa_overpower_custom = class(ursa_overpower_custom)
modifier_ursa_overpower_custom_buff = class(ItemBaseClassBuff)
-------------
function ursa_overpower_custom:GetIntrinsicModifierName()
    return "modifier_ursa_overpower_custom"
end

function ursa_overpower_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local buff = caster:AddNewModifier(caster, self, "modifier_ursa_overpower_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    if buff then
        buff:SetStackCount(self:GetSpecialValueFor("max_attacks"))
    end

    EmitSoundOn("Hero_Ursa.Overpower", caster)
end
-----------
function modifier_ursa_overpower_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_ursa_overpower_custom:OnIntervalThink()
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        SpellCaster:Cast(self:GetAbility(), self:GetParent(), true)
    end
end
---------
function modifier_ursa_overpower_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_ursa/ursa_overpower_buff.vpcf"
end

function modifier_ursa_overpower_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ursa_overpower_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK,
    }
end

function modifier_ursa_overpower_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_ursa_overpower_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_ursa_overpower_custom_buff:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    self:DecrementStackCount()

    if self:GetStackCount() <= 0 then
        self:Destroy()
        return
    end
end
