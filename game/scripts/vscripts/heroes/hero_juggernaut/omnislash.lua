LinkLuaModifier("modifier_juggernaut_omnislash_custom", "heroes/hero_juggernaut/omnislash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omnislash_custom_slash", "heroes/hero_juggernaut/omnislash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omnislash_custom_slash_debuff", "heroes/hero_juggernaut/omnislash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omnislash_custom_casting", "heroes/hero_juggernaut/omnislash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omnislash_custom_scepter", "heroes/hero_juggernaut/omnislash.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassSlash = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

CLONE_UNIT = nil

juggernaut_omnislash_custom = class(ItemBaseClass)
modifier_juggernaut_omnislash_custom = class(juggernaut_omnislash_custom)
modifier_juggernaut_omnislash_custom_slash = class(ItemBaseClassSlash)
modifier_juggernaut_omnislash_custom_slash_debuff = class(ItemBaseClassSlash)
modifier_juggernaut_omnislash_custom_casting = class(ItemBaseClassActive)
modifier_juggernaut_omnislash_custom_scepter = class(ItemBaseClassActive)
-------------
function juggernaut_omnislash_custom:GetIntrinsicModifierName()
    return "modifier_juggernaut_omnislash_custom"
end

function juggernaut_omnislash_custom:GetAOERadius()
    if self:GetCaster():HasScepter() then return self:GetSpecialValueFor("scepter_radius") end
    return 0
end

function juggernaut_omnislash_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_juggernaut_omnislash_custom_scepter", {
        duration = self:GetSpecialValueFor("scepter_activate_duration")
    })

    caster:AddNewModifier(caster, self, "modifier_juggernaut_omnislash_custom_casting", {
        duration = self:GetSpecialValueFor("scepter_activate_duration")
    })

    EmitSoundOn("juggernaut_jug_ability_omnislash_03", caster)

    self:UseResources(false, false, false, true)
end

function juggernaut_omnislash_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if CLONE_UNIT and CLONE_UNIT[1] then
        if not CLONE_UNIT[1]:IsAlive() then return end
        CLONE_UNIT[1]:ForceKill(false)
        CLONE_UNIT = nil
    end

    caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_scepter", caster)
    caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_casting", caster)

    caster:FadeGesture(ACT_DOTA_CAST_ABILITY_4)
end

function juggernaut_omnislash_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end
end

function juggernaut_omnislash_custom:GetChannelTime()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return self:GetSpecialValueFor("scepter_activate_duration")
    end
end
--
function modifier_juggernaut_omnislash_custom_scepter:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local interval = (1 / caster:GetAttacksPerSecond(false))
    if interval > 1.5 then
        interval = 1.5
    end

    if interval < 0.05 then
        interval = 0.05
    end

    self:StartIntervalThink(interval)
end

