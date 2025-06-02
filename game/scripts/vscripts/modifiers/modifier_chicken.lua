modifier_chicken = class({})

function modifier_chicken:CheckState()
    return {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }
end

function modifier_chicken:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

function modifier_chicken:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_chicken:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_chicken:OnDeath(event) 
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    if not event.attacker:IsRealHero() or event.attacker:IsIllusion() then return end 

    SwapHeroWithTCOTRPG(event.attacker, "npc_dota_hero_wisp", nil)
end

function modifier_chicken:IsHidden() return true end
function modifier_chicken:IsPurgable() return false end