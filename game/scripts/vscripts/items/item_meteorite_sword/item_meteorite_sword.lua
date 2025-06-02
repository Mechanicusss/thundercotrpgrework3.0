LinkLuaModifier("modifier_item_meteorite_sword", "items/item_meteorite_sword/item_meteorite_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_meteorite_sword_active", "items/item_meteorite_sword/item_meteorite_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_invoker_chaos_meteor_lua_thinker", "items/item_meteorite_sword/item_meteorite_sword_chaos_meteor_modifier_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_invoker_chaos_meteor_lua_burn", "items/item_meteorite_sword/item_meteorite_sword_chaos_meteor_modifier_burn", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_meteorite_sword = class(ItemBaseClass)
modifier_item_meteorite_sword = class(item_meteorite_sword)
modifier_item_meteorite_sword_active = class(ItemBaseClassActive)
-------------
function item_meteorite_sword:GetIntrinsicModifierName()
    return "modifier_item_meteorite_sword"
end

function item_meteorite_sword:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_meteorite_sword_active") then
        caster:RemoveModifierByName("modifier_item_meteorite_sword_active")
    end

    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_item_meteorite_sword_active", {
        duration = duration
    })
end

function modifier_item_meteorite_sword:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_BONUS, --GetModifierManaBonus
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_item_meteorite_sword:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker or attacker == victim then
        return
    end

    if not attacker:IsRealHero() or attacker:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() then return end
    if victim:IsMagicImmune() or (not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim)) or victim:IsBuilding() then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end 

    local point = victim:GetAbsOrigin()

    CreateModifierThinker(
        attacker, -- player source
        ability, -- ability source
        "modifier_invoker_chaos_meteor_lua_thinker", -- modifier name
        {}, -- kv
        point,
        attacker:GetTeamNumber(),
        false
    )
end

function modifier_item_meteorite_sword:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_meteorite_sword:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_meteorite_sword:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end
--------------
function modifier_item_meteorite_sword_active:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    
    self.radius = self.ability:GetSpecialValueFor("radius")
    
    local interval = self.ability:GetSpecialValueFor("interval")
    
    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_item_meteorite_sword_active:OnIntervalThink()
    local point = self.caster:GetAbsOrigin()
    local randomPos = Vector(point.x+RandomInt(-self.radius, self.radius), point.y+RandomInt(-self.radius, self.radius), point.z)

    CreateModifierThinker(
        self.caster, -- player source
        self.ability, -- ability source
        "modifier_invoker_chaos_meteor_lua_thinker", -- modifier name
        {}, -- kv
        randomPos,
        self.caster:GetTeamNumber(),
        false
    )
end