LinkLuaModifier("modifier_primal_beast_uproar_custom", "heroes/hero_primal_beast/primal_beast_uproar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_uproar_custom_buff", "heroes/hero_primal_beast/primal_beast_uproar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_uproar_custom_status_resistance", "heroes/hero_primal_beast/primal_beast_uproar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_uproar_custom_active", "heroes/hero_primal_beast/primal_beast_uproar_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

primal_beast_uproar_custom = class(ItemBaseClass)
modifier_primal_beast_uproar_custom = class(primal_beast_uproar_custom)
modifier_primal_beast_uproar_custom_buff = class(ItemBaseClassBuff)
modifier_primal_beast_uproar_custom_status_resistance = class(ItemBaseClassBuff)
modifier_primal_beast_uproar_custom_active = class(ItemBaseClassBuff)
-------------
function primal_beast_uproar_custom:GetIntrinsicModifierName()
    return "modifier_primal_beast_uproar_custom"
end

function primal_beast_uproar_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_PrimalBeast.Uproar.Cast", caster)

    local stacks = caster:FindModifierByName("modifier_primal_beast_uproar_custom_buff")
    local count = stacks:GetStackCount()

    if count < self:GetSpecialValueFor("max_stacks") then return end

    if caster:HasModifier("modifier_primal_beast_uproar_custom_active") then
        caster:RemoveModifierByName("modifier_primal_beast_uproar_custom_active")
    end

    local buff = caster:AddNewModifier(caster, self, "modifier_primal_beast_uproar_custom_active", {
        duration = self:GetSpecialValueFor("duration"),
        count = count
    })

    stacks:Destroy()
end
-------------
function modifier_primal_beast_uproar_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
    }
end

function modifier_primal_beast_uproar_custom:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("passive_status_resistance_bonus")
end

function modifier_primal_beast_uproar_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("passive_armor_bonus")
end

function modifier_primal_beast_uproar_custom:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("stacking_chance")

    self.accumulatedChance = chance

    self.sound = false

    self:StartIntervalThink(FrameTime())
end

function modifier_primal_beast_uproar_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    local buff = parent:FindModifierByName("modifier_primal_beast_uproar_custom_buff")
    if buff ~= nil and buff:GetStackCount() == ability:GetSpecialValueFor("max_stacks") then
        ability:SetActivated(true)
    else
        ability:SetActivated(false)
    end
end

function modifier_primal_beast_uproar_custom:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.target or parent == event.attacker then return end

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("stacking_chance")

    if not RollPercentage(self.accumulatedChance) then
        self.accumulatedChance = self.accumulatedChance + chance
        return
    end

    -- Add damage buff
    if not parent:HasModifier("modifier_primal_beast_uproar_custom_active") then
        local buff = parent:FindModifierByName("modifier_primal_beast_uproar_custom_buff")

        if not buff then
            buff = parent:AddNewModifier(parent, ability, "modifier_primal_beast_uproar_custom_buff", {
                duration = ability:GetSpecialValueFor("stack_duration")
            })
        end

        if buff then
            if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                self.sound = false
                buff:IncrementStackCount()
            end

            if buff:GetStackCount() >= ability:GetSpecialValueFor("max_stacks") then
                if not self.sound then
                    EmitSoundOn("Hero_PrimalBeast.Uproar.MaxStacks", parent)
                    self.sound = true
                end
            end

            buff:ForceRefresh()
        end
    end

    -- Status Resistance set to 100% for a brief moment to cause all debuffs to not apply to him
    parent:AddNewModifier(
        parent,
        ability,
        "modifier_primal_beast_uproar_custom_status_resistance",
        {
            duration = 0.5
        }
    )

    -- Reset chance on a successful block
    self.accumulatedChance = chance

    return -event.damage
end
-------------
function modifier_primal_beast_uproar_custom_status_resistance:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    }
end

function modifier_primal_beast_uproar_custom_status_resistance:GetModifierStatusResistanceStacking()
    return 100
end

function modifier_primal_beast_uproar_custom_status_resistance:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_primal_beast_uproar_custom_status_resistance:IsHidden()
    return true 
end
-------------
function modifier_primal_beast_uproar_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_primal_beast_uproar_custom_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("stack_outgoing_damage") * self:GetStackCount()
end
--------------------------
function modifier_primal_beast_uproar_custom_active:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local caster = self:GetCaster()
    local count = params.count 

    local ability = self:GetAbility()

    self.hp = caster:GetMaxHealth() * (ability:GetSpecialValueFor("hp_pct_per_stack")/100) * count
    self.damage = ability:GetSpecialValueFor("stack_outgoing_damage") * count * 2

    self:InvokeBonus()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_primal_beast/primal_beast_uproar_magic_resist.vpcf", PATTACH_OVERHEAD_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        2,
        caster,
        PATTACH_OVERHEAD_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end

function modifier_primal_beast_uproar_custom_active:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_primal_beast_uproar_custom_active:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS 
    }
end

function modifier_primal_beast_uproar_custom_active:GetModifierTotalDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_primal_beast_uproar_custom_active:GetModifierHealthBonus()
    return self.fHp
end

function modifier_primal_beast_uproar_custom_active:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
        hp = self.fHp,
    }
end

function modifier_primal_beast_uproar_custom_active:HandleCustomTransmitterData(data)
    if data.damage ~= nil and data.hp ~= nil then
        self.fDamage = tonumber(data.damage)
        self.fHp = tonumber(data.hp)
    end
end

function modifier_primal_beast_uproar_custom_active:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage
        self.fHp = self.hp

        self:SendBuffRefreshToClients()
    end
end