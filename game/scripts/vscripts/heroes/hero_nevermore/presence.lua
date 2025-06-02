nevermore_presence_of_the_dark_lord_custom = class({})
LinkLuaModifier( "modifier_nevermore_presence_of_the_dark_lord_custom", "heroes/hero_nevermore/presence.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function nevermore_presence_of_the_dark_lord_custom:GetIntrinsicModifierName()
    return "modifier_nevermore_presence_of_the_dark_lord_custom"
end

modifier_nevermore_presence_of_the_dark_lord_custom = class({})
--------------------------------------------------------------------------------

function modifier_nevermore_presence_of_the_dark_lord_custom:IsDebuff()
    return self:GetParent()~=self:GetAbility():GetCaster()
end

function modifier_nevermore_presence_of_the_dark_lord_custom:IsHidden()
    return self:GetParent()==self:GetAbility():GetCaster()
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
--------------------------------------------------------------------------------

function modifier_nevermore_presence_of_the_dark_lord_custom:IsAura()
    if self:GetCaster():IsIllusion() then return false end
    
    if self:GetCaster() == self:GetParent() then
        if not self:GetCaster():PassivesDisabled() then
            return true
        end
    end
    
    return false
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetModifierAura()
    return "modifier_nevermore_presence_of_the_dark_lord_custom"
end


function modifier_nevermore_presence_of_the_dark_lord_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end


function modifier_nevermore_presence_of_the_dark_lord_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetAuraRadius()
    return self.aura_radius
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetAuraEntityReject( hEntity )
    return not hEntity:CanEntityBeSeenByMyTeam(self:GetCaster())
end
--------------------------------------------------------------------------------

function modifier_nevermore_presence_of_the_dark_lord_custom:OnCreated( kv )
    local reduction = self:GetParent():GetPhysicalArmorBaseValue() * ((self:GetAbility():GetSpecialValueFor( "armor_pct_per_stack" ))/100)
    self.armor_reduction = reduction
    self.aura_radius = self:GetAbility():GetSpecialValueFor( "presence_radius" )
    self.magic_reduction = self:GetAbility():GetSpecialValueFor( "presence_magic_res_reduction" )
end

function modifier_nevermore_presence_of_the_dark_lord_custom:OnRefresh( kv )
    self.aura_radius = self:GetAbility():GetSpecialValueFor( "presence_radius" )
    self.magic_reduction = self:GetAbility():GetSpecialValueFor( "presence_magic_res_reduction" )
end

--------------------------------------------------------------------------------

function modifier_nevermore_presence_of_the_dark_lord_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }

    return funcs
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetModifierPhysicalArmorBonus( params )
    if self:GetParent() == self:GetCaster() then
        return 0
    end

    return self.armor_reduction
end

function modifier_nevermore_presence_of_the_dark_lord_custom:GetModifierMagicalResistanceBonus( params )
    if self:GetParent() == self:GetCaster() then
        return 0
    end

    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return 0 end

    return self.magic_reduction
end