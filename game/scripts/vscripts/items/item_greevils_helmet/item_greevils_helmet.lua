LinkLuaModifier("modifier_item_greevils_helmet", "items/item_greevils_helmet/item_greevils_helmet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_greevils_helmet_buff", "items/item_greevils_helmet/item_greevils_helmet", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_greevils_helmet = class(ItemBaseClass)
item_greevils_helmet2 = item_greevils_helmet
item_greevils_helmet3 = item_greevils_helmet
item_greevils_helmet4 = item_greevils_helmet
item_greevils_helmet5 = item_greevils_helmet
item_greevils_helmet6 = item_greevils_helmet
modifier_item_greevils_helmet = class(item_greevils_helmet)

modifier_item_greevils_helmet_buff = class(ItemBaseClassBuff)
-------------
function item_greevils_helmet:GetIntrinsicModifierName()
    return "modifier_item_greevils_helmet"
end

function item_greevils_helmet:CastFilterResultTarget(target)
    if self:GetCaster():GetLevel() < target:GetLevel() then
        return UF_FAIL_CUSTOM 
    end

    if IsServer() then
        if not IsCreepTCOTRPG(target) then 
            return UF_FAIL_CUSTOM
        end
    end

    return UF_SUCCESS 
end

function item_greevils_helmet:GetCustomCastErrorTarget(target)
    return "#dota_hud_error_greevils_helmet_error"
end

function item_greevils_helmet:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local xpMultiplier = self:GetSpecialValueFor("xp_multiplier")
    local goldMultiplier = self:GetSpecialValueFor("gold_multiplier")
    local bonusGold = self:GetSpecialValueFor("bonus_gold")
    local gold = bonusGold+(target:GetGoldBounty() * goldMultiplier)

    -- Arc warden?
    if not caster:IsRealHero() then
        caster = caster:GetPlayerOwner():GetAssignedHero() 
    end

    caster:ModifyGoldFiltered(gold, true, DOTA_ModifyGold_NeutralKill) 
    caster:AddExperience(target:GetDeathXP() * xpMultiplier, 0, false, false) 

    self:PlayEffects(caster, target)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, gold, nil)

    target:SetDeathXP(0)
    target:SetMinimumGoldBounty(0)
    target:SetMaximumGoldBounty(0)
    target:Kill(self, caster)
end

function item_greevils_helmet:PlayEffects(caster, target)
    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)   

    ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
    target:EmitSound("DOTA_Item.Hand_Of_Midas")
end

----------------------
function modifier_item_greevils_helmet:DeclareFunctions()
    local funcs = {
         MODIFIER_EVENT_ON_DEATH,
         MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
         MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
         MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
    }
    return funcs
end

function modifier_item_greevils_helmet:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 
    if not event.ability then return end 
    if event.ability:GetAbilityName() ~= "item_gold_bag" then return end 

    local buff = parent:FindModifierByName("modifier_item_greevils_helmet_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_greevils_helmet_buff", {
            duration = self:GetAbility():GetSpecialValueFor("stack_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_item_greevils_helmet:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_item_greevils_helmet:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    self.damage = (parent:GetGold()+_G.PlayerGoldBank[accountID]) * (ability:GetSpecialValueFor("gold_to_damage_pct")/100)

    self:InvokeBonusDamage()
end

function modifier_item_greevils_helmet:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_greevils_helmet:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit
    local attacker = event.attacker
    local parent = self:GetParent()

    if attacker ~= parent then return end
    if not IsCreepTCOTRPG(victim) then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() then return end
    end

    local ability = self:GetAbility()

    local chickenMod = attacker:FindModifierByName("modifier_chicken_ability_1_target_transmute")

    local gold = (victim:GetGoldBounty() * (ability:GetSpecialValueFor("gold_pct")/100)) + ability:GetSpecialValueFor("gold_per_kill")

    if chickenMod ~= nil then
      local chicken = chickenMod:GetCaster()
      if chicken ~= nil and chicken:IsAlive() then
        chicken:ModifyGoldFiltered(gold, true, 99) 
      end
    else
        attacker:ModifyGoldFiltered(gold, true, 95) 
    end

    self:PlayEffects(victim)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, victim, gold, nil)
end

function modifier_item_greevils_helmet:PlayEffects(target)
    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas_b.vpcf", PATTACH_OVERHEAD_FOLLOW, target)   
    ParticleManager:SetParticleControlEnt(midas_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
    ParticleManager:ReleaseParticleIndex(midas_particle)
end

function modifier_item_greevils_helmet:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_greevils_helmet:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_greevils_helmet:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_item_greevils_helmet:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_greevils_helmet:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-----------------
function modifier_item_greevils_helmet_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_greevils_helmet_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("stack_damage_pct") * self:GetStackCount()
end