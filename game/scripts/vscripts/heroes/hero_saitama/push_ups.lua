LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_push_ups_strength", "heroes/hero_saitama/push_ups.lua", LUA_MODIFIER_MOTION_NONE)

saitama_push_ups = class({})
modifier_saitama_push_ups_strength = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
})

if IsServer() then
	function saitama_push_ups:OnChannelFinish(bInterrupted)
		if not bInterrupted then
			local caster = self:GetCaster()
			
            local bonusStrengthModifier = caster:FindModifierByName("modifier_saitama_push_ups_strength")
            if not bonusStrengthModifier then bonusStrengthModifier = caster:AddNewModifier(caster, self, "modifier_saitama_push_ups_strength", nil) end
            
            local preTotal = caster:GetStrength() + (bonusStrengthModifier:GetStackCount() * self:GetSpecialValueFor("bonus_strength"))
            if preTotal > 10000000 then DisplayError(caster:GetPlayerID(), "Limit Reached") return false end

            bonusStrengthModifier:SetStackCount(bonusStrengthModifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))

			local modifier = caster:FindModifierByName("modifier_saitama_limiter")
			if not modifier then modifier = caster:AddNewModifier(caster, self, "modifier_saitama_limiter", nil) end
			modifier:SetStackCount(modifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))
		end
	end
end

function modifier_saitama_push_ups_strength:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS  
    }

    return funcs
end

function modifier_saitama_push_ups_strength:GetModifierBonusStats_Strength()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_strength")
end