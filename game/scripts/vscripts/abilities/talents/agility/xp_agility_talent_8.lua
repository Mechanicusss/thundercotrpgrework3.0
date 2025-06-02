LinkLuaModifier("modifier_xp_agility_talent_8", "abilities/talents/agility/xp_agility_talent_8", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_8_illusion", "abilities/talents/agility/xp_agility_talent_8", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_8 = class(ItemBaseClass)
modifier_xp_agility_talent_8 = class(xp_agility_talent_8)
modifier_xp_agility_talent_8_illusion = class(ItemBaseClassDebuff)
-------------
function xp_agility_talent_8:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_8"
end
-------------
function modifier_xp_agility_talent_8:OnCreated()
    if not IsServer() then return end 

    self.isCooldown = false
end

function modifier_xp_agility_talent_8:OnDestroy()
end

function modifier_xp_agility_talent_8:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_xp_agility_talent_8:OnAttack(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if not parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 
    if not parent:IsAlive() then return end
    if self.isCooldown then return end

    local illusionDistance = 200  -- Distance from the hero for the illusions
    local illusionDuration = 7
    local angleBetweenIllusions = math.pi / 2  -- Angle between the hero and the illusions (90 degrees)

    -- Calculate the positions for the illusions
    local angleOffset = angleBetweenIllusions / 2
    local origin = parent:GetAbsOrigin()
    local forwardVector = parent:GetForwardVector()
    local rightVector = Vector(-forwardVector.y, forwardVector.x, 0)

    local illusion1Position = origin + (-rightVector * illusionDistance)
    local illusion2Position = origin + (rightVector * illusionDistance)

    -- Spawn the illusion units
    local illusion1 = CreateIllusions(parent, parent, {outgoing_damage=100,incoming_damage=0}, 1, 0, false, true)
    illusion1[1]:SetAbsOrigin(illusion1Position)
    local illusion2 = CreateIllusions(parent, parent, {outgoing_damage=100,incoming_damage=0}, 1, 0, false, true)
    illusion2[1]:SetAbsOrigin(illusion2Position)

    illusion1[1]:AddNewModifier(parent, nil, "modifier_xp_agility_talent_8_illusion", {duration = illusionDuration})
    illusion2[1]:AddNewModifier(parent, nil, "modifier_xp_agility_talent_8_illusion", {duration = illusionDuration})

    self.isCooldown = true

    Timers:CreateTimer(20, function()
        self.isCooldown = false
    end)
end
------------
function modifier_xp_agility_talent_8_illusion:OnCreated()
    if not IsServer() then return end 

    self.target = nil

    self:StartIntervalThink(FrameTime())
end

-- I fucking copied this from waves, gimme a break
function modifier_xp_agility_talent_8_illusion:OnIntervalThink()
    local parent = self:GetParent()

    -- Disable the AI entirely if the unit is channeling an ability
    if parent:IsChanneling() then return end

    -- Targeting logic --
    if self.target ~= nil and not self.target:IsNull() then
        -- The target must be alive, not be attack immune
        if self.target:IsAlive() and not self.target:IsInvulnerable() and not self.target:IsUntargetableFrom(parent) then
            parent:SetForceAttackTarget(self.target)
        else
            parent:SetForceAttackTarget(nil)
            self.target = nil
        end
    end

    -- We will continue to search for units even if there is a target already 
    -- to see if there's another target that is closer
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and victim ~= self.target and not victim:HasModifier("modifier_wave_manager_fow_revealer") and not victim:HasModifier("modifier_chicken_ability_1_self_transmute") then
            if self.target ~= nil then
                local victimDistance = parent:GetRangeToUnit(victim)
                local currentTargetDistance = parent:GetRangeToUnit(self.target)

                -- If there is a unit that is closer to the unit than the current target,
                -- we change the target to be that unit instead
                if victimDistance < currentTargetDistance then
                    self.target = victim 
                    break
                end
            else
                self.target = victim 
                break
            end
        end
    end
end

function modifier_xp_agility_talent_8_illusion:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MAX 
    }
end

function modifier_xp_agility_talent_8_illusion:GetModifierMoveSpeed_AbsoluteMax() return 0 end

function modifier_xp_agility_talent_8_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    }

    return state
end

function modifier_xp_agility_talent_8_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_xp_agility_talent_8_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_xp_agility_talent_8_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_xp_agility_talent_8_illusion:StatusEffectPriority()
    return 10001
end

function modifier_xp_agility_talent_8_illusion:OnDestroy()
    if not IsServer() then return end

    if not self:GetParent():IsNull() then
        UTIL_RemoveImmediate(self:GetParent())
    end
end