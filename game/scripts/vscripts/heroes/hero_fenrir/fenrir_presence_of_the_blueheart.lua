LinkLuaModifier("modifier_fenrir_presence_of_the_blueheart", "heroes/hero_fenrir/fenrir_presence_of_the_blueheart", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fenrir_presence_of_the_blueheart_aura", "heroes/hero_fenrir/fenrir_presence_of_the_blueheart", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

fenrir_presence_of_the_blueheart = class(ItemBaseClass)
modifier_fenrir_presence_of_the_blueheart = class(fenrir_presence_of_the_blueheart)
modifier_fenrir_presence_of_the_blueheart_aura = class(ItemBaseClassBuff)
-------------
function fenrir_presence_of_the_blueheart:GetIntrinsicModifierName()
    return "modifier_fenrir_presence_of_the_blueheart"
end


function fenrir_presence_of_the_blueheart:GetAOERadius()
    return self:GetSpecialValueFor("disable_radius")
end

function modifier_fenrir_presence_of_the_blueheart:IsAura()
	return self.active
end

function modifier_fenrir_presence_of_the_blueheart:GetModifierAura()
	return "modifier_fenrir_presence_of_the_blueheart_aura"
end

function modifier_fenrir_presence_of_the_blueheart:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_fenrir_presence_of_the_blueheart:GetAuraDuration()
	return 0.5
end

function modifier_fenrir_presence_of_the_blueheart:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_fenrir_presence_of_the_blueheart:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_fenrir_presence_of_the_blueheart:GetAuraEntityReject( hEntity )
	return hEntity:HasModifier("modifier_chicken_ability_1_self_transmute") and self:GetCaster():HasModifier("modifier_chicken_ability_1_target_transmute")
end

function modifier_fenrir_presence_of_the_blueheart:OnCreated()
	self.active = true

    if not IsServer() then return end

    self:StartIntervalThink(FrameTime())
end

function modifier_fenrir_presence_of_the_blueheart:OnIntervalThink()
	-- check for enemy
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self:GetAbility():GetSpecialValueFor("disable_radius"),	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local no_enemies = #enemies==0

	-- check if change state
	if self.active ~= no_enemies then
		self.active = no_enemies
	end
end
-----------
function modifier_fenrir_presence_of_the_blueheart_aura:OnCreated( kv )
	-- references
	self.intellect = self:GetAbility():GetSpecialValueFor( "intellect_sharing" )
	self.manaRegen = self:GetAbility():GetSpecialValueFor( "mana_regen_sharing" )

	if not IsServer() then return end
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnRefresh( kv )
	-- references
	self.intellect = self:GetAbility():GetSpecialValueFor( "intellect_sharing" )
    self.manaRegen = self:GetAbility():GetSpecialValueFor( "mana_regen_sharing" )
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnRemoved()
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_fenrir_presence_of_the_blueheart_aura:OnCreated( kv )
	-- references
	self.intellect = self:GetAbility():GetSpecialValueFor( "intellect_sharing" )
    self.manaRegen = self:GetAbility():GetSpecialValueFor( "mana_regen_sharing" )

	if not IsServer() then return end
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnRefresh( kv )
	-- references
	self.intellect = self:GetAbility():GetSpecialValueFor( "intellect_sharing" )
    self.manaRegen = self:GetAbility():GetSpecialValueFor( "mana_regen_sharing" )
end

function modifier_fenrir_presence_of_the_blueheart_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_TOOLTIP2 
	}

	return funcs
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnTooltip()
    if self:GetCaster()==self:GetParent() then
        local agi = self:GetCaster():GetBaseIntellect()
        return self.intellect*agi/100
    else
        local agi = self:GetCaster():GetBaseIntellect()
		agi = 100/(100+self.intellect)*agi

		local bonus = self.intellect*agi/100
        return bonus
    end
end

function modifier_fenrir_presence_of_the_blueheart_aura:OnTooltip2()
    if self:GetCaster()==self:GetParent() then
        local agi = self:GetCaster():GetManaRegen()
        return self.manaRegen*agi/100
    else
        local agi = self:GetCaster():GetManaRegen()
		agi = 100/(100+self.manaRegen)*agi

		local bonus = self.manaRegen*agi/100
        return bonus
    end
end

function modifier_fenrir_presence_of_the_blueheart_aura:GetModifierBonusStats_Intellect()
	if not IsServer() then return end


	if self:GetCaster()==self:GetParent() then
		-- use lock mechanism to prevent infinite recursive
		if self.lock1 then return end

		-- calculate bonus
		self.lock1 = true
		local agi = self:GetCaster():GetBaseIntellect()
		self.lock1 = false

		local bonus = self.intellect*agi/100

		return bonus
	else
		-- this agi includes bonus from this ability, which should be excluded
		local agi = self:GetCaster():GetBaseIntellect()
		agi = 100/(100+self.intellect)*agi

		local bonus = self.intellect*agi/100

		return bonus
	end

end

function modifier_fenrir_presence_of_the_blueheart_aura:GetModifierConstantManaRegen()
	if not IsServer() then return end

	if self:GetCaster()==self:GetParent() then
		-- use lock mechanism to prevent infinite recursive
		if self.lock1 then return end

		-- calculate bonus
		self.lock1 = true
		local agi = self:GetCaster():GetManaRegen()
		self.lock1 = false

		local bonus = self.manaRegen*agi/100

		return bonus
	else
		-- this agi includes bonus from this ability, which should be excluded
		local agi = self:GetCaster():GetManaRegen()
		agi = 100/(100+self.manaRegen)*agi

		local bonus = self.manaRegen*agi/100

		return bonus
	end

end