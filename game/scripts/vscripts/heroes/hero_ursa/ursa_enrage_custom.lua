LinkLuaModifier("modifier_ursa_enrage_custom", "heroes/hero_ursa/ursa_enrage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_enrage_custom_buff", "heroes/hero_ursa/ursa_enrage_custom", LUA_MODIFIER_MOTION_NONE)

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

ursa_enrage_custom = class(ItemBaseClass)
modifier_ursa_enrage_custom = class(ursa_enrage_custom)
modifier_ursa_enrage_custom_buff = class(ItemBaseClassBuff)
-------------
function ursa_enrage_custom:GetIntrinsicModifierName()
    return "modifier_ursa_enrage_custom"
end

function ursa_enrage_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local buff = caster:AddNewModifier(caster, self, "modifier_ursa_enrage_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Ursa.Enrage", caster)

    if caster:HasScepter() then
        local allies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            self:GetSpecialValueFor("scepter_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
        
        for _,ally in ipairs(allies) do
            if ally:IsAlive() and ally ~= caster then
                local buff = ally:AddNewModifier(caster, self, "modifier_ursa_enrage_custom_buff", {
                    duration = self:GetSpecialValueFor("duration")
                })

                EmitSoundOn("Hero_Ursa.Enrage", ally)
            end
        end
    end
end
-----------
function modifier_ursa_enrage_custom_buff:GetStatusEffectName()
    return "particles/units/heroes/hero_ursa/ursa_enrage_hero_effect.vpcf"
end

function modifier_ursa_enrage_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ursa_enrage_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_MODEL_SCALE 
    }
end

function modifier_ursa_enrage_custom_buff:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
end

function modifier_ursa_enrage_custom_buff:GetModifierModelScale()
    return 20
end

function modifier_ursa_enrage_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.vfx, 0, parent:GetAbsOrigin() )
end

function modifier_ursa_enrage_custom_buff:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end