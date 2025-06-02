if oracle_blessing == nil then oracle_blessing = class({}) end

LinkLuaModifier( "modifier_oracle_blessing", "heroes/hero_oracle/blessing", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_blessing_scepter", "heroes/hero_oracle/blessing", LUA_MODIFIER_MOTION_NONE )

fvPointOrigin = 0
function oracle_blessing:GetConceptRecipientType()
    return DOTA_SPEECH_USER_ALL
end
local vPoint
--------------------------------------------------------------------------------

function oracle_blessing:GetAOERadius() return self:GetSpecialValueFor("arrow_width") end

function oracle_blessing:GetBehavior()
    if not self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_AOE
    end 

    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
end

function oracle_blessing:SpeakTrigger()
    return DOTA_ABILITY_SPEAK_CAST
end

oracle_blessing.mod = nil
oracle_blessing.hasSceper = false

--------------------------------------------------------------------------------

function oracle_blessing:GetChannelTime()
    return 1
end

--------------------------------------------------------------------------------

function oracle_blessing:OnAbilityPhaseStart()
    if IsServer() then
        self.vPoint = self:GetCursorPosition()
    end

    return true
end

--------------------------------------------------------------------------------

function oracle_blessing:OnSpellStart()
    if IsServer() then
        self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_oracle_blessing", { duration = self:GetChannelTime() } )
    end
end

--------------------------------------------------------------------------------

function oracle_blessing:OnChannelFinish( bInterrupted )
    if bInterrupted == false then
        local vDirection = self.vPoint - self:GetCaster():GetOrigin()
        vDirection = vDirection:Normalized()

        self.speed = 3000/25
        self.leap_z = 0
        self.traveled = 0
        self.start_pos = self:GetCaster():GetAbsOrigin()
        self.distance = (self.vPoint - self:GetCaster():GetOrigin()):Length2D()

        fvPointOrigin = self.vPoint
        self.info = {
            Ability = self,
            vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
            fStartRadius = 320,
            fEndRadius = 320,
            vVelocity = vDirection * (self:GetSpecialValueFor("arrow_speed") + 2000),
            fDistance = self.distance,
            Source = self:GetCaster(),
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            bProvidesVision = true,
            iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
            iVisionRadius = 400,
        }
        self.nProjID = ProjectileManager:CreateLinearProjectile( self.info )

        EmitSoundOn( "Hero_AbyssalUnderlord.Pit.TargetHero" , self:GetCaster() )

        self.hasSceper = self:GetCaster():HasScepter() and self:GetAutoCastState()

        if self.hasSceper then
            self.mod = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_oracle_blessing_scepter", nil)
        end
    else
        if self:GetCaster():HasModifier("modifier_oracle_blessing") then
            self:GetCaster():RemoveModifierByName("modifier_oracle_blessing")
        end
    end
end

function oracle_blessing:OnProjectileHit_ExtraData( hTarget, vLocation, table )
    if hTarget == nil then
        local hCaster = self:GetCaster()
        local nFXIndex = ParticleManager:CreateParticle( "particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_arcana_fire.vpcf", PATTACH_CUSTOMORIGIN, nil );
        ParticleManager:SetParticleControl( nFXIndex, 0, vLocation);
        ParticleManager:SetParticleControl( nFXIndex, 1, Vector(self:GetSpecialValueFor("arrow_width"), self:GetSpecialValueFor("arrow_width"), 0))
        ParticleManager:SetParticleControl( nFXIndex, 3, vLocation);
        ParticleManager:SetParticleControl( nFXIndex, 5, Vector(350, 350, 0));
        ParticleManager:ReleaseParticleIndex( nFXIndex );

        EmitSoundOnLocationWithCaster(vLocation, "Hero_EarthShaker.EchoSlam", hCaster)
        EmitSoundOnLocationWithCaster(vLocation, "Hero_EarthShaker.EchoSlamSmall", hCaster)
        EmitSoundOnLocationWithCaster(vLocation, "PudgeWarsClassic.echo_slam", hCaster)

        EmitSoundOn("Hero_ObsidianDestroyer.SanityEclipse.TI8", self:GetCaster() )
        local units = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, self:GetSpecialValueFor("arrow_width"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

        for i, target in ipairs(units) do  --Restore health and play a particle effect for every found ally.
            target:EmitSound("Hero_ObsidianDestroyer.EssenceAura")
            local damage = {
                victim = target,
                attacker = hCaster,
                damage = self:GetAbilityDamage(),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self,
            }

            ApplyDamage( damage )
        end

        AddFOWViewer(self:GetCaster():GetTeamNumber(), vLocation, 400, 5, true)

        if self.hasSceper then
            FindClearSpaceForUnit( self:GetCaster(), vLocation, true)
            if self.mod then
                self.mod:Destroy()
            end
        end

        return nil
    end
end
--------------------------------------------------------------------------------

function oracle_blessing:OnProjectileThink( vLocation )
    if self.traveled < self.distance/2 then
        -- Go up
        -- This is to memorize the z point when it comes to cliffs and such although the division of speed by 2 isnt necessary, its more of a cosmetic thing
        self.leap_z = self.leap_z + (self.speed/2)
        -- Set the new location to the current ground location + the memorized z point
    else
        -- Go down
        self.leap_z = self.leap_z - (self.speed/2)
    end
    
    if self.hasSceper then
        self:GetCaster():SetAbsOrigin(vLocation + Vector(0, 0, self.leap_z))
    end

    self.traveled = (vLocation - self.start_pos):Length2D()
end


if modifier_oracle_blessing == nil then modifier_oracle_blessing = class({}) end

function modifier_oracle_blessing:OnCreated( kv )
    if IsServer() then
    end
end

function modifier_oracle_blessing:OnDestroy()
   if IsServer() then

   end
end

function modifier_oracle_blessing:IsPurgable()
    return false
end

function modifier_oracle_blessing:IsHidden()
    return true
end

function oracle_blessing:GetAbilityTextureName() return self.BaseClass.GetAbilityTextureName(self)  end 


if modifier_oracle_blessing_scepter == nil then modifier_oracle_blessing_scepter = class({}) end

function modifier_oracle_blessing_scepter:IsHidden() return true end
function modifier_oracle_blessing_scepter:IsPurgable() return false end
function modifier_oracle_blessing_scepter:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_oracle_blessing_scepter:CheckState () return { [MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_OUT_OF_GAME] = true } end

function modifier_oracle_blessing_scepter:DeclareFunctions ()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }

    return funcs
end


function modifier_oracle_blessing_scepter:GetOverrideAnimation (params)
    return ACT_DOTA_FLAIL
end