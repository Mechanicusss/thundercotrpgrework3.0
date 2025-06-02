LinkLuaModifier("modifier_treant_bark_custom", "heroes/hero_treant/treant_bark", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_bark_custom_layer", "heroes/hero_treant/treant_bark", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_bark_custom_layer_immune", "heroes/hero_treant/treant_bark", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassLayer = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

treant_bark_custom = class(BaseClass)
modifier_treant_bark_custom = class(treant_bark_custom)
modifier_treant_bark_custom_layer = class(BaseClassLayer)
modifier_treant_bark_custom_layer_immune = class(BaseClassLayer)
-------------
function modifier_treant_bark_custom_layer_immune:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true
    }

    return state
end
-------------
function modifier_treant_bark_custom_layer:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, --GetModifierPhysical_ConstantBlock
        MODIFIER_EVENT_ON_TAKEDAMAGE, --OnTakeDamage
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_treant_bark_custom:GetEffectName()
    if not self.isCooldown then
        return "particles/units/heroes/hero_treant/treant_livingarmor.vpcf"
    end

    return ""
end

function modifier_treant_bark_custom:GetEffectAttachType()
    return PATTACH_POINT_FOLLOW
end

function modifier_treant_bark_custom_layer:OnDeath(event)
    local parent = self:GetParent()
    if parent ~= event.unit then return end

    self.isCooldown = false
    self.canRegenLayers = true
    self:SetStackCount(self.max)
end

function modifier_treant_bark_custom_layer:OnTakeDamage(event)
    local parent = self:GetParent()
    if parent ~= event.unit then return end
    if parent:PassivesDisabled() then return end

    if self:GetStackCount() > 0 and not self.isCooldown then
        self.damageAbsorbed = self.damageAbsorbed + event.damage

        if self.damageAbsorbed > (parent:GetMaxHealth() * (self.defense / 100)) then
            self:DecrementStackCount()

            local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                self.explosionRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,victim in ipairs(victims) do
                if not victim:IsAlive() or victim:IsMagicImmune() then break end

                ApplyDamage({
                    victim = victim, 
                    attacker = parent, 
                    damage = parent:GetMaxHealth() * (self.defense/100), 
                    damage_type = DAMAGE_TYPE_MAGICAL
                })
            end

            self.damageAbsorbed = 0

            --self:PlayEffects(parent)
        end
    end

    if self:GetStackCount() < 1 and not self.isCooldown then
        self.canRegenLayers = false
        self.isCooldown = true

        parent:AddNewModifier(parent, nil, "modifier_treant_bark_custom_layer_immune", { duration = self.immunityDuration })
    end
end

function modifier_treant_bark_custom_layer:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()

    local maxStacks = ability:GetSpecialValueFor("max_layers")
    local regenInterval = ability:GetSpecialValueFor("layer_regen_interval")
    local maxHPDefense = ability:GetSpecialValueFor("max_hp_defense_pct")
    local immunityDuration = ability:GetSpecialValueFor("layer_depleted_immunity_duration")
    local explosionRadius = ability:GetSpecialValueFor("layer_explosion_radius")

    self.defense = maxHPDefense
    self.interval = regenInterval
    self.immunityDuration = immunityDuration
    self.explosionRadius = explosionRadius
    self.max = maxStacks
end

function modifier_treant_bark_custom_layer:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local maxStacks = ability:GetSpecialValueFor("max_layers")
    local regenInterval = ability:GetSpecialValueFor("layer_regen_interval")
    local maxHPDefense = ability:GetSpecialValueFor("max_hp_defense_pct")
    local immunityDuration = ability:GetSpecialValueFor("layer_depleted_immunity_duration")
    local explosionRadius = ability:GetSpecialValueFor("layer_explosion_radius")

    self.defense = maxHPDefense
    self.interval = regenInterval
    self.immunityDuration = immunityDuration
    self.explosionRadius = explosionRadius
    self.max = maxStacks

    self.damageAbsorbed = 0
    self.canRegenLayers = true
    self.isCooldown = false

    self:StartIntervalThink(self.interval)
end

function modifier_treant_bark_custom_layer:OnIntervalThink()
    local stacks = self:GetStackCount()

    if self.isCooldown then
        if stacks < self.max then
            self:IncrementStackCount()
        end
        
        if self:GetStackCount() == self.max then
            self.isCooldown = false
            self.canRegenLayers = true
            --EmitSoundOn( "Hero_Treant.LivingArmor.Target", self:GetParent() )
            return
        end
    end

    if (stacks+1) > self.max then return end
    if not self.canRegenLayers then return end

    self:IncrementStackCount()
end

function modifier_treant_bark_custom_layer:GetModifierPhysical_ConstantBlock()
    if self:GetParent():PassivesDisabled() or self.isCooldown then return 0 end
    return (self:GetParent():GetMaxHealth() * (self.defense/100)) * self:GetStackCount()
end

function modifier_treant_bark_custom_layer:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/arena/items_fx/golden_eagle_relic_projectile_explosion_c.vpcf"
    local sound_cast = "Hero_Treant.LivingArmor.Target"

    -- Get Data
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
    ParticleManager:SetParticleControlForward( effect_cast, 1, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-------------
function treant_bark_custom:GetIntrinsicModifierName()
    return "modifier_treant_bark_custom"
end

function treant_bark_custom:OnUpgrade()
    if not IsServer() then return end

    local parent = self:GetCaster()
    local ability = self

    local maxStacks = ability:GetSpecialValueFor("max_layers")
    
    local modifier = parent:FindModifierByNameAndCaster("modifier_treant_bark_custom_layer", parent)
    if modifier ~= nil then
        modifier:ForceRefresh()
        modifier:SetStackCount(maxStacks)
    end
end
---------------
function modifier_treant_bark_custom:DeclareFunctions()
    local funcs = {
         
    }
    return funcs
end

function modifier_treant_bark_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local maxStacks = ability:GetSpecialValueFor("max_layers")
    local regenInterval = ability:GetSpecialValueFor("layer_regen_interval")
    local maxHPDefense = ability:GetSpecialValueFor("max_hp_defense_pct")
    local immunityDuration = ability:GetSpecialValueFor("layer_depleted_immunity_duration")
    local explosionRadius = ability:GetSpecialValueFor("layer_explosion_radius")

    parent:AddNewModifier(parent, ability, "modifier_treant_bark_custom_layer", {}):SetStackCount(maxStacks)
end

