LinkLuaModifier("modifier_doom_infernal_servant", "heroes/hero_doom/doom_infernal_servant", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_infernal_servant_thinker", "heroes/hero_doom/doom_infernal_servant", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

doom_infernal_servant = class(ItemBaseClass)
modifier_doom_infernal_servant = class(doom_infernal_servant)
modifier_doom_infernal_servant_thinker = class(ItemBaseClassThinker)
-------------
function doom_infernal_servant:GetIntrinsicModifierName()
    return "modifier_doom_infernal_servant"
end

function doom_infernal_servant:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    -- Delete Old Golems --
    local existingGolems = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,existingGolem in ipairs(existingGolems) do
        if existingGolem:GetUnitName() == "npc_dota_doom_infernal_servant" then
            UTIL_RemoveImmediate(existingGolem)
        end
    end
    --

    EmitSoundOn("Hero_Warlock.RainOfChaos_buildup", caster)

    CreateUnitByNameAsync(
        "npc_dota_doom_infernal_servant",
        caster:GetAbsOrigin(),
        true,
        caster,
        caster,
        caster:GetTeamNumber(),

        function(unit)
            local damage = self:GetSpecialValueFor("damage")
            local hp = self:GetSpecialValueFor("health")
            local armor = self:GetSpecialValueFor("armor")

            unit:SetPhysicalArmorBaseValue(armor)

            unit:SetBaseDamageMin(damage)
            unit:SetBaseDamageMax(damage)

            unit:SetBaseMaxHealth(hp)
            unit:SetMaxHealth(hp)
            unit:SetHealth(hp)

            unit:SetBaseAttackTime(self:GetSpecialValueFor("bat"))

            unit:CreatureLevelUp(self:GetLevel()-1)

            unit:SetControllableByPlayer(caster:GetPlayerID(), false)
            self:PlayEffects2(unit)
            self:PlayEffects(unit)

            unit:AddNewModifier(unit, nil, "modifier_doom_infernal_servant_thinker", {})
            unit:AddNewModifier(unit, nil, "modifier_doom_scorched_earth_custom_auto", {})
            unit:AddNewModifier(unit, nil, "modifier_max_movement_speed", {})
            unit:AddNewModifier(unit, nil, "modifier_movement_speed_uba", {
                speed = caster:GetBaseMoveSpeed()
            })

            local fists = unit:FindAbilityByName("doom_infernal_servant_flaming_fists")
            if fists ~= nil then
                fists:SetLevel(unit:GetLevel())
            end

            local flames = unit:FindAbilityByName("doom_eternal_fire")
            local casterFlames = caster:FindAbilityByName("doom_eternal_fire")
            if flames ~= nil and casterFlames ~= nil then
                flames:SetLevel(casterFlames:GetLevel())
            end

            local scorched = unit:FindAbilityByName("doom_scorched_earth_custom")
            local casterScorched = caster:FindAbilityByName("doom_scorched_earth_custom")
            if scorched ~= nil and casterScorched ~= nil then
                scorched:SetLevel(casterScorched:GetLevel())
            end

            --local souls = caster:FindModifierByName("modifier_doom_doomsday_apocalypse_soul_stacks")
            --if souls ~= nil then
            --    souls:SetStackCount(souls:GetStackCount()-self:GetSpecialValueFor("stacks_required"))
            --end
        end
    )

    caster:AddNewModifier(caster, nil, "modifier_doom_scorched_earth_custom_auto", {})
end

function doom_infernal_servant:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf"
    local sound_cast = "Hero_Warlock.RainOfChaos"

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
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function doom_infernal_servant:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf"

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
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
----
--
function modifier_doom_infernal_servant_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
    }

    return funcs
end

