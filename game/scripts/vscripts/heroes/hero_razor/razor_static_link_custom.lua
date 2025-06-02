LinkLuaModifier("modifier_razor_static_link_custom", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_razor_static_link_custom_buff", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_razor_static_link_custom_ally_buff", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_razor_static_link_custom_buff_finished", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_razor_static_link_custom_debuff_finished", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_razor_static_link_custom_debuff", "heroes/hero_razor/razor_static_link_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

razor_static_link_custom = class(ItemBaseClass)
modifier_razor_static_link_custom = class(razor_static_link_custom)
modifier_razor_static_link_custom_buff = class(ItemBaseClassBuff)
modifier_razor_static_link_custom_ally_buff = class(ItemBaseClassBuff)
modifier_razor_static_link_custom_buff_finished = class(ItemBaseClassBuff)
modifier_razor_static_link_custom_debuff_finished = class(ItemBaseClassBuff)
modifier_razor_static_link_custom_debuff = class(ItemBaseClassDebuff)
-------------
function razor_static_link_custom:GetIntrinsicModifierName()
    return "modifier_razor_static_link_custom"
end

function razor_static_link_custom:GetAbilityTargetTeam()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return DOTA_UNIT_TARGET_TEAM_BOTH end

    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function razor_static_link_custom:CastFilterResultTarget(target)
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
           if target:IsHero() then
                if target == self:GetCaster() then
                    return UF_FAIL_OTHER
                end
                
                return UF_SUCCESS
            else
                return UF_FAIL_OTHER 
            end
        end

        if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            return UF_SUCCESS
        end
    else
        if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            return UF_SUCCESS
        else
            return UF_FAIL_FRIENDLY
        end
    end
end

function razor_static_link_custom:OnSpellStart()
    if not IsServer() then return end

    local parent = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("Ability.static.start", parent)

    if parent:HasModifier("modifier_razor_static_link_custom_buff") then
        parent:RemoveModifierByName("modifier_razor_static_link_custom_buff")
    end

    if target:HasModifier("modifier_razor_static_link_custom_debuff") then
        target:RemoveModifierByName("modifier_razor_static_link_custom_debuff")
    end

    if target:HasModifier("modifier_razor_static_link_custom_ally_buff") then
        target:RemoveModifierByName("modifier_razor_static_link_custom_ally_buff")
    end

    if target:GetTeamNumber() == parent:GetTeamNumber() then
        parent:AddNewModifier(parent, self, "modifier_razor_static_link_custom_buff", {
            duration = duration,
            enemy = target:GetEntityIndex()
        })

        target:AddNewModifier(parent, self, "modifier_razor_static_link_custom_ally_buff", {
            duration = duration
        })

        return
    end

    parent:AddNewModifier(parent, self, "modifier_razor_static_link_custom_buff", {
        duration = duration,
        enemy = target:GetEntityIndex()
    })

    target:AddNewModifier(parent, self, "modifier_razor_static_link_custom_debuff", {
        duration = duration
    })
end
-------------
function modifier_razor_static_link_custom_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    self.target = EntIndexToHScript(params.enemy)

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_razor/razor_static_link.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        self.target,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self.target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetAbsOrigin() )

    local ability = self:GetAbility()
    
    self.drain = ability:GetSpecialValueFor("drain")

    self.interval = ability:GetSpecialValueFor("interval")

    self.damage = 0

    self:StartIntervalThink(self.interval)

    EmitSoundOn("Ability.static.loop", self:GetParent())
end

