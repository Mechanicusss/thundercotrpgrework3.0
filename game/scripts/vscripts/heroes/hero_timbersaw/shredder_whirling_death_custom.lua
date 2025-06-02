LinkLuaModifier("modifier_shredder_whirling_death_custom", "heroes/hero_timbersaw/shredder_whirling_death_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shredder_whirling_death_custom_debuff", "heroes/hero_timbersaw/shredder_whirling_death_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shredder_whirling_death_custom_buff", "heroes/hero_timbersaw/shredder_whirling_death_custom", LUA_MODIFIER_MOTION_NONE)

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

shredder_whirling_death_custom = class(ItemBaseClass)
modifier_shredder_whirling_death_custom = class(shredder_whirling_death_custom)
modifier_shredder_whirling_death_custom_debuff = class(ItemBaseClassDebuff)
modifier_shredder_whirling_death_custom_buff = class(ItemBaseClassDebuff)
-------------
function shredder_whirling_death_custom:GetIntrinsicModifierName()
    return "modifier_shredder_whirling_death_custom"
end
-------------
function modifier_shredder_whirling_death_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_shredder_whirling_death_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    
    if parent ~= event.target or parent == event.attacker then return end 

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 
    if parent:PassivesDisabled() then return end

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("whirling_radius")
    local damage = ability:GetSpecialValueFor("whirling_damage")
    local duration = ability:GetSpecialValueFor("duration")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")
    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end

    GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), radius, false)

    local found = false

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

        found = true

        ApplyDamage({
            attacker = parent,
            victim = enemy,
            damage = damage + (parent:GetStrength() * (ability:GetSpecialValueFor("str_to_damage"))),
            ability = ability,
            damage_type = ability:GetAbilityDamageType()
        })

        local buff = parent:FindModifierByName("modifier_shredder_whirling_death_custom_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, ability, "modifier_shredder_whirling_death_custom_buff", {
                duration = duration
            })
        end 

        if buff then
            if buff:GetStackCount() < maxStacks then
                buff:IncrementStackCount()
            end 

            buff:ForceRefresh()
        end

        enemy:AddNewModifier(parent, ability, "modifier_shredder_whirling_death_custom_debuff", {
            duration = duration
        })
    end

    self:PlayEffects(radius, found)
end

function modifier_shredder_whirling_death_custom:PlayEffects( radius, hashero )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_shredder/shredder_whirling_death.vpcf"
    local sound_cast = "Hero_Shredder.WhirlingDeath.Cast"
    local sound_target = "Hero_Shredder.WhirlingDeath.Damage"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CENTER_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetCaster(),
        PATTACH_CENTER_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
    if hashero then
        EmitSoundOn( sound_target, self:GetCaster() )
    end
end
-----------
function modifier_shredder_whirling_death_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
    }
end

function modifier_shredder_whirling_death_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local conversion = ability:GetSpecialValueFor("stat_loss_pct")

    self.originalStrength = parent:GetStrength() * (conversion/100)

    self:StartIntervalThink(FrameTime())
end 

function modifier_shredder_whirling_death_custom_buff:OnIntervalThink()
    self.damage = self.originalStrength * self:GetStackCount()
    self:InvokeBonusDamage()
end

function modifier_shredder_whirling_death_custom_buff:GetModifierBonusStats_Strength()
    return self.fDamage
end

function modifier_shredder_whirling_death_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_shredder_whirling_death_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_shredder_whirling_death_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-----------
function modifier_shredder_whirling_death_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_shredder_whirling_death_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end
