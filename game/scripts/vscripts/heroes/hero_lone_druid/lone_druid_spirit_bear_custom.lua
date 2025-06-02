LinkLuaModifier("modifier_lone_druid_spirit_bear_custom", "heroes/hero_lone_druid/lone_druid_spirit_bear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_spirit_bear_custom_thinker", "heroes/hero_lone_druid/lone_druid_spirit_bear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_spirit_bear_custom_disarmed", "heroes/hero_lone_druid/lone_druid_spirit_bear_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_spirit_link_custom_bear", "heroes/hero_lone_druid/lone_druid_spirit_link_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lone_druid_spirit_bear_custom = class(ItemBaseClass)
modifier_lone_druid_spirit_bear_custom = class(lone_druid_spirit_bear_custom)
modifier_lone_druid_spirit_bear_custom_thinker = class(ItemBaseClassBuff)
modifier_lone_druid_spirit_bear_custom_disarmed = class(ItemBaseClassDebuff)

lone_druid_spirit_bear_custom.bearInventory = {}
-------------
function lone_druid_spirit_bear_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_spirit_bear_custom"
end

function lone_druid_spirit_bear_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    -- Delete Old Bears --
    local existing = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ex in ipairs(existing) do
        if string.match(ex:GetUnitName(), "npc_dota_lone_druid_bear_custom") then
            UTIL_RemoveImmediate(ex)
        end
    end
    --

    local unitName = "npc_dota_lone_druid_bear_custom2"
    local hasTalent = false

    local runeSpiritBear = caster:FindModifierByName("modifier_item_socket_rune_legendary_lone_druid_bear")
    if runeSpiritBear then
        unitName = "npc_dota_lone_druid_bear_custom"
        hasTalent = true
    end

    CreateUnitByNameAsync(
        unitName,
        caster:GetAbsOrigin(),
        true,
        caster,
        caster,
        caster:GetTeamNumber(),

        function(unit)
            local damage = self:GetSpecialValueFor("bear_damage")
            local hp = self:GetSpecialValueFor("bear_hp")
            local armor = self:GetSpecialValueFor("bear_armor")

            if hasTalent then
                unit:SetRespawnsDisabled(true)
                for i = 0, caster:GetLevel()-2, 1 do 
                    unit:HeroLevelUp(false)
                end
            else
                unit:SetUnitCanRespawn(false)
                unit:CreatureLevelUp(caster:GetLevel()-1)
            end

            unit:SetPhysicalArmorBaseValue(armor)

            unit:SetBaseDamageMin(damage)
            unit:SetBaseDamageMax(damage)

            unit:SetBaseMaxHealth(hp)
            unit:SetMaxHealth(hp)
            unit:SetHealth(hp)

            unit:SetBaseAttackTime(self:GetSpecialValueFor("bear_bat"))

            unit:SetOwner(caster)
            unit:SetControllableByPlayer(caster:GetPlayerID(), false)
            
            self:PlayEffects(unit)

            unit:AddNewModifier(caster, self, "modifier_lone_druid_spirit_bear_custom_thinker", {})
            unit:AddNewModifier(unit, nil, "modifier_max_movement_speed", {})

            local spiritLink = caster:FindAbilityByName("lone_druid_spirit_link_custom")
            if spiritLink ~= nil and spiritLink:GetLevel() > 0 then
                unit:AddNewModifier(caster, spiritLink, "modifier_lone_druid_spirit_link_custom_bear", {})
            end

            local spiritReturn = unit:FindAbilityByName("lone_druid_return_custom")
            if spiritReturn ~= nil then
                spiritReturn:SetLevel(1)
                spiritReturn:SetActivated(true)
            end

            local abilities = {
                "lone_druid_claw_strike_custom",
                "lone_druid_destructive_claws_custom"
            }

            for _,abil in ipairs(abilities) do 
                local temp = unit:FindAbilityByName(abil)
                if temp ~= nil then
                    temp:SetActivated(true)
                    temp:SetHidden(false)
                    temp:SetLevel(1)
                end
            end

            for _,item in ipairs(self.bearInventory) do 
                unit:AddItemByName(item)
            end
        end
    )
end

function lone_druid_spirit_bear_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lone_druid/lone_druid_bear_spawn.vpcf"
    local sound_cast = "Hero_LoneDruid.SpiritBear.Cast"

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

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
----
--
function modifier_lone_druid_spirit_bear_custom_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS 
    }

    return funcs
