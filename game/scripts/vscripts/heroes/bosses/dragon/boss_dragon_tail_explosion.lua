LinkLuaModifier("modifier_boss_dragon_tail_explosion", "heroes/bosses/dragon/boss_dragon_tail_explosion", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_dragon_tail_explosion = class(ItemBaseClass)
modifier_boss_dragon_tail_explosion = class(boss_dragon_tail_explosion)
-------------
function boss_dragon_tail_explosion:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("impact_radius")
    local damage = self:GetSpecialValueFor("impact_damage")
    local stunDuration = self:GetSpecialValueFor("stun_duration")

    local effect_cast = ParticleManager:CreateParticle("particles/econ/items/dragon_knight/dk_immortal_dragon/dragon_knight_dragon_tail_dragonform_iron_dragon.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)

    ParticleManager:SetParticleControl(effect_cast, 4, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 2, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local victims = FindUnitsInRadius(caster:GetTeam(), vLoc, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        ApplyDamage({
            attacker = caster,
            victim = hTarget,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

        victim:AddNewModifier(victim, nil, "modifier_stunned", {
            duration = stunDuration
        })

        EmitSoundOn("Hero_DragonKnight.DragonTail.Target", victim)
    end
end

function boss_dragon_tail_explosion:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local pos = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("search_radius")

    local info = {
        Source = caster,
        Ability = self,    
        
        EffectName = "particles/econ/items/dragon_knight/dk_2022_immortal/dk_2022_immortal_dragon_tail_dragon_projectile.vpcf",
        iMoveSpeed = 350,
        bDodgeable = true,                           -- Optional
        -- bIsAttack = true,                                -- Optional
    }

    local victims = FindUnitsInRadius(caster:GetTeam(), pos, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        info.Target = victim
    
        ProjectileManager:CreateTrackingProjectile(info)
    end

    EmitSoundOn("Hero_DragonKnight.DragonTail.DragonFormCast", caster)
end