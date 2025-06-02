modifier_timmy = class({})

function modifier_timmy:CheckState()
    return {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }
end

function modifier_timmy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED
    }
end

function modifier_timmy:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_timmy:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_timmy:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_timmy:OnCreated() 
    if not IsServer() then return end

    self:GetParent():FaceTowards(-self:GetParent():GetForwardVector())

    self.mango = {}
    self.moonShard = {}
end

function modifier_timmy:IsHidden() return true end
function modifier_timmy:IsPurgable() return false end

function modifier_timmy:OnAbilityExecuted(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if not event.target then return end
    if event.target ~= parent then return end
    
    if event.ability:GetAbilityName() == "item_enchanted_mango" then 
        self.mango[event.unit:GetUnitName()] = self.mango[event.unit:GetUnitName()] or 0
        self.mango[event.unit:GetUnitName()] = self.mango[event.unit:GetUnitName()] + 1
    end

    if event.ability:GetAbilityName() == "item_moon_shard_custom" then 
        self.moonShard[event.unit:GetUnitName()] = self.moonShard[event.unit:GetUnitName()] or 0
        self.moonShard[event.unit:GetUnitName()] = self.moonShard[event.unit:GetUnitName()] + 1
    end

    if self.mango[event.unit:GetUnitName()] ~= nil and self.moonShard[event.unit:GetUnitName()] ~= nil then
        if self.mango[event.unit:GetUnitName()] >= 30 and self.moonShard[event.unit:GetUnitName()] >= 10 and parent:HasModifier("modifier_legion_commander_press_the_attack_custom_aura") then
            SwapHeroWithTCOTRPG(event.unit, "npc_dota_hero_rattletrap", nil, false)
            GameRules:SendCustomMessage("<font color='lightgreen'>Timmy, the Deserter</font>: Thank you, fellow adventurer, I will not let you down!", 0, 0)
            parent:ForceKill(false)
        end
    end
end