LinkLuaModifier("modifier_dark_willow_cursed_crown_custom", "heroes/hero_dark_willow/dark_willow_cursed_crown_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_cursed_crown_custom_counter", "heroes/hero_dark_willow/dark_willow_cursed_crown_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_cursed_crown_custom_debuff", "heroes/hero_dark_willow/dark_willow_cursed_crown_custom.lua", LUA_MODIFIER_MOTION_NONE)

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

dark_willow_cursed_crown_custom = class(ItemBaseClass)
modifier_dark_willow_cursed_crown_custom = class(dark_willow_cursed_crown_custom)
modifier_dark_willow_cursed_crown_custom_counter = class(ItemBaseClassDebuff)
modifier_dark_willow_cursed_crown_custom_debuff = class(ItemBaseClassDebuff)
-------------
function dark_willow_cursed_crown_custom:GetIntrinsicModifierName()
    return "modifier_dark_willow_cursed_crown_custom"
end
------------
function modifier_dark_willow_cursed_crown_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_dark_willow_cursed_crown_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsIllusion() then return end
    if parent:GetTeam() == target:GetTeam() then return end
    if target:HasModifier("modifier_dark_willow_cursed_crown_custom_counter") then return end

    local ability = self:GetAbility()
    local delay = ability:GetSpecialValueFor("delay")

    if not ability:IsCooldownReady() then return end

    target:AddNewModifier(parent, ability, "modifier_dark_willow_cursed_crown_custom_counter", { duration = delay })

    ability:UseResources(false, false, false, true)

    EmitSoundOn("Hero_DarkWillow.Ley.Cast", parent)
end
---------
function modifier_dark_willow_cursed_crown_custom_counter:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()
    
    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.delay = ability:GetSpecialValueFor("delay")

    local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit__2start.vpcf"
    self.vfxCounter = ParticleManager:CreateParticle(particle_cast, PATTACH_OVERHEAD_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.vfxCounter, 0, parent:GetAbsOrigin())

    EmitSoundOn("Hero_DarkWillow.Ley.Target", parent)

    self:StartIntervalThink(0.5)
end

function modifier_dark_willow_cursed_crown_custom_counter:OnIntervalThink()
    if self:GetElapsedTime() < self.delay then
        EmitSoundOn("Hero_DarkWillow.Ley.Count", self:GetParent())
    end
end

function modifier_dark_willow_cursed_crown_custom_counter:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.vfxCounter ~= nil then
        ParticleManager:DestroyParticle(self.vfxCounter, true)
        ParticleManager:ReleaseParticleIndex(self.vfxCounter)
    end

    local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_marker.vpcf"
    local marker = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(marker, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(marker, 2, Vector(self.radius, self.radius, self.radius))
    ParticleManager:ReleaseParticleIndex(marker)

    EmitSoundOn("Hero_DarkWillow.Ley.Stun", parent)

    local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		parent:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

    for _,enemy in ipairs(enemies) do
        if not enemy:IsAlive() then break end

        EmitSoundOn("Hero_DarkWillow.Brambles.CastTarget", enemy)

        enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dark_willow_cursed_crown_custom_debuff", { duration = self.duration })
    end
end
--------------------
function modifier_dark_willow_cursed_crown_custom_debuff:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("damage_interval")

    local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_bramble.vpcf"
    self.vfx = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 2, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 3, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 4, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 5, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 6, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 7, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 8, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 9, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 10, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 11, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 12, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 13, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 14, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 15, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 16, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 17, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 18, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 19, parent:GetAbsOrigin())

    EmitSoundOn("Hero_DarkWillow.Bramble.Spawn", parent)
    EmitSoundOn("Hero_DarkWillow.Bramble.Target.Layer", parent)
    EmitSoundOn("Hero_DarkWillow.Bramble.Target", parent)

    self:StartIntervalThink(interval)
end

function modifier_dark_willow_cursed_crown_custom_debuff:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    StopSoundOn("Hero_DarkWillow.Bramble.Target.Layer", parent)
    EmitSoundOn("Hero_DarkWillow.Bramble.Destroy", parent)
end

function modifier_dark_willow_cursed_crown_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    ApplyDamage({
        attacker = caster,
        victim = parent,
        ability = ability,
        damage = damage,
        damage_type = ability:GetAbilityDamageType()
    })
end

function modifier_dark_willow_cursed_crown_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_dark_willow_cursed_crown_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.damage_type == DAMAGE_TYPE_MAGICAL then
        return self:GetAbility():GetSpecialValueFor("magic_amp")
    end
end


function modifier_dark_willow_cursed_crown_custom_debuff:GetModifierMoveSpeedBonus_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("slow")
end
