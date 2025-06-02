item_auto_buy = class({})

function item_auto_buy:GetIntrinsicModifierName()
    return "modifier_item_auto_buy"
end

function item_auto_buy:OnCreated()
    if not IsServer() then return end
    if not self.stacks then
        self.stacks = 0
    end
end

function item_auto_buy:GetStacks()
    return self.stacks or 0
end

function item_auto_buy:SetStacks(value)
    self.stacks = value
    
    if not self:IsNull() then
        local caster = self:GetCaster()
        if caster then
            local modifier = caster:FindModifierByName("modifier_item_auto_buy")
            if modifier and modifier:GetAbility() == self then
                modifier:SetStackCount(value)
            end
        end
    end
end

function item_auto_buy:OnDestroy()
    if IsServer() then
        local caster = self:GetCaster()
        if caster then
            -- Сохраняем количество стеков на герое
            caster.item_auto_buy_stacks = self:GetStacks()
        end
    end
end

--------------------------------------------------------------------

LinkLuaModifier("modifier_item_auto_buy", "items/custom/item_auto_buy", LUA_MODIFIER_MOTION_NONE)

modifier_item_auto_buy = class({})

function modifier_item_auto_buy:IsHidden() return false end
function modifier_item_auto_buy:IsPurgable() return false end
function modifier_item_auto_buy:RemoveOnDeath() return false end
function modifier_item_auto_buy:IsPermanent() return true end

function modifier_item_auto_buy:OnCreated()
    if not IsServer() then return end
    
    self.ability = self:GetAbility()
    if not self.ability or self.ability:IsNull() then return end
    
    self.caster = self:GetCaster()
    self.interval = self.ability:GetSpecialValueFor("interval")
    self.gold_cost = self.ability:GetSpecialValueFor("gold_cost")
    self.atri_per_stack = self.ability:GetSpecialValueFor("atri_purshas")
    
    -- Установка начального количества стеков
    if self.caster.item_auto_buy_stacks then
        self.ability:SetStacks(self.caster.item_auto_buy_stacks)
    elseif self.ability.stacks then
        self:SetStackCount(self.ability.stacks)
    else
        self.ability.stacks = 0
        self:SetStackCount(0)
    end
    
    self:StartIntervalThink(self.interval)
end

function modifier_item_auto_buy:OnIntervalThink()
    if not IsServer() then return end
    if not self.ability or self.ability:IsNull() then return end
    if not self.caster then return end
    
    if self.caster:GetGold() >= self.gold_cost then
        self.caster:ModifyGold(-self.gold_cost, false, 0)
        
        self.ability:SetStacks(self.ability:GetStacks() + 1)
    end
end

function modifier_item_auto_buy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_item_auto_buy:GetModifierBonusStats_Strength()
    return self.caster.item_auto_buy_stacks * self.atri_per_stack
end

function modifier_item_auto_buy:GetModifierBonusStats_Agility()
    return self.caster.item_auto_buy_stacks * self.atri_per_stack
end

function modifier_item_auto_buy:GetModifierBonusStats_Intellect()
    return self.caster.item_auto_buy_stacks * self.atri_per_stack
end