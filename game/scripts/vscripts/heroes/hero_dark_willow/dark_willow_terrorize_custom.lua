LinkLuaModifier("modifier_dark_willow_terrorize_custom", "heroes/hero_dark_willow/dark_willow_terrorize_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

dark_willow_terrorize_custom = class(ItemBaseClass)
modifier_dark_willow_terrorize_custom = class(ItemBaseClassDebuff)
-------------
function dark_willow_terrorize_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function dark_willow_terrorize_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell.vpcf"
    self.vfx = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.vfx, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(self.vfx)

    EmitSoundOn("Hero_DarkWillow.Fear.Location", caster)

    local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		caster:GetAbsOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

    for _,enemy in ipairs(enemies) do
        if not enemy:IsAlive() then break end

        EmitSoundOn("Hero_DarkWillow.Brambles.CastTarget", enemy)

        enemy:AddNewModifier(caster, self, "modifier_dark_willow_terrorize_custom", { duration = duration })
        EmitSoundOn("Hero_DarkWillow.Fear.Target", enemy)

        ApplyDamage({
            attacker = caster,
            victim = enemy,
            damage = self:GetSpecialValueFor("damage") + (caster:GetIntellect() * (self:GetSpecialValueFor("int_to_damage")/100)),
            ability = self,
            damage_type = self:GetAbilityDamageType()
        })
    end
end
------------
function modifier_dark_willow_terrorize_custom:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    EmitSoundOn("Hero_DarkWillow.Fear.FP", parent)
end

function modifier_dark_willow_terrorize_custom:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    StopSoundOn("Hero_DarkWillow.Fear.FP", parent)
end

function modifier_dark_willow_terrorize_custom:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_dark_willow_terrorize_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_dark_willow_terrorize_custom:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end

function modifier_dark_willow_terrorize_custom:GetEffectName()
    return "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf"
end

function modifier_dark_willow_terrorize_custom:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end