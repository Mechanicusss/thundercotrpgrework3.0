LinkLuaModifier("modifier_ursa_fury_swipes_custom", "heroes/hero_ursa/fury_swipes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_fury_swipes_custom_buff_permanent", "heroes/hero_ursa/fury_swipes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_fury_swipes_custom_swipe", "heroes/hero_ursa/fury_swipes", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

ursa_fury_swipes_custom = class(ItemBaseClass)
modifier_ursa_fury_swipes_custom = class(ursa_fury_swipes_custom)
modifier_ursa_fury_swipes_custom_buff_permanent = class(ItemBaseClassBuff)
modifier_ursa_fury_swipes_custom_swipe = class(ItemBaseClassDebuff)

function modifier_ursa_fury_swipes_custom_buff_permanent:GetTexture() return "swipes" end
function modifier_ursa_fury_swipes_custom_swipe:GetTexture() return "swipes" end
-------------
function modifier_ursa_fury_swipes_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ursa_fury_swipes_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        
    }

    return funcs
end

function modifier_ursa_fury_swipes_custom_buff_permanent:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_ursa_fury_swipes_custom_buff_permanent:OnTooltip()
    return ((self:GetAbility():GetSpecialValueFor("dmg_per_stack_increase_permanent") * self:GetStackCount()))
end
-------------
function ursa_fury_swipes_custom:GetIntrinsicModifierName()
    return "modifier_ursa_fury_swipes_custom"
end


function modifier_ursa_fury_swipes_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
    }
    return funcs
end

function modifier_ursa_fury_swipes_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()
    if not event.unit:HasModifier("modifier_ursa_fury_swipes_custom_swipe") then return end

    local buff = unit:FindModifierByNameAndCaster("modifier_ursa_fury_swipes_custom_buff_permanent", unit)
    local stacks = unit:GetModifierStackCount("modifier_ursa_fury_swipes_custom_buff_permanent", unit)
    
    if not buff then
        unit:AddNewModifier(unit, ability, "modifier_ursa_fury_swipes_custom_buff_permanent", {})
    else
        buff:ForceRefresh()
    end

    unit:SetModifierStackCount("modifier_ursa_fury_swipes_custom_buff_permanent", unit, (stacks + 1))
end

function modifier_ursa_fury_swipes_custom:OnCreated( kv )
    if IsServer() then
        -- get reference
        self.damage_per_stack = self:GetAbility():GetSpecialValueFor("damage_per_stack")
        self.bonus_reset_time = self:GetAbility():GetSpecialValueFor("bonus_reset_time")
        self.bonus_reset_time_roshan = self:GetAbility():GetSpecialValueFor("bonus_reset_time_roshan")
        self.permanent_stack_damage = self:GetAbility():GetSpecialValueFor("dmg_per_stack_increase_permanent")
    end
end

function modifier_ursa_fury_swipes_custom:OnRefresh( kv )
    if IsServer() then
        -- get reference
        self.damage_per_stack = self:GetAbility():GetSpecialValueFor("damage_per_stack")
        self.bonus_reset_time = self:GetAbility():GetSpecialValueFor("bonus_reset_time")
        self.bonus_reset_time_roshan = self:GetAbility():GetSpecialValueFor("bonus_reset_time_roshan")
        self.permanent_stack_damage = self:GetAbility():GetSpecialValueFor("dmg_per_stack_increase_permanent")
    end
end

function modifier_ursa_fury_swipes_custom:GetModifierProcAttack_BonusDamage_Physical(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        -- get modifier stack
        local stack = 0
        local permanentStack = 0
        local permanentModifier = self:GetAbility():GetCaster():FindModifierByNameAndCaster("modifier_ursa_fury_swipes_custom_buff_permanent", self:GetAbility():GetCaster())
        local modifier = target:FindModifierByNameAndCaster("modifier_ursa_fury_swipes_custom_swipe", self:GetAbility():GetCaster())

        -- add stack if not
        if modifier==nil then
            -- if does not have break
            if not self:GetParent():PassivesDisabled() then
                -- determine duration if roshan/not
                local _duration = self.bonus_reset_time
                if params.target:GetUnitName()=="npc_dota_creature_roshan_boss" then
                    _duration = self.bonus_reset_time_roshan
                end

                -- add modifier
                local _mod = target:AddNewModifier(
                    self:GetAbility():GetCaster(),
                    self:GetAbility(),
                    "modifier_ursa_fury_swipes_custom_swipe",
                    { duration = _duration }
                )

                if self:GetAbility():IsCooldownReady() then
                    _mod:IncrementStackCount()
                end

                -- get stack number
                stack = 1

                self:GetAbility():UseResources(false, false, false, true)
            end
        else
            if self:GetAbility():IsCooldownReady() then
                -- increase stack
                modifier:IncrementStackCount()
                self:GetAbility():UseResources(false, false, false, true)
            end

            modifier:ForceRefresh()

            -- get stack number
            stack = modifier:GetStackCount()
        end

        if permanentModifier ~= nil then
            permanentStack = permanentModifier:GetStackCount()
            permanentModifier:ForceRefresh()
        end

        -- return damage bonus
        local total = stack * (self.damage_per_stack+(self.permanent_stack_damage * permanentStack))
        if self:GetCaster():HasScepter() and self:GetCaster():HasModifier("modifier_ursa_enrage") then
            total = total * self:GetAbility():GetSpecialValueFor("scepter_multiplier")
        end
        
        return total
    end
end
-------------
function modifier_ursa_fury_swipes_custom_swipe:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ursa_fury_swipes_custom_swipe:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_ursa_fury_swipes_custom_swipe:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self.stack = self:GetStackCount()
    self.permanentStack = 0

    self:OnRefresh()
end

function modifier_ursa_fury_swipes_custom_swipe:OnRefresh()
    self.stack = self:GetStackCount()

    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local permanentModifier = caster:FindModifierByNameAndCaster("modifier_ursa_fury_swipes_custom_buff_permanent", caster)

    self.permanentStack = 0

    if permanentModifier ~= nil then
        self.permanentStack = permanentModifier:GetStackCount()
    end

    self:InvokeBonusDamage()
end

function modifier_ursa_fury_swipes_custom_swipe:OnTooltip()
    return self:GetStackCount() * (self:GetAbility():GetSpecialValueFor("damage_per_stack")+(self:GetAbility():GetSpecialValueFor("dmg_per_stack_increase_permanent") * self.fPermanentStack))
end

function modifier_ursa_fury_swipes_custom_swipe:AddCustomTransmitterData()
    return
    {
        permanentStack = self.fPermanentStack,
    }
end

function modifier_ursa_fury_swipes_custom_swipe:HandleCustomTransmitterData(data)
    if data.permanentStack ~= nil then
        self.fPermanentStack = tonumber(data.permanentStack)
    end
end

function modifier_ursa_fury_swipes_custom_swipe:InvokeBonusDamage()
    if IsServer() == true then
        self.fPermanentStack = self.permanentStack

        self:SendBuffRefreshToClients()
    end
end