LinkLuaModifier("modifier_item_socket_rune_legendary_evasive_architect", "modifiers/runes/modifier_item_socket_rune_legendary_evasive_architect", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_evasive_architect_cooldown", "modifiers/runes/modifier_item_socket_rune_legendary_evasive_architect", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_evasive_architect_buff", "modifiers/runes/modifier_item_socket_rune_legendary_evasive_architect", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_evasive_architect_debuff", "modifiers/runes/modifier_item_socket_rune_legendary_evasive_architect", LUA_MODIFIER_MOTION_NONE)

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

modifier_item_socket_rune_legendary_evasive_architect = class(BaseClass)
modifier_item_socket_rune_legendary_evasive_architect_buff = class(BaseClassBuff)
modifier_item_socket_rune_legendary_evasive_architect_cooldown = class(BaseClass)
modifier_item_socket_rune_legendary_evasive_architect_debuff = class(BaseClassBuff)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_evasive_architect:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_tazer.vpcf", context)
end

function modifier_item_socket_rune_legendary_evasive_architect:DeclareFunctions()
    return {
         MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_item_socket_rune_legendary_evasive_architect:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local target = event.target
    local attacker = event.attacker

    if parent ~= attacker or parent == target then return end
    if event.inflictor then return end
    if parent:HasModifier("modifier_item_socket_rune_legendary_evasive_architect_buff") or parent:HasModifier("modifier_item_socket_rune_legendary_evasive_architect_cooldown") then return end

    local duration = 6

    local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_evasive_architect_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_evasive_architect_buff", {
            duration = duration
        })
    end

    if buff then
        buff:ForceRefresh()
    end
end

function modifier_item_socket_rune_legendary_evasive_architect:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_item_socket_rune_legendary_evasive_architect_buff")
    parent:RemoveModifierByName("modifier_item_socket_rune_legendary_evasive_architect_debuff")
end
----------------------------
function modifier_item_socket_rune_legendary_evasive_architect_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Item.Brooch.Cast", parent)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_tazer.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, parent:GetOrigin())
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, --GetModifierBaseAttackTimeConstant
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierDamageOutgoing_Percentage
    }
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:GetModifierBaseAttackTimeConstant()
    return 0.8
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:GetModifierDamageOutgoing_Percentage()
    return 300
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local cooldown = 30
    local duration = 12

    parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_evasive_architect_cooldown", {
        duration = cooldown
    })

    parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_evasive_architect_debuff", {
        duration = duration
    })

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:GetTexture()
    return "runes/rune_legendary_evasive_architect"
end

function modifier_item_socket_rune_legendary_evasive_architect_buff:GetPriority()
    return MODIFIER_PRIORITY_ULTRA 
end
----------------------------
function modifier_item_socket_rune_legendary_evasive_architect_debuff:IsDebuff() return true end

function modifier_item_socket_rune_legendary_evasive_architect_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_item_socket_rune_legendary_evasive_architect_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -70
end

function modifier_item_socket_rune_legendary_evasive_architect_debuff:GetTexture()
    return "runes/rune_legendary_evasive_architect"
end
