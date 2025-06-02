LinkLuaModifier("modifier_item_socket_rune_legendary_rejuvenation", "modifiers/runes/modifier_item_socket_rune_legendary_rejuvenation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_rejuvenation_buff", "modifiers/runes/modifier_item_socket_rune_legendary_rejuvenation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_rejuvenation_cooldown", "modifiers/runes/modifier_item_socket_rune_legendary_rejuvenation", LUA_MODIFIER_MOTION_NONE)

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

modifier_item_socket_rune_legendary_rejuvenation = class(BaseClass)
modifier_item_socket_rune_legendary_rejuvenation_buff = class(BaseClassBuff)
modifier_item_socket_rune_legendary_rejuvenation_cooldown = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_rejuvenation:Precache(context)
    PrecacheResource("particle", "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield__2alliance.vpcf", context)
end

function modifier_item_socket_rune_legendary_rejuvenation:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_HEAL_RECEIVED
    }
end

function modifier_item_socket_rune_legendary_rejuvenation:OnHealReceived(event)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local inflictor = event.inflictor -- Heal ability
    local unit = event.unit 
    local amount = event.gain -- Amount healed

    if not inflictor or inflictor == self:GetAbility() then return end

    local healSpell = caster:FindAbilityByName(inflictor:GetName())

    if not healSpell then return end
    if unit:HasModifier("modifier_item_socket_rune_legendary_rejuvenation_cooldown") then return end

    local healer = inflictor:GetCaster()

    if not healer:HasModifier("modifier_item_socket_rune_legendary_rejuvenation") then return end

    if string.match(inflictor:GetAbilityName(), "item_") or string.match(inflictor:GetAbilityName(), "fountain") then return end

    local duration = 10
    local cooldown = 7

    local buff = unit:FindModifierByName("modifier_item_socket_rune_legendary_rejuvenation_buff")
    if not buff then
        buff = unit:AddNewModifier(healer, nil, "modifier_item_socket_rune_legendary_rejuvenation_buff", {
            duration = duration
        })

        unit:AddNewModifier(healer, nil, "modifier_item_socket_rune_legendary_rejuvenation_cooldown", {
            duration = cooldown
        })
    end

    if buff then
        buff:ForceRefresh()
    end
end
---------------------------------------------
function modifier_item_socket_rune_legendary_rejuvenation_buff:OnCreated()
    if not IsServer() then return end

    self:OnRefresh()

    local parent = self:GetParent()

    EmitSoundOn("Hero_Abaddon.AphoticShield.Cast", parent)

    local particle_cast = "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield__2alliance.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)
    local shield_size = parent:GetModelRadius() * 1.0
    local common_vector = Vector(shield_size,0,shield_size)
    ParticleManager:SetParticleControl(self.effect_cast, 1, common_vector)
    ParticleManager:SetParticleControl(self.effect_cast, 2, common_vector)
    ParticleManager:SetParticleControl(self.effect_cast, 4, common_vector)
    ParticleManager:SetParticleControl(self.effect_cast, 5, Vector(shield_size,0,0))
    ParticleManager:SetParticleControlEnt(self.effect_cast, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:OnIntervalThink()
    if self.shield <= 0 then
        self:Destroy()
    end
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:OnRefresh()
    if not IsServer() then return end

    local shieldAmount = self:GetParent():GetMaxHealth() * 3.0

    self.shield = shieldAmount
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK, 
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK 
    }
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:GetModifierMagical_ConstantBlock(event)
    if self.shield <= 0 then return end

    local block = 0
    local negated = self.shield - event.damage 

    if negated <= 0 then
        block = self.shield
    else
        block = event.damage
    end

    self.shield = negated

    return block
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:GetModifierPhysical_ConstantBlock(event)
    if self.shield <= 0 then return end
    
    local block = 0
    local negated = self.shield - event.damage 

    if negated <= 0 then
        block = self.shield
    else
        block = event.damage
    end

    self.shield = negated

    return block
end

function modifier_item_socket_rune_legendary_rejuvenation_buff:GetTexture()
    return "runes/rune_legendary_rejuvenation"
end