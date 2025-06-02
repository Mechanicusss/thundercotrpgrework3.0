LinkLuaModifier("modifier_item_socket_rune_legendary_blood_rush", "modifiers/runes/modifier_item_socket_rune_legendary_blood_rush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_blood_rush_buff", "modifiers/runes/modifier_item_socket_rune_legendary_blood_rush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_blood_rush_cooldown", "modifiers/runes/modifier_item_socket_rune_legendary_blood_rush", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_item_socket_rune_legendary_blood_rush = class(BaseClass)
modifier_item_socket_rune_legendary_blood_rush_buff = class(BaseClassBuff)
modifier_item_socket_rune_legendary_blood_rush_cooldown = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_blood_rush:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_berserkers_blood_glow.vpcf", context)
end

function modifier_item_socket_rune_legendary_blood_rush:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_item_socket_rune_legendary_blood_rush:OnCreated()
    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_legendary_blood_rush:OnIntervalThink()
    local parent = self:GetParent()
    local health = parent:GetHealthPercent()
    local threshold = 30
    local duration = 12

    if (health < threshold) and parent:HasModifier("modifier_item_socket_rune_legendary_blood_rush_buff") then
        parent:RemoveModifierByName("modifier_item_socket_rune_legendary_blood_rush_buff")

        local cooldown = 60

        parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_blood_rush_cooldown", {
            duration = cooldown
        })

        parent:Purge(false, true, false, true, false)

        local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, parent)
        ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)

        EmitSoundOnLocationWithCaster(parent:GetOrigin(), "DOTA_Item.Refresher.Activate", parent)

        for i=0, parent:GetAbilityCount()-1 do
            local abil = parent:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:EndCooldown()
            end
        end

        for i=0,17 do
            local item = parent:GetItemInSlot(i)
            if item ~= nil then
                local pass = false
                if item:GetPurchaser() == parent then
                    pass = true
                end

                if pass then
                    item:EndCooldown()
                end
            end
        end
    end
end

function modifier_item_socket_rune_legendary_blood_rush:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local target = event.unit
    local attacker = event.attacker

    if attacker ~= parent or target == attacker then return end
    if parent:HasModifier("modifier_item_socket_rune_legendary_blood_rush_cooldown") then return end

    local maxStacks = 20

    local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_blood_rush_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_item_socket_rune_legendary_blood_rush_buff", {})
    end

    if buff then
        if buff:GetStackCount() < maxStacks then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_item_socket_rune_legendary_blood_rush:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local buff = parent:FindModifierByName("modifier_item_socket_rune_legendary_blood_rush_buff")
    if buff ~= nil and buff:GetStackCount() > 0 then
        buff:Destroy()
    end
end
-----------------------------------
function modifier_item_socket_rune_legendary_blood_rush_buff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_item_socket_rune_legendary_blood_rush_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_item_socket_rune_legendary_blood_rush_buff:GetModifierAttackSpeedBonus_Constant()
    return 35 * self:GetStackCount()
end

function modifier_item_socket_rune_legendary_blood_rush_buff:GetModifierTotalDamageOutgoing_Percentage()
    return 2.0 * self:GetStackCount()
end

function modifier_item_socket_rune_legendary_blood_rush_buff:GetTexture()
    return "runes/rune_legendary_blood_rush"
end

function modifier_item_socket_rune_legendary_blood_rush_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local particle_cast = "particles/units/heroes/hero_huskar/huskar_berserkers_blood_glow.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)

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

function modifier_item_socket_rune_legendary_blood_rush_buff:OnStackCountChanged()
    if not IsServer() then return end

    local pct = self:GetStackCount()/100

    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( (1-pct)*100,0,0 ) )
end