LinkLuaModifier("boss_butcher_consume_modifier", "heroes/bosses/butcher/boss_butcher_consume", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_butcher_consume_debuff", "heroes/bosses/butcher/boss_butcher_consume", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "boss_butcher_consume_debuff_thinker_casting", "heroes/bosses/butcher/boss_butcher_consume", LUA_MODIFIER_MOTION_NONE )


local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

boss_butcher_consume = class(BaseClass)
boss_butcher_consume_modifier = class(BaseClass)
boss_butcher_consume_debuff = class(BaseClassDebuff)
boss_butcher_consume_debuff_thinker_casting = class({})


function boss_butcher_consume:GetIntrinsicModifierName()
    return "boss_butcher_consume_modifier"
end

function boss_butcher_consume_modifier:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function boss_butcher_consume_modifier:OnIntervalThink()
    local caster = self:GetCaster()
    local consume = self:GetAbility()
    local meatHook = caster:FindAbilityByName("boss_butcher_meat_hook")

    if caster:IsAttacking() and not caster:IsSilenced() then
        local victim = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            1300, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        if #victim > 0 then
            if not victim[1]:IsAlive() or victim[1]:IsMagicImmune() or not victim[1]:IsRealHero() then return end

            if consume:IsCooldownReady() and not caster:HasModifier("boss_butcher_consume_debuff_thinker_casting") then
                caster:SetAttacking(nil)
                caster:SetForceAttackTarget(nil)

                victim[1]:AddNewModifier(caster, consume, "boss_butcher_consume_debuff", { duration = 10 })
                caster:AddNewModifier(caster, consume, "boss_butcher_consume_debuff_thinker_casting", { duration = 10 })
                
                consume:UseResources(false, false, false, true)
            end

            if meatHook:IsCooldownReady() and not caster:HasModifier("boss_butcher_consume_debuff_thinker_casting") then
                if ((victim[1]:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 300) then
                    caster:SetAttacking(nil)
                    caster:SetForceAttackTarget(nil)

                    caster:AddNewModifier(caster, meatHook, "boss_butcher_consume_debuff_thinker_casting", { duration = 0.5 })
                    caster:CastAbilityOnPosition(victim[1]:GetAbsOrigin(), meatHook, -1)
                    
                    meatHook:UseResources(false, false, false, true)
                end
            end
        end
    end
end

function boss_butcher_consume_debuff_thinker_casting:IsHidden() return true end
function boss_butcher_consume_debuff_thinker_casting:IsPurgable() return false end
function boss_butcher_consume_debuff_thinker_casting:RemoveOnDeath() return false end

function boss_butcher_consume_debuff_thinker_casting:GetOverrideAnimation() return ACT_DOTA_CHANNEL_ABILITY_4 end

function boss_butcher_consume_debuff_thinker_casting:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
    return state
end

function boss_butcher_consume_debuff_thinker_casting:OnCreated()
    if not IsServer() then return end

    self:GetParent():SetAttacking(nil)
    self:GetParent():SetForceAttackTarget(nil)

    self.cap = self:GetParent():GetAttackCapability()

    self:GetParent():SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

    if self:GetAbility():GetAbilityName() == "boss_butcher_consume" then
        self:GetParent():StartGesture(ACT_DOTA_CHANNEL_ABILITY_4)
    end
end

function boss_butcher_consume_debuff_thinker_casting:OnDestroy()
    if not IsServer() then return end

    self:GetParent():SetAttackCapability(self.cap)
    if self:GetAbility():GetAbilityName() == "boss_butcher_consume" then
        self:GetParent():RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_4)
    end
end

function boss_butcher_consume:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    self.target = self:GetCursorTarget()
    self.originPos = self.target:GetAbsOrigin()

    if self.target:TriggerSpellAbsorb(ability) then
        self.target:TriggerSpellAbsorb(ability)
        Timers:CreateTimer(0.5, function()
            --ability:EndChannel(true)
            self.target:RemoveModifierByName("boss_butcher_consume_debuff")
        end)
        caster:Stop()
        return
    end

    self.target:AddNewModifier(caster, ability, "boss_butcher_consume_debuff", {})
end

function boss_butcher_consume:OnChannelFinish(interrupted)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self.target and not self.target:IsNull() then
        self.target:RemoveModifierByNameAndCaster("boss_butcher_consume_debuff", caster)
        self.target:SetAbsOrigin(self.originPos)
    end

    caster:StopSound("Hero_Pudge.Dismember.Arcana")
    caster:StopSound("Hero_Pudge.Gore.Arcana")
end

function boss_butcher_consume:GetChannelTime()
    return self:GetSpecialValueFor("duration")
end
--------
function boss_butcher_consume_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }

    return funcs
end

function boss_butcher_consume_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)

    self:GetParent():AddNoDraw()
end

function boss_butcher_consume_debuff:OnDestroy()
    if not IsServer() then return end

    self:GetParent():RemoveNoDraw()
    self:GetCaster():RemoveModifierByName("boss_butcher_consume_debuff_thinker_casting")
end

function boss_butcher_consume_debuff:OnIntervalThink()
    local ability = self:GetAbility()
    local victim = self:GetParent()
    local attacker = self:GetCaster()

    if attacker:IsSilenced() or attacker:IsStunned() or attacker:IsHexed() then
        victim:RemoveModifierByName("boss_butcher_consume_debuff")
        self:StartIntervalThink(-1)
        return
    end
    
    local damage = ((victim:GetMaxHealth() / 100) * ability:GetSpecialValueFor("health_as_damage_pct")) * 0.5

    local tableDamage = {
        victim = victim,
        attacker = attacker,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        ability = ability
    }

    victim:SetAbsOrigin(attacker:GetAbsOrigin())

    ApplyDamage(tableDamage)

    EmitSoundOnLocationWithCaster(attacker:GetAbsOrigin(), "Hero_Pudge.Dismember.Damage.Arcana", attacker)
    EmitSoundOnLocationWithCaster(attacker:GetAbsOrigin(), "Hero_Pudge.Dismember.Gore.Arcana", attacker)
end

function boss_butcher_consume_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.target ~= self:GetParent() then return end
    if event.attacker:GetUnitName() ~= "npc_dota_creature_100_boss_2" then return -100 end

    return 100
end

function boss_butcher_consume_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true
    }

    return state
end