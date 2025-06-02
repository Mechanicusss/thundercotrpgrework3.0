LinkLuaModifier("modifier_boss_spider_silken_bola_debuff", "heroes/bosses/spider/boss_spider_silken_bola", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

boss_spider_silken_bola = class(ItemBaseClass)
modifier_boss_spider_silken_bola_debuff = class(boss_spider_silken_bola)
-------------
function boss_spider_silken_bola:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    local projectile_info = {
        Source = caster,
        Ability = self, 
        
        EffectName = "particles/units/heroes/hero_broodmother/broodmother_silken_bola_projectile.vpcf",
        iMoveSpeed = 2000,
        bDodgeable = false,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = 300,                              -- Optional
        iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
    }

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() then
            projectile_info.Target = victim
            ProjectileManager:CreateTrackingProjectile(projectile_info)
        end
    end

    EmitSoundOn("Hero_Broodmother.SilkenBola.Cast", caster)
end

function boss_spider_silken_bola:OnProjectileHit(target, location)
    target:AddNewModifier(self:GetCaster(), self, "modifier_boss_spider_silken_bola_debuff", {
        duration = self:GetSpecialValueFor("duration")
    })
    EmitSoundOn("Hero_Broodmother.SilkenBola.Target", target)
end
---------------------
function modifier_boss_spider_silken_bola_debuff:CheckState()
    if self:GetParent():IsMagicImmune() then return end
    return {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

function modifier_boss_spider_silken_bola_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local interval = ability:GetSpecialValueFor("interval")

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage = parent:GetMaxHealth()*(ability:GetSpecialValueFor("hp_drain_pct")/100)*interval,
        ability = ability,
        damage_type = ability:GetAbilityDamageType()
    }

    self:StartIntervalThink(interval)
end

function modifier_boss_spider_silken_bola_debuff:OnIntervalThink()
    if self:GetParent():IsMagicImmune() then return end
    ApplyDamage(self.damageTable)
end

function modifier_boss_spider_silken_bola_debuff:GetEffectName()
    return "particles/units/heroes/hero_broodmother/broodmother_silken_bola_root.vpcf"
end