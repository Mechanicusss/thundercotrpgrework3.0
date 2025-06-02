LinkLuaModifier("modifier_lich_ice_spire_custom", "heroes/hero_lich/lich_ice_spire_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_ice_spire_custom_thinker", "heroes/hero_lich/lich_ice_spire_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lich_ice_spire_custom = class(ItemBaseClass)
modifier_lich_ice_spire_custom = class(lich_ice_spire_custom)
modifier_lich_ice_spire_custom_thinker = class(ItemBaseClass)
-------------
function lich_ice_spire_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lich_ice_spire_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local max = self:GetSpecialValueFor("max")

    -- Delete Old Golems --
    local existingSpires = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local spires = {}

    for _,spire in ipairs(existingSpires) do
        if spire:GetUnitName() == "npc_dota_lich_ice_spire_custom" then
            table.insert(spires, spire)
        end
    end

    if #spires >= max then
        local spire = spires[#spires]
        EmitSoundOn("Hero_Lich.IceSpire.Destroy", spire)
        UTIL_RemoveImmediate(spire)
    end
    --

    EmitSoundOn("Hero_Lich.IceSpire", caster)

    CreateUnitByNameAsync(
        "npc_dota_lich_ice_spire_custom",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber(),

        function(unit)
            unit:CreatureLevelUp(self:GetLevel()-1)
            unit:AddNewModifier(unit, nil, "modifier_lich_ice_spire_custom_thinker", {
                duration = self:GetSpecialValueFor("duration")
            })

            local iceField = unit:FindAbilityByName("lich_ice_spire_custom_field")
            if iceField ~= nil and iceField ~= nil then
                iceField:SetLevel(self:GetLevel())
            end

            local iceAllyAura = unit:FindAbilityByName("lich_ice_spire_custom_icy_aura")
            if iceAllyAura ~= nil and iceAllyAura ~= nil then
                iceAllyAura:SetLevel(self:GetLevel())
            end
        end
    )
end
---------
function modifier_lich_ice_spire_custom_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }

    return funcs
end

function modifier_lich_ice_spire_custom_thinker:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_lich_ice_spire_custom_thinker:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_lich_ice_spire_custom_thinker:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_lich_ice_spire_custom_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    }

    return state
end

function modifier_lich_ice_spire_custom_thinker:OnDestroy()
    if not IsServer() then return end

    if not self or self == nil then return end
    if not self:GetParent() or self:GetParent() == nil then return end
    if not self:GetParent():IsAlive() then return end

    self:GetParent():ForceKill(false)
end