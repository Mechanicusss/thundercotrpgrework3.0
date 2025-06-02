LinkLuaModifier("modifier_hoodwink_scurry_custom", "heroes/hero_hoodwink/hoodwink_scurry_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_scurry_custom_disarm", "heroes/hero_hoodwink/hoodwink_scurry_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

hoodwink_scurry_custom = class(ItemBaseClass)
modifier_hoodwink_scurry_custom = class(hoodwink_scurry_custom)
modifier_hoodwink_scurry_custom_disarm = class(ItemBaseClassDebuff)

function modifier_hoodwink_scurry_custom:IsStackable() return true end
function modifier_hoodwink_scurry_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
-------------
function hoodwink_scurry_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_hoodwink_scurry_custom", {})

        if not caster:HasModifier("modifier_item_aghanims_shard") then
            caster:AddNewModifier(caster, self, "modifier_hoodwink_scurry_custom_disarm", {})
        end
    else
        caster:RemoveModifierByName("modifier_hoodwink_scurry_custom")

        caster:RemoveModifierByName("modifier_hoodwink_scurry_custom_disarm")
    end
end
----------------------------
function modifier_hoodwink_scurry_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_hoodwink_scurry_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_hoodwink_scurry_custom:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_hoodwink_scurry_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_hoodwink_scurry_custom:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_hoodwink_scurry_custom:OnTooltip()
    local total = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("dmg_increase_per_sec_pct")
    return total
end

function modifier_hoodwink_scurry_custom:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("evasion")
end

function modifier_hoodwink_scurry_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_hoodwink_scurry_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_speed_pct")
end

function modifier_hoodwink_scurry_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local caster = self:GetCaster()

    self.duration = 0

    EmitSoundOn("Hero_Hoodwink.Scurry.Cast", caster)

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_hoodwink/hoodwink_scurry_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControl( self.effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, caster:GetAbsOrigin() )

    self:StartIntervalThink(FrameTime())
    self:OnIntervalThink()
end

function modifier_hoodwink_scurry_custom:OnIntervalThink()
    local parent = self:GetParent()

    if parent:HasModifier("modifier_item_aghanims_shard") then
        self.damage = parent:GetEvasion() * 100
    else
        self.damage = 0
    end

    self:InvokeBonus()
end

function modifier_hoodwink_scurry_custom:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_Hoodwink.Scurry.End", caster)

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_hoodwink_scurry_custom:GetEffectName()
    return "particles/units/heroes/hero_hoodwink/hoodwink_scurry_passive.vpcf"
end
---------------------------------------
function modifier_hoodwink_scurry_custom_disarm:CheckState()
    local caster = self:GetCaster()
    
    local state = {
        [MODIFIER_STATE_DISARMED] = not caster:HasModifier("modifier_item_aghanims_shard")
    }

    return state
end

function modifier_hoodwink_scurry_custom_disarm:GetEffectName()
    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_item_aghanims_shard") then
        return "particles/units/heroes/hero_demonartist/demonartist_engulf_disarm/items2_fx/heavens_halberd.vpcf"
    end
end

function modifier_hoodwink_scurry_custom_disarm:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end