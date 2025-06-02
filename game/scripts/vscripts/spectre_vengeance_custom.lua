LinkLuaModifier("modifier_spectre_vengeance_custom", "spectre_vengeance_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_vengeance_custom_active", "spectre_vengeance_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_vengeance_custom_illusion", "spectre_vengeance_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_vengeance_custom = class(ItemBaseClass)
modifier_spectre_vengeance_custom = class(spectre_vengeance_custom)
modifier_spectre_vengeance_custom_active = class(ItemBaseClassAbsorb)
modifier_spectre_vengeance_custom_illusion = class(ItemBaseClass)
-------------
function spectre_vengeance_custom:GetIntrinsicModifierName()
    return "modifier_spectre_vengeance_custom"
end

function spectre_vengeance_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function spectre_vengeance_custom:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local ability = self
    local caster = self:GetCaster()
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local spawnInterval = ability:GetLevelSpecialValueFor("base_interval", (ability:GetLevel() - 1))
    local damageMultiplier = ability:GetLevelSpecialValueFor("outgoing_damage", (ability:GetLevel() - 1))
    local maxInterval = ability:GetLevelSpecialValueFor("max_interval", (ability:GetLevel() - 1))

    if caster:HasModifier("modifier_spectre_vengeance_custom_active") then
        caster:RemoveModifierByNameAndCaster("modifier_spectre_vengeance_custom_active", caster)
    end

    caster:AddNewModifier(caster, ability, "modifier_spectre_vengeance_custom_active", { 
        duration = duration, 
        spawnInterval = spawnInterval, 
        damageMultiplier = damageMultiplier,
        x = point.x,
        y = point.y,
        z = point.z,
        radius = radius,
        maxInterval = maxInterval
    })

    EmitSoundOn("Hero_Spectre.Haunt", caster)
end
------------
function modifier_spectre_vengeance_custom_active:DeclareFunctions()
    local funcs = {
        
    }

    return funcs
end

function modifier_spectre_vengeance_custom_active:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true
    }

    return state
end

function modifier_spectre_vengeance_custom_active:OnCreated(props)
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.radius = props.radius
    self.point = Vector(props.x, props.y, props.z)
    self.spawnInterval = props.spawnInterval
    self.damageMultiplier = props.damageMultiplier
    self.maxInterval = props.maxInterval

    local heroAPS = 1 / self.parent:GetAttacksPerSecond()

    if heroAPS < 1 then
        if heroAPS < self.maxInterval then
            heroAPS = self.maxInterval
        end

        self.spawnInterval = heroAPS
    end

    self:StartIntervalThink(self.spawnInterval)
end

function modifier_spectre_vengeance_custom_active:OnIntervalThink()
    local potentialTargets = FindUnitsInRadius(self.parent:GetTeam(), self.point, nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    if #potentialTargets < 1 then
        return
    end

    local randomTarget = potentialTargets[RandomInt(1, #potentialTargets)]

    local modifierKeys = {
        outgoing_damage = self.damageMultiplier,
        incoming_damage = 0.0,
        bounty_base = 0.0,
        outgoing_damage_structure = self.damageMultiplier,
        outgoing_damage_roshan = self.damageMultiplier
    }

    local illusions = CreateIllusions(EntIndexToHScript(self.parent:entindex()), self.parent, modifierKeys, 1, 0, false, true)
    for _,illusion in ipairs(illusions) do
        illusion:SetAbsOrigin(Vector(randomTarget:GetAbsOrigin().x+(RandomInt(-75, 75)), randomTarget:GetAbsOrigin().y+(RandomInt(-75, 75)), randomTarget:GetAbsOrigin().z))
        --illusion:SetForceAttackTarget(randomTarget)
        illusion:PerformAttack(
            randomTarget,
            true,
            true,
            true,
            true,
            illusion:IsRangedAttacker(),
            false,
            true
        )
        illusion:AddNewModifier(illusion, nil, "modifier_spectre_vengeance_custom_illusion", {})

        --todo: set their attack range to high so they don't miss in case enemy runs.
        --todo: set spawn interval to heroes APS (1.25s etc) but base 1.0s
        
        Timers:CreateTimer(self.spawnInterval, function()
            if not illusion:IsAlive() then return end

            illusion:RemoveModifierByName("modifier_spectre_vengeance_custom_illusion")
            illusion:ForceKill(false)
        end)
    end

end
----
function modifier_spectre_vengeance_custom_illusion:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_spectre_vengeance_custom_illusion:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()

    if unit ~= parent then
        return
    end

    parent:RemoveModifierByName("modifier_spectre_vengeance_custom_illusion")
    parent:ForceKill(false)
end

function modifier_spectre_vengeance_custom_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    return state
end

function modifier_spectre_vengeance_custom_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_spectre_vengeance_custom_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spectre_vengeance_custom_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_spectre_vengeance_custom_illusion:StatusEffectPriority()
    return 10001
end