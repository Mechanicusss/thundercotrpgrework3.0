LinkLuaModifier("modifier_zombie_boss_raise_dead", "heroes/bosses/zombie/zombie_boss_raise_dead", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_boss_raise_dead_zombie_ai", "heroes/bosses/zombie/zombie_boss_raise_dead", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAI = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return false end,
}

zombie_boss_raise_dead = class(ItemBaseClass)
modifier_zombie_boss_raise_dead = class(zombie_boss_raise_dead)
modifier_zombie_boss_raise_dead_zombie_ai = class(ItemBaseClassAI)
-------------
function zombie_boss_raise_dead:GetIntrinsicModifierName()
    return "modifier_zombie_boss_raise_dead"
end

function modifier_zombie_boss_raise_dead:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("spawn_interval")

    self:StartIntervalThink(interval)
end

function modifier_zombie_boss_raise_dead:OnIntervalThink()
    local parent = self:GetParent()
    local position = parent:GetAbsOrigin()

    if not parent:GetAggroTarget() then return end

    local unit = CreateUnitByName("npc_dota_creature_40_crip_8", position, true, nil, nil, parent:GetTeam())

    unit:AddNewModifier(parent, self:GetAbility(), "modifier_zombie_boss_raise_dead_zombie_ai", { duration = self:GetAbility():GetSpecialValueFor("lifetime") })

    unit:SetMaximumGoldBounty(0)
    unit:SetMinimumGoldBounty(0)
    unit:SetDeathXP(0)
end
----------------
function modifier_zombie_boss_raise_dead_zombie_ai:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    local caster = self:GetCaster()

    if not caster:IsNull() and caster:IsAlive() then
        local ability = self:GetAbility()
        local heal = ability:GetSpecialValueFor("death_heal_pct")
        local healAmount = caster:GetMaxHealth() * (heal/100)

        caster:Heal(healAmount, ability)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, healAmount, nil)
    end

    if not parent:IsNull() and parent:IsAlive() then
        UTIL_Remove(parent)
    end
end

function modifier_zombie_boss_raise_dead_zombie_ai:OnCreated()
    if not IsServer() then return end

    self.target = nil

    self:StartIntervalThink(FrameTime())
end

function modifier_zombie_boss_raise_dead_zombie_ai:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:IsNull() or (not caster:IsNull() and not caster:IsAlive()) then 
        self:Destroy()
        return
    end

    local parent = self:GetParent()

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
            900, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        self.target = victim 
        break
    end
end