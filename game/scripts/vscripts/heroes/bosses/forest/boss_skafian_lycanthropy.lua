LinkLuaModifier("modifier_boss_skafian_lycanthropy", "heroes/bosses/forest/boss_skafian_lycanthropy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_skafian_lycanthropy_buff", "heroes/bosses/forest/boss_skafian_lycanthropy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_skafian_lycanthropy_wolf_ai", "heroes/bosses/forest/boss_skafian_lycanthropy", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

boss_skafian_lycanthropy = class(ItemBaseClass)
modifier_boss_skafian_lycanthropy = class(boss_skafian_lycanthropy)
modifier_boss_skafian_lycanthropy_buff = class(ItemBaseClassBuff)
modifier_boss_skafian_lycanthropy_wolf_ai = class(ItemBaseClassBuff)
-------------
function boss_skafian_lycanthropy:GetIntrinsicModifierName()
    return "modifier_boss_skafian_lycanthropy"
end
-------------
function modifier_boss_skafian_lycanthropy:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_boss_skafian_lycanthropy:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local health = parent:GetHealthPercent()
    local threshold = ability:GetSpecialValueFor("threshold")

    if health <= threshold and ability:IsCooldownReady() and not parent:PassivesDisabled() then
        parent:AddNewModifier(parent, ability, "modifier_boss_skafian_lycanthropy_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end
end
--------------------
function modifier_boss_skafian_lycanthropy_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
    parent:Purge(false, true, false, true, false)

    EmitSoundOn("Hero_Lich.ChainFrost", parent)
    EmitSoundOn("Hero_Lich.ChainFrostLoop.TI8", parent)

    ability:UseResources(false, false, false, true)

    self.point = Entities:FindByName(nil, "spawn_boss_skafian2")

    self:StartIntervalThink(0.1)

    -- Summon wolves 
    local wolfCount = 6

    for i = 1, wolfCount, 1 do
        local wolf = CreateUnitByName("npc_dota_creature_skafian_summon_wolves", parent:GetAbsOrigin(), true, parent, parent, parent:GetTeam())

        wolf:AddNewModifier(
            parent,
            ability,
            "modifier_boss_skafian_lycanthropy_wolf_ai",
            {
                duration = ability:GetSpecialValueFor("duration")
            }
        )
    end
end

function modifier_boss_skafian_lycanthropy_buff:OnIntervalThink()
    local parent = self:GetParent()
    
    if self.point ~= nil then
        parent:MoveToPosition(self.point:GetOrigin())
    end
end

function modifier_boss_skafian_lycanthropy_buff:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)

    StopSoundOn("Hero_Lich.ChainFrostLoop.TI8", parent)
    EmitSoundOn("Hero_Lich.ChainFrostImpact.LF", parent)
    EmitSoundOn("Hero_Lich.ChainFrostImpact.Hero", parent)
end

function modifier_boss_skafian_lycanthropy_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
end

function modifier_boss_skafian_lycanthropy_buff:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local attacker = event.attacker
    local victim = event.target

    if victim ~= parent then return end
    if victim == attacker then return end
    if parent:PassivesDisabled() then return end

    if event.damage_flags == DOTA_DAMAGE_FLAG_REFLECTION then return end

    if event.inflictor then
        -- We have to do this to prevent damage reflection from causing an infinite loop and crashing the game
        if string.match(event.inflictor:GetAbilityName(), "item_gladiator_armor") or string.match(event.inflictor:GetAbilityName(), "talent_bristleback_1") then
            return
        end
    end

    return -ability:GetSpecialValueFor("damage_reflect")
end

function modifier_boss_skafian_lycanthropy_buff:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_ROOTED] = false,
    }
end

function modifier_boss_skafian_lycanthropy_buff:GetModifierHealthRegenPercentage()
    if self:GetParent():PassivesDisabled() then return end
    return self:GetAbility():GetSpecialValueFor("hp_regen_pct")
end

function modifier_boss_skafian_lycanthropy_buff:GetModifierMoveSpeedBonus_Constant()
    return 2000
end
-----------------
function modifier_boss_skafian_lycanthropy_wolf_ai:OnCreated()
    if not IsServer() then return end

    self.target = nil

    self:StartIntervalThink(FrameTime())
end

function modifier_boss_skafian_lycanthropy_wolf_ai:OnIntervalThink()
    local parent = self:GetParent()

    local caster = self:GetCaster()

    if (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 900 then
        self.target = nil
        parent:MoveToPosition(caster:GetAbsOrigin())
        return
    end

    if not caster:IsAlive() then
        self:Destroy()
        return
    end

    if self.target ~= nil then
        if self.target:IsAlive() then
            parent:SetForceAttackTarget(self.target)
        else
            parent:SetForceAttackTarget(nil)
            self.target = nil
        end
    end

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            600, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        self.target = victim 
        break
    end
end

function modifier_boss_skafian_lycanthropy_wolf_ai:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:IsAlive() then
        parent:ForceKill(false)
    end
end