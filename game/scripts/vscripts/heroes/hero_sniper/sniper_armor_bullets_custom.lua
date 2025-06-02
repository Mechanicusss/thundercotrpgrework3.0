LinkLuaModifier("modifier_sniper_armor_bullets_custom", "heroes/hero_sniper/sniper_armor_bullets_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_armor_bullets_custom_active", "heroes/hero_sniper/sniper_armor_bullets_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_armor_bullets_custom_debuff", "heroes/hero_sniper/sniper_armor_bullets_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

sniper_armor_bullets_custom = class(ItemBaseClass)
modifier_sniper_armor_bullets_custom = class(sniper_armor_bullets_custom)
modifier_sniper_armor_bullets_custom_active = class(ItemBaseClassBuff)
modifier_sniper_armor_bullets_custom_debuff = class(ItemBaseClassDebuff)
-------------
function sniper_armor_bullets_custom:GetIntrinsicModifierName()
    return "modifier_sniper_armor_bullets_custom"
end

function sniper_armor_bullets_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")
    local charges = self:GetSpecialValueFor("charges")

    local mod = caster:AddNewModifier(
        caster,
        self,
        "modifier_sniper_armor_bullets_custom_active",
        {
            duration = duration
        }
    )

    if mod then
        mod:SetStackCount(charges)
    end

    EmitSoundOn("Hero_Sniper.TakeAim.Cast", caster)
end
-----------
function modifier_sniper_armor_bullets_custom_active:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY 
    }
end

function modifier_sniper_armor_bullets_custom_active:OnCreated()
    self.record = nil
end

function modifier_sniper_armor_bullets_custom_active:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    if self.record ~= nil then
        self.record:RemoveModifierByName("modifier_sniper_armor_bullets_custom_debuff")

        self.record = nil
    end

    if self:GetStackCount() < 1 then
        self:Destroy()
    end
end

function modifier_sniper_armor_bullets_custom_active:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = event.attacker

    if parent ~= attacker then return end

    local target = event.target

    if parent == target then return end

    EmitSoundOn("Hero_Snapfire.ExplosiveShellsBuff.Attack", parent)
end

function modifier_sniper_armor_bullets_custom_active:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = event.attacker

    if parent ~= attacker then return end

    local target = event.target

    if parent == target then return end

    self.record = target

    EmitSoundOn("Hero_Snapfire.ExplosiveShellsBuff.Target", target)
    
    target:AddNewModifier(parent, self:GetAbility(), "modifier_sniper_armor_bullets_custom_debuff", {})

    self:DecrementStackCount()
end
-----------------
function modifier_sniper_armor_bullets_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR,
    }
end

function modifier_sniper_armor_bullets_custom_debuff:GetModifierIgnorePhysicalArmor()
    if IsServer() then
        return 1
    end
end