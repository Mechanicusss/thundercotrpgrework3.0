LinkLuaModifier("modifier_talent_bloodseeker_1", "heroes/hero_bloodseeker/talents/talent_bloodseeker_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_bloodseeker_1 = class(ItemBaseClass)
modifier_talent_bloodseeker_1 = class(talent_bloodseeker_1)
-------------
function talent_bloodseeker_1:GetIntrinsicModifierName()
    return "modifier_talent_bloodseeker_1"
end
-------------
function modifier_talent_bloodseeker_1:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")
    
    self:StartIntervalThink(0.3)
end

function modifier_talent_bloodseeker_1:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    -- Level 1 has a chance to cast ritual on an interval
    if not ability or (ability ~= nil and ability:GetLevel() < 1) then return end

    self.mist = parent:FindAbilityByName("bloodseeker_blood_mist_custom")
    if not self.mist or (self.mist ~= nil and self.mist:GetLevel() < 1) then return end 

    self.ritual = parent:FindAbilityByName("bloodseeker_ritual_custom")
    if not self.ritual or (self.ritual ~= nil and self.ritual:GetLevel() < 1) then return end 

    if not self.mist:GetToggleState() then return end

    local chance = ability:GetSpecialValueFor("chance")
    if not RollPercentage(chance) then return end 

    if ability:GetLevel() < 2 then
        if self.ritual:IsCooldownReady() then
            SpellCaster:Cast(self.ritual, parent:GetAbsOrigin(), true)
        end
    end

    if ability:GetLevel() > 2 then
        SpellCaster:Cast(self.ritual, parent:GetAbsOrigin(), false)
    end
end

function modifier_talent_bloodseeker_1:OnDestroy()
    if not IsServer() then return end 

    self:StartIntervalThink(-1)
end