function modifier_juggernaut_omnislash_custom_scepter:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local smoke_pfx = ParticleManager:CreateParticle("particles/frostivus_herofx/juggernaut_omnislash_ascension.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControl(smoke_pfx, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(smoke_pfx, 1, self:GetCaster():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(smoke_pfx)

    EmitSoundOn("juggernaut_jugg_ability_bladefury_18", caster)
end

function modifier_juggernaut_omnislash_custom_scepter:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("scepter_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #victims < 1 then return end

    local victim = victims[RandomInt(1, #victims)]

    if not victim then return end

    if not victim:IsAlive() or not caster:CanEntityBeSeenByMyTeam(victim) then return end

    if not victim:HasModifier("modifier_juggernaut_omnislash_custom_slash") then
        victim:AddNewModifier(caster, ability, "modifier_juggernaut_omnislash_custom_slash", {
            duration = (1 / caster:GetAttacksPerSecond(false))
        })
    end

    --[[
    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or not caster:CanEntityBeSeenByMyTeam(victim) then break end

        if not victim:HasModifier("modifier_juggernaut_omnislash_custom_slash") then
            victim:AddNewModifier(caster, ability, "modifier_juggernaut_omnislash_custom_slash", {
                duration = ability:GetSpecialValueFor("duration")
            })
        end
    end
    --]]
end
--

function modifier_juggernaut_omnislash_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_juggernaut_omnislash_custom:OnCreated()
    self.parent = self:GetParent()

    self.cooldown = false
end

function modifier_juggernaut_omnislash_custom:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if unit:IsIllusion() then return end

    local ability = self:GetAbility()

    if self.cooldown then return end
    if not RollPercentageTCOT(ability, ability:GetSpecialValueFor("chance")) then return end

    if not victim:HasModifier("modifier_juggernaut_omnislash_custom_slash") and victim:IsAlive() then
        victim:AddNewModifier(caster, ability, "modifier_juggernaut_omnislash_custom_slash", {
            duration = ability:GetSpecialValueFor("duration")
        })

        self.cooldown = true

        Timers:CreateTimer(ability:GetSpecialValueFor("proc_cooldown"), function()
            self.cooldown = false
        end)
    end
end
--
function modifier_juggernaut_omnislash_custom_slash:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local interval = (1 / caster:GetAttacksPerSecond(false))
    if interval > 1.0 then
        interval = 0.75
    end

    if interval < 0.05 then
        interval = 0.05
    end

    if CLONE_UNIT == nil then
        CLONE_UNIT = CreateIllusions(caster, caster, {
            outgoing_damage = 100,
            incoming_damage = 0,
            outgoing_damage_roshan = 100,
            outgoing_damage_structure = 100
        }, 1, 0, false, false)
    end

    self:StartIntervalThink(interval)
    self:OnIntervalThink()

    if self:GetParent():IsAlive() then
        caster:AddNewModifier(caster, ability, "modifier_juggernaut_omnislash_custom_casting", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end
end

function modifier_juggernaut_omnislash_custom_slash:OnIntervalThink()
    local victim = self:GetParent()
    local caster = self:GetCaster()

    if not CLONE_UNIT then return end
    if not CLONE_UNIT[1] then return end

    if not victim:IsAlive() or not caster:IsAlive() or caster:PassivesDisabled() then 
        if not caster:HasModifier("modifier_juggernaut_omnislash_custom_scepter") then
            caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_casting", caster)
        end
        victim:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_slash", caster)
        self:StartIntervalThink(-1) 
        return
    end

    CLONE_UNIT[1]:AddNewModifier(caster, self, "modifier_juggernaut_omnislash_custom_casting", {})
    CLONE_UNIT[1]:SetAbsOrigin(victim:GetAbsOrigin())
    CLONE_UNIT[1]:PerformAttack(victim, true, true, true, true, false, false, true)

    if not victim:IsAlive() then 
        if not caster:HasModifier("modifier_juggernaut_omnislash_custom_scepter") then
            caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_casting", caster)
        end
        victim:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_slash", caster)
        self:StartIntervalThink(-1) 
        return
    end

    local mod = victim:FindModifierByName("modifier_juggernaut_omnislash_custom_slash_debuff")
    if mod == nil then
        mod = victim:AddNewModifier(caster, self:GetAbility(), "modifier_juggernaut_omnislash_custom_slash_debuff", { duration = 1.0 })
    end

    mod:IncrementStackCount()

    self:PlayEffects(victim)
end

function modifier_juggernaut_omnislash_custom_slash:PlayEffects(target)
    -- Get Resources
    local effect = "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_omni_slash_tgt_bladekeeper.vpcf"
    local particle = ParticleManager:CreateParticle( effect, PATTACH_ABSORIGIN_FOLLOW, target )
      ParticleManager:SetParticleControlEnt( particle, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true )
     ParticleManager:SetParticleControlEnt( particle, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true )

    effect = "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_omni_slash_trail.vpcf"
    local trail_pfx = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(trail_pfx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(trail_pfx, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(trail_pfx)

    effect = "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_omni_slash_trail_serrakura.vpcf"
    local trail_pfx = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(trail_pfx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(trail_pfx, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(trail_pfx)
end

function modifier_juggernaut_omnislash_custom_slash:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_juggernaut_omnislash_custom_slash:OnDeath(event)
    if self:GetParent() ~= event.unit then return end

    local caster = event.attacker
    local victim = event.unit

    if not caster:HasModifier("modifier_juggernaut_omnislash_custom_scepter") then
        caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_casting", caster)
    end
    victim:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_slash", caster)
    self:StartIntervalThink(-1)
end

function modifier_juggernaut_omnislash_custom_slash:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local victim = self:GetParent()

    if CLONE_UNIT and CLONE_UNIT[1] then
        if not CLONE_UNIT[1]:IsAlive() then return end
        CLONE_UNIT[1]:ForceKill(false)
        CLONE_UNIT = nil
    end

    if not caster:HasModifier("modifier_juggernaut_omnislash_custom_scepter") then
        caster:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_casting", caster)
    end
    victim:RemoveModifierByNameAndCaster("modifier_juggernaut_omnislash_custom_slash", caster)
    self:StartIntervalThink(-1)
end
--
function modifier_juggernaut_omnislash_custom_slash_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }

    return funcs
end

function modifier_juggernaut_omnislash_custom_slash_debuff:OnCreated()
    local parent = self:GetParent()

    self.shred = parent:GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("armor_shred_pct")/100)

    if self:GetCaster():HasScepter() then
        self.shred = parent:GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("scepter_armor_shred_pct")/100)
    end
end

function modifier_juggernaut_omnislash_custom_slash_debuff:GetModifierPhysicalArmorBonus()
    if not self.shred then return end

    return -self.shred * self:GetStackCount()
end

function modifier_juggernaut_omnislash_custom_slash_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
------
function modifier_juggernaut_omnislash_custom_casting:OnCreated()
    if not IsServer() then return end

    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_4)
    self:GetParent():AddNoDraw()
end

function modifier_juggernaut_omnislash_custom_casting:OnDestroy()
    if not IsServer() then return end

    self:GetParent():RemoveGesture(ACT_DOTA_CAST_ABILITY_4)
    self:GetParent():RemoveNoDraw()
end


function modifier_juggernaut_omnislash_custom_casting:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end