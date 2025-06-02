LinkLuaModifier("modifier_item_socket_rune_legendary_chronomancer", "modifiers/runes/modifier_item_socket_rune_legendary_chronomancer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_chronomancer_buff", "modifiers/runes/modifier_item_socket_rune_legendary_chronomancer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_chronomancer_cd", "modifiers/runes/modifier_item_socket_rune_legendary_chronomancer", LUA_MODIFIER_MOTION_NONE)

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

local BaseClassCd = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_item_socket_rune_legendary_chronomancer = class(BaseClass)
modifier_item_socket_rune_legendary_chronomancer_buff = class(BaseClassBuff)
modifier_item_socket_rune_legendary_chronomancer_cd = class(BaseClassCd)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_chronomancer:OnCreated()
    if not IsServer() then return end

    local interval = 5

    self:StartIntervalThink(interval)
end

function modifier_item_socket_rune_legendary_chronomancer:OnIntervalThink()
    local parent = self:GetParent()
    local reduction = 3
    local duration = 5 -- damage buff duration
    local chance = 50

    local abilities = {}

    for i=0, parent:GetAbilityCount()-1 do
        local current_ability = parent:GetAbilityByIndex(i)
        if current_ability and current_ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE and current_ability:GetCooldown(current_ability:GetLevel()) > 0 and not current_ability:IsAttributeBonus() and not current_ability:IsCooldownReady() and current_ability:GetCooldownTimeRemaining() > 0.9 then
            table.insert(abilities, current_ability)
        end
    end

    if #abilities < 1 then return end

    local ability = abilities[RandomInt(1, #abilities)]
    local remainingTime = ability:GetCooldownTimeRemaining()

    if RollPercentage(50) and not parent:HasModifier("modifier_item_socket_rune_legendary_chronomancer_cd") then
        reduction = remainingTime
        parent:AddNewModifier(
            parent,
            self:GetAbility(),
            "modifier_item_socket_rune_legendary_chronomancer_cd",
            {
                duration = 18
            }
        )
    end

    local cooldown = remainingTime - reduction
        
    if cooldown < 0 then
        cooldown = 0
    end

    if cooldown == 0 then
        local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_chronomancer_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_chronomancer_buff", {
                duration = duration,
                sAbility = ability:GetName(),
            })
        end

        if buff then
            buff:ForceRefresh()
        end
    end

    ability:EndCooldown()
    ability:StartCooldown(cooldown)
end

function modifier_item_socket_rune_legendary_chronomancer:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_item_socket_rune_legendary_chronomancer_buff")
end
----------------------
function modifier_item_socket_rune_legendary_chronomancer_buff:OnCreated(params)
    if not IsServer() then return end

    self.ability = params.sAbility
end

function modifier_item_socket_rune_legendary_chronomancer_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_item_socket_rune_legendary_chronomancer_buff:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    if self.ability == nil then return end

    if not event.inflictor then return end

    if event.inflictor then
        if event.inflictor:GetName() ~= self.ability then return end
    end

    print("buff for:", self.ability)

    return 100
end

function modifier_item_socket_rune_legendary_chronomancer_buff:GetTexture()
    return "runes/rune_legendary_chronomancer"
end