LinkLuaModifier("modifier_keymaster_mist_coil", "heroes/bosses/keymaster/keymaster_mist_coil", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

keymaster_mist_coil = class(ItemBaseClass)
modifier_keymaster_mist_coil = class(keymaster_mist_coil)
-------------
function keymaster_mist_coil:GetIntrinsicModifierName()
    return "modifier_keymaster_mist_coil"
end

function keymaster_mist_coil:OnProjectileHit_ExtraData( target, location, extraData )
	-- check if enemy or ally
    local target_damage = extraData.damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = target_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    self:GetCaster():Heal(target_damage * (self:GetSpecialValueFor("lifesteal")/100), self)

	-- Play effects
	local sound_target = "Hero_Abaddon.DeathCoil.Target"
	EmitSoundOn( sound_target, target )
end
-------------
function modifier_keymaster_mist_coil:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_keymaster_mist_coil:OnCreated()
    if not IsServer() then return end 

    self.stored = {}
end

function modifier_keymaster_mist_coil:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit or parent == event.attacker then return end 

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    local threshold = ability:GetSpecialValueFor("hp_threshold_pct")/100

    local attackerIndex = event.attacker:entindex()

    self.stored[attackerIndex] = self.stored[attackerIndex] or 0

    self.stored[attackerIndex] = self.stored[attackerIndex] + (event.damage*(ability:GetSpecialValueFor("damage_pct")/100))

    local calc = (self.stored[attackerIndex]/parent:GetMaxHealth())

    if calc >= threshold then
        local projectile_speed = 1200
        local projectile_name = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf"

        -- logic
        local info = {
            Target = event.attacker,
            Source = parent,
            Ability = ability,	
            
            EffectName = projectile_name,
            iMoveSpeed = projectile_speed,
            bDodgeable = true, 
            ExtraData = {
                damage = self.stored[attackerIndex]
            }                          
        }
        ProjectileManager:CreateTrackingProjectile(info)

        self:PlayEffects()

        self.stored[attackerIndex] = 0
    end

    ability:UseResources(false, false, false, true)
end

function modifier_keymaster_mist_coil:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_abaddon/abaddon_death_coil_abaddon.vpcf"
	local sound_cast = "Hero_Abaddon.DeathCoil.Cast"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end