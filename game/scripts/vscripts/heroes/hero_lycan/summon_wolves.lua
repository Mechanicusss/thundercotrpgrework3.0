LinkLuaModifier("modifier_lycan_summon_wolves_custom", "heroes/hero_lycan/summon_wolves", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_summon_wolves_custom_wolf", "heroes/hero_lycan/summon_wolves", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff", "heroes/hero_lycan/summon_wolves", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

lycan_summon_wolves_custom = class(ItemBaseClass)
modifier_lycan_summon_wolves_custom = class(lycan_summon_wolves_custom)
modifier_lycan_summon_wolves_custom_wolf = class(ItemBaseClass)
modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff = class(ItemBaseClassBuff)
-------------
function lycan_summon_wolves_custom:GetIntrinsicModifierName()
    return "modifier_lycan_summon_wolves_custom"
end

function lycan_summon_wolves_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lycan_summon_wolves_custom:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self

    local wolfCount = ability:GetSpecialValueFor("wolf_index")
    local wolfSpawnPosition = Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y+50, caster:GetAbsOrigin().z)

    local feral = caster:FindAbilityByName("lycan_feral_impulse_custom")

    EmitSoundOn("Hero_Lycan.SummonWolves", caster)

    -- KILL OLD WOLVES --
    local wolves = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,wolf in ipairs(wolves) do
        if wolf:GetUnitName() ~= "npc_dota_lycan_wolf_custom1" then break end
        if not wolf:IsAlive() then break end
        wolf:ForceKill(false)
        --UTIL_Remove(wolf)
    end
    --

    for i = 1, wolfCount, 1 do
        local unit = CreateUnitByName("npc_dota_lycan_wolf_custom1", wolfSpawnPosition, true, caster, caster, caster:GetTeamNumber())

        unit:SetControllableByPlayer(caster:GetPlayerID(), false)
        unit:SetOwner(caster)

        unit:AddNewModifier(caster, ability, "modifier_lycan_summon_wolves_custom_wolf", {})
        if feral ~= nil and feral:GetLevel() > 0 then
            unit:AddNewModifier(caster, feral, "modifier_lycan_feral_impulse_custom_buff", {})
        end

        for i = 0, unit:GetAbilityCount() - 1 do
            local abil = unit:GetAbilityByIndex(i)
            if abil ~= nil and abil:IsPassive() then
                local level = ability:GetLevel()
                abil:SetLevel(level)
                abil:SetHidden(false)
                abil:SetActivated(true)
            end
        end
    end
