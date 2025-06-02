LinkLuaModifier("modifier_bloodseeker_thirst_custom", "heroes/hero_bloodseeker/thirst", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_thirst_custom_shield", "heroes/hero_bloodseeker/thirst", LUA_MODIFIER_MOTION_NONE)

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


bloodseeker_thirst_custom = class(ItemBaseClass)
modifier_bloodseeker_thirst_custom = class(bloodseeker_thirst_custom)
modifier_bloodseeker_thirst_custom_shield = class(ItemBaseClassBuff)
-------------
function bloodseeker_thirst_custom:GetIntrinsicModifierName()
    return "modifier_bloodseeker_thirst_custom"
end

function modifier_bloodseeker_thirst_custom:IsHidden()
    return self:GetStackCount() < 1
end

function modifier_bloodseeker_thirst_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_bloodseeker_thirst_custom:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local maxStacks = ability:GetSpecialValueFor("max_counter")
    local maxShieldStacks = ability:GetSpecialValueFor("max_stacks")
    local maxHpHeal = ability:GetSpecialValueFor("max_hp_heal")

    if parent:HasModifier("modifier_bloodseeker_blood_mist_custom_buff") then
        local mist = parent:FindAbilityByName("bloodseeker_blood_mist_custom")
        if mist then
            maxHpHeal = maxHpHeal * (1+((mist:GetSpecialValueFor("thirst_amp_pct")/100)))
        end
    end

    local heal = parent:GetMaxHealth() * (maxHpHeal/100)

    self:IncrementStackCount()

    if self:GetStackCount() >= maxStacks then
        if parent:GetHealth() == parent:GetMaxHealth() then
            local shield = parent:FindModifierByName("modifier_bloodseeker_thirst_custom_shield")
            if not shield then
                shield = parent:AddNewModifier(parent, ability, "modifier_bloodseeker_thirst_custom_shield", {})
            end

            if shield then
                shield:ForceRefresh()
            end
        else
            parent:Heal(heal, ability)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
        end

        self:SetStackCount(0)
        self:PlayEffects(parent)

        ability:UseResources(false, false, false, true)
    end
end

function modifier_bloodseeker_thirst_custom:OnCreated()
end

function modifier_bloodseeker_thirst_custom:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf"
end

function modifier_bloodseeker_thirst_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf"
    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
---------------------------------
function modifier_bloodseeker_thirst_custom_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT 
    }
end

function modifier_bloodseeker_thirst_custom_shield:AddCustomTransmitterData()
    return
    {
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_bloodseeker_thirst_custom_shield:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_bloodseeker_thirst_custom_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_bloodseeker_thirst_custom_shield:OnRefresh()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local hpHeal = ability:GetSpecialValueFor("max_hp_heal")

    if parent:HasModifier("modifier_bloodseeker_blood_mist_custom_buff") then
        local mist = parent:FindAbilityByName("bloodseeker_blood_mist_custom")
        if mist then
            hpHeal = hpHeal * (1+((mist:GetSpecialValueFor("thirst_amp_pct")/100)))
        end
    end

    local shield = parent:GetMaxHealth() * (hpHeal/100)
    local maxShield = shield * ability:GetSpecialValueFor("max_stacks")

    if self.amount < maxShield then
        self.amount = self.amount + shield

        if self.amount > maxShield then
            self.amount = maxShield
        end

        self.shieldPhysical = self.amount 
        self:InvokeShield()
    end
end 

function modifier_bloodseeker_thirst_custom_shield:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.amount = 0
end

function modifier_bloodseeker_thirst_custom_shield:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

    if event.target ~= self:GetParent() or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end
    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.amount <= 0 then return end

    local block = 0
    local negated = self.amount - event.damage 

    if negated <= 0 then
        block = self.amount
    else
        block = event.damage
    end

    self.amount = negated

    if self.amount <= 0 then
        self.amount = 0
        self.shieldPhysical = 0

        self:InvokeShield()

        self:Destroy()

        return
    else
        self.shieldPhysical = self.amount
    end

    self:InvokeShield()

    return -block
end