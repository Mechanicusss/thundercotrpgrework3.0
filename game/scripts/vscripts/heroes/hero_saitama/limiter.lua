LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_limiter_autocast", "heroes/hero_saitama/limiter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saitama_limiter_str_buff", "heroes/hero_saitama/limiter.lua", LUA_MODIFIER_MOTION_NONE)

modifier_saitama_limiter_str_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
})

saitama_limiter = class({
	GetIntrinsicModifierName = function() return "modifier_saitama_limiter_autocast" end,
})

--function saitama_limiter:GetManaCost()
--	return self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("manacost_pct") * 0.01 + self:GetSpecialValueFor("manacost")
--end

function saitama_limiter:CastFilterResult()
	local parent = self:GetCaster()
	return parent:GetModifierStackCount("modifier_saitama_limiter", parent) == 0 and UF_FAIL_CUSTOM or UF_SUCCESS
end

function saitama_limiter:GetCustomCastError()
	local parent = self:GetCaster()
	return parent:GetModifierStackCount("modifier_saitama_limiter", parent) == 0 and "#dota_hud_error_no_charges" or ""
end

if IsServer() then
    --[[
	function saitama_limiter:OnSpellStart()
		local caster = self:GetCaster()
		StartAnimation(caster, {
			duration = 1.2, -- 36 / 30
			activity = ACT_DOTA_CAST_ABILITY_6
		})
		

		local bonusStrengthModifier = caster:FindModifierByName("modifier_saitama_limiter_str_buff")
        if not bonusStrengthModifier then bonusStrengthModifier = caster:AddNewModifier(caster, self, "modifier_saitama_limiter_str_buff", nil) end
        
        local preTotal = caster:GetStrength() + ((bonusStrengthModifier:GetStackCount()/10) * (caster:GetBaseStrength() * (self:GetSpecialValueFor("bonus_strength_pct")/100)))
    	if preTotal >= 1000000 or caster:GetStrength() >= 1000000 then DisplayError(caster:GetPlayerID(), "Limit Reached") return false end

        bonusStrengthModifier:SetStackCount((bonusStrengthModifier:GetStackCount()/10) + (caster:GetModifierStackCount("modifier_saitama_limiter", caster)))
        bonusStrengthModifier:ForceRefresh()

        caster:EmitSound("Arena.Hero_Saitama.Limiter")
		--caster:ModifyStrength(caster:GetBaseStrength() * self:GetSpecialValueFor("bonus_strength_pct") * caster:GetModifierStackCount("modifier_saitama_limiter", caster) * 0.01)
	end
    --]]
end

function modifier_saitama_limiter_str_buff:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE  
    }

    return funcs
end

function modifier_saitama_limiter_str_buff:OnCreated()
	self:SetHasCustomTransmitterData(true)

	self:OnRefresh()
end

function modifier_saitama_limiter_str_buff:OnRefresh()
    if not IsServer() then return end

    self.strength = ((self:GetStackCount()/10) * (self:GetCaster():GetBaseStrength() * (self:GetAbility():GetSpecialValueFor("bonus_strength_pct")/100))
    )
    self:InvokeBonusStrength()
end

function modifier_saitama_limiter_str_buff:GetModifierPreAttack_BonusDamage()
    return self.fStrength
end

function modifier_saitama_limiter_str_buff:AddCustomTransmitterData()
    return
    {
        strength = self.fStrength
    }
end

function modifier_saitama_limiter_str_buff:HandleCustomTransmitterData(data)
    if data.strength ~= nil then
        self.fStrength = tonumber(data.strength)
    end
end

function modifier_saitama_limiter_str_buff:InvokeBonusStrength()
    if IsServer() == true then
        self.fStrength = self.strength

        self:SendBuffRefreshToClients()
    end
end

modifier_saitama_limiter_autocast = class({
	IsHidden = function() return true end,
})

if IsServer() then
    function modifier_saitama_limiter_autocast:DeclareFunctions()
        return {
            MODIFIER_EVENT_ON_ATTACK
        }
    end

    function modifier_saitama_limiter_autocast:OnAttack(event)
        local parent = self:GetParent()

        if parent ~= event.attacker then return end

        local ability = self:GetAbility()
        if parent:PassivesDisabled() or not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

        StartAnimation(parent, {
            duration = 1.2, -- 36 / 30
            activity = ACT_DOTA_CAST_ABILITY_6
        })
        
        local bonusStrengthModifier = parent:FindModifierByName("modifier_saitama_limiter_str_buff")
        if not bonusStrengthModifier then bonusStrengthModifier = parent:AddNewModifier(parent, ability, "modifier_saitama_limiter_str_buff", nil) end
        
        local preTotal = parent:GetStrength() + ((bonusStrengthModifier:GetStackCount()/10) * (parent:GetBaseStrength() * (ability:GetSpecialValueFor("bonus_strength_pct")/100)))
        if preTotal >= 1000000 or parent:GetStrength() >= 1000000 then return false end

        bonusStrengthModifier:SetStackCount((bonusStrengthModifier:GetStackCount()/10) + (parent:GetModifierStackCount("modifier_saitama_limiter", parent)))
        bonusStrengthModifier:ForceRefresh()

        parent:EmitSound("Arena.Hero_Saitama.Limiter")
    end

	function modifier_saitama_limiter_autocast:OnCreated()
		--self:StartIntervalThink(0.1)
		local parent = self:GetParent()
		if not parent:HasModifier("modifier_saitama_limiter") then
			parent:AddNewModifier(parent, self:GetAbility(), "modifier_saitama_limiter", nil)
		end
	end

	function modifier_saitama_limiter_autocast:OnIntervalThink()
		local ability = self:GetAbility()
		local parent = self:GetParent()
		if parent:IsAlive() then
			if ability:GetAutoCastState() and parent:GetMana() >= ability:GetManaCost() and not parent:IsChanneling() and not parent:IsInvisible() and not (parent:GetCurrentActiveAbility() and parent:GetCurrentActiveAbility():IsInAbilityPhase()) and parent:GetModifierStackCount("modifier_saitama_limiter", parent) > 0 then
				parent:CastAbilityNoTarget(ability, parent:GetPlayerID())
			end
		end
	end
end
