LinkLuaModifier("modifier_juggernaut_jade_dragonling_custom", "heroes/hero_juggernaut/juggernaut_jade_dragonling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_jade_dragonling_custom_shard", "heroes/hero_juggernaut/juggernaut_jade_dragonling_custom", LUA_MODIFIER_MOTION_NONE)

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

juggernaut_jade_dragonling_custom = class(ItemBaseClass)
modifier_juggernaut_jade_dragonling_custom = class(ItemBaseClassDebuff)
modifier_juggernaut_jade_dragonling_custom_shard = class(ItemBaseClassBuff)
-------------
function juggernaut_jade_dragonling_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function juggernaut_jade_dragonling_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local target = self:GetCursorTarget()

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_juggernaut_jade_dragonling_custom", {
        duration = duration
    })

    EmitSoundOn("CNY_Beast.Death", target)
    EmitSoundOn("Hero_Juggernaut.HealingWard.Cast", target)
end
-----------------------
function modifier_juggernaut_jade_dragonling_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_juggernaut_jade_dragonling_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit or parent == event.attacker then return end

    local stored = self.damage + (event.damage*(self.leech/100))

    if stored > INT_MAX_LIMIT then
        stored = INT_MAX_LIMIT
    end

    self.damage = stored
end

function modifier_juggernaut_jade_dragonling_custom:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.caster = self:GetCaster()

    self.damage = 0

    self.leech = self.ability:GetSpecialValueFor("leech_percent")

    if self.caster:HasTalent("special_bonus_unique_juggernaut_4_custom") then
        self.leech = self.leech + self.caster:FindAbilityByName("special_bonus_unique_juggernaut_4_custom"):GetSpecialValueFor("value")
    end

    local interval = self.ability:GetSpecialValueFor("interval")

    if self.caster:HasTalent("special_bonus_unique_juggernaut_6_custom") then
        interval = interval + self.caster:FindAbilityByName("special_bonus_unique_juggernaut_6_custom"):GetSpecialValueFor("value")
    end

    self.radius = self.ability:GetSpecialValueFor("radius")

    self:StartIntervalThink(interval)

    EmitSoundOn("Hero_Juggernaut.HealingWard.Loop", self.parent)
end

function modifier_juggernaut_jade_dragonling_custom:OnRemoved()
    if not IsServer() then return end

    EmitSoundOn("Hero_Juggernaut.HealingWard.Stop", self.parent)
    StopSoundOn("Hero_Juggernaut.HealingWard.Loop", self.parent)

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_juggernaut_jade_dragonling_custom:OnIntervalThink()
    local units = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    if #units < 1 then return end

    local healing = self.damage / #units

    if healing < 1 then return end

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_fortunes_tout/jugg_healing_ward_fortunes_tout_gold.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 2, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 0, Vector(self.radius, 0, -self.radius))
    ParticleManager:DestroyParticle(self.vfx, false)
    ParticleManager:ReleaseParticleIndex(self.vfx)

    for _,unit in ipairs(units) do
        if not unit:IsAlive() then break end

        unit:Heal(healing, self.ability)

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, healing, nil)

        self.damage = self.damage - healing

        if self.caster:HasModifier("modifier_item_aghanims_shard") then
            local buff = unit:FindModifierByName("modifier_juggernaut_jade_dragonling_custom_shard")

            if not buff then
                buff = unit:AddNewModifier(self.caster, self.ability, "modifier_juggernaut_jade_dragonling_custom_shard", {
                    duration = self.ability:GetSpecialValueFor("shard_duration")
                })
            end

            if buff then
                buff:ForceRefresh()
            end
        end
    end
end

function modifier_juggernaut_jade_dragonling_custom:GetEffectName()
    return "particles/arena/units/heroes/hero_destroyer/destroyer_seal_of_limit_2.vpcf"
end

function modifier_juggernaut_jade_dragonling_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW 
end
----------------
function modifier_juggernaut_jade_dragonling_custom_shard:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP 
    }
end

function modifier_juggernaut_jade_dragonling_custom_shard:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("shard_damage_reduction")
end

function modifier_juggernaut_jade_dragonling_custom_shard:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("shard_damage_reduction")
end

function modifier_juggernaut_jade_dragonling_custom_shard:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end