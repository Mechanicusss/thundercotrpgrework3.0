boss_sf_requiem = class({})
modifier_boss_sf_requiem_thinker = class({})
modifier_boss_sf_requiem_thinker_casting = class({})
LinkLuaModifier( "modifier_boss_sf_requiem", "heroes/bosses/sf/requiem", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sf_requiem_scepter", "heroes/bosses/sf/requiem", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sf_requiem_thinker", "heroes/bosses/sf/requiem", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sf_requiem_thinker_casting", "heroes/bosses/sf/requiem", LUA_MODIFIER_MOTION_NONE )

function boss_sf_requiem:GetIntrinsicModifierName()
    return "modifier_boss_sf_requiem_thinker"
end

function modifier_boss_sf_requiem_thinker:IsHidden() return true end
function modifier_boss_sf_requiem_thinker:IsPurgable() return false end
function modifier_boss_sf_requiem_thinker:RemoveOnDeath() return false end

function modifier_boss_sf_requiem_thinker:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_boss_sf_requiem_thinker:OnIntervalThink()
    local parent = self:GetCaster()

    local requiem = self:GetAbility()

    if parent:IsAttacking() and requiem:IsCooldownReady() and not parent:IsSilenced() and not parent:IsHexed() and not parent:IsStunned() then
        local victim = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        if #victim > 0 then
            if not victim[1]:IsAlive() or victim[1]:IsMagicImmune() then return end
            
            FindClearSpaceForUnit(victim[1], parent:GetAbsOrigin(), false)

            parent:SetAttacking(nil)
            parent:SetForceAttackTarget(nil)
            parent:AddNewModifier(parent, nil, "modifier_boss_sf_requiem_thinker_casting", { duration = 0.5 })

            SpellCaster:Cast(requiem, parent, true)
            --parent:CastAbilityImmediately(requiem, 1)
            
            requiem:UseResources(false, false, false, true)
        end
    end
end

function modifier_boss_sf_requiem_thinker_casting:IsHidden() return true end

function modifier_boss_sf_requiem_thinker_casting:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
    return state
end
--------------------------------------------------------------------------------
-- Ability Phase Start
function boss_sf_requiem:OnAbilityPhaseStart()
    self:PlayEffects1()
    return true -- if success
end
function boss_sf_requiem:OnAbilityPhaseInterrupted()
    self:StopEffects1( false )
end

--------------------------------------------------------------------------------
-- Ability Start
function boss_sf_requiem:OnSpellStart()
    -- get references
    local soul_per_line = 2

    -- get number of souls
    local lines = math.floor(35 / soul_per_line) 
    --[[local modifier = self:GetCaster():FindModifierByNameAndCaster( "modifier_shadow_fiend_necromastery_lua", self:GetCaster() )
    if modifier~=nil then
        lines = math.floor(modifier:GetStackCount() / soul_per_line) 
    end--]]

    -- explode
    self:PlayEffects1()
    self:Explode( lines )

    -- if has scepter, add modifier to implode
    local explodeDuration = self:GetSpecialValueFor("requiem_radius") / self:GetSpecialValueFor("requiem_line_speed")
    self:GetCaster():AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_boss_sf_requiem_scepter",
        {
            lineDuration = explodeDuration,
            lineNumber = lines,
        }
    )
end

--------------------------------------------------------------------------------
-- Projectile Hit
function boss_sf_requiem:OnProjectileHit_ExtraData( hTarget, vLocation, params )
    if hTarget ~= nil then
        -- filter
        pass = false
        if hTarget:GetTeamNumber()~=self:GetCaster():GetTeamNumber() then
            pass = true
        end

        if pass then
            -- check if it is from explode or implode
            if params and params.scepter then

                -- reduce the damage
                damage = self.damage * (self.damage_pct/100)

                -- add to heal calculation
                if hTarget:IsHero() then
                    local modifier = self:RetATValue( params.modifier )
                    modifier:AddTotalHeal( damage )
                end
            end

            -- damage target
            local damage = {
                victim = hTarget,
                attacker = self:GetCaster(),
                damage = self.damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = this,
            }
            ApplyDamage( damage )

            -- apply modifier
            hTarget:AddNewModifier(
                self:GetCaster(),
                self,
                "modifier_boss_sf_requiem",
                { duration = self.duration }
            )
        end
    end

    return false
end

