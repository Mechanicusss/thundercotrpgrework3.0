--[[
	Author: Noya
	Date: April 5, 2015.
	FURION CAN YOU TP TOP? FURION CAN YOU TP TOP? CAN YOU TP TOP? FURION CAN YOU TP TOP? 
]]
function Teleport( event )
	local caster = event.caster
	local point = event.target_points[1]

	local towers = FindUnitsInRadius(
        caster:GetTeam(), 
        point, 
        nil, 
        600, 
        DOTA_UNIT_TARGET_TEAM_BOTH, 
        bit.bor(DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), 
        bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE), 
        FIND_CLOSEST, 
        false
    )

	local pass = false
    for _,tower in ipairs(towers) do
    	if string.find(tower:GetName(), "outpost") or string.find(tower:GetName(), "fountain") or string.find(tower:GetName(), "dummy") or string.find(tower:GetName(), "tower") or tower:IsHero() or tower:HasModifier("modifier_spawn_healing") then
    		if tower:GetTeamNumber() == caster:GetTeamNumber() then
				point = tower:GetAbsOrigin()
	    		pass = true
	    		break
	    	end
    	end
    end

    if not pass then
    	DisplayError(caster:GetPlayerID(), "Cannot teleport. No Fountain Or Captured Outposts Nearby.")
    	caster:Stop() 
    	EndTeleport(event)
    	event.ability:EndCooldown()
    	return
    end

    caster:Stop() 
	FindClearSpaceForUnit(caster, point, true)
	EndTeleport(event)    
end

function CreateTeleportParticles( event )
	local caster = event.caster
	local point = event.target_points[1]
	local particleName = "particles/units/heroes/hero_furion/furion_teleport_end.vpcf"
	caster.teleportParticle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(caster.teleportParticle, 1, point)	
end

function EndTeleport( event )
	local caster = event.caster
	ParticleManager:DestroyParticle(caster.teleportParticle, false)
	caster:StopSound("Hero_Furion.Teleport_Grow")
end