LinkLuaModifier("modifier_saber_instinct", "heroes/hero_saber/instinct", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saber_instinct_buff", "heroes/hero_saber/instinct", LUA_MODIFIER_MOTION_NONE)

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

saber_instinct = class(ItemBaseClass)
modifier_saber_instinct = class(saber_instinct)
modifier_saber_instinct_buff = class(ItemBaseClassBuff)
-------------
function saber_instinct:GetIntrinsicModifierName()
    return "modifier_saber_instinct"
end
--------------
function modifier_saber_instinct:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_saber_instinct:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.target or parent == event.attacker then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local ability = self:GetAbility()

    if not ability then return end 
    if ability:GetLevel() < 1 then return end 
    
    local chance = ability:GetSpecialValueFor("chance")

    if not ability:IsCooldownReady() then return end

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_antimage/antimage_spellshield_reflect_2.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Antimage.Counterspell.Cast", parent)

    ability:UseResources(false, false,false,true)

    local buff = parent:FindModifierByName("modifier_saber_instinct_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_saber_instinct_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    return -9999
end
---------------
function modifier_saber_instinct_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_saber_instinct_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_outgoing") * self:GetStackCount()
end