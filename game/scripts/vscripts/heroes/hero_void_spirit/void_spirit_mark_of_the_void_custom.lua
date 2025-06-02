LinkLuaModifier("modifier_void_spirit_mark_of_the_void_custom", "heroes/hero_void_spirit/void_spirit_mark_of_the_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_mark_of_the_void_custom_debuff", "heroes/hero_void_spirit/void_spirit_mark_of_the_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_mark_of_the_void_custom_scepter_buff", "heroes/hero_void_spirit/void_spirit_mark_of_the_void_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

void_spirit_mark_of_the_void_custom = class(ItemBaseClass)
modifier_void_spirit_mark_of_the_void_custom = class(void_spirit_mark_of_the_void_custom)
modifier_void_spirit_mark_of_the_void_custom_debuff = class(ItemBaseClassDebuff)
modifier_void_spirit_mark_of_the_void_custom_scepter_buff = class(ItemBaseClassBuff)
-------------
function void_spirit_mark_of_the_void_custom:GetIntrinsicModifierName()
    return "modifier_void_spirit_mark_of_the_void_custom"
end

function void_spirit_mark_of_the_void_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end
end

function void_spirit_mark_of_the_void_custom:GetCooldown()
    if not self:GetCaster():HasScepter() then return end

    return self:GetSpecialValueFor("scepter_cooldown")
end

function void_spirit_mark_of_the_void_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not caster:HasScepter() then return end

    local duration = self:GetSpecialValueFor("scepter_duration")

    EmitSoundOn("Hero_VoidSpirit.AstralStep.Start", caster)

    caster:AddNewModifier(
        caster,
        self,
        "modifier_void_spirit_mark_of_the_void_custom_scepter_buff",
        {
            duration = duration
        }
    )
end

function modifier_void_spirit_mark_of_the_void_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_void_spirit_mark_of_the_void_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if attacker ~= parent then return end
    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end
    if not event.inflictor then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() then return end
        if event.inflictor:GetAbilityName() ~= "void_spirit_aether_remnant_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_dissimilate_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_astral_convergence_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_resonant_pulse_custom" then return end
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then return end
    local ability = self:GetAbility()
    
    local debuff = victim:FindModifierByName("modifier_void_spirit_mark_of_the_void_custom_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(attacker, ability, "modifier_void_spirit_mark_of_the_void_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-----------------------
function modifier_void_spirit_mark_of_the_void_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    -- Visual Counter --
    self.vfxCounter = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_drow/drow_hypothermia_counter__2stack.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        parent
    )

    ParticleManager:SetParticleControlEnt(self.vfxCounter, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

    self:SetVFXCounter(1)
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:OnDestroy()
    if not IsServer() then return end

    if self.vfxCounter ~= nil then
        ParticleManager:DestroyParticle(self.vfxCounter, false)
        ParticleManager:ReleaseParticleIndex(self.vfxCounter)
    end
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:OnRefresh()
    if not IsServer() then return end

    self:SetVFXCounter(self:GetStackCount())
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:SetVFXCounter(count)
    if not IsServer() then return end

    ParticleManager:SetParticleControl(self.vfxCounter, 1, Vector(0, count, 0))
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() then return end
        if event.inflictor:GetAbilityName() ~= "void_spirit_aether_remnant_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_dissimilate_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_astral_convergence_custom" and event.inflictor:GetAbilityName() ~= "void_spirit_resonant_pulse_custom" then return end
    end

    local damage = self:GetAbility():GetSpecialValueFor("damage_per_stack") * self:GetStackCount()

    if not self:GetCaster():HasModifier("modifier_void_spirit_mark_of_the_void_custom_scepter_buff") and (self:GetStackCount() >= self:GetAbility():GetSpecialValueFor("max_stacks")) then
        self:SetStackCount(0)
    end

    return damage
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:GetStatusEffectName()
    return "particles/units/heroes/hero_vengeful/vengeful_venge_aura_cast.vpcf"
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_void_spirit_mark_of_the_void_custom_debuff:StatusEffectPriority()
    return 10001
end