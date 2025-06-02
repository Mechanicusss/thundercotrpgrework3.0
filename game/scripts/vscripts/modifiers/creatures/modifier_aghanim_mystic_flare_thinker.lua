
modifier_aghanim_mystic_flare_thinker = class({})
modifier_aghanim_mystic_flare_dummy = class({})
modifier_aghanim_mystic_flare_dummy_aura = class({})

function modifier_aghanim_mystic_flare_dummy_aura:IsDebuff() return true end
function modifier_aghanim_mystic_flare_dummy_aura:RemoveOnDeath() return true end
function modifier_aghanim_mystic_flare_dummy_aura:IsHidden() return true end
-----------------------------------------------------------------------------

function modifier_aghanim_mystic_flare_thinker:OnCreated( kv )
    if IsServer() then
        self.interval = self:GetAbility():GetSpecialValueFor( "summon_interval" )
        self.search_radius = self:GetAbility():GetSpecialValueFor( "search_radius" )
        self.damage_radius = self:GetAbility():GetSpecialValueFor( "damage_radius" )

        self:OnIntervalThink()
        self:StartIntervalThink(self.interval)
    end
end

-----------------------------------------------------------------------------

function modifier_aghanim_mystic_flare_thinker:OnIntervalThink()
    if IsServer() then
        local caster = self:GetCaster()
        local ability = self:GetAbility()

        local enemies = GetVisibleEnemyHeroesInRange(caster, self.search_radius)
        for _,enemy in ipairs(enemies) do
            CreateUnitByNameAsync(
                "outpost_placeholder_unit",
                enemy:GetAbsOrigin(),
                false,
                caster,
                caster,
                caster:GetTeamNumber(),
                function(unit)
                    unit:AddNewModifier(caster, ability, "modifier_aghanim_mystic_flare_dummy", {
                        duration = ability:GetSpecialValueFor("duration")
                    })
                    self:SummonFlare(unit)
                end
            )
        end
    end
end

function modifier_aghanim_mystic_flare_thinker:SummonFlare(target)
    local particle_cast = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf"

    EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_SkywrathMage.MysticFlare.Cast", target)
    EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_SkywrathMage.MysticFlare", target)

    -- Create Particle
    local effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect, 1, Vector(self.damage_radius, 1, 1) )
    ParticleManager:ReleaseParticleIndex(effect)
end

-----------------------------------------------------------------------------
function modifier_aghanim_mystic_flare_dummy:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.damage_interval = ability:GetSpecialValueFor("damage_interval")
    self.damage_radius = ability:GetSpecialValueFor("damage_radius")

    self:OnIntervalThink()
    self:StartIntervalThink(self.damage_interval)
end

function modifier_aghanim_mystic_flare_dummy:OnIntervalThink()
    local caster = self:GetParent()
    local pos = caster:GetAbsOrigin() + RandomVector(RandomFloat(1, self.damage_radius))

    self:PlayEffect(caster, pos)
end

function modifier_aghanim_mystic_flare_dummy:PlayEffect(target, pos)
    local particle_cast = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare.vpcf"

    EmitSoundOnLocationWithCaster(pos, "Hero_SkywrathMage.MysticFlare.Target", target)

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect, 0, pos )
end

function modifier_aghanim_mystic_flare_dummy:OnDestroy()
    if not IsServer() then return end

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, false)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    self:GetParent():ForceKill(false)
    self:StartIntervalThink(-1)
end

function modifier_aghanim_mystic_flare_dummy:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_aghanim_mystic_flare_dummy:IsAura()
  return true
end

function modifier_aghanim_mystic_flare_dummy:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_aghanim_mystic_flare_dummy:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_aghanim_mystic_flare_dummy:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("damage_radius")
end

function modifier_aghanim_mystic_flare_dummy:GetModifierAura()
    return "modifier_aghanim_mystic_flare_dummy_aura"
end

function modifier_aghanim_mystic_flare_dummy:GetAuraEntityReject(ent) 
    return ent:IsMagicImmune()
end
--------------------------------------------------------------------------
function modifier_aghanim_mystic_flare_dummy_aura:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.damage_interval = ability:GetSpecialValueFor("damage_interval")
    self.damage_radius = ability:GetSpecialValueFor("damage_radius")

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage_type = ability:GetAbilityDamageType(),
        damage = ability:GetSpecialValueFor("damage"),
        ability = ability,
    }

    self:StartIntervalThink(self.damage_interval)
end

function modifier_aghanim_mystic_flare_dummy_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local pos = caster:GetAbsOrigin() + RandomVector(RandomFloat(1, self.damage_radius/2))

    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mystic_flare_debuff", {
        duration = 3
    })

    ApplyDamage(self.damageTable)
end