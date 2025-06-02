LinkLuaModifier("modifier_item_vampires_kiss", "items/item_vampires_kiss/item_vampires_kiss", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_vampires_kiss_shield", "items/item_vampires_kiss/item_vampires_kiss", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_vampires_kiss = class(ItemBaseClass)
modifier_item_vampires_kiss = class(item_vampires_kiss)
modifier_item_vampires_kiss_shield = class(ItemBaseClassBuff)
-------------
function item_vampires_kiss:GetIntrinsicModifierName()
    return "modifier_item_vampires_kiss"
end

function item_vampires_kiss:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
-------------
function modifier_item_vampires_kiss:OnCreated()
end

function modifier_item_vampires_kiss:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_vampires_kiss:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetCaster() ~= attacker then
        return
    end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal_amount_pct")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local maxShield = ability:GetSpecialValueFor("max_health_shield_pct")
    
    local allies = FindUnitsInRadius(attacker:GetTeam(), attacker:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,ally in ipairs(allies) do
        if ally ~= nil and not ally:IsNull() and ally:IsAlive() then
            if ally:GetHealth() == ally:GetMaxHealth() then
                local shieldLimit = self:GetCaster():GetMaxHealth() * (maxShield/100)
                local shieldAmount = heal 

                if shieldAmount > shieldLimit then
                    shieldAmount = shieldLimit
                end

                local shield = ally:FindModifierByName("modifier_item_vampires_kiss_shield")
                if not shield then
                    shield = ally:AddNewModifier(self:GetCaster(), ability, "modifier_item_vampires_kiss_shield", {
                        amount = shieldAmount
                    })
                end
    
                if shield then
                    local updatedShieldAmount = shield.amount + shieldAmount

                    if updatedShieldAmount > shieldLimit then
                        updatedShieldAmount = shieldLimit
                    end

                    shield.amount = updatedShieldAmount
                    shield:ForceRefresh()
                end
            else
                ally:Heal(heal, nil)

                local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
                ParticleManager:ReleaseParticleIndex(particle)
            end
        end
    end
end
---------
function modifier_item_vampires_kiss_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT  
    }
end

function modifier_item_vampires_kiss_shield:AddCustomTransmitterData()
    return
    {
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_item_vampires_kiss_shield:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_item_vampires_kiss_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_vampires_kiss_shield:OnRefresh()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local maxShield = self:GetCaster():GetMaxHealth() * (ability:GetSpecialValueFor("max_health_shield_pct")/100)

    if self.amount > maxShield then
        self.amount = maxShield
    end

    self.shieldPhysical = self.amount 
    self:InvokeShield()
end 

function modifier_item_vampires_kiss_shield:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.amount = 0
end

function modifier_item_vampires_kiss_shield:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

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