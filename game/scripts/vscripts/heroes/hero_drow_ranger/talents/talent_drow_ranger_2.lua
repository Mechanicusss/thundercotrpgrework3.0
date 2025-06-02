LinkLuaModifier("modifier_talent_drow_ranger_2", "heroes/hero_drow_ranger/talents/talent_drow_ranger_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_drow_ranger_2_damage_buff", "heroes/hero_drow_ranger/talents/talent_drow_ranger_2", LUA_MODIFIER_MOTION_NONE)

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

talent_drow_ranger_2 = class(ItemBaseClass)
modifier_talent_drow_ranger_2 = class(talent_drow_ranger_2)
modifier_talent_drow_ranger_2_damage_buff = class(ItemBaseClassBuff)
-------------
function talent_drow_ranger_2:GetIntrinsicModifierName()
    return "modifier_talent_drow_ranger_2"
end
-------------
function modifier_talent_drow_ranger_2:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()

    self.auraName = "modifier_talent_drow_ranger_2_damage_buff"

    self.aura = true

    self:StartIntervalThink(0.65)
end

function modifier_talent_drow_ranger_2:OnIntervalThink()
    if self:GetAbility():GetLevel() < 1 then return end 
    
    local caster = self:GetCaster()

    if not caster:IsAlive() then return end 
    
    local maxUnits = self:GetAbility():GetSpecialValueFor("arrow_count")
    local radius = caster:Script_GetAttackRange()
    local i = 0

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST, false)

    victims = shuffleTable(victims)

    for _,enemy in ipairs(victims) do
        if enemy:IsAlive() and not enemy:IsInvulnerable() and not enemy:IsAttackImmune() and i < maxUnits then
            i = i + 1
            caster:PerformAttack(
                enemy,
                true,
                true,
                true,
                false,
                true,
                false,
                false
            )
        end
    end
end

function modifier_talent_drow_ranger_2:OnDestroy()
end