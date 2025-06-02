carl_invoke = class({})
carl_empty_1 = class({})
carl_empty_2 = class({})

orb_manager = {}
ability_manager = {}

--------------------------------------------------------------------------------
-- Invoke List and Constants
orb_manager.orb_order = "qwe"
orb_manager.invoke_list = {
	["qqq"] = "carl_cold_snap",
	["qqw"] = "carl_ghost_walk",
	["qqe"] = "carl_ice_wall",
	["www"] = "carl_emp",
	["qww"] = "invoker_tornado",
	["wwe"] = "carl_alacrity",
	["eee"] = "carl_sun_strike",
	["qee"] = "carl_forge_spirits",
	["wee"] = "carl_chaos_meteor",
	["qwe"] = "invoker_deafening_blast",
}
orb_manager.modifier_list = {
	["q"] = "modifier_carl_quas",
	["w"] = "modifier_carl_wex",
	["e"] = "modifier_carl_exort",

	["modifier_carl_quas"] = "q",
	["modifier_carl_wex"] = "w",
	["modifier_carl_exort"] = "e",
}

--------------------------------------------------------------------------------
-- Ability Start
function carl_invoke:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- get invoked ability name
	local ability_name = self.orb_manager:GetInvokedAbility()

	-- invoke
	self.ability_manager:Invoke( ability_name )

	-- Effects
	self:PlayEffects()
end

--------------------------------------------------------------------------------
-- Hero Events
-- Initializations (OnOwnerSpawned does not work)
function carl_invoke:OnUpgrade()
	-- add orb manager
	self.orb_manager = orb_manager:init()

	-- add ability manager
	self.ability_manager = ability_manager:init()
	self.ability_manager.caster = self:GetCaster()
	self.ability_manager.ability = self

	-- add empty ability
	local empty1 = self:GetCaster():FindAbilityByName( "carl_empty_1" )
	local empty2 = self:GetCaster():FindAbilityByName( "carl_empty_2" )
	table.insert(self.ability_manager.ability_slot,empty1)
	table.insert(self.ability_manager.ability_slot,empty2)
end

--------------------------------------------------------------------------------
-- Helper functions
function carl_invoke:AddOrb( modifier )
	self.orb_manager:Add( modifier )
end

function carl_invoke:UpdateOrb( modifier_name, level )
	updates = self.orb_manager:UpdateOrb( modifier_name, level )
	self.ability_manager:UpgradeAbilities()
end

function carl_invoke:GetOrbLevel( orb_name )
	if not self.orb_manager.status[orb_name] then return 0 end
	return self.orb_manager.status[orb_name].level
end

function carl_invoke:GetOrbInstances( orb_name )
	if not self.orb_manager.status[orb_name] then return 0 end
	return self.orb_manager.status[orb_name].instances
end

function carl_invoke:GetOrbs()
	local ret = {}
	for k,v in pairs(self.orb_manager.status) do
		ret[k] = v.level
	end
	return ret
end

--------------------------------------------------------------------------------
-- Effects
function carl_invoke:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_invoke.vpcf"
	local sound_cast = "Hero_Invoker.Invoke"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Orb management
function orb_manager:init()
	local ret = {}

	-- initialize fields
	ret.MAX_ORB = 3
	ret.status = {}
	ret.modifiers = {}
	ret.names = {}

	-- initialize methods and constants
	for k,v in pairs(self) do
		ret[k] = v
	end
	return ret
end

function orb_manager:Add( modifier )
	-- register new orb type if not exist
	local orb_name = self.modifier_list[modifier:GetName()]
	if not self.status[orb_name] then
		self.status[orb_name] = {
			["instances"] = 0,
			["level"] = modifier:GetAbility():GetLevel(),
		}
	end

	-- add new orb instance
	table.insert(self.modifiers,modifier)
	table.insert(self.names,orb_name)
	self.status[orb_name].instances = self.status[orb_name].instances + 1

	-- remove last orb
	if #self.modifiers>self.MAX_ORB then
		self.status[self.names[1]].instances = self.status[self.names[1]].instances - 1
		self.modifiers[1]:Destroy()

		table.remove(self.modifiers,1)
		table.remove(self.names,1)
	end

	local particlePath = "0"
	local modifier_name = modifier:GetName()
	if modifier_name == "modifier_carl_quas" then
		particlePath = "particles/units/heroes/hero_invoker_kid/invoker_kid_quas_orb.vpcf"
	elseif modifier_name == "modifier_carl_wex" then
		particlePath = "particles/units/heroes/hero_invoker_kid/invoker_kid_wex_orb.vpcf"
	elseif modifier_name == "modifier_carl_exort" then
		particlePath = "particles/units/heroes/hero_invoker_kid/invoker_kid_exort_orb.vpcf"
	end

	self:ReplaceOrb(modifier:GetCaster(), particlePath)
end

function orb_manager:GetInvokedAbility()
	-- check instances
	local key = ""
	for i=1,string.len(self.orb_order) do
		k = string.sub(self.orb_order,i,i)

		if self.status[k] then 
			for i=1,self.status[k].instances do
				key = key .. k
			end
		end
	end
	return self.invoke_list[key]

	-- if allows permutation
	-- return self.invoke_list[ self.names[1] .. self.names[2] .. self.names[3] ]
end

