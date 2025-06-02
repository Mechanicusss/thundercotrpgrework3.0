LinkLuaModifier("modifier_riki_bladebreaker_order_custom", "heroes/hero_riki/riki_bladebreaker_order_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_bladebreaker_order_custom_buff", "heroes/hero_riki/riki_bladebreaker_order_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_bladebreaker_order_custom_buff_stack", "heroes/hero_riki/riki_bladebreaker_order_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

riki_bladebreaker_order_custom = class(BaseClass)
modifier_riki_bladebreaker_order_custom = class(riki_bladebreaker_order_custom)
modifier_riki_bladebreaker_order_custom_buff = class(BaseClassBuff)
modifier_riki_bladebreaker_order_custom_buff_stack = class(BaseClassBuff)
-------------------------------
function riki_bladebreaker_order_custom:GetIntrinsicModifierName()
    return "modifier_riki_bladebreaker_order_custom"
end

--------------------------------------------------------------------------------
-- Helper
function riki_bladebreaker_order_custom:GetAT()
    if self.abilityTable==nil then
        self.abilityTable = {}
    end
    return self.abilityTable
end

function riki_bladebreaker_order_custom:GetATEmptyKey()
    local table = self:GetAT()
    local i = 1
    while table[i]~=nil do
        i = i+1
    end
    return i
end

function riki_bladebreaker_order_custom:AddATValue( value )
    local table = self:GetAT()
    local i = self:GetATEmptyKey()
    table[i] = value
    return i
end

function riki_bladebreaker_order_custom:RetATValue( key )
    local table = self:GetAT()
    local ret = table[key]
    table[key] = nil
    return ret
end
-------------------------------
function modifier_riki_bladebreaker_order_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EXP_RATE_BOOST,
        MODIFIER_EVENT_ON_DEATH 
    }
end

function modifier_riki_bladebreaker_order_custom:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_riki_bladebreaker_order_custom_buff")
end

function modifier_riki_bladebreaker_order_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_pct")
end

function modifier_riki_bladebreaker_order_custom:GetModifierPercentageExpRateBoost()
    return self:GetAbility():GetSpecialValueFor("xp_mult_pct")
end

function modifier_riki_bladebreaker_order_custom:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local stackDuration = self:GetAbility():GetSpecialValueFor("duration")

    parent:AddNewModifier(parent, ability, "modifier_riki_bladebreaker_order_custom_buff", {
        stack_duration = stackDuration
    })
end
-----------------------------
function modifier_riki_bladebreaker_order_custom_buff:IsPurgeException()
    return true
end

function modifier_riki_bladebreaker_order_custom_buff:DestroyOnExpire()
    return false
end

function modifier_riki_bladebreaker_order_custom_buff:OnCreated( kv )
    if IsServer() then
        -- get AT value
        local at = self:GetAbility():AddATValue( self )

        -- Add stack
        self:GetParent():AddNewModifier(
            self:GetCaster(),
            self:GetAbility(),
            "modifier_riki_bladebreaker_order_custom_buff_stack",
            {
                duration = kv.stack_duration,
                modifier = at,
            }
        )

        -- set stack
        self:SetStackCount( 1 )
    end
end

function modifier_riki_bladebreaker_order_custom_buff:OnRefresh( kv )
    if IsServer() then
        -- get AT value
        local at = self:GetAbility():AddATValue( self )

        -- Add stack
        local mod = self:GetParent():AddNewModifier(
            self:GetCaster(),
            self:GetAbility(),
            "modifier_riki_bladebreaker_order_custom_buff_stack",
            {
                duration = kv.stack_duration,
                modifier = at,
            }
        )

        -- increment stack
        self:IncrementStackCount()
    end
end

function modifier_riki_bladebreaker_order_custom_buff:OnDestroy( kv )
end

--------------------------------------------------------------------------------
-- Helper
function modifier_riki_bladebreaker_order_custom_buff:RemoveStack( kv )
    if self:IsNull() or not self or self == nil or type(self) == "[none]" then return end

    self:DecrementStackCount()
    if self:GetStackCount()<1 then
        self:Destroy()
    end
end

function modifier_riki_bladebreaker_order_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_riki_bladebreaker_order_custom_buff:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("agi_per_kill") * self:GetStackCount()
end
-----------------
function modifier_riki_bladebreaker_order_custom_buff_stack:IsHidden()
    return true
end

function modifier_riki_bladebreaker_order_custom_buff_stack:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_riki_bladebreaker_order_custom_buff_stack:IsPurgable()
    return false
end

function modifier_riki_bladebreaker_order_custom_buff_stack:IsPurgeException()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_riki_bladebreaker_order_custom_buff_stack:OnCreated( kv )
    if IsServer() then
        -- references
        self.parent = self:GetAbility():RetATValue( kv.modifier )
    end
end

function modifier_riki_bladebreaker_order_custom_buff_stack:OnRefresh( kv )

end

function modifier_riki_bladebreaker_order_custom_buff_stack:OnDestroy( kv )
    if IsServer() then
        self.parent:RemoveStack()
    end
end