LinkLuaModifier("modifier_item_spirit_otchim", "items/item_spirit_otchim", LUA_MODIFIER_MOTION_NONE)

item_spirit_otchim = class({})

function item_spirit_otchim:GetIntrinsicModifierName()
    return "modifier_item_spirit_otchim"
end

modifier_item_spirit_otchim = class({})

function modifier_item_spirit_otchim:IsHidden() return false end  -- Изменено на false, чтобы показывать модификатор
function modifier_item_spirit_otchim:IsPurgable() return false end
function modifier_item_spirit_otchim:RemoveOnDeath() return false end

function modifier_item_spirit_otchim:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_TOOLTIP,  -- Добавлено для отображения подсказки
    }
end

function modifier_item_spirit_otchim:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local attacker = event.attacker 
    local target = event.unit 

    if parent ~= attacker then return end 
    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    -- Увеличиваем атрибуты владельца
    local strength_bonus = ability:GetSpecialValueFor("strength_bonus")
    local intellect_bonus = ability:GetSpecialValueFor("intellect_bonus")
    local agility_bonus = ability:GetSpecialValueFor("agility_bonus")

    parent:ModifyStrength(strength_bonus)
    parent:ModifyIntellect(intellect_bonus)
    parent:ModifyAgility(agility_bonus)

    -- Увеличиваем количество стаков
    self:SetStackCount(self:GetStackCount() + 1)
end

function modifier_item_spirit_otchim:OnTooltip()
    return self:GetStackCount()  -- Возвращаем количество стаков для отображения в подсказке
end