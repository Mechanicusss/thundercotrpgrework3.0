LinkLuaModifier("modifier_wave_ai", "modules/waves/ai", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

wave_ai = class(BaseClass)
modifier_wave_ai = class(wave_ai)
-------------
function wave_ai:GetIntrinsicModifierName()
    return "modifier_wave_ai"
end

function modifier_wave_ai:OnCreated()
    if not IsServer() then return end

    self.unit = self:GetParent()

    self.unit:SetTeam(DOTA_TEAM_BADGUYS)

    self.attackCapability = nil
    if not self.unit:IsRangedAttacker() == DOTA_UNIT_CAP_MELEE_ATTACK then
        self.attackCapability = DOTA_UNIT_CAP_MELEE_ATTACK
    else
        self.attackCapability = DOTA_UNIT_CAP_RANGED_ATTACK
    end

    self.initialCornerName = Entities:FindByName(nil, "wave_path_1")

    self.enemyBase = Entities:FindByName(nil, "base_ancient")

    self.unit:SetMustReachEachGoalEntity(true)
    self.unit:SetInitialGoalEntity(self.initialCornerName)

    self.aggro = nil

    self:StartIntervalThink(1)
end

function modifier_wave_ai:OnIntervalThink()
    if self.aggro ~= nil then
        if self.aggro:IsAlive() and not self.aggro:IsInvisible() and not self.aggro:IsPhased() and not self.aggro:IsAttackImmune() then
            if (self.aggro:GetAbsOrigin() - self.unit:GetAbsOrigin()):Length2D() > 600 or not IsLocationVisible(DOTA_TEAM_BADGUYS, self.aggro:GetAbsOrigin()) then
                self.aggro = nil
            end

            self.unit:SetAttackCapability(self.attackCapability)
            self.unit:SetForceAttackTarget(self.aggro)
            self.unit:MoveToTargetToAttack(self.aggro)
        else
            self.unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
            self.aggro = nil
        end
    end

    if self.aggro == nil then
        local findTargets = FindUnitsInRadius(self.unit:GetTeam(), self.unit:GetAbsOrigin(), nil,
                600, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
                FIND_CLOSEST, false)

        if #findTargets > 0 then
            for _,target in ipairs(findTargets) do
                if target:GetUnitName() ~= "npc_dota_creature_target_dummy" then
                    self.aggro = target
                    break
                end
            end
        end
    end
end

function modifier_wave_ai:CheckState()
    local state = { 
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
    return state
end