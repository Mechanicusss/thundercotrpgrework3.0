LinkLuaModifier("modifier_silencer_silent_bliss_custom", "heroes/hero_silencer/silencer_silent_bliss_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_silent_bliss_custom_buff", "heroes/hero_silencer/silencer_silent_bliss_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_silent_bliss_custom_debuff", "heroes/hero_silencer/silencer_silent_bliss_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
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

silencer_silent_bliss_custom = class(ItemBaseClass)
modifier_silencer_silent_bliss_custom = class(silencer_silent_bliss_custom)
modifier_silencer_silent_bliss_custom_buff = class(ItemBaseClassBuff)
modifier_silencer_silent_bliss_custom_debuff = class(ItemBaseClassDebuff)
-------------
function silencer_silent_bliss_custom:GetIntrinsicModifierName()
    return "modifier_silencer_silent_bliss_custom"
end

function modifier_silencer_silent_bliss_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_silencer_silent_bliss_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local target = event.target
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local damage = ability:GetSpecialValueFor("bonus_silence_damage_pct")
    local duration = ability:GetSpecialValueFor("duration")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if not target:IsSilenced() then return end 

    if IsServer() then
        local buff = parent:FindModifierByName("modifier_silencer_silent_bliss_custom_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, ability, "modifier_silencer_silent_bliss_custom_buff", { duration = duration })
        end 

        if buff then
            if buff:GetStackCount() < maxStacks then
                buff:IncrementStackCount()
            end 

            buff:ForceRefresh()
        end

        target:AddNewModifier(parent, ability, "modifier_silencer_silent_bliss_custom_debuff", {})
    end

    return damage
end
------------
function modifier_silencer_silent_bliss_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if IsServer() then
        self:OnIntervalThink()
        self:StartIntervalThink(0.1)
    end
end

function modifier_silencer_silent_bliss_custom_buff:OnIntervalThink()
    self.total = self:GetParent():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("bonus_spell_damage")/100) * self:GetStackCount()
    self:InvokeBonus()
end

function modifier_silencer_silent_bliss_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_silencer_silent_bliss_custom_buff:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_silencer_silent_bliss_custom_buff:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_silencer_silent_bliss_custom_buff:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end

function modifier_silencer_silent_bliss_custom_buff:GetModifierSpellAmplify_Percentage()
    return self.fTotal
end
-------------
function modifier_silencer_silent_bliss_custom_debuff:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    EmitSoundOn("Hero_Silencer.Curse.Impact", self:GetParent())

    self:StartIntervalThink(interval)
end

function modifier_silencer_silent_bliss_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsSilenced() then
        self:Destroy()
        return
    end

    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage, nil)

    EmitSoundOn("Hero_Silencer.Curse_Tick", parent)
end

function modifier_silencer_silent_bliss_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_silencer/silencer_curse.vpcf"
end

function modifier_silencer_silent_bliss_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end