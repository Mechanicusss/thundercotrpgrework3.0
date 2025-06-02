LinkLuaModifier("modifier_lycan_wolf_bite_custom", "heroes/hero_lycan/bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_wolf_bite_custom_buff", "heroes/hero_lycan/bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_wolf_bite_custom_debuff", "heroes/hero_lycan/bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_wolf_bite_custom_debuff_leech", "heroes/hero_lycan/bite", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassdeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

lycan_wolf_bite_custom = class(ItemBaseClass)
modifier_lycan_wolf_bite_custom = class(lycan_wolf_bite_custom)
modifier_lycan_wolf_bite_custom_debuff = class(ItemBaseClassdeBuff)
modifier_lycan_wolf_bite_custom_debuff_leech = class(ItemBaseClassdeBuff)
modifier_lycan_wolf_bite_custom_buff = class(ItemBaseClassBuff)
-------------
function lycan_wolf_bite_custom:GetIntrinsicModifierName()
    return "modifier_lycan_wolf_bite_custom"
end

function modifier_lycan_wolf_bite_custom:OnCreated()
    if not IsServer() then return end

    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lycan_wolf_bite_custom_buff", {})
end
--
function modifier_lycan_wolf_bite_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_lycan_wolf_bite_custom_buff:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.attacker:GetUnitName() ~= "npc_dota_lycan_wolf_custom1" then
        if not event.attacker:HasScepter() then return end
        if not event.attacker:HasModifier("modifier_lycan_shapeshift_custom_buff") then return end
    else
        if not event.attacker:GetOwner():HasScepter() then return end
    end

    local victim = event.target

    local mod = victim:FindModifierByName("modifier_lycan_wolf_bite_custom_debuff")
    if mod == nil then
        mod = victim:AddNewModifier(event.attacker, self:GetAbility(), "modifier_lycan_wolf_bite_custom_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("stacks_proc") then
        mod:IncrementStackCount()
    end

    mod:ForceRefresh()
end
--
function modifier_lycan_wolf_bite_custom_debuff:OnCreated()
    if not IsServer() then return end
    self.cooldown = false
end

function modifier_lycan_wolf_bite_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  
    }

    return funcs
end

function modifier_lycan_wolf_bite_custom_debuff:OnCreated()
    if not IsServer() then end

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
end

function modifier_lycan_wolf_bite_custom_debuff:OnRefresh()
    if not IsServer() then return end

    local stacks = self:GetStackCount()
    local ability = self:GetAbility()
    local maxStacks = ability:GetSpecialValueFor("stacks_proc")

    if stacks >= maxStacks and not self.cooldown then
        self.parent:AddNewModifier(self.caster, ability, "modifier_lycan_wolf_bite_custom_debuff_leech", {
            duration = ability:GetSpecialValueFor("leech_duration")
        })

        self.cooldown = true
        Timers:CreateTimer(ability:GetSpecialValueFor("leech_cooldown"), function()
            self.cooldown = false
        end)
    end
    -- check for max stacks here and apply hp leech
end

function modifier_lycan_wolf_bite_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("disarmor_per_hit") * self:GetStackCount()
end

function modifier_lycan_wolf_bite_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
----------
function modifier_lycan_wolf_bite_custom_debuff_leech:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_lycan_wolf_bite_custom_debuff_leech:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_life_stealer/life_stealer_open_wounds.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetAbsOrigin() )

    EmitSoundOn("Hero_LifeStealer.OpenWounds.Cast", parent)
end

function modifier_lycan_wolf_bite_custom_debuff_leech:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_lycan_wolf_bite_custom_debuff_leech:OnAttackLanded(event)
    if not IsServer() then return end

    if event.target ~= self:GetParent() then return end

    local attacker = event.attacker

    local healing = event.target:GetHealth() * (self:GetAbility():GetSpecialValueFor("target_heal_hp_pct")/100)

    attacker:Heal(healing, self:GetAbility())
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        attacker,
        healing,
        nil
    )
end

function modifier_lycan_wolf_bite_custom_debuff_leech:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("leech_slow_pct")
end