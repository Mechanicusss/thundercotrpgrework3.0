LinkLuaModifier("modifier_item_war_horn", "items/item_war_horn/item_war_horn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_war_horn_buff", "items/item_war_horn/item_war_horn", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_war_horn = class(ItemBaseClass)
modifier_item_war_horn = class(item_war_horn)
modifier_item_war_horn_buff = class(ItemBaseClassBuff)
-------------
function item_war_horn:GetIntrinsicModifierName()
    return "modifier_item_war_horn"
end

function item_war_horn:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_war_horn:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local allies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,ally in ipairs(allies) do
        if ally ~= nil and not ally:IsNull() and ally:IsAlive() then
            ally:AddNewModifier(caster, self, "modifier_item_war_horn_buff", {
                duration = duration
            })
        end
    end

    EmitSoundOn("DOTA_Item.MinotaurHorn.Cast", caster)
end
-------------
function modifier_item_war_horn_buff:OnCreated()
end

function modifier_item_war_horn_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_MODEL_SCALE 
    }
end

function modifier_item_war_horn_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_outgoing_damage_pct")
end

function modifier_item_war_horn_buff:GetModifierBaseAttackTimeConstant()
    if not self:GetParent():HasModifier("modifier_chicken_ability_2_buff") then
        return self:GetAbility():GetSpecialValueFor("base_attack_time")
    end
end

function modifier_item_war_horn_buff:GetModifierModelScale()
    return 15
end

function modifier_item_war_horn_buff:GetEffectName()
    return "particles/items5_fx/minotaur_horn.vpcf"
end