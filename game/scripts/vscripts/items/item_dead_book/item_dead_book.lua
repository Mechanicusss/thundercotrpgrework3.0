LinkLuaModifier("modifier_item_dead_book", "items/item_dead_book/item_dead_book", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dead_book_debuff", "items/item_dead_book/item_dead_book", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dead_book_aura", "items/item_dead_book/item_dead_book", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_dead_book = class(ItemBaseClass)
modifier_item_dead_book = class(ItemBaseClass)
modifier_item_dead_book_debuff = class(ItemBaseClassDebuff)
modifier_item_dead_book_aura = class(ItemBaseClassBuff)
-------------
function item_dead_book:GetIntrinsicModifierName()
    return "modifier_item_dead_book"
end

function modifier_item_dead_book:IsAura()
    return true
end

function modifier_item_dead_book:GetAuraSearchType()
    return DOTA_UNIT_TARGET_BASIC
end

function modifier_item_dead_book:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_dead_book:GetAuraRadius()
    return FIND_UNITS_EVERYWHERE
end

function modifier_item_dead_book:GetModifierAura()
    return "modifier_item_dead_book_aura"
end

function modifier_item_dead_book:GetAuraEntityReject(target)
    -- Reject non-summons
    if not IsSummonTCOTRPG(target) then return true end 

    -- Reject summons that don't belong to the wearer
    if target:GetOwner() ~= self:GetCaster() then return true end 
    
    return false
end

function modifier_item_dead_book_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_POST_CRIT,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }
    return funcs
end

function modifier_item_dead_book_aura:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    target:RemoveModifierByName("modifier_item_dead_book_debuff")
end



function modifier_item_dead_book_aura:OnCreated()
    if not IsServer() then return end
end

function modifier_item_dead_book_aura:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            
            local ability = self:GetAbility()
            local victimArmor = params.target:GetPhysicalArmorValue(false)
            local reducedArmor = victimArmor * (ability:GetSpecialValueFor("ignore_armor_pct")/100)
            
            params.target:AddNewModifier(self:GetCaster():GetOwner(), ability, "modifier_item_dead_book_debuff", {
                armor = -reducedArmor
            })

            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)
        end
    end
end

function modifier_item_dead_book_aura:GetModifierPreAttack_CriticalStrike(keys)
    local ability = self:GetAbility()
    local unit = self:GetParent()

    local crit = ability:GetSpecialValueFor("crit_chance")

    if RollPercentage(crit) then
        self.record = keys.record

        return ability:GetSpecialValueFor("crit_multiplier")
    end
end
-----------
function modifier_item_dead_book_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end


function modifier_item_dead_book_debuff:OnCreated(props)
    self.armor = props.armor
end

function modifier_item_dead_book_debuff:GetModifierPhysicalArmorBonus()
    if IsServer() then
        return self.armor
    end
end
----------
function modifier_item_dead_book:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_dead_book:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
    }
    return funcs
end