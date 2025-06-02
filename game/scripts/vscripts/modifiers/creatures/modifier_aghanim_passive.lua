
modifier_aghanim_passive = class({})

-----------------------------------------------------------------------------------------

function modifier_aghanim_passive:IsHidden()
	return true
end

-----------------------------------------------------------------------------------------

function modifier_aghanim_passive:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_aghanim_passive:GetPriority()
	return MODIFIER_PRIORITY_ULTRA + 10000
end

-----------------------------------------------------------------------------------------

function modifier_aghanim_passive:CheckState()
	local state =
	{
		[MODIFIER_STATE_HEXED] = false,
		[MODIFIER_STATE_ROOTED] = false,
		[MODIFIER_STATE_SILENCED] = false,
		[MODIFIER_STATE_STUNNED] = false,
		[MODIFIER_STATE_FROZEN] = false,
		[MODIFIER_STATE_FEARED] = false,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}

	if IsServer() then
		if self:GetParent() and self:GetParent().AI and self:GetParent().AI.bDefeated == true then
			state[MODIFIER_STATE_INVULNERABLE] = true
		end
	end
	
	return state
end

--------------------------------------------------------------------------------

function modifier_aghanim_passive:OnCreated( kv )
	self.status_resist = self:GetAbility():GetSpecialValueFor( "status_resist" )
	if IsServer() then
		self:GetParent().bAbsoluteNoCC = true
		self:GetParent().bNoNullifier = true
	end
end

--------------------------------------------------------------------------------

function modifier_aghanim_passive:OnRefresh( kv )
	self.status_resist = self:GetAbility():GetSpecialValueFor( "status_resist" )
end

-----------------------------------------------------------------------------------------

function modifier_aghanim_passive:DeclareFunctions()
	local funcs = 
	{
		--MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_aghanim_passive:GetModifierStatusResistanceStacking( params )
	return self.status_resist 
end

--------------------------------------------------------------------------------

function modifier_aghanim_passive:GetMinHealth( params )
	if IsServer() then
		--if GameRules.Aghanim:GetAscensionLevel() < 4 then
			--return math.floor( self:GetParent():GetMaxHealth() * 0.1 )
		--end
	end
 	return 1
end 

--------------------------------------------------------------------------------
function modifier_aghanim_passive:OnDeath( params )
	if IsServer() then
		if self:GetParent() == params.unit and self:GetParent().AI and self:GetParent().AI.bDefeated == false then 			
			local pos = self:GetParent():GetAbsOrigin()
			_G.AghanimDefeated = true

			local uberPortalSpawnPoint = Entities:FindByName(nil, "trigger_entrance_uber_bosses")
			if uberPortalSpawnPoint ~= nil then
				_G.UberBossesGateUnit = CreateUnitByName("outpost_placeholder_unit", uberPortalSpawnPoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
				_G.UberBossesGateUnit:AddNewModifier(_G.UberBossesGateUnit, nil, "modifier_uber_bosses_portal", {})
			end

			local portal = _G.UberBossesGateUnit
			if portal ~= nil then
				portal:SetModel("models/props_structures/dungeon_temple_portal001.vmdl")
				portal:RemoveNoDraw()

				local particle = ParticleManager:CreateParticle("particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_portal_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, portal)   
				ParticleManager:SetParticleControlEnt(particle, 0, portal, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", portal:GetAbsOrigin(), false)
				ParticleManager:ReleaseParticleIndex(particle)

				EmitSoundOn("Hero_Underlord.Portal.Spawn", portal)
				AddFOWViewer(DOTA_TEAM_GOODGUYS, portal:GetAbsOrigin(), 300, 99999, false)
			end

			-- Drop Everything Else --
			local dropAmount = 5
			for i = 1, dropAmount, 1 do
		        Timers:CreateTimer((i/dropAmount)+(i/5), function()
		            local items = {
		                "item_tome_agi_1000",
		                "item_tome_str_1000",
		                "item_tome_int_1000",
		            }

		            local chosenDrop = RandomInt(1, #items)

		            DropNeutralItemAtPositionForHero(items[chosenDrop], Vector(pos.x+RandomInt(-100, 100), pos.y+RandomInt(-100, 100), pos.z), self:GetParent(), 1, false)
		        end)
		    end
		end
	end
end