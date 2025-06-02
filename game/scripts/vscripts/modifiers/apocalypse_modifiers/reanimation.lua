LinkLuaModifier("modifier_apocalypse_reanimation", "modifiers/apocalypse_modifiers/reanimation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_reanimation_reanimated", "modifiers/apocalypse_modifiers/reanimation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_reanimation_prevent_death", "modifiers/apocalypse_modifiers/reanimation", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassReanimated = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_reanimation = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_reanimation = class(ItemBaseClass)
modifier_apocalypse_reanimation_reanimated = class(ItemBaseClassReanimated)
modifier_apocalypse_reanimation_prevent_death = class(ItemBaseClass)

function modifier_apocalypse_reanimation_prevent_death:IsHidden() return true end

function modifier_apocalypse_reanimation:GetIntrinsicModifierName()
    return "modifier_apocalypse_reanimation"
end

function modifier_apocalypse_reanimation:GetTexture() return "skeleton_king_reincarnation" end
function modifier_apocalypse_reanimation_reanimated:GetTexture() return "skeleton_king_reincarnation" end
-------------


function modifier_apocalypse_reanimation:OnCreated()
    if not IsServer() then return end 

    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_apocalypse_reanimation_prevent_death", {})

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_apocalypse_reanimation:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetHealth() <= 1 and not parent:HasModifier("modifier_apocalypse_reanimation_prevent_death") then
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_apocalypse_reanimation_reanimated", {})

        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end

    if parent:GetHealth() <= 1 and parent:HasModifier("modifier_apocalypse_reanimation_prevent_death") then
        parent:RemoveModifierByName("modifier_apocalypse_reanimation_prevent_death")
    end
end

function modifier_apocalypse_reanimation_prevent_death:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MIN_HEALTH,  
    }

    return funcs
end

function modifier_apocalypse_reanimation_prevent_death:GetMinHealth(event)
    return 1
end
--------------------
function modifier_apocalypse_reanimation_reanimated:GetEffectName()
    return "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf"
end

function modifier_apocalypse_reanimation_reanimated:OnCreated()
    if not IsServer() then return end

    self.oldScale = self:GetParent():GetModelScale()
    self.oldColor = self:GetParent():GetRenderColor()

    self:GetParent():SetModelScale(self:GetParent():GetModelScale() * 1.20)
    self:GetParent():SetRenderColor(0, 255, 0)

    self:GetParent():ModifyHealth(self:GetParent():GetMaxHealth() * 0.4, self:GetAbility(), false, -1)
end

function modifier_apocalypse_reanimation_reanimated:OnRemoved()
    if not IsServer() then return end

    self:GetParent():SetModelScale(self.oldScale)
    self:GetParent():SetRenderColor(self.oldColor.r, self.oldColor.g, self.oldColor.b)
end