end

function modifier_lone_druid_spirit_bear_custom_thinker:GetModifierHealthBonus()
    if self:GetParent():GetUnitName() == "npc_dota_lone_druid_bear_custom" then
        return self:GetAbility():GetSpecialValueFor("bear_hp")
    end
end

function modifier_lone_druid_spirit_bear_custom_thinker:GetModifierAttackRangeBonus()
    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return end

    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_lone_druid_spirit_bear_custom_thinker:OnCreated()
    if not IsServer() then return end

    local unit = self:GetParent()

    self.ability = self:GetAbility()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_ambient_beard.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(self.particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 7, unit, PATTACH_POINT_FOLLOW, "attach_mane2", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 10, unit, PATTACH_POINT_FOLLOW, "attach_attack1", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 11, unit, PATTACH_POINT_FOLLOW, "attach_attack2", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle, 12, unit, PATTACH_POINT_FOLLOW, "attach_mane2", unit:GetAbsOrigin(), true)

    self:StartIntervalThink(FrameTime())
end

function modifier_lone_druid_spirit_bear_custom_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local owner = parent:GetOwner()

    self.ability.bearInventory = {}

    -- Distance logic
    local runeSpiritBear = owner:FindModifierByName("modifier_item_socket_rune_legendary_lone_druid_bear")

    if runeSpiritBear then
        -- Inventory Logic
        for i=0,17 do
            local item = parent:GetItemInSlot(i)
            if item ~= nil then
                table.insert(self.ability.bearInventory, item:GetName())
            end
        end
    end
    
    if runeSpiritBear then
        if parent:HasModifier("modifier_lone_druid_spirit_bear_custom_disarmed") then
            parent:RemoveModifierByName("modifier_lone_druid_spirit_bear_custom_disarmed")
        end
        return
    end

    local distance = (owner:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    if distance > self:GetAbility():GetSpecialValueFor("bear_disarm_range") then
        if not parent:HasModifier("modifier_lone_druid_spirit_bear_custom_disarmed") then
            parent:AddNewModifier(owner, self:GetAbility(), "modifier_lone_druid_spirit_bear_custom_disarmed", {})
        end
    else
        if parent:HasModifier("modifier_lone_druid_spirit_bear_custom_disarmed") then
            parent:RemoveModifierByName("modifier_lone_druid_spirit_bear_custom_disarmed")
        end
    end
end

function modifier_lone_druid_spirit_bear_custom_thinker:OnDeath(event)
    if not IsServer() then return end

    if self:GetParent() ~= event.unit then 
        if self:GetParent():GetOwner() == event.unit then
            local runeSpiritBear = self:GetParent():GetOwner():FindModifierByName("modifier_item_socket_rune_legendary_lone_druid_bear")
            
            if runeSpiritBear then
                return
            end

            -- Delete Old Golems --
            local existing = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
                FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,ex in ipairs(existing) do
                if string.match(ex:GetUnitName(), "npc_dota_lone_druid_bear_custom") then
                    ex:ForceKill(false)
                    Timers:CreateTimer(3.0, function()
                        if not ex:IsNull() then
                            UTIL_Remove(ex)
                        end
                    end)
                end
            end
            --
        end

        return 
    end

    local parent = self:GetParent()

    Timers:CreateTimer(3.0, function()
        if not parent:IsNull() then
            UTIL_Remove(parent)
        end
    end)

    local owner = self:GetParent():GetOwner()

    ApplyDamage({
        victim = owner,
        attacker = event.attacker,
        damage = owner:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("bear_backlash_damage_pct")/100),
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })
end
----------------
function modifier_lone_druid_spirit_bear_custom_disarmed:CheckState()
    local states = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return states
end

function modifier_lone_druid_spirit_bear_custom_disarmed:GetEffectName()
    return "particles/units/heroes/hero_demonartist/demonartist_engulf_disarm/items2_fx/heavens_halberd.vpcf"
end

function modifier_lone_druid_spirit_bear_custom_disarmed:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end