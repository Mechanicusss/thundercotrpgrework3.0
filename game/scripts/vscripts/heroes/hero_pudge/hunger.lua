LinkLuaModifier("modifier_pudge_hunger_custom", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_kill_counter", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_buff_goal_1", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_buff_goal_2", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_buff_goal_3", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_buff_goal_4", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_hunger_custom_buff_goal_5", "heroes/hero_pudge/hunger", LUA_MODIFIER_MOTION_NONE)

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
local ItemBaseClassCounter = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

pudge_hunger_custom = class(ItemBaseClass)
modifier_pudge_hunger_custom = class(pudge_hunger_custom)
modifier_pudge_hunger_custom_kill_counter = class(ItemBaseClassCounter)
modifier_pudge_hunger_custom_buff_goal_1 = class(ItemBaseClassBuff)
modifier_pudge_hunger_custom_buff_goal_2 = class(ItemBaseClassBuff)
modifier_pudge_hunger_custom_buff_goal_3 = class(ItemBaseClassBuff)
modifier_pudge_hunger_custom_buff_goal_4 = class(ItemBaseClassBuff)
modifier_pudge_hunger_custom_buff_goal_5 = class(ItemBaseClassBuff)
-------------
function modifier_pudge_hunger_custom_buff_goal_1:GetTexture() return "hunger" end
function modifier_pudge_hunger_custom_buff_goal_2:GetTexture() return "hunger" end
function modifier_pudge_hunger_custom_buff_goal_3:GetTexture() return "hunger" end
function modifier_pudge_hunger_custom_buff_goal_4:GetTexture() return "hunger" end
function modifier_pudge_hunger_custom_buff_goal_5:GetTexture() return "hunger" end
function modifier_pudge_hunger_custom_kill_counter:GetTexture() return "hunger" end

-------------
function modifier_pudge_hunger_custom_kill_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function pudge_hunger_custom:OnHeroCalculateStatBonus()
 if not IsServer() then return end

 local modif = self:GetCaster():FindModifierByName("modifier_pudge_hunger_custom_kill_counter")

 if modif ~= nil then
    modif:ForceRefresh()
 end
 -- should fix the skill not updating unless you die
end

function modifier_pudge_hunger_custom_kill_counter:OnRefresh()
    if not IsServer() then return end

    local count = self:GetStackCount()
    local ability = self:GetAbility()

    if count >= ability:GetSpecialValueFor("kill_goals") then
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
            if UnitIsNotMonkeyClone(hero) then
                if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                    if hero:GetTeam() == self:GetParent():GetTeam() then
                        if ability:GetLevel() >= 1 and not hero:HasModifier("modifier_pudge_hunger_custom_buff_goal_1") then
                            hero:AddNewModifier(self:GetParent(), ability, "modifier_pudge_hunger_custom_buff_goal_1", {})
                        end

                        if ability:GetLevel() >= 2 and not hero:HasModifier("modifier_pudge_hunger_custom_buff_goal_4") then
                            hero:AddNewModifier(self:GetParent(), ability, "modifier_pudge_hunger_custom_buff_goal_4", {})
                        end

                        if ability:GetLevel() >= 3 and not hero:HasModifier("modifier_pudge_hunger_custom_buff_goal_3") then
                            hero:AddNewModifier(self:GetParent(), ability, "modifier_pudge_hunger_custom_buff_goal_3", {})
                        end

                        if ability:GetLevel() >= 4 and not hero:HasModifier("modifier_pudge_hunger_custom_buff_goal_2") then
                            hero:AddNewModifier(self:GetParent(), ability, "modifier_pudge_hunger_custom_buff_goal_2", {})
                        end

                        if ability:GetLevel() >= 5 and not hero:HasModifier("modifier_pudge_hunger_custom_buff_goal_5") then
                            hero:AddNewModifier(self:GetParent(), ability, "modifier_pudge_hunger_custom_buff_goal_5", {})
                        end
                    end
                end
            end
        end
    end
end
-------------
function pudge_hunger_custom:GetIntrinsicModifierName()
    return "modifier_pudge_hunger_custom"
end

function modifier_pudge_hunger_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        --MODIFIER_PROPERTY_MODEL_SCALE, --GetModifierModelScale
        --MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierDamageOutgoing_Percentage
    }
    return funcs
end

function modifier_pudge_hunger_custom:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_dmg_bonus_pct")
end

function modifier_pudge_hunger_custom:GetModifierModelScale()
    return self:GetAbility():GetSpecialValueFor("model_scale")
end

function modifier_pudge_hunger_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_pudge_hunger_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buff = parent:FindModifierByNameAndCaster("modifier_pudge_hunger_custom_kill_counter", parent)
    local stacks = parent:GetModifierStackCount("modifier_pudge_hunger_custom_kill_counter", parent)
    
    if not buff then
        parent:AddNewModifier(parent, ability, "modifier_pudge_hunger_custom_kill_counter", {})
        local buff = parent:FindModifierByNameAndCaster("modifier_pudge_hunger_custom_kill_counter", parent)
        buff:IncrementStackCount()
        buff:ForceRefresh()
    else
        buff:ForceRefresh()
    end

    local buff = parent:FindModifierByNameAndCaster("modifier_pudge_hunger_custom_kill_counter", parent)
    if buff:GetStackCount() >= ability:GetSpecialValueFor("kill_goals") then
        return
    end

    parent:SetModifierStackCount("modifier_pudge_hunger_custom_kill_counter", parent, (stacks + 1))
end
-----------
function modifier_pudge_hunger_custom_buff_goal_1:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS,
    }

    return funcs
end

function modifier_pudge_hunger_custom_buff_goal_1:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("goal_1_bonus_hp")
end
--------------
function modifier_pudge_hunger_custom_buff_goal_2:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }

    return funcs
end

function modifier_pudge_hunger_custom_buff_goal_2:OnCreated()
    self:SetHasCustomTransmitterData(true)
    self:OnRefresh()
end

function modifier_pudge_hunger_custom_buff_goal_2:OnRefresh()
    if not IsServer() then return end

    self.damage = ((self:GetParent():GetBaseDamageMax() + self:GetParent():GetBaseDamageMin())/2) * (self:GetAbility():GetSpecialValueFor("goal_2_bonus_base_damage_pct")/100)

    self:InvokeBonusDamage()
end

function modifier_pudge_hunger_custom_buff_goal_2:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_pudge_hunger_custom_buff_goal_2:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_pudge_hunger_custom_buff_goal_2:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_pudge_hunger_custom_buff_goal_2:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
--------------
function modifier_pudge_hunger_custom_buff_goal_3:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }

    return funcs
end

function modifier_pudge_hunger_custom_buff_goal_3:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("goal_3_bonus_spell_amp")
end
--------------
function modifier_pudge_hunger_custom_buff_goal_4:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    }

    return funcs
end

function modifier_pudge_hunger_custom_buff_goal_4:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("goal_4_bonus_max_regen_pct")
end
--------------
function modifier_pudge_hunger_custom_buff_goal_5:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("goal_5_bonus_damage_reduction")
end

function modifier_pudge_hunger_custom_buff_goal_5:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end