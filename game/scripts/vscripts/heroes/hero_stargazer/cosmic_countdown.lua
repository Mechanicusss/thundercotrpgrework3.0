function CheckAbility(keys)
	local caster = keys.caster
	local ability = keys.ability
	if ability:IsCooldownReady() and IsServer() then
		local stats_per_cycle = ability:GetLevelSpecialValueFor("stats_per_cycle", ability:GetLevel() - 1)
        local stats_per_cycle_from_stats_pct_increase_per_min = ability:GetSpecialValueFor("stats_per_cycle_increase_per_min")

        local gameTime = math.floor(GameRules:GetGameTime() / 60)

		local bonusStr = stats_per_cycle + (gameTime * stats_per_cycle_from_stats_pct_increase_per_min)
		local bonusAgi = stats_per_cycle + (gameTime * stats_per_cycle_from_stats_pct_increase_per_min)
		local bonusInt = stats_per_cycle + (gameTime * stats_per_cycle_from_stats_pct_increase_per_min)

		local preTotalStr = caster:GetStrength() + bonusStr 
		local preTotalAgi = caster:GetAgility() + bonusAgi 
		local preTotalInt = caster:GetBaseIntellect() + bonusInt 

        local maxLimit = 1000000
        
        if preTotalStr < maxLimit and caster:GetStrength() < maxLimit then 
          caster:ModifyStrength(bonusStr)
        end

        if preTotalAgi < maxLimit and caster:GetAgility() < maxLimit then 
          caster:ModifyAgility(bonusAgi)
        end

        if preTotalInt < maxLimit and caster:GetBaseIntellect() < maxLimit then 
          caster:ModifyIntellect(bonusInt)
        end

        if (preTotalStr >= maxLimit and preTotalAgi >= maxLimit and preTotalInt >= maxLimit) or (caster:GetStrength() >= maxLimit and caster:GetAgility() >= maxLimit and caster:GetBaseIntellect() >= maxLimit) then 
            ability:SetActivated(false) 
            DisplayError(caster:GetPlayerID(), "Limit Reached") 
            caster:FindModifierByNameAndCaster("modifier_stargazer_cosmic_countdown", caster):StartIntervalThink(-1)
            return false 
        end

		ability:StartCooldown(ability:GetEffectiveCooldown(ability:GetLevel()-1))
		caster:EmitSound("Arena.Hero_Stargazer.CosmicCountdown.Cast")
		ParticleManager:CreateParticle("particles/arena/units/heroes/hero_stargazer/cosmic_countdown.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	end
end