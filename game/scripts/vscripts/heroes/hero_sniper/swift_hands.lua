LinkLuaModifier("modifier_sniper_swift_hands_custom", "heroes/hero_sniper/swift_hands", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_swift_hands_custom_buff_permanent_damage", "heroes/hero_sniper/swift_hands", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_swift_hands_custom_buff_permanent_cdr", "heroes/hero_sniper/swift_hands", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

sniper_swift_hands_custom = class(ItemBaseClass)
modifier_sniper_swift_hands_custom = class(sniper_swift_hands_custom)
modifier_sniper_swift_hands_custom_buff_permanent_damage = class(ItemBaseClassBuff)
modifier_sniper_swift_hands_custom_buff_permanent_cdr = class(ItemBaseClassBuff)

function modifier_sniper_swift_hands_custom_buff_permanent_cdr:GetTexture() return "gun_joe_rapid" end
function modifier_sniper_swift_hands_custom_buff_permanent_damage:GetTexture() return "gun_joe_rapid" end
-------------
function modifier_sniper_swift_hands_custom_buff_permanent_damage:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_sniper_swift_hands_custom_buff_permanent_damage:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
    }

    return funcs
end

function modifier_sniper_swift_hands_custom_buff_permanent_damage:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage_gain") * self:GetStackCount()
end
-------------
function modifier_sniper_swift_hands_custom_buff_permanent_cdr:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_sniper_swift_hands_custom_buff_permanent_cdr:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
    }

    return funcs
end

function modifier_sniper_swift_hands_custom_buff_permanent_cdr:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("cdr_gain") * self:GetStackCount()
end
-------------
function sniper_swift_hands_custom:GetIntrinsicModifierName()
    return "modifier_sniper_swift_hands_custom"
end


function modifier_sniper_swift_hands_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_sniper_swift_hands_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_sniper_swift_hands_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()
    local isRifleStance = parent:HasModifier("modifier_gun_joe_rifle")
    local isMachineGunStance = parent:HasModifier("modifier_gun_joe_machine_gun")

    if isRifleStance then
        local buff = unit:FindModifierByNameAndCaster("modifier_sniper_swift_hands_custom_buff_permanent_damage", unit)
        local stacks = unit:GetModifierStackCount("modifier_sniper_swift_hands_custom_buff_permanent_damage", unit)
        
        if not buff then
            unit:AddNewModifier(unit, ability, "modifier_sniper_swift_hands_custom_buff_permanent_damage", {})
        else
            buff:ForceRefresh()
        end

        unit:SetModifierStackCount("modifier_sniper_swift_hands_custom_buff_permanent_damage", unit, (stacks + 1))
    end
    ---------
    if isMachineGunStance then
        local buffcdr = unit:FindModifierByNameAndCaster("modifier_sniper_swift_hands_custom_buff_permanent_cdr", unit)
        local stackscdr = unit:GetModifierStackCount("modifier_sniper_swift_hands_custom_buff_permanent_cdr", unit)
        local buffcdr_max = ability:GetSpecialValueFor("max_stacks_cdr")
        
        if not buffcdr then
            unit:AddNewModifier(unit, ability, "modifier_sniper_swift_hands_custom_buff_permanent_cdr", {})
        else
            buffcdr:ForceRefresh()
        end

        local buffcdr = unit:FindModifierByNameAndCaster("modifier_sniper_swift_hands_custom_buff_permanent_cdr", unit)
        unit:SetModifierStackCount("modifier_sniper_swift_hands_custom_buff_permanent_cdr", unit, (stackscdr + 1))
    end
end