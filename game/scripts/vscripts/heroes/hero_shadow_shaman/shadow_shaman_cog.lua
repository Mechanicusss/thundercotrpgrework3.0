LinkLuaModifier("modifier_shadow_shaman_cog", "heroes/hero_shadow_shaman/shadow_shaman_cog", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_cog_thinker", "heroes/hero_shadow_shaman/shadow_shaman_cog", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_cog_taunt_debuff", "heroes/hero_shadow_shaman/shadow_shaman_cog", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_cog_taunt_buff", "heroes/hero_shadow_shaman/shadow_shaman_cog", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassTauntDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}


local ItemBaseClassTauntBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

shadow_shaman_cog = class(ItemBaseClass)
modifier_shadow_shaman_cog = class(shadow_shaman_cog)
modifier_shadow_shaman_cog_thinker = class(ItemBaseClass)
modifier_shadow_shaman_cog_taunt_debuff = class(ItemBaseClassTauntDebuff)
modifier_shadow_shaman_cog_taunt_buff = class(ItemBaseClassTauntBuff)
-------------
function shadow_shaman_cog:GetIntrinsicModifierName()
    return "modifier_shadow_shaman_cog"
end

function modifier_shadow_shaman_cog_thinker:RemoveOnDeath() return true end

function modifier_shadow_shaman_cog_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }

    return state
end

function modifier_shadow_shaman_cog_thinker:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local duration = self:GetAbility():GetSpecialValueFor("duration")
    local target = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/items5_fx/wraith_pact_ambient_fire_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(particle, 2, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(particle, true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)

    self:SetDuration(duration, true)

    self:StartIntervalThink(1.0)
    self:OnIntervalThink()

    self:OnRefresh()
end

function modifier_shadow_shaman_cog_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local effect_cast = ParticleManager:CreateParticle("particles/items5_fx/wraith_pact_ambient_pulses.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end
        if victim:GetUnitName() == "npc_dota_boss_aghanim" then break end

        if IsCreepTCOTRPG(victim) or IsBossTCOTRPG(victim) or IsSummonTCOTRPG(victim) then
            local effect_cast = ParticleManager:CreateParticle("particles/items5_fx/wraith_pact_pulses_target.vpcf", PATTACH_POINT_FOLLOW, victim)
            ParticleManager:SetParticleControl(effect_cast, 0, victim:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(effect_cast)

            if victim:GetTeamNumber() ~= parent:GetTeamNumber() then
                victim:SetForceAttackTarget(parent)

                victim:AddNewModifier(parent, ability, "modifier_shadow_shaman_cog_taunt_debuff", {
                    duration = ability:GetSpecialValueFor("taunt_duration")
                })
            else
                victim:AddNewModifier(parent, ability, "modifier_shadow_shaman_cog_taunt_buff", {
                    duration = ability:GetSpecialValueFor("taunt_duration")
                })
            end
        end
    end
end

function modifier_shadow_shaman_cog_thinker:OnDestroy()
    if not IsServer() then return end

    if not self or self == nil then return end
    if not self:GetParent() or self:GetParent() == nil then return end
    if not self:GetParent():IsAlive() then return end

    self:GetParent():ForceKill(false)
end

function shadow_shaman_cog:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetCursorPosition()

    local unit = CreateUnitByName(
        "npc_dota_shadow_shaman_cog",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    local hp = self:GetSpecialValueFor("health")
    local armor = self:GetSpecialValueFor("armor")
    
    unit:SetPhysicalArmorBaseValue(armor)
    
    unit:SetBaseMaxHealth(hp)
    unit:SetMaxHealth(hp)
    unit:SetHealth(hp)

    unit:SetControllableByPlayer(caster:GetPlayerID(), false)

    unit:AddNewModifier(unit, self, "modifier_shadow_shaman_cog_thinker", {})

    EmitSoundOn("Hero_Rattletrap.Power_Cogs", caster)
end

function modifier_shadow_shaman_cog_taunt_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_IGNORING_STOP_ORDERS] = true,
        [MODIFIER_STATE_TAUNTED] = true
    }

    return state
end

function modifier_shadow_shaman_cog_taunt_debuff:OnDestroy()
    if not IsServer() then return end

    self:GetParent():SetForceAttackTarget(nil)
end

function modifier_shadow_shaman_cog_taunt_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }

    return funcs
end

function modifier_shadow_shaman_cog_taunt_buff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("ally_damage_reduction")
end
-----------------
function modifier_shadow_shaman_cog_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    }

    return funcs
end

function modifier_shadow_shaman_cog_thinker:OnRefresh()
    if not IsServer() then return end

    local owner = self:GetParent():GetOwner()

    self.summonerStaff = nil
    self.armor = 0
    self.health = 0

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

    self.armor = owner:GetAgility() * self.summonerStaff:GetSpecialValueFor("agi_armor")
    self.health = owner:GetStrength() * self.summonerStaff:GetSpecialValueFor("str_hp")

    --self:InvokeBonuses()
end

function modifier_shadow_shaman_cog_thinker:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_shadow_shaman_cog_thinker:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_shadow_shaman_cog_thinker:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
        health = self.fHealth
    }
end

function modifier_shadow_shaman_cog_thinker:HandleCustomTransmitterData(data)
    if data.armor ~= nil and data.health ~= nil then
        self.fArmor = tonumber(data.armor)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_shadow_shaman_cog_thinker:InvokeBonuses()
    if IsServer() == true then
        self.fArmor = self.armor
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end