--[[
function boss_sf_requiem:OnOwnerDied()
    -- do nothing if not learned
    if self:GetLevel()<1 then return end

    -- get references
    local soul_per_line = self:GetSpecialValueFor("requiem_soul_conversion")

    -- get number of souls
    local lines = math.floor(65 / soul_per_line) 
    local modifier = self:GetCaster():FindModifierByNameAndCaster( "modifier_shadow_fiend_necromastery_lua", self:GetCaster() )
    if modifier~=nil then
        lines = math.floor(modifier:GetStackCount() / soul_per_line) 
    end

    -- explode
    self:Explode( lines/2 )
end
--]]

--------------------------------------------------------------------------------
-- Helper
function boss_sf_requiem:Explode( lines )
    -- get references
    self.damage =  self:GetAbilityDamage()
    self.duration = self:GetSpecialValueFor("requiem_slow_duration")

    -- get projectile
    local particle_line = "particles/econ/items/lina/lina_head_headflame/lina_spell_dragon_slave_headflame.vpcf"
    local line_length = self:GetSpecialValueFor("requiem_radius")
    local width_start = self:GetSpecialValueFor("requiem_line_width_start")
    local width_end = self:GetSpecialValueFor("requiem_line_width_end")
    local line_speed = self:GetSpecialValueFor("requiem_line_speed")

    -- create linear projectile
    local initial_angle_deg = self:GetCaster():GetAnglesAsVector().y
    local delta_angle = 360/lines
    for i=0,lines-1 do
        -- Determine velocity
        local facing_angle_deg = initial_angle_deg + delta_angle * i
        if facing_angle_deg>360 then facing_angle_deg = facing_angle_deg - 360 end
        local facing_angle = math.rad(facing_angle_deg)
        local facing_vector = Vector( math.cos(facing_angle), math.sin(facing_angle), 0 ):Normalized()
        local velocity = facing_vector * line_speed

        -- create projectile
        local info = {
            Source = self:GetCaster(),
            Ability = self,
            EffectName = particle_line,
            vSpawnOrigin = self:GetCaster():GetOrigin(),
            fDistance = line_length,
            vVelocity = velocity,
            fStartRadius = width_start,
            fEndRadius = width_end,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_SPELL_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            bReplaceExisting = false,
            bProvidesVision = false,
        }
        ProjectileManager:CreateLinearProjectile( info )
    end

    -- Play effects
    self:StopEffects1( true )
    self:PlayEffects2( lines )
end

function boss_sf_requiem:Implode( lines, modifier )
    -- get data
    self.damage_pct = self:GetSpecialValueFor("requiem_damage_pct_scepter")
    self.damage_heal_pct = self:GetSpecialValueFor("requiem_heal_pct_scepter")

    -- create identifier
    local modifierAT = self:AddATValue( modifier )
    modifier.identifier = modifierAT

    -- get projectile
    local particle_line = "particles/econ/items/lina/lina_head_headflame/lina_spell_dragon_slave_headflame.vpcf"
    local line_length = self:GetSpecialValueFor("requiem_radius")
    local width_start = self:GetSpecialValueFor("requiem_line_width_end")
    local width_end = self:GetSpecialValueFor("requiem_line_width_start")
    local line_speed = self:GetSpecialValueFor("requiem_line_speed")

    -- create linear projectile
    local initial_angle_deg = self:GetCaster():GetAnglesAsVector().y
    local delta_angle = 360/lines
    for i=0,lines-1 do
        -- Determine velocity
        local facing_angle_deg = initial_angle_deg + delta_angle * i
        if facing_angle_deg>360 then facing_angle_deg = facing_angle_deg - 360 end
        local facing_angle = math.rad(facing_angle_deg)
        local facing_vector = Vector( math.cos(facing_angle), math.sin(facing_angle), 0 ):Normalized()
        local velocity = facing_vector * line_speed

        
        -- create projectile
        local info = {
            Source = self:GetCaster(),
            Ability = self,
            EffectName = particle_line,
            vSpawnOrigin = self:GetCaster():GetOrigin() + facing_vector * line_length,
            fDistance = line_length,
            vVelocity = -velocity,
            fStartRadius = width_start,
            fEndRadius = width_end,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_SPELL_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            bReplaceExisting = false,
            bProvidesVision = false,
            ExtraData = {
                scepter = true,
                modifier = modifierAT,
            }
        }
        ProjectileManager:CreateLinearProjectile( info )
    end
end

--------------------------------------------------------------------------------
-- Effects
function boss_sf_requiem:PlayEffects1()
    -- Get Resources
    local particle_precast = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_wings.vpcf"
    local sound_precast = "Hero_Nevermore.ROS.Arcana.Cast"

    -- Create Particles
    self.effect_precast = ParticleManager:CreateParticle( particle_precast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )    

    -- Play Sounds
    EmitSoundOn(sound_precast, self:GetCaster())
