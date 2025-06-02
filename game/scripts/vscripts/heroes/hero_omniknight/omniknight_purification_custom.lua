LinkLuaModifier("modifier_omniknight_purification_custom", "heroes/hero_omniknight/omniknight_purification_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_purification_custom_casting", "heroes/hero_omniknight/omniknight_purification_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_purification_custom_linger_heal", "heroes/hero_omniknight/omniknight_purification_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCasting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

omniknight_purification_custom = class(ItemBaseClass)
modifier_omniknight_purification_custom = class(omniknight_purification_custom)
modifier_omniknight_purification_custom_casting = class(ItemBaseClassCasting)
modifier_omniknight_purification_custom_linger_heal = class(ItemBaseClassCasting)
-------------
function omniknight_purification_custom:GetIntrinsicModifierName()
    return "modifier_omniknight_purification_custom"
end

function omniknight_purification_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function omniknight_purification_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_CHANNELLED 
    else
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_CHANNELLED 
    end
end

function omniknight_purification_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local target = self:GetCursorTarget()

    if not caster:HasModifier("modifier_item_aghanims_shard") then
        caster:AddNewModifier(caster, self, "modifier_omniknight_purification_custom_casting", {
            duration = self:GetChannelTime(),
            targetEntIndex = target:entindex()
        })
    else
        caster:AddNewModifier(caster, self, "modifier_omniknight_purification_custom_casting", {
            duration = self:GetChannelTime()
        })
    end
end

function omniknight_purification_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_omniknight_purification_custom_casting")
end
-----------
function modifier_omniknight_purification_custom_casting:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")

    if not params.targetEntIndex or params.targetEntIndex == nil and parent:HasModifier("modifier_item_aghanims_shard") then
        self.target = nil
    else
        self.target = EntIndexToHScript(params.targetEntIndex)
        if not self.target or self.target == nil then self:Destroy() return end
    end

    local interval = ability:GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_omniknight_purification_custom_casting:OnIntervalThink()
    local parent = self:GetParent()

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    if self.target ~= nil then
        self:HealPurification(self.target)
    else
        local allies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self:GetAbility():GetSpecialValueFor("shard_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,ally in ipairs(allies) do
            if not ally:IsAlive() then break end

            self:HealPurification(ally)
        end
    end
end

function modifier_omniknight_purification_custom_casting:HealPurification(target)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not target or target == nil then self:Destroy() end
    if not target:IsAlive() then self:Destroy() end

    local healAmount = ability:GetSpecialValueFor("heal") + (caster:GetStrength() * (ability:GetSpecialValueFor("heal_from_str")/100))
    
    target:Purge(false, true, false, true, false)
    target:Heal(healAmount, ability)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        target,
        healAmount,
        nil
    )

    local buff = target:FindModifierByName("modifier_omniknight_purification_custom_linger_heal")
    if not buff then
        buff = target:AddNewModifier(caster, ability, "modifier_omniknight_purification_custom_linger_heal", {
            duration = ability:GetSpecialValueFor("linger_heal_duration")
        })
    end

    if buff then
        buff:ForceRefresh()
    end

    --- Find Targets ---
    local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = healAmount, 
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
    end

    self:PlayEffects(target)
end

function modifier_omniknight_purification_custom_casting:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf"
    local sound_cast = "Hero_Omniknight.Purification"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(self.radius, self.radius, self.radius) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
--------
function modifier_omniknight_purification_custom_linger_heal:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("linger_heal_interval")

    self:StartIntervalThink(interval)
end

function modifier_omniknight_purification_custom_linger_heal:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local healAmount = parent:GetMaxHealth() * (ability:GetSpecialValueFor("linger_heal_pct")/100)
    
    parent:Heal(healAmount, ability)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        parent,
        healAmount,
        nil
    )
end