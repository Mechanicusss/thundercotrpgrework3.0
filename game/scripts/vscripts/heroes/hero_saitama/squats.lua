LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_squats_armor", "heroes/hero_saitama/squats.lua", LUA_MODIFIER_MOTION_NONE)
modifier_saitama_squats_armor = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
})
saitama_squats = class({})

if IsServer() then
	function saitama_squats:OnChannelFinish(bInterrupted)
		if not bInterrupted then
			local caster = self:GetCaster()
            
			local bonusArmorModifier = caster:FindModifierByName("modifier_saitama_squats_armor")
            if not bonusArmorModifier then bonusArmorModifier = caster:AddNewModifier(caster, self, "modifier_saitama_squats_armor", nil) end
            bonusArmorModifier:SetStackCount(bonusArmorModifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))

			local modifier = caster:FindModifierByName("modifier_saitama_limiter")
			if not modifier then modifier = caster:AddNewModifier(caster, self, "modifier_saitama_limiter", nil) end
			modifier:SetStackCount(modifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))
		end
	end
end

function modifier_saitama_squats_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  
    }

    return funcs
end

function modifier_saitama_squats_armor:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_armor")
end