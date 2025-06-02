
modifier_aghanim_summon_portals_thinker = class({})
-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:OnCreated( kv )
	if IsServer() then
		self.nMode = kv.mode 
		self.hTarget = EntIndexToHScript( kv.target_entindex )
		self.nDepth = kv.depth

		local vFwd = nil
		if self.hTarget == nil then
			vFwd = self:GetCaster():GetAbsOrigin() - self:GetParent():GetAbsOrigin()
			vFwd = vFwd:Normalized()
		else
			vFwd = self.hTarget:GetAbsOrigin() - self:GetParent():GetAbsOrigin()
			vFwd = vFwd:Normalized()
		end

		local szEffect = nil
		if self.hTarget then
			self:CreateSpear()
			szEffect = "particles/creatures/aghanim/portal_summon.vpcf"
			self:StartIntervalThink( 0.1 )
		end

		EmitSoundOn( "SeasonalConsumable.TI10.Portal.Open", self:GetParent() )
		EmitSoundOn( "SeasonalConsumable.TI10.Portal.Loop", self:GetParent() )

		self.nPortalFX = ParticleManager:CreateParticle( szEffect, PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( self.nPortalFX, 0, self:GetParent():GetAbsOrigin() )
		ParticleManager:SetParticleControlForward( self.nPortalFX, 0, vFwd )

		AddFOWViewer( DOTA_TEAM_GOODGUYS, self:GetParent():GetAbsOrigin(), 300.0, self:GetDuration(), false )
		GridNav:DestroyTreesAroundPoint( self:GetParent():GetAbsOrigin(), 300, false )
	end
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:CreateSpear()
	if IsServer() then
		self.hSpear = CreateUnitByName( "npc_dota_boss_aghanim_spear", self:GetParent():GetAbsOrigin(), true, self:GetCaster(), self:GetCaster():GetOwner(), self:GetCaster():GetTeamNumber() )
		if self.hSpear then
			self.hSpear:SetControllableByPlayer( self:GetCaster():GetPlayerOwnerID(), false )
			self.hSpear:SetOwner( self:GetCaster() )
			self.hSpear:AddEffects( EF_NODRAW )
			self.hSpear:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_rooted", {} )
			self.hSpear:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_hero_statue_pedestal", {} )
			
			--self.hSpear:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_aghanim_portal_spawn_effect", {} )
			self.hSpear:FaceTowards( self.hTarget:GetAbsOrigin() )
		end
	end
end

--------------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
	}
	return funcs
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:GetModifierIgnoreCastAngle( params )
	return 1
end