function orb_manager:UpdateOrb( modifier_name, level )
	-- refresh orb instances
	for _,modifier in pairs(self.modifiers) do
		if modifier:GetName()==modifier_name then
			modifier:ForceRefresh()
		end
	end

	-- update its level
	local orb_name = self.modifier_list[modifier_name]
	if not self.status[orb_name] then
		self.status[orb_name] = {
			["instances"] = 0,
			["level"] = level,
		}
	else
		self.status[orb_name].level = level
	end
end

function orb_manager:ReplaceOrb(caster, particle_filepath)
    --Initialization for storing the orb properties, if not already done.
    if caster.invoked_orbs == nil then
        caster.invoked_orbs = {}
    end
    if caster.invoked_orbs_particle == nil then
        caster.invoked_orbs_particle = {}
    end
    if caster.invoked_orbs_particle_attach == nil then
        caster.invoked_orbs_particle_attach = {}
        caster.invoked_orbs_particle_attach[1] = "attach_orb1"
        caster.invoked_orbs_particle_attach[2] = "attach_orb2"
        caster.invoked_orbs_particle_attach[3] = "attach_orb3"
    end

    --Remove the removed orb's particle effect.
    if caster.invoked_orbs_particle[1] ~= nil then
        ParticleManager:DestroyParticle(caster.invoked_orbs_particle[1], false)
        caster.invoked_orbs_particle[1] = nil
    end

    --Shift the ordered list of currently summoned orb particle effects down, and create the new particle.
    caster.invoked_orbs_particle[1] = caster.invoked_orbs_particle[2]
    caster.invoked_orbs_particle[2] = caster.invoked_orbs_particle[3]
    caster.invoked_orbs_particle[3] = ParticleManager:CreateParticle(particle_filepath, PATTACH_OVERHEAD_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(caster.invoked_orbs_particle[3], 1, caster, PATTACH_POINT_FOLLOW, caster.invoked_orbs_particle_attach[1], caster:GetAbsOrigin(), false)

    --Shift the ordered list of currently summoned orb particle effect attach locations down.
    local temp_attachment_point = caster.invoked_orbs_particle_attach[1]
    caster.invoked_orbs_particle_attach[1] = caster.invoked_orbs_particle_attach[2]
    caster.invoked_orbs_particle_attach[2] = caster.invoked_orbs_particle_attach[3]
    caster.invoked_orbs_particle_attach[3] = temp_attachment_point
end

--------------------------------------------------------------------------------
-- Ability Management
function ability_manager:init()
	local ret = {}

	-- initialize fields
	ret.abilities = {}
	ret.ability_slot = {}
	ret.MAX_ABILITY = 2

	-- initialize methods and constants
	for k,v in pairs(self) do
		ret[k] = v
	end
	return ret
end

function ability_manager:Invoke( ability_name )
	if not ability_name then return end

	local ability = self:GetAbilityHandle( ability_name )
	ability.orbs = self.ability:GetOrbs()

	-- nothing to invoke
	if self.ability_slot[1] and self.ability_slot[1]==ability then
		self.ability:RefundManaCost()
		self.ability:EndCooldown()
		return
	end

	-- swap already existing
	local exist = 0
	for i=1,#self.ability_slot do
		if self.ability_slot[i]==ability then
			exist = i
		end
	end
	if exist>0 then
		self:InvokeExist( exist )
		self.ability:RefundManaCost()
		self.ability:EndCooldown()
		return
	end

	-- summon new ability
	self:InvokeNew( ability )
end

function ability_manager:InvokeExist( slot )
	for i=slot,2,-1 do
		-- swap abilities
		self.caster:SwapAbilities( 
			self.ability_slot[slot-1]:GetAbilityName(),
			self.ability_slot[slot]:GetAbilityName(),
			true,
			true
		)

		-- sync slot
		self.ability_slot[slot], self.ability_slot[slot-1] = self.ability_slot[slot-1], self.ability_slot[slot]
	end
end

function ability_manager:InvokeNew( ability )
	if #self.ability_slot<self.MAX_ABILITY then
		-- add ability at tail
		table.insert(self.ability_slot,ability)
	else
		-- swap the last ability with the summoned
		self.caster:SwapAbilities( 
			ability:GetAbilityName(),
			self.ability_slot[#self.ability_slot]:GetAbilityName(),
			true,
			false
		)

		-- sync slot
		self.ability_slot[#self.ability_slot] = ability
	end

	-- move to the front
	self:InvokeExist( #self.ability_slot )
end

function ability_manager:GetAbilityHandle( ability_name )
	-- get ability handle
	local ability = self.abilities[ability_name]

	-- if handle not exist, get one existing
	if not ability then
		ability = self.caster:FindAbilityByName( ability_name )
		self.abilities[ability_name] = ability
		
		-- if not exist, create one
		if not ability then
			ability = self.caster:AddAbility( ability_name )
			self.abilities[ability_name] = ability
		end

		-- ability:SetLevel(1)
		self:InitAbility( ability )
	end

	return ability
end

function ability_manager:InitAbility( ability )
	ability:SetLevel(1)
	ability.GetOrbSpecialValueFor = function( self, key_name, orb_name )
		if not IsServer() then return 0 end
		if not self.orbs[orb_name] then return 0 end
		return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
	end
end 

function ability_manager:UpgradeAbilities()
	for _,ability in pairs(self.abilities) do
		ability.orbs = self.ability:GetOrbs()
	end
end