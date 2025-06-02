-- Thanks to Dota IMBA for the hunter in the night model code and effects https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_night_stalker
LinkLuaModifier("modifier_night_stalker_hunter_in_the_night_custom", "heroes/hero_night_stalker/night_stalker_hunter_in_the_night_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_hunter_in_the_night_custom_flying", "heroes/hero_night_stalker/night_stalker_hunter_in_the_night_custom", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_debuff", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)

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

night_stalker_hunter_in_the_night_custom = class(ItemBaseClass)
modifier_night_stalker_hunter_in_the_night_custom = class(night_stalker_hunter_in_the_night_custom)
modifier_night_stalker_hunter_in_the_night_custom_flying = class(ItemBaseClassBuff)

function night_stalker_hunter_in_the_night_custom:GetIntrinsicModifierName()
    return "modifier_night_stalker_hunter_in_the_night_custom"
end

--[[
function night_stalker_hunter_in_the_night_custom:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()

    local ascension = self:GetCaster():FindAbilityByName("night_stalker_dark_ascension_custom")
    if not ascension then return end
    if ascension:GetLevel() < 1 then return end

    local duration = ascension:GetSpecialValueFor("interval")

    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if talent and talent:GetLevel() > 0 then
        duration = talent:GetSpecialValueFor("prey_duration")
    end

    target:AddNewModifier(self:GetCaster(), ascension, "modifier_night_stalker_dark_ascension_custom_debuff", {
        duration = duration
    })
end
--]]
-------------
function modifier_night_stalker_hunter_in_the_night_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:StartIntervalThink(FrameTime())
end

function modifier_night_stalker_hunter_in_the_night_custom:OnRemoved()
    if not IsServer() then return end

    GameRules:GetGameModeEntity():SetDaynightCycleAdvanceRate(1)
end

function modifier_night_stalker_hunter_in_the_night_custom:OnIntervalThink()
    if not GameRules:IsDaytime() and not self:GetParent():HasModifier("modifier_night_stalker_hunter_in_the_night_custom_flying") then
        self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_night_stalker_hunter_in_the_night_custom_flying", {})
    end

    if self:GetParent():HasModifier("modifier_night_stalker_hunter_in_the_night_custom_flying") then
        if GameRules:GetGameModeEntity():GetDaynightCycleAdvanceRate() == 1 then
            GameRules:GetGameModeEntity():SetDaynightCycleAdvanceRate(0.5)
        end 

        self:GetAbility():SetActivated(true)
    else
        if GameRules:GetGameModeEntity():GetDaynightCycleAdvanceRate() == 0.5 then
            GameRules:GetGameModeEntity():SetDaynightCycleAdvanceRate(1)
        end 

        self:GetAbility():SetActivated(false)
    end
end
-------------
function modifier_night_stalker_hunter_in_the_night_custom_flying:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:CheckState()
    return {
        [MODIFIER_STATE_FLYING] = true
    }
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:GetActivityTranslationModifiers()
	return "hunter_night"
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:GetModifierBaseAttackTimeConstant()
    return self.fBat
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:GetModifierMoveSpeedBonus_Percentage()
    return self.fSpeed
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.caster = self:GetCaster()
    
    -- Check wearables 
    self.caster.hiddenWearables = {}
    local model = self.caster:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            table.insert(self.caster.hiddenWearables, model)
        end

        model = model:NextMovePeer()
    end

    self.normal_model = "models/heroes/nightstalker/nightstalker.vmdl"    
	self.night_model = "models/heroes/nightstalker/nightstalker_night.vmdl"   
    
    self.caster:SetModel(self.night_model)
    self.caster:SetOriginalModel(self.night_model)
    
    if self.wings then
        -- Remove old wearables
        UTIL_Remove(self.wings)
        UTIL_Remove(self.legs)
        UTIL_Remove(self.tail)
    end
    
    -- Set new wearables
    -- These are the fallback in case the wearable loop doesn't work out for some reason
    self.wings = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/nightstalker/nightstalker_wings_night.vmdl"})
    self.legs = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/nightstalker/nightstalker_legarmor_night.vmdl"})
    self.tail = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/nightstalker/nightstalker_tail_night.vmdl"})

    for _,wearable in ipairs(self.caster.hiddenWearables) do
        local name = wearable:GetModelName()

        if string.match(name, "_wings") or string.match(name, "_back") then
            name = name:gsub("%.vmdl$", "_night.vmdl") -- We want the night version of the wings
            self.wings = SpawnEntityFromTableSynchronous("prop_dynamic", {model = name})
        end

        if string.match(name, "_leg") then
            self.legs = SpawnEntityFromTableSynchronous("prop_dynamic", {model = name})
        end

        if string.match(name, "_tail") then
            self.tail = SpawnEntityFromTableSynchronous("prop_dynamic", {model = name})
        end
    end

    -- lock to bone
    self.wings:FollowEntity(self:GetCaster(), true)
    self.legs:FollowEntity(self:GetCaster(), true)
    self.tail:FollowEntity(self:GetCaster(), true)

    Timers:CreateTimer(FrameTime(), function()
        if self.caster:IsRealHero() then        
            -- Apply change particle
            self.particle_change_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_change.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
            ParticleManager:SetParticleControl(self.particle_change_fx, 0, self.caster:GetAbsOrigin())
            ParticleManager:SetParticleControl(self.particle_change_fx, 1, self.caster:GetAbsOrigin())    
            ParticleManager:ReleaseParticleIndex(self.particle_change_fx)
        end
    end)

    self.particle_buff_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_night_buff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.caster)    
    ParticleManager:SetParticleControl(self.particle_buff_fx, 0, self.caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle_buff_fx, 1, Vector(1,0,0))
    self:AddParticle(self.particle_buff_fx, false, false, -1, false, false)

    self:StartIntervalThink(FrameTime())
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self.particle_buff_fx then
        ParticleManager:DestroyParticle(self.particle_buff_fx, false)
        ParticleManager:ReleaseParticleIndex(self.particle_buff_fx)
    end

    self.particle_change_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_change.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(self.particle_change_fx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle_change_fx, 1, caster:GetAbsOrigin())    
    ParticleManager:ReleaseParticleIndex(self.particle_change_fx)   

    caster:SetModel(self.normal_model)
    caster:SetOriginalModel(self.normal_model)
    
    if self.wings then
        -- Remove old wearables
        UTIL_Remove(self.wings)
        UTIL_Remove(self.legs)
        UTIL_Remove(self.tail)
    end
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:OnIntervalThink()
    if not self:GetCaster():HasModifier("modifier_night_stalker_hunter_in_the_night_custom") then self:Destroy() return end

    if not GameRules:IsDaytime() then
        self.bat = self:GetAbility():GetSpecialValueFor("bat_reduction")
        self.speed = self:GetAbility():GetSpecialValueFor("bonus_speed_pct")
        self.damage = ((self:GetParent():GetBaseDamageMin()+self:GetParent():GetBaseDamageMax())/2) * (self:GetAbility():GetSpecialValueFor("bonus_base_damage_pct")/100)
    else
        self.bat = 0
        self.speed = 0
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end

    self:InvokeBonus()
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
        bat = self.fBat,
        damage = self.fDamage,
    }
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:HandleCustomTransmitterData(data)
    if data.speed ~= nil and data.bat ~= nil and data.damage ~= nil then
        self.fSpeed = tonumber(data.speed)
        self.fBat = tonumber(data.bat)
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_night_stalker_hunter_in_the_night_custom_flying:InvokeBonus()
    if IsServer() == true then
        self.fSpeed = self.speed
        self.fBat = self.bat
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end