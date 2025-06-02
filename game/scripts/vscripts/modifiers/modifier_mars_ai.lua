LinkLuaModifier("modifier_mars_ai", "modifiers/modifier_mars_ai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_ai_casting", "modifiers/modifier_mars_ai", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

spectre_desolate_custom = class(ItemBaseClass)
modifier_mars_ai = class(spectre_desolate_custom)
modifier_mars_ai_casting = class(ItemBaseClass)
-------------
function spectre_desolate_custom:GetIntrinsicModifierName()
    return "modifier_mars_ai"
end

function modifier_mars_ai:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_mars_ai:OnIntervalThink()
    local caster = self:GetCaster()
    local arena = caster:FindAbilityByName("boss_mars_arena_of_blood")
    local spear = caster:FindAbilityByName("boss_mars_spear")

    if caster:IsAttacking() then
        local victim = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            1300, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        if #victim > 0 then
            if not victim[1]:IsAlive() or victim[1]:IsMagicImmune() or not victim[1]:IsRealHero() then return end

            if arena:IsCooldownReady() then
                caster:SetAttacking(nil)
                caster:SetForceAttackTarget(nil)

                caster:AddNewModifier(caster, arena, "modifier_mars_ai_casting", { duration = 1.0 })
                Timers:CreateTimer(0.5, function()
                    if not victim[1]:IsAlive() or victim[1]:IsMagicImmune() or not victim[1]:IsRealHero() then return end

                    caster:CastAbilityOnPosition(victim[1]:GetAbsOrigin(), arena, -1)

                    -- Cast spear next --
                    if spear:IsCooldownReady() then
                        if ((victim[1]:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= 1300) then
                            caster:SetAttacking(nil)
                            caster:SetForceAttackTarget(nil)

                            caster:AddNewModifier(caster, spear, "modifier_mars_ai_casting", { duration = 1.0 })
                            caster:CastAbilityOnPosition(victim[1]:GetAbsOrigin(), spear, -1)
                            
                            spear:UseResources(false, false, false, true)
                        end
                    end
                    -- --
                    
                    arena:UseResources(false, false, false, true)
                end)
            end
        end
    end
end

function modifier_mars_ai_casting:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
    return state
end

function modifier_mars_ai_casting:OnCreated()
    if not IsServer() then return end

    self:GetParent():SetAttacking(nil)
    self:GetParent():SetForceAttackTarget(nil)

    self.cap = self:GetParent():GetAttackCapability()

    self:GetParent():SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
end

function modifier_mars_ai_casting:OnDestroy()
    if not IsServer() then return end

    self:GetParent():SetAttackCapability(self.cap)
end