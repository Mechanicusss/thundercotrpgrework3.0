LinkLuaModifier("modifier_item_heavens_counter", "items/item_heavens_counter/item_heavens_counter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heavens_counter_disarm", "items/item_heavens_counter/item_heavens_counter", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassProc = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_heavens_counter = class(ItemBaseClass)
item_heavens_counter_2 = item_heavens_counter
item_heavens_counter_3 = item_heavens_counter
item_heavens_counter_4 = item_heavens_counter
item_heavens_counter_5 = item_heavens_counter
item_heavens_counter_6 = item_heavens_counter
item_heavens_counter_7 = item_heavens_counter
item_heavens_counter_8 = item_heavens_counter
item_heavens_counter_9 = item_heavens_counter
modifier_item_heavens_counter = class(item_heavens_counter)
modifier_item_heavens_counter_disarm = class(ItemBaseClassDebuff)
-------------
function item_heavens_counter:GetIntrinsicModifierName()
    return "modifier_item_heavens_counter"
end

function item_heavens_counter:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    local caster = self:GetCaster()

    target:AddNewModifier(caster, self, "modifier_item_heavens_counter_disarm", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("DOTA_Item.HeavensHalberd.Activate", target)
end
----------
function modifier_item_heavens_counter:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE (dont use this, will instakill centaur with return)
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT
    }
end

function modifier_item_heavens_counter:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.target ~= parent or event.attacker == parent then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end

    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    EmitSoundOn("Hero_Pangolier.LuckyShot.Proc", parent)

    ApplyDamage({
        attacker = parent,
        victim = event.attacker,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage = event.damage,
        ability = ability
    })

    return -event.damage
end

function modifier_item_heavens_counter:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heavens_counter:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_heavens_counter:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
end

function modifier_item_heavens_counter:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_regen_amp")
end

function modifier_item_heavens_counter:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_regen_amp")
end
----------
function modifier_item_heavens_counter_disarm:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end

function modifier_item_heavens_counter_disarm:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/items2_fx/heavens_halberd.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetOrigin() )
end

function modifier_item_heavens_counter_disarm:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end