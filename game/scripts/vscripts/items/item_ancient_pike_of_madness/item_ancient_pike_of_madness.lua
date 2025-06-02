LinkLuaModifier("modifier_item_ancient_pike_of_madness", "items/item_ancient_pike_of_madness/item_ancient_pike_of_madness.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_pike_of_madness_agi", "items/item_ancient_pike_of_madness/item_ancient_pike_of_madness.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_pike_of_madness_madness", "items/item_ancient_pike_of_madness/item_ancient_pike_of_madness.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_ancient_pike_of_madness = class(ItemBaseClass)
item_ancient_pike_of_madness_2 = item_ancient_pike_of_madness
item_ancient_pike_of_madness_3 = item_ancient_pike_of_madness
item_ancient_pike_of_madness_4 = item_ancient_pike_of_madness
item_ancient_pike_of_madness_5 = item_ancient_pike_of_madness
modifier_item_ancient_pike_of_madness = class(ItemBaseClass)
modifier_item_ancient_pike_of_madness_agi = class(ItemBaseClassBuff)
modifier_item_ancient_pike_of_madness_madness = class(ItemBaseClassBuff)
-------------
function item_ancient_pike_of_madness:GetIntrinsicModifierName()
    return "modifier_item_ancient_pike_of_madness"
end
-------------
function modifier_item_ancient_pike_of_madness:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL 
    }
end

function modifier_item_ancient_pike_of_madness:GetModifierProcAttack_BonusDamage_Physical(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        -- get modifier stack
        local ability = self:GetAbility()
        local multiplier = ability:GetSpecialValueFor("agi_damage_multiplier")

        return self:GetParent():GetAgility() * multiplier
    end
end


function modifier_item_ancient_pike_of_madness:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage") + (self:GetParent():GetAgility() * (self:GetAbility():GetSpecialValueFor("agi_dmg")))
end

function modifier_item_ancient_pike_of_madness:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_ancient_pike_of_madness:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_ancient_pike_of_madness:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_ancient_pike_of_madness:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed_pct")
end

function modifier_item_ancient_pike_of_madness:GetModifierAttackRangeBonus()
    if not self:GetCaster():IsRangedAttacker() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_item_ancient_pike_of_madness:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if self:GetCaster() ~= attacker or not UnitIsNotMonkeyClone(attacker) then return end
    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

    local distance = (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D()
    if distance < ability:GetSpecialValueFor("min_damage_range") then return end

    if distance > ability:GetSpecialValueFor("max_damage_range") then
        distance = ability:GetSpecialValueFor("max_damage_range")
    end

    local multiplier = (distance / ability:GetSpecialValueFor("range_falloff_multiplier"))

    return multiplier
end

function modifier_item_ancient_pike_of_madness:OnAttack(event)
    if event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local madnessChance = ability:GetSpecialValueFor("madness_chance")
    local madnessDuration = ability:GetSpecialValueFor("madness_duration")
    
    if RollPercentage(madnessChance) and ability:GetLevel() == 5 then
        parent:AddNewModifier(parent, ability, "modifier_item_ancient_pike_of_madness_madness", { duration = madnessDuration })
    end

    if not RollPercentage(ability:GetSpecialValueFor("boost_chance")) then return end

    local buff = parent:FindModifierByNameAndCaster("modifier_item_ancient_pike_of_madness_agi", parent)
    local stacks = parent:GetModifierStackCount("modifier_item_ancient_pike_of_madness_agi", parent)
    
    if not buff then
        parent:AddNewModifier(parent, ability, "modifier_item_ancient_pike_of_madness_agi", { duration = ability:GetSpecialValueFor("boost_duration") })
    end

    if stacks < ability:GetSpecialValueFor("boost_max_stacks") then
        parent:SetModifierStackCount("modifier_item_ancient_pike_of_madness_agi", parent, (stacks + 1))
    end

    if buff ~= nil then
        buff:ForceRefresh()
    end
end

function modifier_item_ancient_pike_of_madness:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:RemoveModifierByNameAndCaster("modifier_item_ancient_pike_of_madness_agi", parent)
end
---------------
function modifier_item_ancient_pike_of_madness_agi:OnCreated()
    if not IsServer() then return end
    self.agility = self:GetParent():GetBaseAgility()
end

function modifier_item_ancient_pike_of_madness_agi:OnRefresh()
    if not IsServer() then return end
    self.agility = self:GetParent():GetBaseAgility()
end

function modifier_item_ancient_pike_of_madness_agi:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
    }

    return funcs
end

function modifier_item_ancient_pike_of_madness_agi:GetModifierBonusStats_Agility()
    if IsServer() and self.agility then
        if not self:GetCaster():HasItemInInventory(self:GetAbility():GetAbilityName()) then
            if self:GetCaster():HasModifier("modifier_item_ancient_pike_of_madness_agi") then
                self:GetCaster():RemoveModifierByNameAndCaster("modifier_item_ancient_pike_of_madness_agi", self:GetCaster())
            end
            return
        end
        
        local amount = (self.agility * (self:GetAbility():GetSpecialValueFor("boost_agility_pct")/100)) * self:GetStackCount()
        local limit = 2147483647

        if amount > limit or amount < 0 then
            amount = limit
        end

        return amount
    end
end
---------
function modifier_item_ancient_pike_of_madness_madness:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
    }
end

function modifier_item_ancient_pike_of_madness_madness:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("madness_damage_pct")
end

function modifier_item_ancient_pike_of_madness_madness:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("madness_increased_damage_taken_pct")
end

function modifier_item_ancient_pike_of_madness_madness:GetModifierBaseAttackTimeConstant()
    return self.bat
end

function modifier_item_ancient_pike_of_madness_madness:OnCreated()
    local parent = self:GetParent()

    self.baseAttackTimeDefault = parent:GetBaseAttackTime()
    self.bat = self.baseAttackTimeDefault - self:GetAbility():GetSpecialValueFor("madness_bat_reduction")

    EmitSoundOn("DOTA_Item.MaskOfMadness.Activate", parent)

    if not IsServer() then return end 

    self.effect_cast = ParticleManager:CreateParticle( "particles/econ/items/drow/drow_head_mania/mask_of_madness_active_mania.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
end

function modifier_item_ancient_pike_of_madness_madness:OnDestroy()
    if not IsServer() then return end 

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end