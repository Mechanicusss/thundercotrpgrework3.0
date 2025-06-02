timbersaw_whirling_death_custom = class({})
LinkLuaModifier( "modifier_timbersaw_whirling_death_custom", "heroes/hero_timbersaw/whirling_death", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function timbersaw_whirling_death_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local radius = self:GetSpecialValueFor( "whirling_radius" )
    local damage = self:GetSpecialValueFor( "whirling_damage" )
    local duration = self:GetSpecialValueFor( "duration" )
    local tree_damage = self:GetSpecialValueFor( "tree_damage_scale" )

    -- calculate number of trees, then cut down
    local trees = GridNav:GetAllTreesAroundPoint( caster:GetOrigin(), radius, false )
    GridNav:DestroyTreesAroundPoint( caster:GetOrigin(), radius, false )

    -- calculate and precache damage
    damage = damage + (caster:GetStrength() * (self:GetSpecialValueFor("str_damage_pct")/100)) + #trees * tree_damage
    local damageTable = {
        -- victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    -- ApplyDamage(damageTable)

    -- find enemies
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        caster:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    local hashero = false
    for _,enemy in pairs(enemies) do
        -- debuff if hero
        if IsCreepTCOTRPG(enemy) or IsBossTCOTRPG(enemy) then
            caster:AddNewModifier(
                caster, -- player source
                self, -- ability source
                "modifier_timbersaw_whirling_death_custom", -- modifier name
                { duration = duration } -- kv
            )

            hashero = true
        end

        -- damage
        damageTable.victim = enemy
        ApplyDamage( damageTable )
    end

    -- Play effects
    self:PlayEffects( radius, hashero )
end

--------------------------------------------------------------------------------
function timbersaw_whirling_death_custom:PlayEffects( radius, hashero )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_shredder/shredder_whirling_death.vpcf"
    local sound_cast = "Hero_Shredder.WhirlingDeath.Cast"
    local sound_target = "Hero_Shredder.WhirlingDeath.Damage"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CENTER_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetCaster(),
        PATTACH_CENTER_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
    if hashero then
        EmitSoundOn( sound_target, self:GetCaster() )
    end
end


modifier_timbersaw_whirling_death_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_whirling_death_custom:IsHidden()
    return false
end

function modifier_timbersaw_whirling_death_custom:IsDebuff()
    return false
end

function modifier_timbersaw_whirling_death_custom:IsStunDebuff()
    return false
end

function modifier_timbersaw_whirling_death_custom:IsPurgable()
    return true
end

function modifier_timbersaw_whirling_death_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_whirling_death_custom:OnCreated( kv )
    self.parent = self:GetParent()

    -- references
    self.stat_loss_pct = self:GetAbility():GetSpecialValueFor( "stat_loss_pct" )

    if not IsServer() then return end
    -- calculate stat loss
    self.stat_loss = self.parent:GetPrimaryStatValue() * self.stat_loss_pct/100

    local preTotal = self.parent:GetStrength() + self.stat_loss
    if preTotal >= 1000000 or self.parent:GetStrength() >= 1000000 then DisplayError(self.parent:GetPlayerID(), "Limit Reached") return false end

    -- reduce health by 20 per strength loss if strength hero
    if self.parent:GetPrimaryAttribute()==DOTA_ATTRIBUTE_STRENGTH then
        --self:GetParent():ModifyHealth( self:GetParent():GetHealth() + 20*self.stat_loss, self:GetAbility(), true, DOTA_DAMAGE_FLAG_NONE )
    end
end

function modifier_timbersaw_whirling_death_custom:OnRefresh( kv )
    
end

function modifier_timbersaw_whirling_death_custom:OnRemoved()
    if not IsServer() then return end

    -- give health back by 19 per strength if strength hero
    if self.parent:GetPrimaryAttribute()==DOTA_ATTRIBUTE_STRENGTH then
        --self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 19*self.stat_loss, self:GetAbility(), true, DOTA_DAMAGE_FLAG_NONE )
    end
end

function modifier_timbersaw_whirling_death_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_timbersaw_whirling_death_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }

    return funcs
end

if IsServer() then
    function modifier_timbersaw_whirling_death_custom:GetModifierBonusStats_Agility()
        --if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_AGILITY then return 0 end
        return self.stat_loss or 0
    end
    function modifier_timbersaw_whirling_death_custom:GetModifierBonusStats_Intellect()
        --if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_INTELLECT then return 0 end
        return self.stat_loss or 0
    end
    function modifier_timbersaw_whirling_death_custom:GetModifierBonusStats_Strength()
        --if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_STRENGTH then return 0 end
        return self.stat_loss or 0
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_timbersaw_whirling_death_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_shredder_whirl.vpcf"
end

function modifier_timbersaw_whirling_death_custom:StatusEffectPriority()
    return MODIFIER_PRIORITY_NORMAL
end

function modifier_timbersaw_whirling_death_custom:GetEffectName()
    return "particles/units/heroes/hero_shredder/shredder_whirling_death_debuff.vpcf"
end

function modifier_timbersaw_whirling_death_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end