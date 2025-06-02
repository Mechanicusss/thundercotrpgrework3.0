--[[
    Thanks to Dota IMBA for parts of the code! Credits goes to them.
    https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_ember_spirit
]]--
LinkLuaModifier("modifier_gabriel_divine_retribution", "heroes/hero_gabriel/gabriel_divine_retribution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_divine_retribution_target", "heroes/hero_gabriel/gabriel_divine_retribution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_divine_retribution_caster", "heroes/hero_gabriel/gabriel_divine_retribution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_divine_retribution_autocast", "heroes/hero_gabriel/gabriel_divine_retribution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_divine_retribution_scepter_buff", "heroes/hero_gabriel/gabriel_divine_retribution", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassTarget = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
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

gabriel_divine_retribution = class(ItemBaseClass)
modifier_gabriel_divine_retribution = class(gabriel_divine_retribution)
modifier_gabriel_divine_retribution_target = class(ItemBaseClassTarget)
modifier_gabriel_divine_retribution_caster = class(ItemBaseClassTarget)
modifier_gabriel_divine_retribution_autocast = class(ItemBaseClass)
modifier_gabriel_divine_retribution_scepter_buff = class(ItemBaseClassBuff)
-------------
function gabriel_divine_retribution:GetIntrinsicModifierName()
    return "modifier_gabriel_divine_retribution_autocast"
end

function gabriel_divine_retribution:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function gabriel_divine_retribution:GetManaCost(level)
    return self:GetCaster():GetMana() * (self:GetSpecialValueFor("mana_cost_pct")/100)
end

function gabriel_divine_retribution:OnAbilityPhaseStart()
    self.preManaCost = self:GetManaCost(-1)
    return true
end

function gabriel_divine_retribution:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local caster_loc = caster:GetAbsOrigin()
    local original_direction = (caster:GetAbsOrigin() - point):Normalized()

    local radius = self:GetSpecialValueFor("radius")
    local interval = self:GetSpecialValueFor("attack_interval")
    local manaCost = self.preManaCost
    local maxJumps = self:GetSpecialValueFor("max_jumps")

    local units = FindUnitsInRadius(caster:GetTeam(), point, nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local targets = {}

    for _,unit in ipairs(units) do
        if unit:IsAlive() then
            targets[#targets + 1] = unit:entindex()

            unit:AddNewModifier(caster, self, "modifier_gabriel_divine_retribution_target", {
                duration = (#targets - 1) * interval
            })
        end
    end

    if #targets >= 1 then
        local previous_position = caster:GetAbsOrigin()
        local current_count = 1
        local jumps = 1
        local current_target = EntIndexToHScript(targets[current_count])

        caster:AddNewModifier(caster, self, "modifier_gabriel_divine_retribution_caster", {
            manaCost = self.preManaCost
        })

        if caster:HasScepter() then
            caster:AddNewModifier(caster, self, "modifier_gabriel_divine_retribution_scepter_buff", {
                duration = self:GetSpecialValueFor("scepter_duration")
            })
        end
        
        Timers:CreateTimer(FrameTime(), function()
            local bPass = false

            if current_target and not current_target:IsNull() and current_target:IsAlive() and not (current_target:IsInvisible() and not caster:CanEntityBeSeenByMyTeam(current_target)) and not current_target:IsAttackImmune() then
                -- Particles and sound
                caster:EmitSound("Hero_EmberSpirit.SleightOfFist.Damage")
                local slash_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, current_target)
                ParticleManager:SetParticleControl(slash_pfx, 0, current_target:GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(slash_pfx)

                local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail_2.vpcf", PATTACH_CUSTOMORIGIN, nil)
                ParticleManager:SetParticleControl(trail_pfx, 0, current_target:GetAbsOrigin())
                ParticleManager:SetParticleControl(trail_pfx, 1, previous_position)
                ParticleManager:ReleaseParticleIndex(trail_pfx)

                -- Perform the attack
                if caster:HasModifier("modifier_gabriel_divine_retribution_caster") then
                    caster:SetAbsOrigin(current_target:GetAbsOrigin() + original_direction * 64)

                    if self.preManaCost ~= nil and caster:GetManaPercent() < self:GetSpecialValueFor("mana_threshold") then
                        caster:GiveMana(self.preManaCost*2)
                    end

                    caster:PerformAttack(current_target, true, true, true, false, false, false, false)
                end
            end

            for i = 1, #targets do
                local temp = targets[i]
                if temp ~= nil then
                    local unitTemp = EntIndexToHScript(targets[i])
                    if unitTemp ~= nil and unitTemp:IsAlive() then
                        bPass = true
                        break
                    end
                end
            end

            -- Check if the loop continues
            current_count = current_count + 1
            
            if bPass and jumps < maxJumps and maxJumps >= current_count and caster:HasModifier("modifier_gabriel_divine_retribution_caster") then
                previous_position = current_target:GetAbsOrigin()

                if current_count >= #targets then
                    current_count = 1
                end

                current_target = EntIndexToHScript(targets[current_count])
                
                if not (current_target:IsInvisible() and not caster:CanEntityBeSeenByMyTeam(current_target)) and not current_target:IsAttackImmune() then
                    jumps = jumps + 1
                    return interval
                else
                    return 0
                end
            -- If not, stop everything
            else
                Timers:CreateTimer(interval - FrameTime(), function()
                    if caster:HasModifier("modifier_gabriel_divine_retribution_caster") then
                        FindClearSpaceForUnit(caster, caster_loc, true)
                    end
                    caster:RemoveModifierByName("modifier_gabriel_divine_retribution_caster")
                    for _, target in pairs(targets) do
                        EntIndexToHScript(target):RemoveModifierByName("modifier_gabriel_divine_retribution_target")
                    end
                end)
            end
        end)
    end
end
---------
function modifier_gabriel_divine_retribution_target:GetEffectName()
    return "particles/econ/events/ti9/high_five/high_five_lvl3_overhead_glow.vpcf"
end

function modifier_gabriel_divine_retribution_target:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
-------
function modifier_gabriel_divine_retribution_caster:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if IsServer() then
        self.manaCost = params.manaCost

        if self.manaCost ~= nil then
            self.cost = (self.manaCost * (self:GetAbility():GetSpecialValueFor("mana_cost_damage_pct")/100)) + self:GetAbility():GetSpecialValueFor("bonus_damage")

            self:InvokeBonus()
        end

        self:GetParent():AddNoDraw()
        self:GetAbility():SetActivated(false)
    end
end

function modifier_gabriel_divine_retribution_caster:AddCustomTransmitterData()
    return
    {
        cost = self.fCost,
    }
end

function modifier_gabriel_divine_retribution_caster:HandleCustomTransmitterData(data)
    if data.cost ~= nil then
        self.fCost = tonumber(data.cost)
    end
end

function modifier_gabriel_divine_retribution_caster:InvokeBonus()
    if IsServer() == true then
        self.fCost = self.cost

        self:SendBuffRefreshToClients()
    end
end

function modifier_gabriel_divine_retribution_caster:OnDestroy()
    if IsServer() then
        self:GetParent():RemoveNoDraw()
        self:GetAbility():SetActivated(true)
    end
end

function modifier_gabriel_divine_retribution_caster:CheckState()
    if IsServer() then
        local state = {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_STUNNED] = true
        }

        return state
    end
end

function modifier_gabriel_divine_retribution_caster:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE 
    }

    return funcs
end

function modifier_gabriel_divine_retribution_caster:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_gabriel_divine_retribution_caster:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_gabriel_divine_retribution_caster:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_gabriel_divine_retribution_caster:GetModifierPreAttack_BonusDamage(keys)
    return self.fCost
end

function modifier_gabriel_divine_retribution_caster:GetModifierIgnoreCastAngle()
    return 1
end
-----------
function modifier_gabriel_divine_retribution_autocast:DeclareFunctions()
    return {
    }
end
------------
function modifier_gabriel_divine_retribution_scepter_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_gabriel_divine_retribution_scepter_buff:GetModifierDamageOutgoing_Percentage(keys)
    return self.fDamage
end

function modifier_gabriel_divine_retribution_scepter_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if IsServer() then
        self.damage = (self:GetParent():GetSpellAmplification(false) * 100) * (self:GetAbility():GetSpecialValueFor("scepter_amount")/100)

        self:InvokeBonus()
    end
end

function modifier_gabriel_divine_retribution_scepter_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_gabriel_divine_retribution_scepter_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_gabriel_divine_retribution_scepter_buff:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end