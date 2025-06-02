LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_sit_ups_damage", "heroes/hero_saitama/sit_ups.lua", LUA_MODIFIER_MOTION_NONE)
saitama_sit_ups = class({})
modifier_saitama_sit_ups_damage = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
})

if IsServer() then
	function saitama_sit_ups:OnChannelFinish(bInterrupted)
		if not bInterrupted then
			local caster = self:GetCaster()
			
            local bonusDamageModifier = caster:FindModifierByName("modifier_saitama_sit_ups_damage")
            if not bonusDamageModifier then bonusDamageModifier = caster:AddNewModifier(caster, self, "modifier_saitama_sit_ups_damage", nil) end
            bonusDamageModifier:SetStackCount(bonusDamageModifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))

			local modifier = caster:FindModifierByName("modifier_saitama_limiter")
			if not modifier then modifier = caster:AddNewModifier(caster, self, "modifier_saitama_limiter", nil) end
			modifier:SetStackCount(modifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))
		end
	end
end

function modifier_saitama_sit_ups_damage:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }

    return funcs
end

function modifier_saitama_sit_ups_damage:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_damage")
end