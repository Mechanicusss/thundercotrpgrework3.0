LinkLuaModifier("tricks_of_the_trade_custom_modifier", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_thinker", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_banished", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("tricks_of_the_trade_custom_buff", "heroes/hero_riki/tricks_of_the_trade_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local BaseClassThinker = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

tricks_of_the_trade_custom = class(BaseClass)
tricks_of_the_trade_custom_thinker = class(BaseClassThinker)
tricks_of_the_trade_custom_banished = class(BaseClassThinker)
tricks_of_the_trade_custom_modifier = class(BaseClass)
tricks_of_the_trade_custom_buff = class(BaseClassBuff)

function tricks_of_the_trade_custom:GetIntrinsicModifierName()
    return "tricks_of_the_trade_custom_modifier"
end

function tricks_of_the_trade_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tricks_of_the_trade_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
    else
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
    end
end

function tricks_of_the_trade_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    if caster:HasScepter() then
        duration = self:GetSpecialValueFor("scepter_duration")
    end

    local target = self:GetCursorTarget()
    local targetIndex = nil 

    if target ~= nil then
        targetIndex = target:entindex()
    end

    --todo: check if Length2D instead of Length fixes the stair thing
    if (point - caster:GetAbsOrigin()):Length2D() > self:GetEffectiveCastRange(caster:GetOrigin(), nil) then return end -- Exceeded cast range

    -- Give Riki his agility buff --
    caster:AddNewModifier(caster, self, "tricks_of_the_trade_custom_buff", {
        duration = duration
    })

    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())

    -- Thinker
    local interval = 1 / caster:GetAttacksPerSecond(false)

    FindClearSpaceForUnit(emitter, point, true)

    emitter:AddNewModifier(caster, self, "tricks_of_the_trade_custom_banished", {
        targetIndex = targetIndex
    })

    emitter:AddNewModifier(caster, self, "tricks_of_the_trade_custom_thinker", {
        interval = interval,
        radius = radius,
        duration = duration
    })
end
--------------
function tricks_of_the_trade_custom_thinker:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.interval = params.interval
    self.radius = params.radius

    EmitSoundOn("Hero_Riki.TricksOfTheTrade", parent)

    self:StartIntervalThink(self.interval)
    self:OnIntervalThink()
end

function tricks_of_the_trade_custom_thinker:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("tricks_of_the_trade_custom_banished")
end

function tricks_of_the_trade_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES),
        FIND_CLOSEST, false)

    if #units > 0 then
        local target = units[RandomInt(1, #units)]
        if target and not target:IsNull() then
            caster:PerformAttack(target, true, true, true, false, false, false, true)
        end
    end
end
-------------------
function tricks_of_the_trade_custom_banished:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local point = parent:GetAbsOrigin()

    local duration = self:GetAbility():GetSpecialValueFor("duration")
    local radius = self:GetAbility():GetSpecialValueFor("radius")

    if caster:HasScepter() then
        duration = self:GetAbility():GetSpecialValueFor("scepter_duration")
    end

    self.target = nil 

    if params.targetIndex ~= nil then
        self.target = EntIndexToHScript(params.targetIndex)
    end

    -- Particles
    self.castParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks_cast.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.castParticle, 0, point)
    ParticleManager:SetParticleControl(self.castParticle, 3, point)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.particle, 0, point)
    ParticleManager:SetParticleControl(self.particle, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(self.particle, 2, Vector(duration, 0, 0))
    
    parent:AddNoDraw()

    self:StartIntervalThink(FrameTime())
end

function tricks_of_the_trade_custom_banished:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if caster:HasScepter() then
        if self.target ~= nil and not self.target:IsNull() then
            if not self.target:IsAlive() then
                self:Destroy()
                return
            end

            parent:SetAbsOrigin(self.target:GetAbsOrigin())

            local point = parent:GetAbsOrigin()

            ParticleManager:SetParticleControl(self.castParticle, 0, point)
            ParticleManager:SetParticleControl(self.castParticle, 3, point)
            ParticleManager:SetParticleControl(self.particle, 0, point)
        end
    end
end

function tricks_of_the_trade_custom_banished:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    
    parent:RemoveNoDraw()

    parent:RemoveModifierByName("tricks_of_the_trade_custom_thinker")

    if self.castParticle ~= nil then
        ParticleManager:DestroyParticle(self.castParticle, true)
        ParticleManager:ReleaseParticleIndex(self.castParticle)
    end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end

    UTIL_Remove(parent)
end

function tricks_of_the_trade_custom_banished:CheckState()
    local states = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
    }

    return states
end
-----------
function tricks_of_the_trade_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }

    return funcs
end

function tricks_of_the_trade_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.agility = self:GetParent():GetBaseAgility() * (self:GetAbility():GetSpecialValueFor("agi_mult")/100)

    self:InvokeBonusAgility()
end

function tricks_of_the_trade_custom_buff:AddCustomTransmitterData()
    return
    {
        agility = self.fAgility,
    }
end

function tricks_of_the_trade_custom_buff:HandleCustomTransmitterData(data)
    if data.agility ~= nil then
        self.fAgility = tonumber(data.agility)
    end
end

function tricks_of_the_trade_custom_buff:InvokeBonusAgility()
    if IsServer() == true then
        self.fAgility = self.agility

        self:SendBuffRefreshToClients()
    end
end

function tricks_of_the_trade_custom_buff:GetModifierBonusStats_Agility()
    return self.fAgility
end