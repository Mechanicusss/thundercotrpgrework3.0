LinkLuaModifier("boss_skeleton_king_hellfire_blast_modifier", "heroes/bosses/skeleton_king/boss_skeleton_king_hellfire_blast", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_hellfire_blast_modifier_debuff", "heroes/bosses/skeleton_king/boss_skeleton_king_hellfire_blast", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local ItemSelfDeBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_skeleton_king_hellfire_blast = class(BaseClass)
boss_skeleton_king_hellfire_blast_modifier = class(BaseClass)
boss_skeleton_king_hellfire_blast_modifier_debuff = class(ItemSelfDeBuffBaseClass)

function boss_skeleton_king_hellfire_blast:GetIntrinsicModifierName()
    return "boss_skeleton_king_hellfire_blast_modifier"
end
----------------------------------------------------
function boss_skeleton_king_hellfire_blast:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    EmitSoundOn("Hero_SkeletonKing.Hellfire_Blast", caster)

    self:WraithFireBlast(target)
end

function boss_skeleton_king_hellfire_blast:WraithFireBlast(target)
    local caster = self:GetCaster()

    local info = {
        Source = caster,
        Target = target,
        Ability = self,
        iMoveSpeed = self:GetSpecialValueFor("blast_speed"),
        EffectName = "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast.vpcf",
        bDodgeable = true, 
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        bProvidesVision = false, 
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }

    ProjectileManager:CreateTrackingProjectile(info)
end

function boss_skeleton_king_hellfire_blast:OnProjectileHit(hTarget, hLoc)
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local stunDuration = self:GetSpecialValueFor("stun_duration")

    local damage = hTarget:GetMaxHealthTCOTRPG() * (self:GetSpecialValueFor("blast_max_hp_damage_pct")/100)

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        ability = self,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
    })

    hTarget:AddNewModifier(caster, nil, "modifier_stunned", {
        duration = stunDuration
    })

    hTarget:AddNewModifier(caster, self, "boss_skeleton_king_hellfire_blast_modifier_debuff", {
        duration = duration
    })

    EmitSoundOn("Hero_SkeletonKing.Hellfire_BlastImpact", hTarget)
end
--------------
function boss_skeleton_king_hellfire_blast_modifier_debuff:GetEffectName()
    return "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_debuff.vpcf"
end

function boss_skeleton_king_hellfire_blast_modifier_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function boss_skeleton_king_hellfire_blast_modifier_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        ability = self:GetAbility(),
        damage = self:GetParent():GetHealth() * (self:GetAbility():GetSpecialValueFor("blast_dot_current_hp_damage_pct")/100),
        damage_type = DAMAGE_TYPE_MAGICAL,
    })
end

function boss_skeleton_king_hellfire_blast_modifier_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function boss_skeleton_king_hellfire_blast_modifier_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("blast_slow")
end