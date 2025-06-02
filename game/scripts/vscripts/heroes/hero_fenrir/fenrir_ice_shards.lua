LinkLuaModifier("modifier_fenrir_ice_shards", "heroes/hero_fenrir/fenrir_ice_shards", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fenrir_ice_shards_debuff", "heroes/hero_fenrir/fenrir_ice_shards", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

fenrir_ice_shards = class(ItemBaseClass)
modifier_fenrir_ice_shards = class(fenrir_ice_shards)
modifier_fenrir_ice_shards_debuff = class(ItemBaseClassDebuff)
-------------
function fenrir_ice_shards:OnProjectileHit(hTarget, hLoc)
    if not hTarget or hTarget:IsNull() then return end 
    
    local caster = self:GetCaster()
    local ability = self
    local damageType = self:GetAbilityDamageType()

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    caster:PerformAttack(
        hTarget,
        true,
        true,
        true,
        false,
        false,
        false,
        false
    )

    if not caster:HasModifier("modifier_item_aghanims_shard") then return end

     -- Play particles
     local particle_cast = "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_freezing_field_explosion.vpcf"

     -- Create particle
     local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
     ParticleManager:SetParticleControl( effect_cast, 0, hLoc )
     ParticleManager:ReleaseParticleIndex(effect_cast)
     
     Timers:CreateTimer(0.6, function() 
        if not hTarget or hTarget:IsNull() then return end 
        if not hTarget:IsAlive() then return end 

        ApplyDamage({
            attacker = caster,
            victim = hTarget,
            damage = damage,
            ability = ability,
            damage_type = damageType,
        })

        -- Play sound
        local sound_cast = "hero_Crystal.freezingField.explosion"
        EmitSoundOnLocationWithCaster( hLoc, sound_cast, hTarget )

        hTarget:AddNewModifier(caster, ability, "modifier_fenrir_ice_shards_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })

        EmitSoundOn("hero_Crystal.frostbite", hTarget)
     end)
end

function fenrir_ice_shards:GetIntrinsicModifierName()
    return "modifier_fenrir_ice_shards"
end

function fenrir_ice_shards:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local shards = self:GetSpecialValueFor("shards_num")
    local i = 0
    local targets = {}
    
    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            caster:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() then break end

        if i < shards then
            self:LaunchIceShard(enemy)

            i = i + 1
        end
    end

    EmitSoundOn("hero_Crystal.CrystalNovaCast", caster)
end

function fenrir_ice_shards:LaunchIceShard(target)
    local caster = self:GetCaster()
    local projName = caster:GetRangedProjectileName()
    local projSpeed = caster:GetProjectileSpeed()

    local attachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    if RandomFloat(0.0, 100.0) <= 50 then
        attachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    end

    local info = {
        Source = caster,
        Target = target,
        Ability = self,
        iMoveSpeed = projSpeed,
        EffectName = projName,
        bDodgeable = true, 
        bVisibleToEnemies = true,
        iSourceAttachment = attachment
    }

    ProjectileManager:CreateTrackingProjectile(info)
end
-----------
function modifier_fenrir_ice_shards:OnCreated()
    if not IsServer() then return end
    
    self:StartIntervalThink(FrameTime())
end

function modifier_fenrir_ice_shards:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetAutoCastState() and not parent:IsSilenced() and ability:GetManaCost(-1) <= parent:GetMana() and ability:IsCooldownReady() then 
        SpellCaster:Cast(ability, self:GetParent(), true)
    end
end
-----------
function modifier_fenrir_ice_shards_debuff:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true, 
        [MODIFIER_STATE_STUNNED] = true, 
    }
end

function modifier_fenrir_ice_shards_debuff:GetEffectName()
    return "particles/_2econ/items/crystal_maiden/ti7_immortal_shoulder/cm_ti7_immortal_frostbite.vpcf"
end