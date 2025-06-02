LinkLuaModifier("modifier_item_socket_rune_legendary_exodus_shield", "modifiers/runes/modifier_item_socket_rune_legendary_exodus_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_exodus_shield_buff", "modifiers/runes/modifier_item_socket_rune_legendary_exodus_shield", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_item_socket_rune_legendary_exodus_shield = class(BaseClass)
modifier_item_socket_rune_legendary_exodus_shield_buff = class(BaseClassBuff)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_exodus_shield:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_legendary_exodus_shield:OnIntervalThink()
    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID][abilityName] = 30
end

function modifier_item_socket_rune_legendary_exodus_shield:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    caster:RemoveModifierByName("modifier_item_socket_rune_legendary_exodus_shield_buff")
end

function modifier_item_socket_rune_legendary_exodus_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_socket_rune_legendary_exodus_shield:GetModifierTotalDamageOutgoing_Percentage()
    return -30
end

function modifier_item_socket_rune_legendary_exodus_shield:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local target = event.target
    local attacker = event.attacker

    if parent ~= target or parent == attacker then return end

    if event.inflictor then return end

    local duration = 3
    local maxStacks = 8

    local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_exodus_shield_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_exodus_shield_buff", {
            duration = duration
        })
    end

    if buff then
        if buff:GetStackCount() < maxStacks then
            buff:IncrementStackCount()
        end

        if buff:GetStackCount() == maxStacks then
            EmitSoundOn("DOTA_Item.AbyssalBlade.Activate", parent)

            local damage = parent:GetStrength() * 10

            ApplyDamage({
                attacker = parent,
                victim = attacker,
                damage = damage,
                damage_type = DAMAGE_TYPE_PHYSICAL,
            })

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, attacker, damage, nil)

            buff:Destroy()
            return
        end

        buff:ForceRefresh()
    end
end
----------------------
function modifier_item_socket_rune_legendary_exodus_shield_buff:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_legendary_exodus_shield_buff:OnIntervalThink()
    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID][abilityName] = 2.5 * self:GetStackCount()
end

function modifier_item_socket_rune_legendary_exodus_shield_buff:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_item_socket_rune_legendary_exodus_shield_buff:GetTexture()
    return "runes/rune_legendary_exodus_shield"
end