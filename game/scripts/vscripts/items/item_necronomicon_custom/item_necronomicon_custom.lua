LinkLuaModifier("modifier_item_necronomicon_custom", "items/item_necronomicon_custom/item_necronomicon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_necronomicon_custom_archer", "items/item_necronomicon_custom/item_necronomicon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassArcher = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_necronomicon_custom = class(ItemBaseClass)
item_necronomicon_custom2 = item_necronomicon_custom
item_necronomicon_custom3 = item_necronomicon_custom
item_necronomicon_custom4 = item_necronomicon_custom
item_necronomicon_custom5 = item_necronomicon_custom
item_necronomicon_custom6 = item_necronomicon_custom
item_necronomicon_custom7 = item_necronomicon_custom
item_necronomicon_custom8 = item_necronomicon_custom
item_necronomicon_custom9 = item_necronomicon_custom
modifier_item_necronomicon_custom = class(item_necronomicon_custom)
modifier_item_necronomicon_custom_archer = class(ItemBaseClassArcher)
-------------
function item_necronomicon_custom:GetIntrinsicModifierName()
    return "modifier_item_necronomicon_custom"
end
--------
function modifier_item_necronomicon_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT 
    }
    return funcs
end

function modifier_item_necronomicon_custom:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    -- Delete Old Golems --
    local existingGolems = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,existingGolem in ipairs(existingGolems) do
        if existingGolem:GetUnitName() == "npc_dota_necronomicon_archer_custom" then
            existingGolem:ForceKill(false)
        end
    end
end
function modifier_item_necronomicon_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_necronomicon_custom:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end
--------
function item_necronomicon_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("DOTA_Item.Necronomicon.Activate", caster)

    -- Delete Old Golems --
    local existingGolems = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,existingGolem in ipairs(existingGolems) do
        if existingGolem:GetUnitName() == "npc_dota_necronomicon_archer_custom" then
            existingGolem:ForceKill(false)
        end
    end
    --

    CreateUnitByNameAsync(
        "npc_dota_necronomicon_archer_custom",
        caster:GetAbsOrigin(),
        true,
        caster,
        caster,
        caster:GetTeamNumber(),

        function(unit)
            local damage = self:GetSpecialValueFor("archer_damage")
            local hp = self:GetSpecialValueFor("archer_health")
            local bat = self:GetSpecialValueFor("bonus_base_attack_time")
            local armor = self:GetSpecialValueFor("archer_armor")

            unit:SetBaseDamageMin(damage)
            unit:SetBaseDamageMax(damage)

            unit:SetBaseMaxHealth(hp)
            unit:SetMaxHealth(hp)
            unit:SetHealth(hp)

            unit:SetPhysicalArmorBaseValue(armor)

            unit:SetBaseAttackTime(bat)

            unit:CreatureLevelUp(self:GetLevel())

            unit:SetControllableByPlayer(caster:GetPlayerID(), false)

            unit:AddNewModifier(unit, nil, "modifier_max_movement_speed", {})
            unit:AddNewModifier(unit, nil, "modifier_movement_speed_uba", {
                speed = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), true)
            })

            unit:SetOwner(caster)

            unit:AddNewModifier(unit, self, "modifier_item_necronomicon_custom_archer", {})

            for i = 0, unit:GetAbilityCount() - 1 do
                local abil = unit:GetAbilityByIndex(i)
                if abil ~= nil then
                    abil:SetLevel(unit:GetLevel())
                end
            end
        end
    )
end
-------
function modifier_item_necronomicon_custom_archer:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
    return funcs
end

function modifier_item_necronomicon_custom_archer:CheckState()
    return {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true
    }
end

function modifier_item_necronomicon_custom_archer:GetEffectName()
    return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
end

function modifier_item_necronomicon_custom_archer:GetModifierProjectileName() 
    return "particles/econ/items/clinkz/clinkz_maraxiform/clinkz_ti9_summon_projectile_arrow.vpcf"
end

function modifier_item_necronomicon_custom_archer:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_item_necronomicon_custom_archer:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_necronomicon_custom_archer:OnRefresh()
    if not IsServer() then return end

    local owner = self:GetParent():GetOwner()

    self.attackSpeed = 0
    self.armor = 0
    self.health = 0
    self.damage = 0

    --self:InvokeBonuses()
end

function modifier_item_necronomicon_custom_archer:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_item_necronomicon_custom_archer:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_item_necronomicon_custom_archer:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_item_necronomicon_custom_archer:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_necronomicon_custom_archer:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
        armor = self.fArmor,
        damage = self.fDamage,
        health = self.fHealth,
    }
end

function modifier_item_necronomicon_custom_archer:HandleCustomTransmitterData(data)
    if data.attackSpeed ~= nil and data.armor ~= nil and data.damage ~= nil and data.health ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
        self.fArmor = tonumber(data.armor)
        self.fDamage = tonumber(data.damage)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_item_necronomicon_custom_archer:InvokeBonuses()
    if IsServer() == true then
        self.fAttackSpeed = self.attackSpeed
        self.fArmor = self.armor
        self.fDamage = self.damage
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end