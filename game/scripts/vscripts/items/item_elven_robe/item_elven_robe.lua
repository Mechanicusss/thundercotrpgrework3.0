LinkLuaModifier("modifier_item_elven_robe", "items/item_elven_robe/item_elven_robe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_elven_robe_attack_buff", "items/item_elven_robe/item_elven_robe", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_elven_robe = class(ItemBaseClass)
item_elven_robe2 = item_elven_robe
item_elven_robe3 = item_elven_robe
item_elven_robe4 = item_elven_robe
item_elven_robe5 = item_elven_robe
item_elven_robe6 = item_elven_robe
item_elven_robe7 = item_elven_robe
item_elven_robe8 = item_elven_robe
item_elven_robe9 = item_elven_robe
modifier_item_elven_robe = class(item_elven_robe)
modifier_item_elven_robe_attack_buff = class(ItemBaseClassBuff)
-------------
function item_elven_robe:GetIntrinsicModifierName()
    return "modifier_item_elven_robe"
end

function modifier_item_elven_robe:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT 

    }
    return funcs
end

function modifier_item_elven_robe:GetModifierIncomingPhysicalDamageConstant(event)
    if IsServer() then
        local parent = self:GetParent()
        if parent ~= event.target or parent == event.attacker then return end
        
        local ability = self:GetAbility()
        if ability:IsCooldownReady() then
            ability:UseResources(false, false, false, true)
            return -event.damage
        end
    end
end

function modifier_item_elven_robe:GetModifierIncomingSpellDamageConstant(event)
    if IsServer() then
        local parent = self:GetParent()
        if parent ~= event.target or parent == event.attacker then return end
        
        local ability = self:GetAbility()
        if ability:IsCooldownReady() then
            ability:UseResources(false, false, false, true)
            return -event.damage
        end
    end
end

function modifier_item_elven_robe:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end

function modifier_item_elven_robe:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_elven_robe:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_elven_robe:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_elven_robe:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("dmg_increase_moving_duration")

    self.pos1 = parent:GetAbsOrigin()
    self.pos2 = parent:GetAbsOrigin()

    self:StartIntervalThink(interval)
end

function modifier_item_elven_robe:OnIntervalThink()
    local parent = self:GetParent()

    self.pos1 = parent:GetAbsOrigin()

    if self.pos1 == self.pos2 then
        self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_item_elven_robe_attack_buff", {})
    else
        self:GetParent():RemoveModifierByName("modifier_item_elven_robe_attack_buff")
        self.pos2 = parent:GetAbsOrigin()
    end
end
-------
function modifier_item_elven_robe_attack_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self:StartIntervalThink(FrameTime())
end

function modifier_item_elven_robe_attack_buff:OnIntervalThink()
    local parent = self:GetParent()

    if parent:IsMoving() then
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end
end

function modifier_item_elven_robe_attack_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT
    }
    return funcs
end

function modifier_item_elven_robe_attack_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("dmg_increase_moving_pct")
end

function modifier_item_elven_robe_attack_buff:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("evasion_increase_moving_duration")
end