function modifier_doom_infernal_servant_thinker:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local unit = self:GetParent()

    self.particle = ParticleManager:CreateParticle("particles/econ/items/warlock/warlock_hellsworn_construct/golem_hellsworn_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(self.particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 7, unit, PATTACH_POINT_FOLLOW, "attach_mane2", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 10, unit, PATTACH_POINT_FOLLOW, "attach_attack1", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 11, unit, PATTACH_POINT_FOLLOW, "attach_attack2", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 12, unit, PATTACH_POINT_FOLLOW, "attach_mane2", unit:GetAbsOrigin(), true)

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_doom_infernal_servant_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local owner = parent:GetOwner()

    local distance = (owner:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    if distance > 600 then
        local penalty = (distance*-0.03)
        if penalty < -99 then
            penalty = -99
        end

        self.reduction = penalty
    else
        self.reduction = 0
    end

    self:InvokeBonuses()
end

function modifier_doom_infernal_servant_thinker:OnDeath(event)
    if not IsServer() then return end

    if self:GetParent() ~= event.unit then 
        if self:GetParent():GetOwner() == event.unit then
            -- Delete Old Golems --
            local existingGolems = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
                FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,existingGolem in ipairs(existingGolems) do
                if existingGolem:GetUnitName() == "npc_dota_doom_infernal_servant" then
                    UTIL_RemoveImmediate(existingGolem)
                end
            end
            --
        end

        return 
    end

    local particle = ParticleManager:CreateParticle("particles/custom/creeps/hellsworn/warlock_death.vpcf", PATTACH_CUSTOMORIGIN, event.unit)
    ParticleManager:SetParticleControl(particle, 0, event.unit:GetAbsOrigin())

    ParticleManager:DestroyParticle(self.particle, true)

    local owner = self:GetParent():GetOwner()
    if owner:HasModifier("modifier_doom_scorched_earth_custom_auto") then
        owner:RemoveModifierByName("modifier_doom_scorched_earth_custom_auto")
    end
end

function modifier_doom_infernal_servant_thinker:OnRefresh()
    if not IsServer() then return end

    local owner = self:GetParent():GetOwner()

    self.summonerStaff = nil
    self.attackSpeed = 0
    self.armor = 0
    self.health = 0
    self.damage = 0

    if owner:FindItemInInventory("item_summoning_staff") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff")
    elseif owner:FindItemInInventory("item_summoning_staff_2") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_2")
    elseif owner:FindItemInInventory("item_summoning_staff_3") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_3")
    elseif owner:FindItemInInventory("item_summoning_staff_4") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_4")
    elseif owner:FindItemInInventory("item_summoning_staff_5") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_5")
    elseif owner:FindItemInInventory("item_summoning_staff_6") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_6")
    elseif owner:FindItemInInventory("item_summoning_staff_7") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_7")
    end

    if self.summonerStaff == nil or self.summonerStaff:IsInBackpack() then return end

    self.attackSpeed = 0
    self.armor = 0
    self.health = 0
    self.damage = 0

    --self:InvokeBonuses()
end

function modifier_doom_infernal_servant_thinker:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_doom_infernal_servant_thinker:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_doom_infernal_servant_thinker:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_doom_infernal_servant_thinker:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_doom_infernal_servant_thinker:GetModifierDamageOutgoing_Percentage()
    return self.fReduction
end

function modifier_doom_infernal_servant_thinker:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
        armor = self.fArmor,
        damage = self.fDamage,
        health = self.fHealth,
        reduction = self.fReduction
    }
end

function modifier_doom_infernal_servant_thinker:HandleCustomTransmitterData(data)
    if data.attackSpeed ~= nil and data.armor ~= nil and data.damage ~= nil and data.health ~= nil and data.reduction ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
        self.fArmor = tonumber(data.armor)
        self.fDamage = tonumber(data.damage)
        self.fHealth = tonumber(data.health)
        self.fReduction = tonumber(data.reduction)
    end
end

function modifier_doom_infernal_servant_thinker:InvokeBonuses()
    if IsServer() == true then
        self.fAttackSpeed = self.attackSpeed
        self.fArmor = self.armor
        self.fDamage = self.damage
        self.fHealth = self.health
        self.fReduction = self.reduction

        self:SendBuffRefreshToClients()
    end
end