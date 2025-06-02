LinkLuaModifier("modifier_sven_warcry_custom", "heroes/hero_sven/sven_warcry_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sven_warcry_custom_intrin", "heroes/hero_sven/sven_warcry_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

sven_warcry_custom = class(ItemBaseClass)
modifier_sven_warcry_custom = class(sven_warcry_custom)
modifier_sven_warcry_custom_intrin = class(sven_warcry_custom)
-------------
function modifier_sven_warcry_custom_intrin:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_sven_warcry_custom_intrin:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability:GetAutoCastState() then return end

    if not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() and parent:GetMana() >= ability:GetManaCost(-1) and ability:IsCooldownReady() and ability:IsFullyCastable() then
        SpellCaster:Cast(ability, parent, true)
    end
end

function sven_warcry_custom:GetIntrinsicModifierName()
    return "modifier_sven_warcry_custom_intrin"
end

function sven_warcry_custom:GetAbilityTextureName()
    local texture = "sven_warcry"

    if self:GetCaster():HasModifier("modifier_sven_gods_strength_custom") and self:GetCaster():HasScepter() then
        texture = "warcry_godsstrength"
    end

    return texture
end

function sven_warcry_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_warcry.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Sven.WarCry", caster)

    local radius = self:GetSpecialValueFor("radius")

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,target in ipairs(targets) do
        if not target:IsAlive() then break end

        target:AddNewModifier(caster, self, "modifier_sven_warcry_custom", {
            duration = self:GetSpecialValueFor("duration")
        })
    end
end
-------------
function modifier_sven_warcry_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_sven_warcry_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_sven_warcry_custom:GetModifierPhysicalArmorBonus()
    return self.fTotal
end

function modifier_sven_warcry_custom:GetEffectName()
    return "particles/units/heroes/hero_sven/sven_warcry_buff.vpcf"
end

function modifier_sven_warcry_custom:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_sven_warcry_custom:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_sven_warcry_custom:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end

function modifier_sven_warcry_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local isUlt = caster:HasModifier("modifier_sven_gods_strength_custom")

    self.total = ability:GetSpecialValueFor("bonus_armor")

    if isUlt and caster:HasScepter() and caster == self:GetParent() then
        self.total = ability:GetSpecialValueFor("bonus_armor") + (caster:GetPhysicalArmorValue(false) * (ability:GetSpecialValueFor("gods_strength_armor_pct")/100))
    end

    self:InvokeBonus()
end