-- Created by Elfansoer
--[[
Ability checklist (erase if done/checked):
- Scepter Upgrade
- Break behavior
- Linken/Reflect behavior
- Spell Immune/Invulnerable/Invisible behavior
- Illusion behavior
- Stolen behavior
]]
--------------------------------------------------------------------------------
medusa_mana_shield_custom = class({})
LinkLuaModifier( "modifier_medusa_mana_shield_custom", "heroes/hero_medusa/medusa_mana_shield_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_medusa_mana_shield_custom_mana", "heroes/hero_medusa/medusa_mana_shield_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_medusa_mana_shield_custom_mana = class(ItemBaseClass)

function medusa_mana_shield_custom:GetIntrinsicModifierName()
    return "modifier_medusa_mana_shield_custom"
end
--------------------------------------------------------------------------------
-- Ability Start
function medusa_mana_shield_custom:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	-- load data
	local value1 = self:GetSpecialValueFor("some_value")

	-- logic

end
--------------------------------------------------------------------------------
-- Toggle
function medusa_mana_shield_custom:OnToggle()
	-- unit identifier
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName( "modifier_medusa_mana_shield_custom" )

	if self:GetToggleState() then
		if not modifier then
			caster:AddNewModifier(
				caster, -- player source
				self, -- ability source
				"modifier_medusa_mana_shield_custom", -- modifier name
				{} -- kv
			)
		end
	else
		if modifier then
			modifier:Destroy()
		end
	end
end
function medusa_mana_shield_custom:ProcsMagicStick()
	return false
end

--------------------------------------------------------------------------------
-- Ability Events
function medusa_mana_shield_custom:OnUpgrade()
	-- refresh values if on
	local modifier = self:GetCaster():FindModifierByName( "modifier_medusa_mana_shield_custom" )
	if modifier then
		modifier:ForceRefresh()
	end
end

modifier_medusa_mana_shield_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_medusa_mana_shield_custom:IsHidden()
	return false
end

function modifier_medusa_mana_shield_custom:IsDebuff()
	return false
end

function modifier_medusa_mana_shield_custom:IsPurgable()
	return false
end

function modifier_medusa_mana_shield_custom:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_medusa_mana_shield_custom:OnCreated( kv )
	-- references
	self.damage_per_mana = self:GetAbility():GetSpecialValueFor( "damage_per_mana" )
	self.absorb_pct = self:GetAbility():GetSpecialValueFor( "max_damage_reduction" )/100

	if not IsServer() then return end
	-- Play effects
	local sound_cast = "Hero_Medusa.ManaShield.On"
	EmitSoundOn( sound_cast, self:GetParent() )

    self:StartIntervalThink(FrameTime())
end

--[[
function modifier_medusa_mana_shield_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local dr = ability:GetSpecialValueFor("max_damage_reduction")
    local damagePerMana = ability:GetSpecialValueFor("damage_per_mana")

	if parent:GetMana() < damagePerMana then
		dr = 0
	end

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = dr
end

function modifier_medusa_mana_shield_custom:OnRefresh( kv )
	-- references
	self.damage_per_mana = self:GetAbility():GetSpecialValueFor( "damage_per_mana" )
	self.absorb_pct = self:GetAbility():GetSpecialValueFor( "max_damage_reduction" )	
end

function modifier_medusa_mana_shield_custom:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end
--]]

function modifier_medusa_mana_shield_custom:OnDestroy()
	if not IsServer() then return end
	-- Play effects
	local sound_cast = "Hero_Medusa.ManaShield.Off"
	EmitSoundOn( sound_cast, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_medusa_mana_shield_custom:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE 
	}

	return funcs
end

function modifier_medusa_mana_shield_custom:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_medusa_mana_shield_custom:GetModifierMPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen_amp")
end

function modifier_medusa_mana_shield_custom:GetModifierIncomingDamageConstant(keys)
	if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local MaxAbsorbedDamage = self.absorb_pct
    local DamagePerMana = self.damage_per_mana

    --local damageToAbsorb = keys.original_damage * MaxAbsorbedDamage -- the amount of damage blocked to absorb from mana instead
    --local manaToBurn = damageToAbsorb / DamagePerMana
	--local currentMana = parent:GetMana()

	local block = keys.original_damage

	local manaCost = keys.original_damage * MaxAbsorbedDamage * 0.01 / DamagePerMana

	if parent:GetMana() >= manaCost then
		parent:EmitSound("Hero_Medusa.ManaShield.Proc")

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(particle)

		block = -block
	else
		block = keys.damage -- keys.damage needs to be used to account for armor and other reductions etc
	end

	parent:Script_ReduceMana(manaCost, ability)

	return block
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_medusa_mana_shield_custom:GetEffectName()
	return "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf"
end

function modifier_medusa_mana_shield_custom:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_medusa_mana_shield_custom:PlayEffects( damage )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf"
	local sound_cast = "Hero_Medusa.ManaShield.Proc"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( damage, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
end