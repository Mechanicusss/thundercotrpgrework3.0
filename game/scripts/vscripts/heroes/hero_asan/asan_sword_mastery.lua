LinkLuaModifier("modifier_asan_sword_mastery", "heroes/hero_asan/asan_sword_mastery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_sword_mastery_charges", "heroes/hero_asan/asan_sword_mastery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_sword_mastery_effect", "heroes/hero_asan/asan_sword_mastery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_sword_mastery_scepter", "heroes/hero_asan/asan_sword_mastery", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCharges = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

asan_sword_mastery = class(ItemBaseClass)
modifier_asan_sword_mastery = class(asan_sword_mastery)
modifier_asan_sword_mastery_charges = class(ItemBaseClassCharges)
modifier_asan_sword_mastery_effect = class(ItemBaseClassBuff)
modifier_asan_sword_mastery_scepter = class(ItemBaseClassBuff)
-------------
function asan_sword_mastery:GetIntrinsicModifierName()
    return "modifier_asan_sword_mastery"
end

function asan_sword_mastery:OnToggle()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    if self:GetToggleState() then
        EmitSoundOn("Hero_Terrorblade.Sunder.Cast", caster)
        caster:AddNewModifier(caster, self, "modifier_asan_sword_mastery_effect", {})

        if caster:HasScepter() then
            caster:AddNewModifier(caster, self, "modifier_asan_sword_mastery_scepter", {
                duration = self:GetSpecialValueFor("scepter_duration")
            })
        end
    else
        caster:RemoveModifierByName("modifier_asan_sword_mastery_effect")

        caster:RemoveModifierByName("modifier_asan_sword_mastery_scepter")
    end
end
-------------
function modifier_asan_sword_mastery:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_asan_sword_mastery:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    -- Don't gain stacks if ability is toggled
    if ability:GetToggleState() then return end

    local stacks = parent:FindModifierByName("modifier_asan_sword_mastery_charges")
    if not stacks then
        stacks = parent:AddNewModifier(parent, ability, "modifier_asan_sword_mastery_charges", {})
    end

    if stacks then
        local count = ability:GetSpecialValueFor("stack_gain")

        local talent = parent:FindAbilityByName("talent_elder_titan_2")
        if talent ~= nil and talent:GetLevel() > 0 then
            count = count + talent:GetSpecialValueFor("bonus_stack_per_kill")
        end
        
        local amount = stacks:GetStackCount()+count

        stacks:SetStackCount(amount)
        stacks:ForceRefresh()
    end
end
-----------------------
function modifier_asan_sword_mastery_charges:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_TOOLTIP,
    }
end

function modifier_asan_sword_mastery_charges:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    if not ability:GetToggleState() then return end 

    local amount = self:GetStackCount()-ability:GetSpecialValueFor("stack_loss")

    local talent = parent:FindAbilityByName("talent_elder_titan_2")
    if talent ~= nil and talent:GetLevel() > 1 then
        amount = self:GetStackCount()

        if talent:GetLevel() > 2 then
            ApplyDamage({
                victim = target,
                attacker = parent,
                damage = event.damage * (talent:GetSpecialValueFor("pure_damage_pct")/100),
                damage_type = DAMAGE_TYPE_PURE,
                ability = ability
            })
        end
    end

    if amount < 0 then
        amount = 0
    end

    self:SetStackCount(amount)
    self:ForceRefresh()

    if self:GetStackCount() <= 0 then
        self:Destroy()
    end
end

function modifier_asan_sword_mastery_charges:GetModifierDamageOutgoing_Percentage()
    if self:GetAbility():GetToggleState() then
        return self:GetAbility():GetSpecialValueFor("pct_increase_per_charge") * self:GetStackCount()
    end
end

function modifier_asan_sword_mastery_charges:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("pct_increase_per_charge") * self:GetStackCount()
end
------------------------
function modifier_asan_sword_mastery_effect:IsHidden() return true end 

function modifier_asan_sword_mastery_effect:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.agility = 0

    if parent:HasScepter() then
        local stack = parent:FindModifierByName("modifier_asan_sword_mastery_charges")
        if stack and stack:GetStackCount() > 0 then
            self.agility = parent:GetAgility() * (self:GetAbility():GetSpecialValueFor("scepter_agility_increase")/100) * stack:GetStackCount()
        end
    end

    self.buffEffect = ParticleManager:CreateParticle( "particles/econ/items/phantom_assassin/pa_fall20_immortal_shoulders/pa_fall20_blur_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.buffEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
end

function modifier_asan_sword_mastery_effect:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.buffEffect ~= nil then
        ParticleManager:DestroyParticle(self.buffEffect, true)
        ParticleManager:ReleaseParticleIndex(self.buffEffect)
    end
end
-------------------
function modifier_asan_sword_mastery_scepter:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.agility = 0

    if parent:HasScepter() then
        local stack = parent:FindModifierByName("modifier_asan_sword_mastery_charges")
        if stack and stack:GetStackCount() > 0 then
            self.agility = parent:GetAgility() * (self:GetAbility():GetSpecialValueFor("scepter_agility_increase")/100) * stack:GetStackCount()
        end
    end
end

function modifier_asan_sword_mastery_scepter:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_asan_sword_mastery_scepter:GetModifierBonusStats_Agility()
    return self.agility
end