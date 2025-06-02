LinkLuaModifier("modifier_fountain_attack", "fountain_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fountain_attack_debuff", "fountain_attack", LUA_MODIFIER_MOTION_NONE)

local ModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    RemoveOnDeath = function(self) return true end
}

fountain_attack = class({})

function fountain_attack:GetIntrinsicModifierName()
    return "modifier_fountain_attack"
end

modifier_fountain_attack = class({})
modifier_fountain_attack_debuff = class(ModifierClass)

function modifier_fountain_attack:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_fountain_attack:OnCreated()
    if not IsServer() then return end
    
    local splitshot = self:GetParent():FindAbilityByName("fountain_split_shot")
    splitshot:ToggleAbility()
end

function modifier_fountain_attack:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local teamID = parent:GetTeamNumber()
    local target = event.target
    local attacker = event.attacker

    if (attacker ~= parent) or (not target) or (target:IsNull()) then
        return -- Make sure it's the fountain that's hitting enemies
    end

    -- Illusions are too tanky
    if target:IsIllusion() then
        --target:ForceKill(false)
    end

    target:MakeVisibleDueToAttack(teamID, 0)
    target:Purge(true, false, false, false, true)

    if target:HasModifier("modifier_fountain_attack_debuff") == false then
        target:AddNewModifier(target, nil, "modifier_fountain_attack_debuff", { duration = 12 });
    else
        target:SetModifierStackCount("modifier_fountain_attack_debuff", target, (target:GetModifierStackCount("modifier_fountain_attack_debuff", target) + 1))
        target:FindModifierByName("modifier_fountain_attack_debuff"):ForceRefresh()
    end
end

function modifier_fountain_attack_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, --GetModifierPhysicalArmorBase_Percentage (%)
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_fountain_attack_debuff:OnDeath(event)
    if self:GetParent() ~= event.unit then
        return
    end

    self:GetParent():RemoveModifierByName("modifier_fountain_attack_debuff")
end

function modifier_fountain_attack_debuff:GetModifierPhysicalArmorBonus(event)
    local target = self:GetParent()

    return target:GetModifierStackCount("modifier_fountain_attack_debuff", target) * - 1.5
end

function modifier_fountain_attack_debuff:GetModifierPhysicalArmorBase_Percentage(event)
    local target = self:GetParent()

    return 100 - math.abs(target:GetModifierStackCount("modifier_fountain_attack_debuff", target) * - 1.5)
end

function modifier_fountain_attack_debuff:GetAttributes()
    local funcs = {
        MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
    }

    return funcs
end

function modifier_fountain_attack:CheckState()
    local states = {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }

    return states
end

function modifier_fountain_attack_debuff:CheckState()
    local states = {
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
        --[MODIFIER_STATE_SILENCED] = true,
        --[MODIFIER_STATE_MUTED] = true
    }

    return states
end