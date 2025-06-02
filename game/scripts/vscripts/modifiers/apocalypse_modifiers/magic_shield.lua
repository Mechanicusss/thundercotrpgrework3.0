LinkLuaModifier("modifier_apocalypse_magic_shield", "modifiers/apocalypse_modifiers/magic_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_magic_shield_buff", "modifiers/apocalypse_modifiers/magic_shield", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_magic_shield = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_magic_shield = class(ItemBaseClass)

modifier_apocalypse_magic_shield_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

function modifier_apocalypse_magic_shield:GetIntrinsicModifierName()
    return "modifier_apocalypse_magic_shield"
end

function modifier_apocalypse_magic_shield:GetTexture() return "magicshield" end
function modifier_apocalypse_magic_shield_buff:GetTexture() return "magicshield" end
-------------
function modifier_apocalypse_magic_shield:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_apocalypse_magic_shield_buff", {})
end
-------------
function modifier_apocalypse_magic_shield_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK 
    }
end

function modifier_apocalypse_magic_shield_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.shield = parent:GetMaxHealth() * 0.4

    self.particle = ParticleManager:CreateParticle("particles/items2_fx/pipe_of_insight.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.particle, 2, Vector(parent:GetModelRadius() * 1.1,0,0))
end

function modifier_apocalypse_magic_shield_buff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_apocalypse_magic_shield_buff:GetModifierMagical_ConstantBlock(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.target ~= parent then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end

    local toRemove = self.shield - event.damage 

    self.shield = toRemove

    if self.shield <= 0 then
        self:Destroy()
        return
    end

    return self.shield
end