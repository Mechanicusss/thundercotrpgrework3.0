LinkLuaModifier("modifier_item_blood_drainer", "items/item_blood_drainer/item_blood_drainer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_blood_drainer_toggle", "items/item_blood_drainer/item_blood_drainer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_blood_drainer_particle", "items/item_blood_drainer/item_blood_drainer", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassToggle = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassEffect = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_blood_drainer = class(ItemBaseClass)
item_blood_drainer_2 = item_blood_drainer
item_blood_drainer_3 = item_blood_drainer
item_blood_drainer_4 = item_blood_drainer
item_blood_drainer_5 = item_blood_drainer
item_blood_drainer_6 = item_blood_drainer
item_blood_drainer_7 = item_blood_drainer
modifier_item_blood_drainer = class(item_blood_drainer)
modifier_item_blood_drainer_toggle = class(ItemBaseClassToggle)
modifier_item_blood_drainer_particle = class(ItemBaseClassEffect)
-------------
function item_blood_drainer:GetIntrinsicModifierName()
    return "modifier_item_blood_drainer"
end

function item_blood_drainer:GetAbilityTextureName()
    if self:GetToggleState() then
        return "blood_drainer_toggle"
    end

    if self:GetLevel() == 1 then
        return "blood_drainer"
    elseif self:GetLevel() == 2 then
        return "blood_drainer_2"
    elseif self:GetLevel() == 3 then
        return "blood_drainer_3"
    elseif self:GetLevel() == 4 then
        return "blood_drainer_4"
    elseif self:GetLevel() == 5 then
        return "blood_drainer_5"
    elseif self:GetLevel() == 6 then
        return "blood_drainer_6"
    elseif self:GetLevel() == 7 then
        return "blood_drainer_7"
    end
end

function item_blood_drainer:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_blood_drainer:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_item_blood_drainer_toggle", {})
        caster:AddNewModifier(caster, self, "modifier_item_blood_drainer_particle", {})
    else
        caster:RemoveModifierByName("modifier_item_blood_drainer_toggle")
        caster:RemoveModifierByName("modifier_item_blood_drainer_particle")
    end
end
----------
function modifier_item_blood_drainer:OnRemoved()
    if not IsServer() then return end

    local ability = self:GetAbility()
    if ability:GetToggleState() then
        ability:ToggleAbility()
    end

    local parent = self:GetParent()
    parent:RemoveModifierByName("modifier_item_blood_drainer_toggle")
    parent:RemoveModifierByName("modifier_item_blood_drainer_particle")
end
----------
function modifier_item_blood_drainer:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }
end

function modifier_item_blood_drainer:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_blood_drainer:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
----------
function modifier_item_blood_drainer_toggle:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()


    self.baseDamage = ability:GetSpecialValueFor("base_damage")
    self.radius = ability:GetSpecialValueFor("radius")
    self.interval = ability:GetSpecialValueFor("interval")
    self.drain = ability:GetSpecialValueFor("health_drain_pct")/100
    self.maxDrain = ability:GetSpecialValueFor("max_health_drain")/100
    self.increment = ability:GetSpecialValueFor("health_drain_increment_pct")/100

    local damage = ((parent:GetMaxHealth() * (self.drain))) * self.interval

    self.damageTable = {
        attacker = parent,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
        --ability = ability,
    }

    self.damageTableEnemy = {
        attacker = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    self:StartIntervalThink(self.interval)
end

function modifier_item_blood_drainer_toggle:OnIntervalThink()
    local parent = self:GetParent()

    if self.drain < self.maxDrain then
        self.drain = self.drain + self.increment
    end

    self.damageTable.damage = ((parent:GetMaxHealth() * (self.drain)))
    self.damageTableEnemy.damage = (self.baseDamage + self.damageTable.damage) * self.interval

    self.damageTable.damage = self.damageTable.damage * self.interval
    self.damageTableEnemy.damage_flags = DOTA_DAMAGE_FLAG_NONE

    local resMult = 1 - parent:Script_GetMagicalArmorValue()

    if parent:GetHealth()-(self.damageTable.damage*resMult) <= 1 then 
        if self:GetAbility():GetToggleState() then
            self:GetAbility():ToggleAbility()
        end
        
        return 
    end

    ApplyDamage(self.damageTable)

    -- Damage Enemies --
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        self.damageTableEnemy.victim = victim

        ApplyDamage(self.damageTableEnemy)
    end
end

function modifier_item_blood_drainer_toggle:OnRemoved()
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_item_blood_drainer_particle")
end
-----------
function modifier_item_blood_drainer_particle:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local radius = self:GetAbility():GetSpecialValueFor("radius")

    local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_aoe_2.vpcf"
    local sound_cast = "Hero_Boodseeker.Bloodmist"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, radius, radius ) )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )

    self:StartIntervalThink(GameRules:GetGameFrameTime())
    self:OnIntervalThink()
end

function modifier_item_blood_drainer_particle:OnDestroy()
    if not IsServer() then return end

    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Stop sound
    local sound_cast = "Hero_Boodseeker.Bloodmist"
    StopSoundOn( sound_cast, self:GetParent() )
end

function modifier_item_blood_drainer_particle:OnIntervalThink()
    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetOrigin())
end