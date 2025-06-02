LinkLuaModifier("modifier_void_spirit_aether_remnant_custom", "heroes/hero_void_spirit/void_spirit_aether_remnant_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_aether_remnant_custom_emitter", "heroes/hero_void_spirit/void_spirit_aether_remnant_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_aether_remnant_custom_emitter_aura", "heroes/hero_void_spirit/void_spirit_aether_remnant_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_aether_remnant_custom_buff", "heroes/hero_void_spirit/void_spirit_aether_remnant_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCaster = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

void_spirit_aether_remnant_custom = class(ItemBaseClass)
modifier_void_spirit_aether_remnant_custom = class(void_spirit_aether_remnant_custom)
modifier_void_spirit_aether_remnant_custom_emitter = class(ItemBaseClassCaster)
modifier_void_spirit_aether_remnant_custom_emitter_aura = class(ItemBaseClassCaster)
modifier_void_spirit_aether_remnant_custom_buff = class(ItemBaseClassCaster)
void_spirit_aether_remnant_custom.clones = {}
-------------
function void_spirit_aether_remnant_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function void_spirit_aether_remnant_custom:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    EmitSoundOn("Hero_VoidSpirit.AetherRemnant.Cast", caster)
end

function void_spirit_aether_remnant_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local damage = self:GetSpecialValueFor("illusion_damage")

    local illusions = CreateIllusions(
        caster,
        caster,
        {
            outgoing_damage = damage,
            incoming_damage = 0,
            bounty_base = 0,
            bounty_growth = 0,
            outgoing_damage_structure = 0,
            outgoing_damage_roshan = damage,
        },
        1,
        0,
        false,
        true
    )

    if #illusions < 1 then return end

    local illusion = illusions[1]
    if not illusion or illusion == nil then return end

    local duration = self:GetSpecialValueFor("duration")

    illusion:SetAbsOrigin(point)
    illusion:AddNewModifier(caster, self, "modifier_void_spirit_aether_remnant_custom_emitter", { 
        duration = duration
    })

    EmitSoundOn("Hero_VoidSpirit.AetherRemnant", caster)

    table.insert(self.clones, illusion:entindex())

    local maxCount = self:GetSpecialValueFor("max_count")
    if #self.clones > maxCount then
        for _,cloneIndex in pairs(self.clones) do
            local hClone = EntIndexToHScript(cloneIndex)
            if hClone ~= nil and not hClone:IsNull() then
                local mod = hClone:FindModifierByName("modifier_void_spirit_aether_remnant_custom_emitter")
                if mod ~= nil then
                    mod:Destroy()
                    break
                end
            end
        end
    end

    -- Buffs --
    if not caster:HasModifier("modifier_item_aghanims_shard") then return end
    
    local buff = caster:FindModifierByName("modifier_void_spirit_aether_remnant_custom_buff")
    if not buff then
        buff = caster:AddNewModifier(caster, self, "modifier_void_spirit_aether_remnant_custom_buff", {
            duration = self:GetSpecialValueFor("spell_amp_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetSpecialValueFor("max_count") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
------------
function modifier_void_spirit_aether_remnant_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetModifierBonusStats_Agility()
    return self.agility
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetModifierBonusStats_Strength()
    return self.strength
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetModifierBonusStats_Intellect()
    return self.intellect
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetModifierDamageOutgoing_Percentage()
    if self:GetCaster():HasModifier("modifier_void_spirit_astral_convergence_custom_caster") then
        return (self:GetAbility():GetSpecialValueFor("illusion_damage_empowered_multi")-1) * 100
    end
end

function modifier_void_spirit_aether_remnant_custom_emitter:OnAbilityFullyCast(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = event.ability

    if self.bCast == true then return end

    if not ability then return end
    if ability ~= nil then
        if ability == self:GetAbility() then return end
        if ability:GetAbilityName() ~= "void_spirit_dissimilate_custom" and ability:GetAbilityName() ~= "void_spirit_resonant_pulse_custom" then return end
    end

    if event.unit ~= caster then return end

    local copy = parent:FindAbilityByName(ability:GetAbilityName())
    if copy == nil then return end

    if ability:GetAbilityName() ~= "void_spirit_dissimilate_custom" then
        parent:StartGesture(ACT_DOTA_CAST_ABILITY_3)
    end

    if ability:GetAbilityName() ~= "void_spirit_resonant_pulse_custom" then
        parent:StartGesture(ACT_DOTA_CAST_ABILITY_4)
    end

    SpellCaster:Cast(copy, event.target, true)

    self.bCast = true
end

function modifier_void_spirit_aether_remnant_custom_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_void_spirit_aether_remnant_custom_emitter:OnCreated(params)
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    -- We need to calculate the attribute difference since 
    -- illusions don't seem to have the same attributes as the caster
    self.agility = caster:GetAgility() - parent:GetAgility()
    self.strength = caster:GetStrength() - parent:GetStrength()
    self.intellect = caster:GetBaseIntellect() - parent:GetBaseIntellect()

    if not IsServer() then return end

    for i=0, parent:GetAbilityCount()-1 do
        local abil = parent:GetAbilityByIndex(i)
        if abil ~= nil then
            if abil:GetAbilityName() == "void_spirit_dissimilate_custom" or abil:GetAbilityName() == "void_spirit_astral_convergence_custom" or abil:GetAbilityName() == "void_spirit_resonant_pulse_custom" then
                local parentLevel = self:GetCaster():FindAbilityByName(abil:GetAbilityName())
                if parentLevel ~= nil then
                    abil:SetLevel(parentLevel:GetLevel())
                end
            end
        end
    end

    parent:StartGesture(ACT_IDLE)

    EmitSoundOn("Hero_VoidSpirit.AetherRemnant.Spawn_lp", parent)
    
    local interval = ability:GetSpecialValueFor("interval")
    local radius = ability:GetSpecialValueFor("radius")

    self.bCast = false

    self.pfx = ParticleManager:CreateParticle("particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_darkrift__2ambient.vpcf", PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControl(self.pfx, 2, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 1, Vector(radius, radius, radius))

    self.pfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant__2watch.vpcf", PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControl(self.pfx2, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx2, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx2, 2, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx2, 3, parent:GetAbsOrigin())

    self:StartIntervalThink(0.1)
end

function modifier_void_spirit_aether_remnant_custom_emitter:OnIntervalThink()
    local parent = self:GetParent()
    if parent:IsAttacking() then return end

    local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in pairs(enemies) do
        if not enemy:IsAlive() or enemy:IsAttackImmune() then break end

        parent:SetForceAttackTarget(enemy)
        break
    end
end

function modifier_void_spirit_aether_remnant_custom_emitter:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    StopSoundOn("Hero_VoidSpirit.AetherRemnant.Spawn_lp", parent)
    EmitSoundOn("Hero_VoidSpirit.AetherRemnant.Destroy", parent)

    if self.pfx ~= nil then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
    end

    if self.pfx2 ~= nil then
        ParticleManager:DestroyParticle(self.pfx2, false)
        ParticleManager:ReleaseParticleIndex(self.pfx2)
    end

    for index,cloneIndex in pairs(ability.clones) do
        if cloneIndex == parent:entindex() then
            table.remove(ability.clones, index)
        end
    end

    if parent:IsAlive() then
        parent:ForceKill(false)
    end
end

function modifier_void_spirit_aether_remnant_custom_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetStatusEffectName()
    return "particles/status_fx/status_effect_void_spirit_pulse_buff.vpcf"
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_void_spirit_aether_remnant_custom_emitter:StatusEffectPriority()
    return 10001
end

function modifier_void_spirit_aether_remnant_custom_emitter:IsAura()
  return true
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetModifierAura()
    return "modifier_void_spirit_aether_remnant_custom_emitter_aura"
end

function modifier_void_spirit_aether_remnant_custom_emitter:GetAuraEntityReject(target)
    return false
end
-------------
function modifier_void_spirit_aether_remnant_custom_emitter_aura:IsDebuff() return true end

function modifier_void_spirit_aether_remnant_custom_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_void_spirit_aether_remnant_custom_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_slow")
end

function modifier_void_spirit_aether_remnant_custom_emitter_aura:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = (self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))) * interval,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    }

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_void_spirit_aether_remnant_custom_emitter_aura:OnIntervalThink()
    ApplyDamage(self.damageTable)
end
--------------
function modifier_void_spirit_aether_remnant_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end
function modifier_void_spirit_aether_remnant_custom_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp") * self:GetStackCount()
end