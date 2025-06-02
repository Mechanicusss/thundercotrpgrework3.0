LinkLuaModifier("modifier_night_stalker_erupting_void_custom", "heroes/hero_night_stalker/night_stalker_erupting_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_erupting_void_custom_eruption_debuff", "heroes/hero_night_stalker/night_stalker_erupting_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_erupting_void_custom_eruption_aura", "heroes/hero_night_stalker/night_stalker_erupting_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_erupting_void_custom_eruption_end_slow", "heroes/hero_night_stalker/night_stalker_erupting_void_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_erupting_void_custom_silence", "heroes/hero_night_stalker/night_stalker_erupting_void_custom", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_debuff", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)

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

night_stalker_erupting_void_custom = class(ItemBaseClass)
modifier_night_stalker_erupting_void_custom = class(night_stalker_erupting_void_custom)
modifier_night_stalker_erupting_void_custom_eruption_debuff = class(ItemBaseClassDebuff)
modifier_night_stalker_erupting_void_custom_eruption_aura = class(ItemBaseClassDebuff)
modifier_night_stalker_erupting_void_custom_eruption_end_slow = class(ItemBaseClassDebuff)
modifier_night_stalker_erupting_void_custom_silence = class(ItemBaseClassDebuff)
-------------
function night_stalker_erupting_void_custom:GetIntrinsicModifierName()
    return "modifier_night_stalker_erupting_void_custom"
end
-------------
function modifier_night_stalker_erupting_void_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_night_stalker_erupting_void_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if parent:PassivesDisabled() then return end 

    local ability = self:GetAbility()

    if not ability:GetAutoCastState() then return end
    if target:HasModifier("modifier_night_stalker_erupting_void_custom_eruption_end_slow") then return end

    local duration = ability:GetSpecialValueFor("duration")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")

    local debuff = target:FindModifierByName("modifier_night_stalker_erupting_void_custom_eruption_debuff")
    if not debuff and ability:IsCooldownReady() then
        debuff = target:AddNewModifier(parent, ability, "modifier_night_stalker_erupting_void_custom_eruption_debuff", {
            duration = duration
        })

        ability:UseResources(false, false, false, true)

        EmitSoundOn("Hero_Nightstalker.Void", target)
    end

    if debuff then
        debuff:ForceRefresh()
    end
end
------------
function modifier_night_stalker_erupting_void_custom_eruption_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    self:Destroy()
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()
    self.caster = self:GetCaster()

    self.ability = self:GetAbility()

    self.radius = self.ability:GetSpecialValueFor("radius")
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")

    local interval = self.ability:GetSpecialValueFor("tick_interval")

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    self:AddParticle(self.vfx, false, false, -1, false, false)
    ParticleManager:SetParticleControl(self.vfx, 1, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 2, Vector(self.radius, self.radius, self.radius))
    ParticleManager:SetParticleControl(self.vfx, 3, self.parent:GetAbsOrigin())

    self.vfx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_night_stalker/night_stalker_void_zone.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl(self.vfx2, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx2, 1, Vector(self.radius, self.radius, self.radius))

    EmitSoundOn("Hero_Nightstalker.Trickling_Fear", target)

    self:StartIntervalThink(interval)
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:OnIntervalThink()
    if self:GetStackCount() < self.maxStacks then
        self:IncrementStackCount()
    end
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:OnRemoved()
    if not IsServer() then return end 

    if self.vfx then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if self.vfx2 then
        ParticleManager:DestroyParticle(self.vfx2, false)
        ParticleManager:ReleaseParticleIndex(self.vfx2)
    end

    EmitSoundOn("Hero_Nightstalker.Trickling_Fear_end", self:GetParent())
    StopSoundOn("Hero_Nightstalker.Trickling_Fear_lp", self:GetParent())

    local units = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil,
    self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_CLOSEST, false)

    for _,enemy in ipairs(units) do 
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end 

        ApplyDamage({
            attacker = self.caster,
            victim = enemy,
            damage = (self.caster:GetAverageTrueAttackDamage(self.caster) * (self.ability:GetSpecialValueFor("eruption_damage_attack_pct")/100)) + (self.caster:GetStrength() * (self.ability:GetSpecialValueFor("str_to_damage")/100)),
            ability = self.ability,
            damage_type = self.ability:GetAbilityDamageType()
        })

        enemy:AddNewModifier(self.caster, self.ability, "modifier_night_stalker_erupting_void_custom_eruption_end_slow", {
            duration = self.ability:GetSpecialValueFor("eruption_debuff_duration")
        })
    end
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:OnStackCountChanged(old)
    local count = self:GetStackCount()
    local ability = self:GetAbility()
    local growth = ability:GetSpecialValueFor("stack_area_growth")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")

    if not self.radius then
        self.radius = ability:GetSpecialValueFor("radius")
    end
    
    if count > old and count > 1 and self.vfx ~= nil and self.vfx2 ~= nil then
        self.radius = ability:GetSpecialValueFor("radius") + (growth*self:GetStackCount())

        ParticleManager:SetParticleControl(self.vfx, 2, Vector(self.radius, self.radius, self.radius))
        ParticleManager:SetParticleControl(self.vfx2, 1, Vector(self.radius, self.radius, self.radius))

        if count >= maxStacks then
            self:Destroy()
            return
        end
    end
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:IsAura()
    return true
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:GetAuraRadius()
    return self.radius
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:GetModifierAura()
    return "modifier_night_stalker_erupting_void_custom_eruption_aura"
