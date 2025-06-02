LinkLuaModifier("modifier_legion_commander_duel_custom", "legion_commander_duel_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_duel_custom_buff", "legion_commander_duel_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_duel_custom_window", "legion_commander_duel_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_duel_custom_window_cooldown", "legion_commander_duel_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_duel_custom_window_boost", "legion_commander_duel_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuffWindow = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDeBuffWindow = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

legion_commander_duel_custom = class(ItemBaseClass)
modifier_legion_commander_duel_custom = class(legion_commander_duel_custom)
modifier_legion_commander_duel_custom_buff = class(ItemBaseClassBuff)
modifier_legion_commander_duel_custom_window = class(ItemBaseClassBuffWindow)
modifier_legion_commander_duel_custom_window_cooldown = class(ItemBaseClassDeBuffWindow)
modifier_legion_commander_duel_custom_window_boost = class(ItemBaseClassBuffWindow)

function modifier_legion_commander_duel_custom_window:GetTexture() return "duel" end
function modifier_legion_commander_duel_custom_window_boost:GetTexture() return "duel" end
-------------
function legion_commander_duel_custom:GetIntrinsicModifierName()
    return "modifier_legion_commander_duel_custom"
end

function legion_commander_duel_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING 
    end

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function legion_commander_duel_custom:GetManaCost()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return self:GetSpecialValueFor("active_mana_cost")
    end

    return 0
end

function legion_commander_duel_custom:GetCooldown()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return self:GetSpecialValueFor("active_cooldown")
    end

    return 0
end

function legion_commander_duel_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if not caster:HasScepter() then return end

    caster:RemoveModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", caster)
    caster:RemoveModifierByNameAndCaster("modifier_legion_commander_duel_custom_window_cooldown", caster)
    
    local boost = caster:AddNewModifier(caster, self, "modifier_legion_commander_duel_custom_window_boost", {
        duration = self:GetSpecialValueFor("active_duration")
    })
end

function modifier_legion_commander_duel_custom:OnCreated()
    if not IsServer() then return end
end

function modifier_legion_commander_duel_custom_buff:DeclareFunctions()
    local funcs = { 
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_legion_commander_duel_custom:DeclareFunctions()
    local funcs = { 
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_legion_commander_duel_custom:OnDeath(event)
    if not IsServer() then return end
    if event.attacker ~= self:GetParent() or event.unit == self:GetParent() then return end

    local parent = self:GetParent()

    if not parent:HasModifier("modifier_legion_commander_duel_custom_window_cooldown") then
        local window = parent:FindModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", parent)
        if window == nil then
            if parent:HasModifier("modifier_legion_commander_duel_custom_window_boost") then
                window = parent:AddNewModifier(parent, self:GetAbility(), "modifier_legion_commander_duel_custom_window", {})
            else
                window = parent:AddNewModifier(parent, self:GetAbility(), "modifier_legion_commander_duel_custom_window", {
                    duration = self:GetAbility():GetSpecialValueFor("duration")
                })
            end
        end

        window:IncrementStackCount()
    end

    ---
    local buff = parent:FindModifierByName("modifier_legion_commander_duel_custom_buff")
    if buff == nil then
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_legion_commander_duel_custom_buff", {}):SetStackCount(self:GetAbility():GetSpecialValueFor("damage_per_kill"))
    else
        if not parent:HasModifier("modifier_legion_commander_duel_custom_window_cooldown") then
            local window = parent:FindModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", parent)
            if window ~= nil then 
                buff:SetStackCount(self:GetAbility():GetSpecialValueFor("damage_per_kill") + buff:GetStackCount() + (window:GetStackCount() * self:GetAbility():GetSpecialValueFor("kill_window_increase")))
            end
        else
            buff:SetStackCount(buff:GetStackCount() + self:GetAbility():GetSpecialValueFor("damage_per_kill"))
        end
    end

    if not parent:HasModifier("modifier_legion_commander_duel_custom_window_cooldown") and not parent:HasModifier("modifier_legion_commander_duel_custom_window_boost") then
        local window = parent:FindModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", parent)
        if window ~= nil then
            window:SetDuration(window:GetDuration() - self:GetAbility():GetSpecialValueFor("kill_window_shrink_time"), true)
            if window:GetDuration() <= 0 then
                parent:RemoveModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", parent)
            end
        end
    end
end

function modifier_legion_commander_duel_custom_buff:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount()
end

function modifier_legion_commander_duel_custom_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

----

function modifier_legion_commander_duel_custom_window:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_legion_commander_duel_custom_window:OnDestroy()
    if not IsServer() then return end

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_legion_commander_duel_custom_window_cooldown", {
        duration = self:GetAbility():GetSpecialValueFor("cooldown")
    })
end
----
function modifier_legion_commander_duel_custom_window_boost:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByNameAndCaster("modifier_legion_commander_duel_custom_window", caster)
end