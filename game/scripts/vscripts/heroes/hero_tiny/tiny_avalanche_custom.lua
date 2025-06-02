LinkLuaModifier("modifier_tiny_avalanche_custom", "heroes/hero_tiny/tiny_avalanche_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiny_avalanche_custom_thinker", "heroes/hero_tiny/tiny_avalanche_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiny_avalanche_custom_debuff", "heroes/hero_tiny/tiny_avalanche_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiny_avalanche_custom_slow", "heroes/hero_tiny/tiny_avalanche_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tiny_avalanche_custom = class(ItemBaseClass)
modifier_tiny_avalanche_custom = class(tiny_avalanche_custom)
modifier_tiny_avalanche_custom_thinker = class(ItemBaseClass)
modifier_tiny_avalanche_custom_debuff = class(ItemBaseClass)
modifier_tiny_avalanche_custom_slow = class(ItemBaseClass)
-------------
function tiny_avalanche_custom:GetIntrinsicModifierName()
    return "modifier_tiny_avalanche_custom"
end
------------
function modifier_tiny_avalanche_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_tiny_avalanche_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if parent:IsIllusion() then return end

    local target = event.target 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    local duration = ability:GetSpecialValueFor("duration")

    if not RollPercentage(chance) then return end

    CreateModifierThinker(
        parent,
        ability,
        "modifier_tiny_avalanche_custom_thinker",
        { duration = duration },
        target:GetAbsOrigin(),
        parent:GetTeam(),
        false
    )
end
-------------------------
function modifier_tiny_avalanche_custom_thinker:RemoveOnDeath() return true end

function modifier_tiny_avalanche_custom_thinker:OnCreated( kv )
    if IsServer() then
        -- references
        self.ability = self:GetAbility()
        self.parent = self:GetParent()
        self.caster = self:GetCaster()

        self.health = (self.caster:GetHealth() * (self.ability:GetSpecialValueFor("hp_cost_pct")/100))

        self.damage = self.ability:GetSpecialValueFor("damage") + self.health
        self.radius = self.ability:GetSpecialValueFor("radius")

        self.origin = self.parent:GetAbsOrigin()

        self.tick = self.ability:GetSpecialValueFor("tick_rate")

        if self.caster:HasModifier("modifier_item_aghanims_shard") then
            self.tick = self.tick/2
        end

        self.damageTable = {
            attacker = self.caster, 
            damage = self.damage, 
            damage_type = self.ability:GetAbilityDamageType(),
            ability = self.ability
        }

        -- Play effects
        self.effect_cast = nil
        self:PlayEffects(self.origin, self.radius)

        self:OnIntervalThink()
        self:StartIntervalThink(self.tick)

        if not self.caster:HasModifier("modifier_item_aghanims_shard") then
            ApplyDamage({
                victim = self.caster,
                attacker = self.caster,
                damage = self.health,
                damage_type = DAMAGE_TYPE_PURE,
                damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
            })
        end
    end
end

function modifier_tiny_avalanche_custom_thinker:OnIntervalThink()
    local victims = FindUnitsInRadius(self.parent:GetTeam(), self.origin, nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        self.damageTable.victim = victim 

        ApplyDamage(self.damageTable)

        victim:AddNewModifier(
            self.parent,
            self.ability,
            "modifier_tiny_avalanche_custom_slow",
            {
                duration = self.tick
            }
        )

        victim:AddNewModifier(
            self.parent,
            self.ability,
            "modifier_tiny_avalanche_custom_debuff",
            {
                duration = self.ability:GetSpecialValueFor("damage_weakness_duration")
            }
        )
    end
end

function modifier_tiny_avalanche_custom_thinker:OnDestroy( kv )
    if IsServer() then
        -- Damage enemies
        if self.effect_cast ~= nil then
            ParticleManager:DestroyParticle(self.effect_cast, false)
            ParticleManager:ReleaseParticleIndex(self.effect_cast)
        end

        -- remove thinker
        UTIL_Remove( self:GetParent() )
    end
end

function modifier_tiny_avalanche_custom_thinker:PlayEffects(origin, radius)
    -- Get Resources
    local particle_cast = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_avalanche.vpcf"
    local sound_cast = "Ability.Avalanche"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, origin )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector(radius, radius, radius) )

    -- Create Sound
    EmitSoundOnLocationWithCaster( origin, sound_cast, self.parent )
end
-------------------------
function modifier_tiny_avalanche_custom_debuff:RemoveOnDeath() return true end
function modifier_tiny_avalanche_custom_debuff:IsHidden() return false end
function modifier_tiny_avalanche_custom_debuff:IsDebuff() return true end

function modifier_tiny_avalanche_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_tiny_avalanche_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_weakness")
end
-------------------------
function modifier_tiny_avalanche_custom_slow:RemoveOnDeath() return true end
function modifier_tiny_avalanche_custom_slow:IsHidden() return false end
function modifier_tiny_avalanche_custom_slow:IsDebuff() return true end

function modifier_tiny_avalanche_custom_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  
    }
end

function modifier_tiny_avalanche_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end