end

function modifier_night_stalker_erupting_void_custom_eruption_debuff:GetAuraEntityReject(target)
    return target:GetTeam() == self.caster:GetTeam()
end
----------
function modifier_night_stalker_erupting_void_custom_eruption_aura:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()
    self.caster = self:GetCaster()

    self.ability = self:GetAbility()

    local radius = self.ability:GetSpecialValueFor("radius")
    local interval = self.ability:GetSpecialValueFor("tick_interval")

    self.damage = self.ability:GetSpecialValueFor("tick_damage")

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())

    self:StartIntervalThink(interval)

    if not GameRules:IsDaytime() then
        self.parent:AddNewModifier(self.caster, self.ability, "modifier_night_stalker_erupting_void_custom_silence", {})
    end

    if not self.caster:HasScepter() then return end 

    local chance = self.ability:GetSpecialValueFor("scepter_chance")
    if not RollPercentage(chance) then return end 

    local ascension = self.caster:FindAbilityByName("night_stalker_dark_ascension_custom")
    if not ascension then return end
    if ascension:GetLevel() < 1 then return end

    self.parent:AddNewModifier(self.caster, ascension, "modifier_night_stalker_dark_ascension_custom_debuff", {
        duration = ascension:GetSpecialValueFor("interval")
    })
end

function modifier_night_stalker_erupting_void_custom_eruption_aura:OnRemoved()
    if not IsServer() then return end 

    if self.vfx then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if self.parent:HasModifier("modifier_night_stalker_erupting_void_custom_silence") then
        self.parent:RemoveModifierByName("modifier_night_stalker_erupting_void_custom_silence")
    end
end

function modifier_night_stalker_erupting_void_custom_eruption_aura:OnIntervalThink()
    local owner = self:GetAuraOwner()

    if not owner:IsAlive() then
        self:Destroy()
        return
    end

    local debuff = owner:FindModifierByName("modifier_night_stalker_erupting_void_custom_eruption_debuff")
    
    if debuff then
        local stacks = debuff:GetStackCount()

        ApplyDamage({
            attacker = self.caster,
            victim = self.parent,
            damage = (self.damage + (self.caster:GetStrength() * (self.ability:GetSpecialValueFor("str_to_damage")/100))) * stacks,
            ability = self.ability,
            damage_type = self.ability:GetAbilityDamageType()
        })
    end
end
------------
function modifier_night_stalker_erupting_void_custom_eruption_end_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_night_stalker_erupting_void_custom_eruption_end_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("eruption_slow")
end

function modifier_night_stalker_erupting_void_custom_eruption_end_slow:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())

    EmitSoundOn("Hero_Nightstalker.Void", self.parent)
end

function modifier_night_stalker_erupting_void_custom_eruption_end_slow:OnRemoved()
    if not IsServer() then return end 

    if self.vfx then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end
----------
function modifier_night_stalker_erupting_void_custom_silence:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true,
    }
end

function modifier_night_stalker_erupting_void_custom_silence:GetEffectName()
    return "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear.vpcf"
end

function modifier_night_stalker_erupting_void_custom_silence:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end