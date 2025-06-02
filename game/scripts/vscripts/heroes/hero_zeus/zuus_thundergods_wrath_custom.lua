LinkLuaModifier("modifier_zuus_thundergods_wrath_custom", "heroes/hero_zeus/zuus_thundergods_wrath_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_thundergods_wrath_custom_active", "heroes/hero_zeus/zuus_thundergods_wrath_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

zuus_thundergods_wrath_custom = class(ItemBaseClass)
modifier_zuus_thundergods_wrath_custom = class(zuus_thundergods_wrath_custom)
modifier_zuus_thundergods_wrath_custom_active = class(ItemBaseClassActive)
-------------
function zuus_thundergods_wrath_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_zuus_transcendence_custom_transport") then
        self:EndCooldown()
        return
    end

    caster:AddNewModifier(caster, self, "modifier_zuus_thundergods_wrath_custom_active", {
        duration = self:GetSpecialValueFor("duration")
    })
end

function zuus_thundergods_wrath_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
----
function modifier_zuus_thundergods_wrath_custom_active:DeclareFunctions()
    local funcs = {
    }
    return funcs
end

function modifier_zuus_thundergods_wrath_custom_active:OnCreated(params)
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.interval = self.ability:GetSpecialValueFor("damage_interval")
    self.damage = self.ability:GetSpecialValueFor("damage") + (self.parent:GetBaseIntellect() * (self.ability:GetSpecialValueFor("int_to_damage")/100))

    self.effect_cast = nil
    self.particlePosition = self.parent:GetAbsOrigin()
    self.particleAttach = PATTACH_CENTER_FOLLOW 

    -- Supercharge --
    self.superchargeStacks = self.parent:FindModifierByName("modifier_zuus_static_field_custom_stacks")
    if self.superchargeStacks ~= nil then
        local superchargesNeeded = self.ability:GetSpecialValueFor("static_field_charges")
        if self.superchargeStacks:GetAbility():GetToggleState() and superchargesNeeded <= self.superchargeStacks:GetStackCount() then 
            self.radius = self.ability:GetSpecialValueFor("static_field_radius")
            self.damage = self.damage * self.ability:GetSpecialValueFor("static_field_damage_mult")
            self.superchargeStacks:SetStackCount(self.superchargeStacks:GetStackCount()-superchargesNeeded)
        end
    end
    --

    self:CreateNimbusCircle(self.parent)

    self:StartIntervalThink(self.interval)
    self:OnIntervalThink()
end

function modifier_zuus_thundergods_wrath_custom_active:OnIntervalThink()
    local randomPos = Vector(
        RandomInt(self.parent:GetAbsOrigin().x-(self.radius-100), self.parent:GetAbsOrigin().x+(self.radius-100)), 
        RandomInt(self.parent:GetAbsOrigin().y-(self.radius-100), self.parent:GetAbsOrigin().y+(self.radius-100)), 
        self.parent:GetAbsOrigin().z
    )

    self:CreateLightningBolt(self.parent, randomPos)

    -- Deal damage --
    local victims = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local victim = victims[RandomInt(1, #victims)]

    if not victim or victim == nil then return end
    if not victim:IsAlive() or victim:IsMagicImmune() then return end

    ApplyDamage({
        victim = victim, 
        attacker = self.parent, 
        damage = self.damage, 
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    })
end

function modifier_zuus_thundergods_wrath_custom_active:OnDestroy()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_zuus_thundergods_wrath_custom_active:CreateNimbusCircle(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zeus/zeus_cloud_2.vpcf"
    local sound_cast = "Hero_Zuus.Cloud.Cast"

    self.particlePosition = target:GetAbsOrigin()

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle(particle_cast, self.particleAttach, target)

    ParticleManager:SetParticleControl(self.effect_cast, 0, self.particlePosition)
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(self.radius, self.radius, self.radius))
    ParticleManager:SetParticleControl(self.effect_cast, 2, self.particlePosition)
    ParticleManager:SetParticleControl(self.effect_cast, 5, self.particlePosition)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_zuus_thundergods_wrath_custom_active:CreateLightningBolt(target, pos)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt"

    -- Create Particle
    local effect = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, target)

    ParticleManager:SetParticleControl(effect, 0, Vector(pos.x, pos.y, pos.z))
    ParticleManager:SetParticleControl(effect, 1, Vector(pos.x, pos.y, 2000))
    ParticleManager:SetParticleControl(effect, 2, Vector(pos.x, pos.y, pos.z))

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_zuus_thundergods_wrath_custom_active:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end