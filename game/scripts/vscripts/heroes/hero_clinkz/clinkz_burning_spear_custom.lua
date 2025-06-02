LinkLuaModifier("modifier_clinkz_burning_spear_custom", "heroes/hero_clinkz/clinkz_burning_spear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_burning_spear_custom_casting", "heroes/hero_clinkz/clinkz_burning_spear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_burning_spear_custom_debuff", "heroes/hero_clinkz/clinkz_burning_spear_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

clinkz_burning_spear_custom = class(ItemBaseClass)
modifier_clinkz_burning_spear_custom = class(clinkz_burning_spear_custom)
modifier_clinkz_burning_spear_custom_casting = class(ItemBaseClassCasting)
modifier_clinkz_burning_spear_custom_debuff = class(ItemBaseClassDebuff)
-------------
function clinkz_burning_spear_custom:GetIntrinsicModifierName()
    return "modifier_clinkz_burning_spear_custom"
end

function clinkz_burning_spear_custom:GetAOERadius()
    return self:GetSpecialValueFor("spear_range")
end

function clinkz_burning_spear_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_clinkz_burning_spear_custom_casting", {
        x = point.x,
        y = point.y,
        z = point.z
    })
end

function clinkz_burning_spear_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_clinkz_burning_spear_custom_casting")
end

function clinkz_burning_spear_custom:OnProjectileThink(vLocation)
    if not IsServer() then return end

    if self.trailblazer_thinker and vLocation then
        self.trailblazer_thinker:SetAbsOrigin(vLocation)
    end
end

function clinkz_burning_spear_custom:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    if not hTarget then return end

    local caster = self:GetCaster()

    if caster:GetUnitName() == "npc_dota_clinkz_skeleton_archer_custom" then
        caster = caster:GetOwner()
    end

    local ability = self

    EmitSoundOn("Hero_Clinkz.SearingArrows.Impact", hTarget)

    local debuff = hTarget:FindModifierByName("modifier_clinkz_burning_spear_custom_debuff")
    if not debuff then
        debuff = hTarget:AddNewModifier(caster, ability, "modifier_clinkz_burning_spear_custom_debuff", {
            duration = ability:GetSpecialValueFor("debuff_duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("damage_increase_max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    local agility = caster:GetAgility()

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = (caster:GetAverageTrueAttackDamage(caster)*(ability:GetSpecialValueFor("damage")/100)) + (agility * (ability:GetSpecialValueFor("str_to_damage")/100)),
        ability = ability,
        damage_type = DAMAGE_TYPE_PHYSICAL,
    })
end
-----------
function modifier_clinkz_burning_spear_custom_casting:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    if caster:GetUnitName() == "npc_dota_clinkz_skeleton_archer_custom" then
        parent = caster:GetOwner()
    end

    print("Parent unit:", parent:GetUnitName())  -- Отладочный вывод

    local ability = self:GetAbility()
    local minInterval = ability:GetSpecialValueFor("min_interval")
    local interval = ability:GetSpecialValueFor("interval")
    local tInterval = interval

    if parent:HasModifier("modifier_item_aghanims_shard") then
        tInterval = parent:GetSecondsPerAttack(unit, target)  -- Исправлено: передаем 2 аргумента

        if tInterval < minInterval then
            tInterval = minInterval
        end

        if tInterval > interval then
            tInterval = interval
        end
    end

    interval = tInterval

    local vision = ability:GetSpecialValueFor("spear_vision")
    local speed = ability:GetSpecialValueFor("spear_speed")
    local radius = ability:GetSpecialValueFor("spear_width")
    local maxDistance = ability:GetSpecialValueFor("spear_range")
    self.point = Vector(params.x, params.y, params.z)
    local projectile_direction = (self.point - parent:GetAbsOrigin()):Normalized()

    self.proj = {
        vSpawnOrigin = Vector(self:GetParent():GetAbsOrigin().x, self:GetParent():GetAbsOrigin().y, self:GetParent():GetAbsOrigin().z+100),
        vVelocity = projectile_direction * speed,
        fDistance = maxDistance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_clinkz/clinkz_searing_arrow_linear_proj.vpcf",
        Ability = ability,
        Source = self:GetParent(),
        bProvidesVision = true,
        iVisionRadius = vision,
        fVisionDuration = 10,
        iVisionTeamNumber = parent:GetTeamNumber(),
    }

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_clinkz_burning_spear_custom_casting:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetUnitName() == "npc_dota_clinkz_skeleton_archer_custom" then
        parent:StartGesture(ACT_DOTA_ATTACK)
    else
        parent:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    end

    EmitSoundOn("Hero_Clinkz.Barrage.Attack", parent)

    self:FireSpear()
end

function modifier_clinkz_burning_spear_custom_casting:FireSpear()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local pos = caster:GetAbsOrigin()
    local team = caster:GetTeamNumber()
    local dur = ability:GetSpecialValueFor("shard_trail_duration")

    ProjectileManager:CreateLinearProjectile(self.proj)
end
--------
function modifier_clinkz_burning_spear_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP 
    }
end

function modifier_clinkz_burning_spear_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.attacker == self:GetCaster() and event.inflictor ~= nil and event.inflictor:GetName() == "clinkz_burning_spear_custom" then
        print("clinkz bonus!")
        return self:GetAbility():GetSpecialValueFor("damage_increase") * self:GetStackCount()
    end
end

function modifier_clinkz_burning_spear_custom_debuff:OnTooltip(event)
    return self:GetAbility():GetSpecialValueFor("damage_increase") * self:GetStackCount()
end