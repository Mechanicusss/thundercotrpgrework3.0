LinkLuaModifier("modifier_terrorblade_demon_zeal_custom", "heroes/hero_terrorblade/terrorblade_demon_zeal_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_terrorblade_demon_zeal_custom_buff", "heroes/hero_terrorblade/terrorblade_demon_zeal_custom", LUA_MODIFIER_MOTION_NONE)

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

terrorblade_demon_zeal_custom = class(ItemBaseClass)
modifier_terrorblade_demon_zeal_custom = class(terrorblade_demon_zeal_custom)
modifier_terrorblade_demon_zeal_custom_buff = class(ItemBaseClassBuff)
-------------
function terrorblade_demon_zeal_custom:GetIntrinsicModifierName()
    return "modifier_terrorblade_demon_zeal_custom"
end

function modifier_terrorblade_demon_zeal_custom:OnCreated()
    if not IsServer() then return end

    --self:StartIntervalThink(0.1)
end

function modifier_terrorblade_demon_zeal_custom:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster:HasModifier("modifier_terrorblade_metamorphosis_custom_aura") and not caster:HasModifier("modifier_item_aghanims_shard") and ability:IsActivated() then
        ability:SetActivated(false)
    end

    if caster:HasModifier("modifier_terrorblade_metamorphosis_custom_aura") and caster:HasModifier("modifier_item_aghanims_shard") and not ability:IsActivated() then
        ability:SetActivated(true)
    end

    if not caster:HasModifier("modifier_terrorblade_metamorphosis_custom_aura") then
        ability:SetActivated(true)
    end
end

function terrorblade_demon_zeal_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_terrorblade_demon_zeal_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Terrorblade.DemonZeal.Cast", caster)
end

function modifier_terrorblade_demon_zeal_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_terrorblade_demon_zeal_custom_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    self.vfx = ParticleManager:CreateParticle("particles/models/heroes/terrorblade/demon_zeal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function modifier_terrorblade_demon_zeal_custom_buff:OnRemoved()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_terrorblade_demon_zeal_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_terrorblade_demon_zeal_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end