LinkLuaModifier("modifier_centaur_stampede_custom", "heroes/hero_centaur/centaur_stampede_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_stampede_custom_buff", "heroes/hero_centaur/centaur_stampede_custom", LUA_MODIFIER_MOTION_NONE)

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

centaur_stampede_custom = class(ItemBaseClass)
modifier_centaur_stampede_custom = class(centaur_stampede_custom)
modifier_centaur_stampede_custom_buff = class(ItemBaseClassBuff)
-------------
function centaur_stampede_custom:GetIntrinsicModifierName()
    return "modifier_centaur_stampede_custom"
end

function centaur_stampede_custom:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() and hero:IsRealHero() and not hero:IsIllusion() then
            hero:AddNewModifier(caster, ability, "modifier_centaur_stampede_custom_buff", { duration = duration })
        end
    end

    EmitSoundOn("Hero_Centaur.Stampede.Cast", caster)
end
------------
function modifier_centaur_stampede_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }

    return funcs
end

function modifier_centaur_stampede_custom_buff:GetModifierMoveSpeed_Limit()
    return 2000
end

function modifier_centaur_stampede_custom_buff:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_centaur_stampede_custom_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetParent()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.health = caster:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_increase")/100)

    EmitSoundOn("Hero_Centaur.Stampede.Movement", parent)

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_centaur/centaur_stampede_haste.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
        
    if caster:HasScepter() then
        _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
        _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

        _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")
    end
end

function modifier_centaur_stampede_custom_buff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    StopSoundOn("Hero_Centaur.Stampede.Movement", self:GetParent())

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_centaur_stampede_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_centaur/centaur_stampede_overhead.vpcf"
end

function modifier_centaur_stampede_custom_buff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_centaur_stampede_custom_buff:GetModifierHealthBonus()
    return self.health
end

function modifier_centaur_stampede_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed")
end
