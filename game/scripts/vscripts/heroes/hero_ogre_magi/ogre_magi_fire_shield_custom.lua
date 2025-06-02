LinkLuaModifier("modifier_ogre_magi_fire_shield_custom", "heroes/hero_ogre_magi/ogre_magi_fire_shield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ogre_magi_fire_shield_custom_absorb_state", "heroes/hero_ogre_magi/ogre_magi_fire_shield_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

ogre_magi_fire_shield_custom = class(ItemBaseClass)
modifier_ogre_magi_fire_shield_custom = class(ogre_magi_fire_shield_custom)
modifier_ogre_magi_fire_shield_custom_absorb_state = class(ItemBaseClassAbsorb)
-------------
function ogre_magi_fire_shield_custom:GetIntrinsicModifierName()
    return "modifier_ogre_magi_fire_shield_custom"
end

function ogre_magi_fire_shield_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local target = self:GetCursorTarget()

    EmitSoundOn("Hero_OgreMagi.FireShield.Cast", caster)

    if target:HasModifier("modifier_ogre_magi_fire_shield_custom_absorb_state") then
        target:RemoveModifierByName("modifier_ogre_magi_fire_shield_custom_absorb_state")
    end
    
    local buff = target:AddNewModifier(caster, ability, "modifier_ogre_magi_fire_shield_custom_absorb_state", { duration = duration })
    if buff then
        buff:SetStackCount(self:GetSpecialValueFor("attacks"))
    end
end
------------
function modifier_ogre_magi_fire_shield_custom_absorb_state:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, --GetModifierPhysical_ConstantBlock
         MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
         MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if victim ~= parent or attacker == parent then
        return
    end

    if not victim:IsAlive() or victim:IsIllusion() then
        return
    end

    local ability = caster:FindAbilityByName("ogre_magi_fireblast_custom")
    if not ability then return end
    if ability:GetLevel() < 1 then return end

    SpellCaster:Cast(ability, unit, false)
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:GetModifierPhysical_ConstantBlock(params)
    if params.inflictor then return 0 end
    if not IsCreepTCOTRPG(params.attacker) and not IsBossTCOTRPG(params.attacker) and not params.attacker:IsRealHero() then return end

    EmitSoundOn("Hero_OgreMagi.FireShield.Damage", self:GetParent())

    self:DecrementStackCount()
    if self:GetStackCount() < 1 then
        self:Destroy()
    end

    return params.damage * (1-(self:GetAbility():GetSpecialValueFor("damage_absorb_pct")/100))
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:GetModifierMagical_ConstantBlock(params)
    if not params.inflictor then return 0 end
    if not IsCreepTCOTRPG(params.attacker) and not IsBossTCOTRPG(params.attacker) and not params.attacker:IsRealHero() then return end

    EmitSoundOn("Hero_OgreMagi.FireShield.Damage", self:GetParent())

    self:DecrementStackCount()
    if self:GetStackCount() < 1 then
        self:Destroy()
    end

    return params.damage * (1-(self:GetAbility():GetSpecialValueFor("damage_absorb_pct")/100))
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:OnCreated(props)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    EmitSoundOn("Hero_OgreMagi.FireShield.Target", parent)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fire_shield.vpcf", PATTACH_CENTER_FOLLOW , parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_CENTER_FOLLOW , nil, parent:GetOrigin(), true)
    ParticleManager:SetParticleControl(self.particle, 1, Vector( 3, 0, 0 ))
    ParticleManager:SetParticleControl(self.particle, 9, Vector( 1, 0, 0 ))
    ParticleManager:SetParticleControl(self.particle, 10, Vector( 1, 0, 0 ))
    ParticleManager:SetParticleControl(self.particle, 11, Vector( 1, 0, 0 ))
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ogre_magi_fire_shield_custom_absorb_state:OnDestroy()
    if not IsServer() then return end

    if self.particle ~= nil then 
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle) 
    end
end