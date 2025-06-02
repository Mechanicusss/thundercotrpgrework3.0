LinkLuaModifier("modifier_shadow_shaman_death_ward", "heroes/hero_shadow_shaman/shadow_shaman_death_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_death_ward_thinker", "heroes/hero_shadow_shaman/shadow_shaman_death_ward", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

shadow_shaman_death_ward = class(ItemBaseClass)
modifier_shadow_shaman_death_ward = class(shadow_shaman_death_ward)
modifier_shadow_shaman_death_ward_thinker = class(ItemBaseClass)
-------------
function shadow_shaman_death_ward:GetIntrinsicModifierName()
    return "modifier_shadow_shaman_death_ward"
end

function modifier_shadow_shaman_death_ward_thinker:RemoveOnDeath() return true end

function modifier_shadow_shaman_death_ward_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true

    }

    return state
end

function modifier_shadow_shaman_death_ward_thinker:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target == self:GetParent() then return end

    local owner = event.attacker:GetOwner()
    local damage = owner:GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("damage_to_magical")/100)

    ApplyDamage({
        victim = event.target,
        attacker = event.attacker:GetOwner(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
        event.target,
        damage,
        nil
    )
end

function modifier_shadow_shaman_death_ward_thinker:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local duration = self:GetAbility():GetSpecialValueFor("duration")

    self:SetDuration(duration, true)

    local target = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(particle, 2, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(particle, true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)

    self:StartIntervalThink(0.1)

    self:OnRefresh()
end

function modifier_shadow_shaman_death_ward_thinker:OnIntervalThink()
    local parent = self:GetParent()

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #victims < 1 then return end

    local victim = victims[1]
    
    if not victim:IsAlive() then return end

    parent:SetForceAttackTarget(victim)
end

function modifier_shadow_shaman_death_ward_thinker:OnDestroy()
    if not IsServer() then return end

    if not self or self == nil then return end
    if not self:GetParent() or self:GetParent() == nil then return end
    if not self:GetParent():IsAlive() then return end

    self:GetParent():ForceKill(false)
end

function shadow_shaman_death_ward:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetCursorPosition()

    function HasShard(target)
        return target:HasModifier("modifier_item_aghanims_shard")
    end

    local unit = CreateUnitByName(
        "npc_dota_shadow_shaman_death_ward",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    unit:SetBaseDamageMin(self:GetSpecialValueFor("damage"))
    unit:SetBaseDamageMax(self:GetSpecialValueFor("damage"))

    unit:SetBaseAttackTime(self:GetSpecialValueFor("bat"))

    local hp = self:GetSpecialValueFor("health")
    local armor = self:GetSpecialValueFor("armor")

    unit:SetPhysicalArmorBaseValue(armor)
    
    unit:SetBaseMaxHealth(hp)
    unit:SetMaxHealth(hp)
    unit:SetHealth(hp)

    unit:SetControllableByPlayer(caster:GetPlayerID(), false)

    unit:AddNewModifier(unit, self, "modifier_shadow_shaman_death_ward_thinker", {})

    EmitSoundOn("Hero_WitchDoctor.Death_WardBuild", caster)
end
---------------
function modifier_shadow_shaman_death_ward_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_shadow_shaman_death_ward_thinker:OnRefresh()
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

function modifier_shadow_shaman_death_ward_thinker:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_shadow_shaman_death_ward_thinker:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_shadow_shaman_death_ward_thinker:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_shadow_shaman_death_ward_thinker:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_shadow_shaman_death_ward_thinker:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
        armor = self.fArmor,
        damage = self.fDamage,
        health = self.fHealth
    }
end

function modifier_shadow_shaman_death_ward_thinker:HandleCustomTransmitterData(data)
    if data.attackSpeed ~= nil and data.armor ~= nil and data.damage ~= nil and data.health ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
        self.fArmor = tonumber(data.armor)
        self.fDamage = tonumber(data.damage)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_shadow_shaman_death_ward_thinker:InvokeBonuses()
    if IsServer() == true then
        self.fAttackSpeed = self.attackSpeed
        self.fArmor = self.armor
        self.fDamage = self.damage
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end