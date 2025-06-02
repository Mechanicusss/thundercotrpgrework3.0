LinkLuaModifier("modifier_shadow_shaman_plague_ward", "heroes/hero_shadow_shaman/shadow_shaman_plague_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_plague_ward_thinker", "heroes/hero_shadow_shaman/shadow_shaman_plague_ward", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

shadow_shaman_plague_ward = class(ItemBaseClass)
modifier_shadow_shaman_plague_ward = class(shadow_shaman_plague_ward)
modifier_shadow_shaman_plague_ward_thinker = class(ItemBaseClass)
-------------
function shadow_shaman_plague_ward:GetIntrinsicModifierName()
    return "modifier_shadow_shaman_plague_ward"
end

function modifier_shadow_shaman_plague_ward_thinker:RemoveOnDeath() return true end

function modifier_shadow_shaman_plague_ward_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }

    return state
end

function modifier_shadow_shaman_plague_ward_thinker:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)

    self:OnRefresh()

    --local bat = self:GetAbility():GetSpecialValueFor("bat")

    --self:OnIntervalThink()
    --self:StartIntervalThink(bat)
end

function modifier_shadow_shaman_plague_ward_thinker:OnIntervalThink()
    local parent = self:GetParent()

    local radius = 850

    parent:FadeGesture(ACT_DOTA_ATTACK)

    EmitSoundOn("Hero_Venomancer.PoisonNova", parent)

    local effect_cast = ParticleManager:CreateParticle("particles/econ/items/venomancer/veno_2022_immortal_tail/veno_2022_immortal_poison_nova.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(radius, 1, radius))
    ParticleManager:SetParticleControl(effect_cast, 3, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES),
        FIND_CLOSEST, false)

    local corrosion = parent:GetOwner():FindAbilityByName("plague_ward_corrosion")

    for _,unit in ipairs(units) do
        -- Can apply corrosion --
        if corrosion ~= nil then
            local buff = unit:FindModifierByName("modifier_plague_ward_corrosion_debuff")
            if buff == nil then
                buff = unit:AddNewModifier(parent:GetOwner(), corrosion, "modifier_plague_ward_corrosion_debuff", {
                    duration = corrosion:GetSpecialValueFor("duration")
                })
            end

            if buff ~= nil then
                if buff:GetStackCount() < corrosion:GetSpecialValueFor("max_stacks") then
                    buff:IncrementStackCount()
                end

                buff:ForceRefresh()
            end
        end
        --

        ApplyDamage({
            attacker = parent:GetOwner(),
            victim = unit,
            damage = (parent:GetAverageTrueAttackDamage(parent) * (parent:GetDisplayAttackSpeed()/100)) / #units,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })

        EmitSoundOn("Hero_Venomancer.PoisonNovaImpact", unit)
    end
end

function modifier_shadow_shaman_plague_ward_thinker:OnDestroy()
    if not IsServer() then return end

    if not self or self == nil then return end
    if not self:GetParent() or self:GetParent() == nil then return end
    if not self:GetParent():IsAlive() then return end

    self:GetParent():ForceKill(false)
end

function shadow_shaman_plague_ward:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetCursorPosition()

    local unit = CreateUnitByName(
        "npc_dota_shadow_shaman_plague_ward",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )
    
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

    unit:SetControllableByPlayer(caster:GetPlayerID(), false)

    local corrosion = unit:AddAbility("plague_ward_corrosion")
    corrosion:SetLevel(self:GetLevel())
    corrosion:SetActivated(true)
    corrosion:SetHidden(false)

    local splitshot = unit:AddAbility("plague_ward_splitshot")
    splitshot:SetLevel(self:GetLevel())
    splitshot:SetActivated(true)
    splitshot:SetHidden(false)

    unit:AddNewModifier(unit, self, "modifier_shadow_shaman_plague_ward_thinker", {})

    EmitSoundOn("Hero_Venomancer.Plague_Ward", caster)
end
---------------
function modifier_shadow_shaman_plague_ward_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }

    return funcs
end

function modifier_shadow_shaman_plague_ward_thinker:OnRefresh()
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

    self.attackSpeed = owner:GetAgility() * self.summonerStaff:GetSpecialValueFor("agi_atk_speed")
    self.armor = owner:GetAgility() * self.summonerStaff:GetSpecialValueFor("agi_armor")
    self.health = owner:GetStrength() * self.summonerStaff:GetSpecialValueFor("str_hp")
    self.damage = owner:GetBaseIntellect() * self.summonerStaff:GetSpecialValueFor("int_damage")

    --self:InvokeBonuses()
end

function modifier_shadow_shaman_plague_ward_thinker:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_shadow_shaman_plague_ward_thinker:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_shadow_shaman_plague_ward_thinker:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_shadow_shaman_plague_ward_thinker:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_shadow_shaman_plague_ward_thinker:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
        armor = self.fArmor,
        damage = self.fDamage,
        health = self.fHealth
    }
end

function modifier_shadow_shaman_plague_ward_thinker:HandleCustomTransmitterData(data)
    if data.attackSpeed ~= nil and data.armor ~= nil and data.damage ~= nil and data.health ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
        self.fArmor = tonumber(data.armor)
        self.fDamage = tonumber(data.damage)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_shadow_shaman_plague_ward_thinker:InvokeBonuses()
    if IsServer() == true then
        self.fAttackSpeed = self.attackSpeed
        self.fArmor = self.armor
        self.fDamage = self.damage
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end