end
------------
function modifier_lycan_summon_wolves_custom:CheckState()
    local state = {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    return state
end

function modifier_lycan_summon_wolves_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_lycan_summon_wolves_custom:OnAttack(event)
    if event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    local wolves = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("wolf_attack_search_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,wolf in ipairs(wolves) do
        if wolf:GetUnitName() ~= "npc_dota_lycan_wolf_custom1" then break end
        if not wolf:IsAlive() then break end
        if (wolf:GetAbsOrigin() - event.target:GetAbsOrigin()):Length2D() <= wolf:Script_GetAttackRange() then
            wolf:StartGesture(ACT_DOTA_ATTACK)
            wolf:FaceTowards(event.target:GetAbsOrigin())
            wolf:PerformAttack(
                event.target,
                true,
                true,
                true,
                true,
                false,
                false,
                false
            )

        end
    end
end
------------
function modifier_lycan_summon_wolves_custom_wolf:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS
    }

    return funcs
end

function modifier_lycan_summon_wolves_custom_wolf:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local owner = parent:GetOwner()

    --[[
    self.speed = owner:GetIdealSpeedNoSlows()
    self.damage = owner:GetAverageTrueAttackDamage(owner) * (ability:GetSpecialValueFor("wolf_damage_from_lycan_pct")/100)
    self.armor = owner:GetPhysicalArmorValue(false) * (ability:GetSpecialValueFor("wolf_armor_from_lycan_pct")/100)
    self.hp = owner:GetMaxHealth() * (ability:GetSpecialValueFor("wolf_hp_from_lycan_pct")/100)

    self:InvokeWolfSpeedModifier()
    --]]

    --[[
    parent:SetBaseDamageMin(ability:GetSpecialValueFor("wolf_damage"))
    parent:SetBaseDamageMax(ability:GetSpecialValueFor("wolf_damage"))
    parent:SetBaseMaxHealth(self.hp)
    parent:SetMaxHealth(self.hp)
    parent:SetHealth(self.hp)
    --]]

    parent:SetBaseDamageMin(ability:GetSpecialValueFor("wolf_damage"))
    parent:SetBaseDamageMax(ability:GetSpecialValueFor("wolf_damage"))

    Timers:CreateTimer(ability:GetSpecialValueFor("wolf_duration"), function()
        if not parent or parent == nil or parent:IsNull() then return end
        if not parent:IsAlive() then return end

        parent:ForceKill(false)
        --UTIL_Remove(parent)
    end)

    self:StartIntervalThink(0.1)
end

function modifier_lycan_summon_wolves_custom_wolf:OnRefresh()
    if not IsServer() then return end

    local owner = self:GetParent():GetOwner()

    self.attackSpeed = 0
    self.armor = 0
    self.health = 0
    self.damage = 0

    self.speed = owner:GetIdealSpeedNoSlows()

    self:InvokeWolfSpeedModifier()
end

function modifier_lycan_summon_wolves_custom_wolf:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end

    local ability = self:GetAbility()
    local owner = parent:GetOwner()

    --[[
    self.speed = owner:GetIdealSpeedNoSlows()
    self.damage = owner:GetAverageTrueAttackDamage(owner) * (ability:GetSpecialValueFor("wolf_damage_from_lycan_pct")/100)
    
    self:InvokeWolfSpeedModifier()
    --]]
    self:OnRefresh()

    if owner:HasModifier("modifier_lycan_shapeshift_custom_buff") and not parent:HasModifier("modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff") then
        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf", PATTACH_POINT_FOLLOW, parent )
        ParticleManager:SetParticleControl( effect_cast, 0, parent:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex( effect_cast )

        parent:AddNewModifier(owner, nil, "modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff", {})
    end

    if not owner:HasModifier("modifier_lycan_shapeshift_custom_buff") and parent:HasModifier("modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff") then
        parent:RemoveModifierByName("modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff")
    end

    if owner:HasModifier("modifier_lycan_wolf_bite_custom_buff") and not parent:HasModifier("modifier_lycan_wolf_bite_custom_buff") then
        local bite = owner:FindAbilityByName("lycan_wolf_bite_custom")
        if bite ~= nil and bite:GetLevel() > 0 then
            parent:AddNewModifier(owner, bite, "modifier_lycan_wolf_bite_custom_buff", {})
        end
    end
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierMoveSpeed_Limit()
    return self.fSpeed
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierMoveSpeedOverride()
    return self.fSpeed
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierExtraHealthBonus()
    return self.fHp
end

function modifier_lycan_summon_wolves_custom_wolf:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_lycan_summon_wolves_custom_wolf:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
        speed = self.fSpeed,
        damage = self.fDamage,
        armor = self.fArmor,
        hp = self.fHp
    }
end

function modifier_lycan_summon_wolves_custom_wolf:HandleCustomTransmitterData(data)
    if data.speed ~= nil and data.damage ~= nil and data.armor ~= nil and data.hp ~= nil and data.attackSpeed ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
        self.fSpeed = tonumber(data.speed)
        self.fDamage = tonumber(data.damage)
        self.fArmor = tonumber(data.armor)
        self.fHp = tonumber(data.hp)
    end
end

function modifier_lycan_summon_wolves_custom_wolf:InvokeWolfSpeedModifier()
    if IsServer() == true then
        self.fSpeed = self.speed
        self.fDamage = self.damage
        self.fArmor = self.armor
        self.fHp = self.hp
        self.fAttackSpeed = self.attackSpeed

        self:SendBuffRefreshToClients()
    end
end
----
function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE, --GetModifierMoveSpeedOverride
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION, --GetBonusNightVision
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:OnCreated()
    local lycan = self:GetCaster()

    self.critChance = 0
    self.critDamage = 0
    self.nightVision = 0
    self.speed = 0

    local shapeshift = lycan:FindAbilityByName("lycan_shapeshift_custom")
    if shapeshift ~= nil and shapeshift:GetLevel() > 0 then
        self.critChance = shapeshift:GetSpecialValueFor("crit_chance")
        self.critDamage = shapeshift:GetSpecialValueFor("crit_multiplier")
        self.nightVision = shapeshift:GetSpecialValueFor("bonus_night_vision")
        self.speed = shapeshift:GetSpecialValueFor("speed")
    end
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cc = self.critChance

        if RollPercentage(cc) then
            self.record = params.record
            return self.critDamage
        end
    end
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetModifierMoveSpeed_Limit()
    return 2000
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetBonusNightVision()
    return self.nightVision
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetEffectName()
    return "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf"
end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetTexture() return "lycan_shapeshift" end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_lycan_summon_wolves_custom_wolf_shapeshift_buff:CheckState()
    local state = {
        [MODIFIER_STATE_UNSLOWABLE] = true
    }

    return state
end