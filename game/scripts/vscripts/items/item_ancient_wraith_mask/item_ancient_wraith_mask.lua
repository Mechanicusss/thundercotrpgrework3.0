LinkLuaModifier("modifier_item_ancient_wraith_mask", "items/item_ancient_wraith_mask/item_ancient_wraith_mask.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_wraith_mask_immortality", "items/item_ancient_wraith_mask/item_ancient_wraith_mask.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_wraith_mask_aura", "items/item_ancient_wraith_mask/item_ancient_wraith_mask.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_wraith_mask_cooldown", "items/item_ancient_wraith_mask/item_ancient_wraith_mask.lua", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassCd = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_ancient_wraith_mask = class(ItemBaseClass)
item_ancient_wraith_mask_2 = item_ancient_wraith_mask
item_ancient_wraith_mask_3 = item_ancient_wraith_mask
item_ancient_wraith_mask_4 = item_ancient_wraith_mask
item_ancient_wraith_mask_5 = item_ancient_wraith_mask
modifier_item_ancient_wraith_mask = class(ItemBaseClass)
modifier_item_ancient_wraith_mask_cooldown = class(ItemBaseClassCd)
modifier_item_ancient_wraith_mask_aura = class(ItemBaseClassBuff)
modifier_item_ancient_wraith_mask_immortality = class(ItemBaseClassBuff)
-------------
function item_ancient_wraith_mask:GetIntrinsicModifierName()
    return "modifier_item_ancient_wraith_mask"
end
--------------
function modifier_item_ancient_wraith_mask:IsAura()
    return true
end

function modifier_item_ancient_wraith_mask:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_item_ancient_wraith_mask:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_ancient_wraith_mask:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_ancient_wraith_mask:GetModifierAura()
    return "modifier_item_ancient_wraith_mask_aura"
end

function modifier_item_ancient_wraith_mask:GetAuraEntityReject(target)
    if self:GetAbility():GetLevel() < 5 then
        if target ~= self:GetCaster() then return true end
    else
        return false
    end
end

function modifier_item_ancient_wraith_mask:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_ancient_wraith_mask:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor_per_str") * self:GetParent():GetStrength()
end

function modifier_item_ancient_wraith_mask:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_per_str") * self:GetParent():GetStrength()
end

function modifier_item_ancient_wraith_mask:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_max_health_pct")
end

function modifier_item_ancient_wraith_mask:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_ancient_wraith_mask:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")

    self:StartIntervalThink(0.1)
end

function modifier_item_ancient_wraith_mask:OnIntervalThink()
    local abilityName = self:GetName()
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")
end

function modifier_item_ancient_wraith_mask:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end
--------
function modifier_item_ancient_wraith_mask_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH 
    }
end

function modifier_item_ancient_wraith_mask_aura:GetMinHealth()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if not parent:HasModifier("modifier_item_ancient_wraith_mask_cooldown") then return 1 end 
end

function modifier_item_ancient_wraith_mask_aura:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_item_ancient_wraith_mask_aura:OnIntervalThink()
    local ability = self:GetAbility()

    local parent = self:GetParent()
    local caster = self:GetCaster()

    if parent:HasModifier("modifier_chicken_ability_1_self_transmute") then return end 
    if parent:HasModifier("modifier_item_ancient_wraith_mask_cooldown") then return end 

    if parent:IsAlive() and parent:GetHealth() <= 1 then
        local duration = ability:GetSpecialValueFor("duration")
        local cooldown = ability:GetSpecialValueFor("cooldown")

        parent:AddNewModifier(caster, ability, "modifier_item_ancient_wraith_mask_immortality", { duration = duration })
        parent:AddNewModifier(caster, ability, "modifier_item_ancient_wraith_mask_cooldown", { duration = cooldown })
    end
end
---------------
function modifier_item_ancient_wraith_mask_immortality:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_item_ancient_wraith_mask_immortality:GetModifierBaseAttackTimeConstant()
    return self.bat
end

function modifier_item_ancient_wraith_mask_immortality:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_move_pct")
end

function modifier_item_ancient_wraith_mask_immortality:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_item_ancient_wraith_mask_immortality:GetModifierModelScale()
    return 25
end

function modifier_item_ancient_wraith_mask_immortality:GetMinHealth()
    return 1
end

function modifier_item_ancient_wraith_mask_immortality:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:SetRenderColor(self.color.r, self.color.g, self.color.b)

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    if parent:IsAlive() and parent:GetHealth() > 0 then
        parent:SetHealth(parent:GetMaxHealth())
    end 
end

function modifier_item_ancient_wraith_mask_immortality:GetEffectName()
    return "particles/status_fx/status_effect_wraithking_ghosts.vpcf"
end

function modifier_item_ancient_wraith_mask_immortality:OnCreated()
    local parent = self:GetParent()

    self.baseAttackTimeDefault = parent:GetBaseAttackTime()
    self.bat = self.baseAttackTimeDefault - self:GetAbility():GetSpecialValueFor("bat_reduction")

    if not IsServer() then return end 

    EmitSoundOn("Hero_SkeletonKing.Reincarnate.Ghost", parent)

    self.color = parent:GetRenderColor()

    parent:SetRenderColor(64, 224, 208)

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
end