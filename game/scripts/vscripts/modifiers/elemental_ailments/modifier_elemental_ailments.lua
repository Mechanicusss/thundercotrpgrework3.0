
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailments = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailments:OnCreated()
    if not IsServer() then return end 

    self.outgoingDamage = {}
end

function modifier_elemental_ailments:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_elemental_ailments:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    local inflictor = event.inflictor 

    if not inflictor then return end 

    local name = inflictor:GetAbilityName()

    local damageType = ELEMENTAL_AILMENT_ABILITIES[name]

    if not damageType then return end 

    local parent = self:GetParent()
    
    local victim = event.target

    local ailmentEffectName = "modifier_elemental_ailment_" .. damageType
    local ailmentDuration

    if damageType == "fire" then 
        ailmentDuration = 7
    end

    if damageType == "cold" then 
        ailmentDuration = 7
    end

    if damageType == "necrotic" then 
        ailmentDuration = 30
    end

    if damageType == "nature" then 
        ailmentDuration = 10
    end

    if damageType == "lightning" then 
        ailmentDuration = 10
    end

    if damageType == "arcane" then 
        ailmentDuration = 3
    end

    -- Only add the status effect if they don't have immunity to it
    if not victim:HasModifier("modifier_elemental_ailment_"..damageType.."_immunity") then
        local ailmentEffect = victim:FindModifierByName(ailmentEffectName)
        if not ailmentEffect then 
            ailmentEffect = victim:AddNewModifier(parent, nil, ailmentEffectName, { duration = ailmentDuration })
        end

        if ailmentEffect then 
            if damageType == "fire" then 
                if ailmentEffect:GetStackCount() < 99 then
                    ailmentEffect:IncrementStackCount()
                end

                ailmentEffect:ForceRefresh()
            end

            if damageType == "cold" then 
                if ailmentEffect:GetStackCount() < 99 then
                    ailmentEffect:IncrementStackCount()
                end

                ailmentEffect:ForceRefresh()
            end

            if damageType == "nature" then 
                if ailmentEffect:GetStackCount() < 99 then
                    ailmentEffect:IncrementStackCount()
                end

                ailmentEffect:ForceRefresh()
            end

            if damageType == "lightning" then 
                ailmentEffect:ForceRefresh()
            end

            if damageType == "necrotic" then 
                ailmentEffect:ForceRefresh()
            end

            if damageType == "arcane" then 
                if ailmentEffect:GetStackCount() < 99 then
                    ailmentEffect:IncrementStackCount()
                end
                
                ailmentEffect:ForceRefresh()
            end
        end
    end

    local damageBonuses = self:GetAilmentBonusForElements()

    local bonus = damageBonuses[damageType]

    if not bonus then return end

    return bonus
end

function modifier_elemental_ailments:GetAilmentBonusForElements()
    local values = {
        ["fire"] = 0,
        ["cold"] = 0,
        ["lightning"] = 0,
        ["temporal"] = 0,
        ["arcane"] = 0,
        ["necrotic"] = 0,
        ["nature"] = 0,
    }

    for abilityName,obj in pairs(self.outgoingDamage) do 
        for dt,damage in pairs(obj) do 
            values[dt] = values[dt] + damage
        end
    end

    return values
end

function modifier_elemental_ailments:SetAilmentBonusDamage(ability, damageType, damage)
    local name = ability:GetAbilityName()

    self.outgoingDamage[name] = self.outgoingDamage[name] or {}
    self.outgoingDamage[name][damageType] = self.outgoingDamage[name][damageType] or 0
    self.outgoingDamage[name][damageType] = math.floor(damage)
end