LinkLuaModifier("modifier_lava_drake_flames_thinker", "creeps/lava_drake_flames", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lava_drake_flames_debuff", "creeps/lava_drake_flames", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
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

lava_drake_flames = class(ItemBaseClass)
modifier_lava_drake_flames_thinker = class(ItemBaseClassThinker)
modifier_lava_drake_flames_debuff = class(ItemBaseClassDebuff)
-------------
function lava_drake_flames:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_lava_drake_flames_thinker", -- modifier name
        {
            duration = self:GetSpecialValueFor("ground_duration")
        }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

    local effect_cast = ParticleManager:CreateParticle( "particles/neutral_fx/black_dragon_fireball_cast.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn("Hero_DragonKnight.Fireball.Cast", caster)
end
--------------
function modifier_lava_drake_flames_thinker:OnCreated()
    if not IsServer() then return end 

    -- references
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.duration = self:GetAbility():GetSpecialValueFor("burn_duration")
    
    local vision = self.radius

    -- Start interval
    self:StartIntervalThink(1)

    -- Create fow viewer
    AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), vision, 3, true)

    local particle_cast = "particles/neutral_fx/black_dragon_fireball.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, self:GetParent():GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 2, self:GetParent():GetAbsOrigin() )
end

function modifier_lava_drake_flames_thinker:OnIntervalThink()
	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local damageTable = {
		-- victim = target,
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(), --Optional.
	}

	for _,enemy in pairs(enemies) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end
		-- damage
		damageTable.victim = enemy
		ApplyDamage(damageTable)

        EmitSoundOn("Hero_DragonKnight.Fireball.Target", enemy)

        enemy:AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_lava_drake_flames_debuff", -- modifier name
            { duration = self.duration } -- kv
        )
	end
end

function modifier_lava_drake_flames_thinker:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_DragonKnight.Fireball.Target", self:GetParent())

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    UTIL_Remove(self:GetParent())
end
--------------------
function modifier_lava_drake_flames_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_lava_drake_flames_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end