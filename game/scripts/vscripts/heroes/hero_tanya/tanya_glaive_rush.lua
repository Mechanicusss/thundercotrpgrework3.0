LinkLuaModifier("modifier_tanya_glaive_rush", "heroes/hero_tanya/tanya_glaive_rush.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_tanya_glaive_rush_cooldown_refresh", "heroes/hero_tanya/tanya_glaive_rush.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_tanya_glaive_rush_shard_buff", "heroes/hero_tanya/tanya_glaive_rush.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

tanya_glaive_rush = class(ItemBaseClass)
modifier_tanya_glaive_rush = class(tanya_glaive_rush)
modifier_tanya_glaive_rush_cooldown_refresh = class(ItemBaseClassBuff)
modifier_tanya_glaive_rush_shard_buff = class(ItemBaseClassBuff)
-------------
function tanya_glaive_rush:GetCooldown(level)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_tanya_glaive_rush_cooldown_refresh") then return 0 end 

    return self.BaseClass.GetCooldown(self, level)
end

function tanya_glaive_rush:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_aghanims_shard") then
        local buff = caster:FindModifierByName("modifier_tanya_glaive_rush_shard_buff")
        if not buff then
            buff = caster:AddNewModifier(caster, self, "modifier_tanya_glaive_rush_shard_buff", { duration = self:GetSpecialValueFor("shard_duration") })
        end

        if buff then
            if buff:GetStackCount() < self:GetSpecialValueFor("shard_max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end
    end

    caster:AddNewModifier(caster, self, "modifier_tanya_glaive_rush", {})

    EmitSoundOn("Hero_Spectre.Attack.Arcana", caster)
end
-------------
function modifier_tanya_glaive_rush:OnCreated(props)
    if not IsServer() then return end 
    
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    self.direction = (self.ability:GetCursorPosition() - self.parent:GetAbsOrigin()):Normalized()
	self.speed = self.ability:GetSpecialValueFor("speed")/25
	self.traveled = 0
	self.distance = (self.parent:GetAbsOrigin() - self.ability:GetCursorPosition()):Length2D() 
	self.units = {}

    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/antimage/antimage_ti7/antimage_blink_start_ti7_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end
end

function modifier_tanya_glaive_rush:GetEffectName()
    return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur_light.vpcf"
end

function modifier_tanya_glaive_rush:OnDestroy()
    if not IsServer() then return end

    self.parent:RemoveHorizontalMotionController(self)

    self.parent:StartGesture(ACT_DOTA_ATTACK)
end

function modifier_tanya_glaive_rush:UpdateHorizontalMotion( me, dt )
    if self.parent:IsRooted() or self.parent:IsStunned() then
        self:Destroy()
        return
    end

    if self.traveled < self.distance then
		self.parent:SetAbsOrigin(self.parent:GetAbsOrigin() + self.direction*self.speed)
		self.traveled = self.traveled + self.speed
		local units = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin() , nil, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false) 
		if units then
			for i = 1, #units do
				if not self.units[ units[i] ] then
					self.units[units[i]] = 1

					self.parent:PerformAttack(units[i], true, true, true, false, true, false, true) 

                    EmitSoundOn("Hero_Antimage.Attack.Persona", units[i])

                    local chance = self.ability:GetSpecialValueFor("reset_chance")
                    if RollPercentage(chance) and not self.parent:HasModifier("modifier_tanya_glaive_rush_cooldown_refresh") then
                        local mod = self.parent:FindModifierByName("modifier_tanya_glaive_rush_cooldown_refresh")
                    
                        if not mod then
                            mod = self.parent:AddNewModifier(self.parent, self.ability, "modifier_tanya_glaive_rush_cooldown_refresh", {
                                duration = self.ability:GetSpecialValueFor("cd_refresh_window"),
                                oldCd = self.ability:GetCooldownTimeRemaining()
                            })
                        end
                    
                        if mod then
                            mod:ForceRefresh()
                        end
                    
                        self.ability:EndCooldown()
                    end
				end
			end
		end
	else
		self.parent:InterruptMotionControllers(true)
		self:Destroy()
	end
end

function modifier_tanya_glaive_rush:OnHorizontalMotionInterrupted()
    self:Destroy()
end

function modifier_tanya_glaive_rush:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE 
    }

    return funcs
end

function modifier_tanya_glaive_rush:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() then
        self.record = params.record
        return self:GetAbility():GetSpecialValueFor("crit_damage") + (self:GetCaster():GetAgility() * (self:GetAbility():GetSpecialValueFor("crit_damage_per_agility")))
    end
end

function modifier_tanya_glaive_rush:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            self:PlayEffects(params.target)
        end
    end
end

function modifier_tanya_glaive_rush:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_tanya_glaive_rush:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_tanya_glaive_rush:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_tanya_glaive_rush:GetModifierDisableTurning()
    return 1
end

function modifier_tanya_glaive_rush:PlayEffects( target )
    -- Load effects
    local particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
    local sound_cast = "Hero_PhantomAssassin.CoupDeGrace"

    -- if target:IsMechanical() then
    --  particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf"
    --  sound_cast = "Hero_PhantomAssassin.CoupDeGrace.Mech"
    -- end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlForward( effect_cast, 1, (self:GetParent():GetOrigin()-target:GetOrigin()):Normalized() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( sound_cast, target )
end
-----------
function modifier_tanya_glaive_rush_cooldown_refresh:OnCreated(props)
    if not IsServer() then return end 

    self.cd = props.oldCd
end

function modifier_tanya_glaive_rush_cooldown_refresh:OnDestroy()
    if not IsServer() then return end 

    local ability = self:GetAbility()

    ability:StartCooldown(self.cd)
end
--------------
function modifier_tanya_glaive_rush_shard_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_tanya_glaive_rush_shard_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("shard_damage_pct") * self:GetStackCount()
end