function modifier_razor_static_link_custom_buff:OnRemoved(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    EmitSoundOn("Ability.static.end", parent)
    StopSoundOn("Ability.static.loop", parent)

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    if parent:GetTeamNumber() == self.target:GetTeamNumber() then return end
    
    parent:AddNewModifier(parent, ability, "modifier_razor_static_link_custom_buff_finished", {
        duration = ability:GetSpecialValueFor("end_duration"),
        damage = self.damage
    })
end

function modifier_razor_static_link_custom_buff:OnIntervalThink()
    local parent = self:GetParent()

    local distance = (self:GetCaster():GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D()
    if distance > self:GetAbility():GetSpecialValueFor("max_distance") then
        self:Destroy()
    end

    if self:GetCaster():GetTeamNumber() == self.target:GetTeamNumber() then return end

    --local levelDifference = (self:GetCaster():GetLevel() / self.target:GetLevel())/(11-self:GetAbility():GetLevel())

    local drain = ((parent:GetAverageTrueAttackDamage(parent)) * (self.drain/100) * self.interval)

    self.damage = self.damage + drain

    self:InvokeBonusDamage()
end

function modifier_razor_static_link_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_razor_static_link_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_razor_static_link_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_static_link_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_static_link_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_razor_static_link_custom_debuff:IsDebuff()
    return true
end

function modifier_razor_static_link_custom_debuff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.target = self:GetParent()

    local ability = self:GetAbility()

    self.drain = ability:GetSpecialValueFor("drain")

    self.interval = ability:GetSpecialValueFor("interval")

    self.damage = 0

    self:StartIntervalThink(self.interval)
end

function modifier_razor_static_link_custom_debuff:OnRemoved(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:AddNewModifier(self:GetCaster(), ability, "modifier_razor_static_link_custom_debuff_finished", {
        duration = ability:GetSpecialValueFor("end_duration"),
        damage = self.damage
    })
end

function modifier_razor_static_link_custom_debuff:OnIntervalThink()
    local caster = self:GetCaster()

    local distance = (self:GetCaster():GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D()
    if distance > self:GetAbility():GetSpecialValueFor("max_distance") then
        self:Destroy()
    end

    --local levelDifference = (self:GetCaster():GetLevel() / self.target:GetLevel())/(11-self:GetAbility():GetLevel())

    local drain = ((caster:GetAverageTrueAttackDamage(caster)) * (self.drain/100) * self.interval)

    self.damage = self.damage + drain

    self:InvokeBonusDamage()
end

function modifier_razor_static_link_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_razor_static_link_custom_debuff:GetModifierPreAttack_BonusDamage()
    if self.fDamage ~= nil then
        return -self.fDamage
    end
end

function modifier_razor_static_link_custom_debuff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_static_link_custom_debuff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_static_link_custom_debuff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
---------------
function modifier_razor_static_link_custom_buff_finished:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_razor_static_link_custom_buff_finished:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_razor_static_link_custom_buff_finished:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_razor_static_link_custom_buff_finished:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_static_link_custom_buff_finished:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_static_link_custom_buff_finished:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
---------------
function modifier_razor_static_link_custom_debuff_finished:IsDebuff()
    return true
end

function modifier_razor_static_link_custom_debuff_finished:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_razor_static_link_custom_debuff_finished:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_razor_static_link_custom_debuff_finished:GetModifierPreAttack_BonusDamage()
    if self.fDamage ~= nil then
        return -self.fDamage
    end
end

function modifier_razor_static_link_custom_debuff_finished:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_static_link_custom_debuff_finished:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_static_link_custom_debuff_finished:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_razor_static_link_custom_ally_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.target = self:GetParent()

    local ability = self:GetAbility()

    self.drain = ability:GetSpecialValueFor("drain")

    self.interval = ability:GetSpecialValueFor("interval")

    self.damage = 0

    self:StartIntervalThink(self.interval)
end

function modifier_razor_static_link_custom_ally_buff:OnRemoved(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:AddNewModifier(self:GetCaster(), ability, "modifier_razor_static_link_custom_buff_finished", {
        duration = ability:GetSpecialValueFor("end_duration"),
        damage = self.damage
    })
end

function modifier_razor_static_link_custom_ally_buff:OnIntervalThink()
    local distance = (self:GetCaster():GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D()
    if distance > self:GetAbility():GetSpecialValueFor("max_distance") then
        self:Destroy()
    end

    local gains = ((self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())) * (self.drain/100) * self.interval)
    self.damage = self.damage + gains

    self:InvokeBonusDamage()
end

function modifier_razor_static_link_custom_ally_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_razor_static_link_custom_ally_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_razor_static_link_custom_ally_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_static_link_custom_ally_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_static_link_custom_ally_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end