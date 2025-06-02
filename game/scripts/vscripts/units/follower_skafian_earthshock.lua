follower_skafian_earthshock = class({})
modifier_follower_skafian_earthshock = class({})
LinkLuaModifier( "modifier_follower_skafian_earthshock_debuff", "units/follower_skafian_earthshock", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_follower_skafian_earthshock", "units/follower_skafian_earthshock", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
function follower_skafian_earthshock:GetIntrinsicModifierName()
    return "modifier_follower_skafian_earthshock"
end

function modifier_follower_skafian_earthshock:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_follower_skafian_earthshock:OnIntervalThink()
    local parent = self:GetParent()
    local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #enemies > 0 and self:GetAbility():IsCooldownReady() and parent:IsAttacking() then
        parent:CastAbilityImmediately(self:GetAbility(), 1)
        self:GetAbility():UseResources(false, false, false, true)
    end
end

function follower_skafian_earthshock:OnSpellStart()
    -- get references
    local slow_radius = self:GetSpecialValueFor("shock_radius")
    local slow_duration = self:GetDuration()
    local ability_damage = self:GetAbilityDamage()

    -- get list of affected enemies
    local enemies = FindUnitsInRadius (
        self:GetCaster():GetTeamNumber(),
        self:GetCaster():GetOrigin(),
        nil,
        slow_radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    -- Do for each affected enemies
    for _,enemy in pairs(enemies) do
        -- Apply damage
        local damage = {
            victim = enemy,
            attacker = self:GetCaster(),
            damage = ability_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        }
        ApplyDamage( damage )

        -- Add slow modifier
        enemy:AddNewModifier(
            self:GetCaster(),
            self,
            "modifier_follower_skafian_earthshock_debuff",
            { duration = slow_duration }
        )
    end

    -- Play effects
    self:PlayEffects()
end

function follower_skafian_earthshock:PlayEffects()
    -- get resources
    local sound_cast = "Hero_Ursa.Earthshock"
    local particle_cast = "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf"

    -- get data
    local slow_radius = self:GetSpecialValueFor("shock_radius")

    -- play particles
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, self:GetCaster():GetForwardVector() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(slow_radius/2, slow_radius/2, slow_radius/2) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- play sounds
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_follower_skafian_earthshock_debuff = class({})

--------------------------------------------------------------------------------

function modifier_follower_skafian_earthshock_debuff:IsDebuff()
    return true
end

--------------------------------------------------------------------------------

function modifier_follower_skafian_earthshock_debuff:OnCreated( kv )
    self.slow = self:GetAbility():GetSpecialValueFor("movement_slow")
end

function modifier_follower_skafian_earthshock_debuff:OnRefresh( kv )
    self.slow = self:GetAbility():GetSpecialValueFor("movement_slow")
end
--------------------------------------------------------------------------------

function modifier_follower_skafian_earthshock_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

--------------------------------------------------------------------------------

function modifier_follower_skafian_earthshock_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_follower_skafian_earthshock_debuff:GetEffectName()
    return "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf"
end

function modifier_follower_skafian_earthshock_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end