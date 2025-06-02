LinkLuaModifier("boss_queen_of_pain_berserk_modifier", "heroes/bosses/akasha/berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_berserk_modifier_buff", "heroes/bosses/akasha/berserk", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local ItemSelfBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

boss_queen_of_pain_berserk = class(BaseClass)
boss_queen_of_pain_berserk_modifier = class(BaseClass)
boss_queen_of_pain_berserk_modifier_buff = class(ItemSelfBuffBaseClass)

function boss_queen_of_pain_berserk:GetIntrinsicModifierName()
    return "boss_queen_of_pain_berserk_modifier"
end
--------------
function boss_queen_of_pain_berserk_modifier:OnCreated()
    if not IsServer() then return end

    self.timer = nil

    self:StartIntervalThink(10.0)
end

function boss_queen_of_pain_berserk_modifier:OnIntervalThink()
    local parent = self:GetParent()
    if not parent:IsAttacking() and not parent:IsChanneling() and parent:HasModifier("boss_queen_of_pain_berserk_modifier_buff") then
        --parent:RemoveModifierByName("boss_queen_of_pain_berserk_modifier_buff")
        if self.timer ~= nil then
            Timers:RemoveTimer(self.timer)
            self.timer = nil
        end
    elseif parent:IsAttacking() then 
        if self.timer ~= nil then return end

        self.timer = Timers:CreateTimer(180, function()
            if self.timer == nil then return end
            if not parent or parent == nil then return end
            if not parent:IsAlive() then return end

            if not parent:HasModifier("boss_queen_of_pain_berserk_modifier_buff") then
                parent:AddNewModifier(parent, nil, "boss_queen_of_pain_berserk_modifier_buff", {}):SetStackCount(1)
            else
                local mod = parent:FindModifierByName("boss_queen_of_pain_berserk_modifier_buff")
                if mod ~= nil then
                    if mod:GetStackCount() < 3 then
                        mod:IncrementStackCount()
                    end
                end
            end

            return 180
        end)
    end
end
--------------
function boss_queen_of_pain_berserk_modifier_buff:GetTexture() return "qoparcanaresonator" end
function boss_queen_of_pain_berserk_modifier_buff:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
    }

    return funcs
end

function boss_queen_of_pain_berserk_modifier_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function boss_queen_of_pain_berserk_modifier_buff:GetModifierProcAttack_BonusDamage_Pure(params)
    if not IsServer() then return end

    local target = params.target if target==nil then target = params.unit end
    if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
        return 0
    end

    local parent = self:GetParent()
    local stacks = self:GetStackCount()
    local bonusDamage = parent:GetAverageTrueAttackDamage(parent) * 0.05 * stacks

    return bonusDamage
end

function boss_queen_of_pain_berserk_modifier_buff:GetModifierAttackSpeedPercentage()
    local atkspd = self:GetStackCount() * 30

    if atkspd > 90 then
        atkspd = 90
    end

    return atkspd
end

function boss_queen_of_pain_berserk_modifier_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetStackCount() * 30
end