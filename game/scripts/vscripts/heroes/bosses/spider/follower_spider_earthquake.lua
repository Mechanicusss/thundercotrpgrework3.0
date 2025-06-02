LinkLuaModifier("modifier_follower_spider_earthquake", "heroes/bosses/spider/follower_spider_earthquake", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

follower_spider_earthquake = class(ItemBaseClass)
modifier_follower_spider_earthquake = class(ItemBaseClassBuff)
-------------
function follower_spider_earthquake:GetIntrinsicModifierName()
    return "modifier_follower_spider_earthquake"
end

function follower_spider_earthquake:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
----------
function modifier_follower_spider_earthquake:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_follower_spider_earthquake:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_follower_spider_earthquake:OnIntervalThink()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")

    local caster = self:GetParent()

    if caster:PassivesDisabled() then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = self:GetAbility():GetSpecialValueFor("damage"),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(self.vfx, 0, caster:GetOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(self.radius, self.radius, self.radius))
    ParticleManager:ReleaseParticleIndex(self.vfx)
end


function modifier_follower_spider_earthquake:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("speed")
end