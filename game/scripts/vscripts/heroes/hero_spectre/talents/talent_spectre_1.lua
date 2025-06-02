LinkLuaModifier("modifier_talent_spectre_1", "heroes/hero_spectre/talents/talent_spectre_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_spectre_1 = class(ItemBaseClass)
modifier_talent_spectre_1 = class(talent_spectre_1)
-------------
function talent_spectre_1:GetIntrinsicModifierName()
    return "modifier_talent_spectre_1"
end
-------------
function modifier_talent_spectre_1:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.reality = parent:FindAbilityByName("spectre_reality_custom")

    if not self.reality then
        self.reality = parent:AddAbility("spectre_reality_custom")
    end

    if self.reality then
        self.reality:SetLevel(1)
        self.reality:SetActivated(false)
        self.reality:SetHidden(false)
    end

    self:StartIntervalThink(FrameTime())
end

function modifier_talent_spectre_1:OnIntervalThink()
    local parent = self:GetParent()

    if not self.reality then return end

    if not parent:HasModifier("modifier_spectre_spectral_dagger_custom") and self.reality:IsActivated() then
        self.reality:SetActivated(false)
    elseif parent:HasModifier("modifier_spectre_spectral_dagger_custom") and not self.reality:IsActivated() then
        self.reality:SetActivated(true)
    end
end

function modifier_talent_spectre_1:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.reality then
        self.reality:SetActivated(false)
        self.reality:SetHidden(true)
    end
end