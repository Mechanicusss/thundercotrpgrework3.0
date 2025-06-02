LinkLuaModifier("modifier_lich_sacrifice_custom", "heroes/hero_lich/lich_sacrifice_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_sacrifice_custom_buff_permanent", "heroes/hero_lich/lich_sacrifice_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

lich_sacrifice_custom = class(ItemBaseClass)
modifier_lich_sacrifice_custom = class(lich_sacrifice_custom)
modifier_lich_sacrifice_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function lich_sacrifice_custom:GetAOERadius()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return self:GetSpecialValueFor("radius")
    end
end

function lich_sacrifice_custom:GetBehavior()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    end

    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
end

function lich_sacrifice_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local hasShard = caster:HasModifier("modifier_item_aghanims_shard")

    if hasShard then
        local point = self:GetCursorPosition()
        local radius = self:GetSpecialValueFor("radius")

        local targets = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,target in ipairs(targets) do
            if target:IsAlive() and IsCreepTCOTRPG(target) and target:GetLevel() < caster:GetLevel() then
                local conv_pct = self:GetSpecialValueFor( "health_conversion" )
                local health = target:GetHealth() * (conv_pct/100)
                caster:Heal( health, self )
                SendOverheadEventMessage(
                    nil,
                    OVERHEAD_ALERT_HEAL,
                    caster,
                    health,
                    nil
                )
                target:Kill( self, caster )
                self:PlayEffects( target )

                local buff = caster:FindModifierByName("modifier_lich_sacrifice_custom_buff_permanent")
                
                if buff == nil then
                    buff = caster:AddNewModifier(caster, self, "modifier_lich_sacrifice_custom_buff_permanent", {})
                end

                if buff ~= nil then
                    buff:IncrementStackCount()
                end
            end
        end

        return
    end

    if not IsCreepTCOTRPG(target) or target:GetLevel() > caster:GetLevel() then
        DisplayError(caster:GetPlayerID(), "Cannot Do That.")
        self:EndCooldown()
        return 
    end

    local conv_pct = self:GetSpecialValueFor( "health_conversion" )
    local health = target:GetHealth() * (conv_pct/100)
    caster:Heal( health, self )
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        caster,
        health,
        nil
    )
    target:Kill( self, caster )
    self:PlayEffects( target )

    local buff = caster:FindModifierByName("modifier_lich_sacrifice_custom_buff_permanent")
    
    if buff == nil then
        buff = caster:AddNewModifier(caster, self, "modifier_lich_sacrifice_custom_buff_permanent", {})
    end

    if buff ~= nil then
        buff:IncrementStackCount()
    end
end

function lich_sacrifice_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lich/lich_dark_ritual.vpcf"
    local sound_cast = "Hero_Lich.SinisterGaze.Cast.TI10"

    -- Get Data

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    -- ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_lich_sacrifice_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_lich_sacrifice_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP
    }

    return funcs
end

function modifier_lich_sacrifice_custom_buff_permanent:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.total = 0
end

function modifier_lich_sacrifice_custom_buff_permanent:OnTooltip()
    return self.fTotal
end

function modifier_lich_sacrifice_custom_buff_permanent:OnStackCountChanged()    
    if not IsServer() then return end

    local gain = self:GetAbility():GetSpecialValueFor("int_per_kill")

    self:GetParent():ModifyIntellect(gain)

    self.total = self.total + gain

    self:InvokeBonus()
end

function modifier_lich_sacrifice_custom_buff_permanent:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_lich_sacrifice_custom_buff_permanent:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_lich_sacrifice_custom_buff_permanent:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end
-------------
function lich_sacrifice_custom:GetIntrinsicModifierName()
    return "modifier_lich_sacrifice_custom"
end

function modifier_lich_sacrifice_custom:OnCreated()
end