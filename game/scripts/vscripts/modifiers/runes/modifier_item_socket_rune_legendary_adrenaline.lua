LinkLuaModifier("modifier_item_socket_rune_legendary_adrenaline", "modifiers/runes/modifier_item_socket_rune_legendary_adrenaline", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_adrenaline_buff", "modifiers/runes/modifier_item_socket_rune_legendary_adrenaline", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_adrenaline_cooldown", "modifiers/runes/modifier_item_socket_rune_legendary_adrenaline", LUA_MODIFIER_MOTION_NONE)

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

modifier_item_socket_rune_legendary_adrenaline = class(BaseClass)
modifier_item_socket_rune_legendary_adrenaline_buff = class(BaseClassBuff)
modifier_item_socket_rune_legendary_adrenaline_cooldown = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_adrenaline:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf", context)
end

function modifier_item_socket_rune_legendary_adrenaline:OnCreated()
    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_legendary_adrenaline:OnIntervalThink()
    local parent = self:GetParent()
    local health = parent:GetHealthPercent()
    local threshold = 50
    local duration = 12

    if (health <= threshold) and not parent:HasModifier("modifier_item_socket_rune_legendary_adrenaline_buff") and not parent:HasModifier("modifier_item_socket_rune_legendary_adrenaline_cooldown") then
        parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_adrenaline_buff", {
            duration = duration
        })
    end
end

function modifier_item_socket_rune_legendary_adrenaline:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_adrenaline_buff")
    if buff ~= nil then
        buff:Destroy()
    end
end
--------------------------------------------------------------
function modifier_item_socket_rune_legendary_adrenaline_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_socket_rune_legendary_adrenaline_buff:GetModifierAttackSpeedBonus_Constant()
    return 300
end

function modifier_item_socket_rune_legendary_adrenaline_buff:GetModifierDamageOutgoing_Percentage()
    return 100
end

function modifier_item_socket_rune_legendary_adrenaline_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Ursa.Enrage", parent)
end

function modifier_item_socket_rune_legendary_adrenaline_buff:OnRemoved()
    if not IsServer() then return end

    local cooldown = 12

    local parent = self:GetParent()
    parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_adrenaline_cooldown", {
        duration = cooldown
    })
end

function modifier_item_socket_rune_legendary_adrenaline_buff:GetEffectName()
    return "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf"
end

function modifier_item_socket_rune_legendary_adrenaline_buff:GetTexture()
    return "runes/rune_legendary_adrenaline"
end