--------------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:OnIntervalThink()
	if IsServer() then
		if self.hSpear then
			self.hSpear:RemoveEffects( EF_NODRAW )
			self.hSpear:FaceTowards( self.hTarget:GetAbsOrigin() )
		end
	end
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:CreateEnemies()
	if IsServer() then
		self.Summons = {}
		if 1 then		
			
			local summons = {
						npc_dota_creature_elemental_tiny = 1,
							npc_aghsfort_creature_enraged_wildwing = 1,
							npc_dota_creature_bandit_captain = 2,
							npc_dota_creature_bandit_archer = 4,
							npc_aghsfort_creature_walrus_pudge = 3,
							npc_aghsfort_creature_bomb_squad = 2,
							npc_dota_undead_woods_skeleton_king = 2,
							-- npc_dota_creature_phoenix = 1,
							npc_dota_creature_ember_spirit = 3,
							npc_dota_creature_huge_broodmother = 1,
							npc_dota_creature_kunkka_medium = 4,							
							-- npc_dota_creature_shadow_demon = 10,
							-- npc_dota_creature_puck = 9,
							-- npc_dota_creature_beastmaster_boss = 10,
							-- npc_dota_creature_legion_commander = 10,
							npc_dota_creature_shroom_giant = 4,
							-- npc_dota_creature_mirana = 9,
							-- npc_dota_creature_large_elder_titan = 6,
							-- npc_dota_creature_tidehunter_medium = 6,
							-- npc_dota_creature_catapult = 10,
							npc_dota_creature_naga_siren_boss = 1,
							-- npc_dota_creature_ogre_seer = 7,
							npc_dota_creature_lich = 1,
							
							-- npc_dota_creature_scarab_priest = 7,
							-- npc_dota_creature_huskar = 7,							
							-- npc_dota_creature_tidehunter_large = 1,
							-- npc_dota_creature_life_stealer = 5,
							-- npc_dota_creature_baby_ogre_magi = 15,
							-- npc_dota_creature_kidnap_spider = 1,
							-- npc_dota_creature_warlock = 15,
			}			
			
			local creature_index = RandomInt(1, 17)
			local ind = 1

			local creature = nil
			local nCount = 0

			for summon,count in pairs(summons) do
				if ind == creature_index then
					creature = summon
					nCount = count
					break
				end
				ind = ind + 1
			end

			if PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) < 3 then
				creature = "npc_dota_creature_kunkka_medium"
				nCount =  PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
			end

			local parent = self:GetParent()
			local caster = self:GetCaster()
			local ability = self:GetAbility()
			for n=1,nCount do 
				Timers:CreateTimer(1 * n, function()
					if parent and not parent:IsNull() then
						local vSpawnPos = parent:GetAbsOrigin() + RandomVector( RandomInt(200,650))
						local hSummon = CreateUnitByName( creature, vSpawnPos, true, caster, caster, caster:GetTeamNumber() )
						local nPortalFX = ParticleManager:CreateParticle( "particles/creatures/aghanim/portal_summon.vpcf", PATTACH_CUSTOMORIGIN, nil )
						ParticleManager:SetParticleControl( nPortalFX, 0, vSpawnPos )					

						Timers:CreateTimer(ability:GetChannelTime(), function()
							if nPortalFX then
								ParticleManager:DestroyParticle(nPortalFX, false)
								ParticleManager:ReleaseParticleIndex(nPortalFX)
							end
						end)

						AddFOWViewer( DOTA_TEAM_GOODGUYS, parent:GetAbsOrigin(), 300.0, self:GetDuration(), false )
						GridNav:DestroyTreesAroundPoint( parent:GetAbsOrigin(), 300, false )
						-- hSummon:AddNewModifier( self:GetCaster(), self:GetCaster():FindAbilityByName("aghanim_spell_swap"), "modifier_kill", { duration = 1.5 * self:GetCaster():FindAbilityByName("aghanim_spell_swap"):GetCooldown(self:GetCaster():FindAbilityByName("aghanim_spell_swap"):GetLevel()) } )
						if hSummon ~= nil then
							table.insert( self.Summons, hSummon )
							hSummon.nDisableResistance = hSummon:GetDisableResistance( )
							hSummon.nUltimateDisableResistance = hSummon:GetUltimateDisableResistance( )
							hSummon:SetDisableResistance( 0 )
							hSummon:SetUltimateDisableResistance( 0 )
							hSummon:SetOwner( self:GetCaster() )
							hSummon:SetDeathXP( 0 )
							hSummon:SetMinimumGoldBounty( 0 )
							hSummon:SetMaximumGoldBounty( 0 )
							hSummon:AddEffects( EF_NODRAW )
							hSummon:SetAbsAngles( 0, RandomFloat( 0, 360 ), 0 )
							hSummon:SetMaterialGroup( "1" )
							hSummon:AddNewModifier( caster, ability, "modifier_aghanim_portal_spawn_effect", { duration = self:GetRemainingTime() } )
							hSummon:AddNewModifier( caster, ability, "modifier_kill", { duration = 50 } )
							FindClearSpaceForUnit(hSummon, vSpawnPos, true)
						end
					end
				end)
			end
		else
			local PossibleSummons = GameRules.Aghanim:GetSummonsForAghanim()
			local Summon = nil

			while Summon == nil and self.nDepth > 1 do
				for _,CurSummon in pairs( PossibleSummons ) do
					if CurSummon[ "depth" ] == self.nDepth then
						Summon = CurSummon
						break
					end
				end

				if Summon == nil then
					self.nDepth = self.nDepth - 1
				end
			end

			if Summon then
				local nCount = math.max( 1, 5 - math.floor( self.nDepth / 2 ) )
				for n=1,nCount do 
					local vSpawnPos = self:GetParent():GetAbsOrigin() + RandomVector( 25 * nCount )
					local hSummon = CreateUnitByName( Summon[ "unit_name" ], vSpawnPos, true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber() )
					if hSummon ~= nil then
						table.insert( self.Summons, hSummon )
						hSummon.nDisableResistance = hSummon:GetDisableResistance( )
						hSummon.nUltimateDisableResistance = hSummon:GetUltimateDisableResistance( )
						hSummon:SetDisableResistance( 0 )
						hSummon:SetUltimateDisableResistance( 0 )
						hSummon:SetOwner( self:GetCaster() )
						hSummon:SetDeathXP( 0 )
						hSummon:SetMinimumGoldBounty( 0 )
						hSummon:SetMaximumGoldBounty( 0 )
						hSummon:AddEffects( EF_NODRAW )
						hSummon:SetAbsAngles( 0, RandomFloat( 0, 360 ), 0 )
						hSummon:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_aghanim_portal_spawn_effect", { duration = self:GetRemainingTime() } )
		
					end
				end
			end
		end		
	end
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:OnDestroy()
	if IsServer() then
		self:LaunchSpear()
		StopSoundOn( "SeasonalConsumable.TI10.Portal.Open", self:GetParent() )
		StopSoundOn( "SeasonalConsumable.TI10.Portal.Loop", self:GetParent() )

		ParticleManager:DestroyParticle( self.nPortalFX, false )
		UTIL_Remove( self:GetParent() )
	end
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:LaunchSpear()
	if IsServer() then
		if self.hSpear ~= nil then
			self.hSpear:AddEffects( EF_NODRAW )
			self.hSpear:ForceKill( false )
		end

		local hSpear = self:GetCaster():FindAbilityByName( "aghanim_spear" )
		if hSpear and self.hTarget and self.hTarget:IsNull() == false then
			hSpear:EndCooldown()

			EmitSoundOn(  "SeasonalConsumable.TI10.Portal.Emit", self:GetParent() )
			local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_portal_emit.vpcf", PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetAbsOrigin() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )

			hSpear:LaunchSpear( self.hTarget:GetAbsOrigin(), self:GetParent():GetAbsOrigin() )
		else
			print( "No spear, or no target?" )
		end
	end
end

-----------------------------------------------------------------------------

function modifier_aghanim_summon_portals_thinker:ReleaseEnemies()
	if IsServer() then
		for _, Summon in pairs ( self.Summons ) do
			EmitSoundOn(  "SeasonalConsumable.TI10.Portal.Emit", Summon )
			local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_portal_emit.vpcf", PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControl( nFXIndex, 0, Summon:GetAbsOrigin() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )

			Summon:RemoveModifierByName( "modifier_aghanim_portal_spawn_effect" )
			Summon:SetAcquisitionRange( 5000 )
			Summon:SetDayTimeVisionRange( 5000 )
			Summon:SetNightTimeVisionRange( 5000 )
			Summon:SetDisableResistance( Summon.nDisableResistance )
			Summon:SetUltimateDisableResistance( Summon.nUltimateDisableResistance )
			Summon.bBossMinion = true
			FindClearSpaceForUnit( Summon, Summon:GetAbsOrigin(), false )
		end
	end
end
