LinkLuaModifier("modifier_silencer_global_silence_custom", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_global_silence_custom_buff", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_global_silence_custom_buff_int", "heroes/hero_silencer/silencer_global_silence_custom.lua", LUA_MODIFIER_MOTION_NONE)

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

silencer_global_silence_custom = class(ItemBaseClass)
modifier_silencer_global_silence_custom = class(silencer_global_silence_custom)
modifier_silencer_global_silence_custom_buff = class(ItemBaseClassBuff)
modifier_silencer_global_silence_custom_buff_int = class(ItemBaseClassBuff)
-------------
function silencer_global_silence_custom:GetIntrinsicModifierName()
    return "modifier_silencer_global_silence_custom"
end

function silencer_global_silence_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_silencer/silencer_global_silence.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, caster:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Silencer.GlobalSilence.Cast", caster)

    caster:AddNewModifier(caster, self, "modifier_silencer_global_silence_custom_buff_int", {
        duration = self:GetSpecialValueFor("duration")
    })

    local shield = caster:GetBaseIntellect() * self:GetSpecialValueFor("int_to_shield_mult")

    local buff = caster:FindModifierByName("modifier_silencer_global_silence_custom_buff")
    if not buff then
        buff = caster:AddNewModifier(caster, self, "modifier_silencer_global_silence_custom_buff", {
            overhealPhysical = shield,
            duration = self:GetSpecialValueFor("duration")
        })
    end

    if buff then
        local shieldToAddPhysical = shield

        if shieldToAddPhysical < 0 then
            shieldToAddPhysical = 0
        end

        buff.overhealPhysical = shieldToAddPhysical

        buff:ForceRefresh()
    end
end
---------
function modifier_silencer_global_silence_custom:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_silencer_global_silence_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end 
    if parent:HasModifier("modifier_silencer_global_silence_custom_buff") then return end

    if (parent:GetHealthPercent() <= ability:GetSpecialValueFor("scepter_health_pct")) and ability:IsCooldownReady() and (parent:GetMana() >= ability:GetManaCost(-1)) then
        SpellCaster:Cast(ability, parent, true)
    end
end
---------
function modifier_silencer_global_silence_custom_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.overhealPhysical = params.overhealPhysical

    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()
end

function modifier_silencer_global_silence_custom_buff:OnRefresh()
    if not IsServer() then return end 

    self.shieldPhysical = self.overhealPhysical

    self:InvokeShield()
end

function modifier_silencer_global_silence_custom_buff:AddCustomTransmitterData()
    return
    {
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_silencer_global_silence_custom_buff:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_silencer_global_silence_custom_buff:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_silencer_global_silence_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT  
    }
end

function modifier_silencer_global_silence_custom_buff:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.overhealPhysical <= 0 then return end

    local block = 0
    local negated = self.overhealPhysical - event.damage 

    if negated <= 0 then
        block = self.overhealPhysical
    else
        block = event.damage
    end

    self.overhealPhysical = negated

    if self.overhealPhysical <= 0 then
        self.overhealPhysical = 0
        self.shieldPhysical = 0
    else
        self.shieldPhysical = self.overhealPhysical
    end

    self:InvokeShield()

    return -block
end
--------
function modifier_silencer_global_silence_custom_buff_int:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
    }
end

function modifier_silencer_global_silence_custom_buff_int:GetModifierBonusStats_Intellect()
    if self.lock then return 0 end

    self.lock = true

    local bonusInt = self:GetCaster():GetBaseIntellect()

    self.lock = false

    local bonus = bonusInt * (self:GetAbility():GetSpecialValueFor("int_pct")/100)
    
    return bonus
end