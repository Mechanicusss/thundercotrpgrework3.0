LinkLuaModifier("modifier_furion_wrath_of_nature_custom", "heroes/hero_furion/furion_wrath_of_nature_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_custom_thinker", "heroes/hero_furion/furion_wrath_of_nature_custom", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_furion_wrath_of_nature_custom_kill", "heroes/hero_furion/furion_wrath_of_nature_custom", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_furion_wrath_of_nature_custom_buff", "heroes/hero_furion/furion_wrath_of_nature_custom", LUA_MODIFIER_MOTION_NONE) 

local AbilityClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local AbilityClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local AbilityClassBuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

furion_wrath_of_nature_custom = class(AbilityClass)
modifier_furion_wrath_of_nature_custom = class(furion_wrath_of_nature_custom)
modifier_furion_wrath_of_nature_custom_thinker = class(AbilityClass)
modifier_furion_wrath_of_nature_custom_kill = class(AbilityClassDebuff)
modifier_furion_wrath_of_nature_custom_buff = class(AbilityClassBuff)

function furion_wrath_of_nature_custom:GetIntrinsicModifierName()
  return "modifier_furion_wrath_of_nature_custom"
end

function modifier_furion_wrath_of_nature_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_furion_wrath_of_nature_custom:OnCreated()
    if not IsServer() then return end

    self.enemiesHit = nil
end

function modifier_furion_wrath_of_nature_custom:OnAttack(event)
    if not IsServer() then return end

    local victim = event.target
    local attacker = event.attacker
    local parent = self:GetParent()

    if attacker ~= parent then return end
    if attacker == victim then return end
    if event.inflictor then return end

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("bounce_radius")
    local chance = ability:GetSpecialValueFor("chance")

    if not ability:IsCooldownReady() then return end
    if not RollPercentage(chance) then return end

    local victims = FindUnitsInRadius(parent:GetTeam(), victim:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() then
            victim:AddNewModifier(parent, ability, "modifier_furion_wrath_of_nature_custom_thinker", {})
            break
        end
    end

    self:PlayEffects(parent)
    EmitSoundOn("Hero_Furion.WrathOfNature_Cast", parent)
    ability:UseResources(false, false, false, true)
end

function modifier_furion_wrath_of_nature_custom:PlayEffects(target)
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_cast.vpcf", PATTACH_POINT_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
end

---------------
function modifier_furion_wrath_of_nature_custom_thinker:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.caster = self:GetCaster()

    self.ability = self:GetAbility()

    self.interval = self.ability:GetSpecialValueFor("bounce_interval")
    self.radius = self.ability:GetSpecialValueFor("bounce_radius")
    self.maxBounce = self.ability:GetSpecialValueFor("bounce_max")
    self.jumpMultiplier = self.ability:GetSpecialValueFor("bounce_damage_increase_per_jump")
    self.abilityType = self.ability:GetAbilityDamageType()

    self.position = self.caster:GetAbsOrigin()
    self.counter = 0
    self.bFoundTarget = false

    self.enemiesHit = {}

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_furion_wrath_of_nature_custom_thinker:OnIntervalThink()
    self.bFoundTarget = false

    function FindVictims()
        return FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
    end

    local victims = FindVictims()

    for i = 1, self.maxBounce, 1 do
        local victim = victims[i]
        if victim ~= nil and victim:IsAlive() and not victim:IsMagicImmune() and not self.enemiesHit[victim:entindex()] then
            self.bFoundTarget = true
            self.counter = self.counter + 1

            self:BounceAttack(victim, self.counter)

            self.enemiesHit[victim:entindex()] = true

            if i == #victims and self.maxBounce > #victims then
                self.enemiesHit = {}
                i = 1
            end

            victims = FindVictims()

            break
        end 
    end

    if not self.bFoundTarget or self.counter >= self.maxBounce then
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end

function modifier_furion_wrath_of_nature_custom_thinker:BounceAttack(enemy, nJump)
    self.wrath_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_POINT_FOLLOW, enemy)
    ParticleManager:SetParticleControl(self.wrath_particle, 0, enemy:GetAbsOrigin() + ((self.position - enemy:GetAbsOrigin()):Normalized() * 200))
    ParticleManager:SetParticleControlEnt(self.wrath_particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.wrath_particle, 2, enemy:GetAbsOrigin() + ((self.position - enemy:GetAbsOrigin()):Normalized() * 200))
    ParticleManager:SetParticleControlEnt(self.wrath_particle, 3, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.wrath_particle, 4, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(self.wrath_particle)

    self.position = enemy:GetAbsOrigin()
    enemy:EmitSound("Hero_Furion.WrathOfNature_Damage")

    self.damage = (self.ability:GetSpecialValueFor("bounce_damage") + (self.caster:GetBaseIntellect() * (self.ability:GetSpecialValueFor("int_to_damage")/100))) * (1 + (nJump * (self.jumpMultiplier/100)))

    if self.caster:HasScepter() then
        local debuff = enemy:FindModifierByName("modifier_furion_wrath_of_nature_custom_kill")
        if not debuff then
            debuff = enemy:AddNewModifier(self.caster, self.ability, "modifier_furion_wrath_of_nature_custom_kill", { duration = 1 })
        end

        if debuff then
            debuff:ForceRefresh()
        end
    end

    ApplyDamage({
        attacker = self.caster,
        victim = enemy,
        damage = self.damage,   
        damage_type = self.abilityType,
        ability = self.ability,     
    })
end
------------------
function modifier_furion_wrath_of_nature_custom_kill:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_furion_wrath_of_nature_custom_kill:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit
    local attacker = event.attacker

    if victim ~= parent then return end
    if victim == attacker then return end
    if attacker ~= self:GetCaster() then return end
    if not event.inflictor then return end
    if event.inflictor ~= self:GetAbility() then return end

    if not attacker:HasScepter() then return end

    local buff = attacker:FindModifierByName("modifier_furion_wrath_of_nature_custom_buff")
    if not buff then
        buff = attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_furion_wrath_of_nature_custom_buff", {
            duration = self:GetAbility():GetSpecialValueFor("scepter_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("scepter_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
-----------
function modifier_furion_wrath_of_nature_custom_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_furion_wrath_of_nature_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_furion_wrath_of_nature_custom_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("scepter_spell_amp") * self:GetStackCount()
end

function modifier_furion_wrath_of_nature_custom_buff:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("scepter_spell_amp") * self:GetStackCount()
end