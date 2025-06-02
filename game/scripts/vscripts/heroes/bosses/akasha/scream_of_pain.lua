LinkLuaModifier("boss_queen_of_pain_scream_of_pain_modifier", "heroes/bosses/akasha/scream_of_pain", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_scream_of_pain_modifier_debuff", "heroes/bosses/akasha/scream_of_pain", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

boss_queen_of_pain_scream_of_pain = class(BaseClass)
boss_queen_of_pain_scream_of_pain_modifier = class(BaseClass)
boss_queen_of_pain_scream_of_pain_modifier_debuff = class(BaseClassDebuff)

function boss_queen_of_pain_scream_of_pain:GetIntrinsicModifierName()
    return "boss_queen_of_pain_scream_of_pain_modifier"
end

function boss_queen_of_pain_scream_of_pain:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.ScreamOfPain", caster)

    local aoe = self:GetLevelSpecialValueFor("area_of_effect", (self:GetLevel() - 1))

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #units < 1 then return end

    local projectileSpeed = self:GetLevelSpecialValueFor("projectile_speed", (self:GetLevel() - 1))
    local projectile = "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf"

    for _,target in ipairs(units) do
        local info = {
            Source = caster,
            Target = target,
            Ability = self,
            iMoveSpeed = projectileSpeed,
            EffectName = projectile,
            bDodgeable = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
        }

        ProjectileManager:CreateTrackingProjectile(info)
    end
end

function boss_queen_of_pain_scream_of_pain:OnProjectileHit(hTarget, vLocation)
    local caster = self:GetCaster()
    local damage = self:GetLevelSpecialValueFor("damage", (self:GetLevel() - 1))
    local tauntDuration = self:GetLevelSpecialValueFor("taunt_duration", (self:GetLevel() - 1))

    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_queenofpain/queen_scream_of_pain_explosion.vpcf", hTarget, 1.0)

    local hitDamage = {
        victim = hTarget,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    }

    ApplyDamage(hitDamage)

    hTarget:AddNewModifier(caster, self, "boss_queen_of_pain_scream_of_pain_modifier_debuff", { duration = tauntDuration })
end
--------
function boss_queen_of_pain_scream_of_pain_modifier_debuff:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_queen_of_pain_scream_of_pain_modifier_debuff:OnCreated()
    if not IsServer() then return end

    local target = self:GetParent()
    local caster = self:GetCaster()

    target:MoveToTargetToAttack(caster)

    self:StartIntervalThink(FrameTime())
end

function boss_queen_of_pain_scream_of_pain_modifier_debuff:OnIntervalThink()
    local target = self:GetParent()
    local caster = self:GetCaster()

    target:MoveToTargetToAttack(caster)
end

function boss_queen_of_pain_scream_of_pain_modifier_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_TAUNTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_IGNORING_STOP_ORDERS] = true
    }

    return state
end