end
function boss_sf_requiem:StopEffects1( success )
    -- Get Resources
    local sound_precast = "Hero_Nevermore.ROS.Arcana.Cast"

    -- Destroy Particles
    if not success then
        ParticleManager:DestroyParticle( self.effect_precast, true )
        StopSoundOn(sound_precast, self:GetCaster())
    end

    ParticleManager:ReleaseParticleIndex( self.effect_precast )
end

function boss_sf_requiem:PlayEffects2( lines )
    -- Get Resources
    local particle_cast = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls.vpcf"
    local sound_cast = "Hero_Nevermore.ROS.Arcana"

    -- Create Particles
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( lines, 0, 0 ) ) -- Lines
    ParticleManager:SetParticleControlForward( effect_cast, 2, self:GetCaster():GetForwardVector() )        -- initial direction
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Play Sounds
    EmitSoundOn(sound_cast, self:GetCaster())
end

--------------------------------------------------------------------------------
-- Helper: Ability Table (AT)
function boss_sf_requiem:GetAT()
    if self.abilityTable==nil then
        self.abilityTable = {}
    end
    return self.abilityTable
end

function boss_sf_requiem:GetATEmptyKey()
    local table = self:GetAT()
    local i = 1
    while table[i]~=nil do
        i = i+1
    end
    return i
end

function boss_sf_requiem:AddATValue( value )
    local table = self:GetAT()
    local i = self:GetATEmptyKey()
    table[i] = value
    return i
end

function boss_sf_requiem:RetATValue( key )
    local table = self:GetAT()
    local ret = table[key]
    return ret
end

function boss_sf_requiem:DelATValue( key )
    local table = self:GetAT()
    local ret = table[key]
    table[key] = nil
end

modifier_boss_sf_requiem = class({})

--------------------------------------------------------------------------------

function modifier_boss_sf_requiem:IsDebuff()
    return true
end

function modifier_boss_sf_requiem:IsPurgable()
    return true
end

--------------------------------------------------------------------------------

function modifier_boss_sf_requiem:OnCreated( kv )
    self.reduction_ms_pct = self:GetAbility():GetSpecialValueFor("requiem_reduction_ms")
    self.reduction_damage_pct = self:GetAbility():GetSpecialValueFor("requiem_reduction_damage")
end

function modifier_boss_sf_requiem:OnRefresh( kv )
    self.reduction_ms_pct = self:GetAbility():GetSpecialValueFor("requiem_reduction_ms")
    self.reduction_damage_pct = self:GetAbility():GetSpecialValueFor("requiem_reduction_damage")
end

--------------------------------------------------------------------------------

function modifier_boss_sf_requiem:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_boss_sf_requiem:GetModifierDamageOutgoing_Percentage()
    return self.reduction_damage_pct
end

function modifier_boss_sf_requiem:GetModifierMoveSpeedBonus_Percentage()
    return self.reduction_ms_pct
end

modifier_boss_sf_requiem_scepter = class({})

--------------------------------------------------------------------------------

function modifier_boss_sf_requiem_scepter:IsHidden()
    return false
    -- return true
end

function modifier_boss_sf_requiem_scepter:IsPurgable()
    return false
end
function modifier_boss_sf_requiem_scepter:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_sf_requiem_scepter:OnCreated( kv )
    -- get references
    self.lines = kv.lineNumber
    self.duration = kv.lineDuration

    self.heal = 0

    -- Add timer
    if IsServer() then
        self:StartIntervalThink( self.duration )
    end
end

function modifier_boss_sf_requiem_scepter:OnRefresh( kv )
end

function modifier_boss_sf_requiem_scepter:OnDestroy()
    if IsServer() then
        if self.identifier then
            self:GetAbility():DelATValue( self.identifier )
        end
    end
end
--------------------------------------------------------------------------------
-- Interval
function modifier_boss_sf_requiem_scepter:OnIntervalThink()
    if not self.afterImplode then
        self.afterImplode = true

        -- implode
        self:GetAbility():Implode( self.lines, self )

        -- play effects
        local sound_cast = "Hero_Nevermore.RequiemOfSouls"
        EmitSoundOn(sound_cast, self:GetParent())
    else
        -- Heal
        self:GetParent():Heal( self.heal, self:GetAbility() )
        if self.heal > 0 then
            self:PlayEffects()
        end

        -- remove references
        self:Destroy()
    end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_boss_sf_requiem_scepter:AddTotalHeal( value )
    self.heal = self.heal + value
end

--------------------------------------------------------------------------------
-- Effects
function modifier_boss_sf_requiem_scepter:PlayEffects()
    local particle_cast = "particles/items3_fx/octarine_core_lifesteal.vpcf"
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end