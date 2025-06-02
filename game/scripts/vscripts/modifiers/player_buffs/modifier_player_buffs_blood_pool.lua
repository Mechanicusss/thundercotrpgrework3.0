LinkLuaModifier("modifier_player_buffs_blood_pool", "modifiers/player_buffs/modifier_player_buffs_blood_pool", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_blood_pool_emitter", "modifiers/player_buffs/modifier_player_buffs_blood_pool", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_blood_pool_emitter_aura", "modifiers/player_buffs/modifier_player_buffs_blood_pool", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_blood_pool_emitter_aura_enemy", "modifiers/player_buffs/modifier_player_buffs_blood_pool", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_blood_pool_shield", "modifiers/player_buffs/modifier_player_buffs_blood_pool", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_blood_pool = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_blood_pool_emitter = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_blood_pool_emitter_aura = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_blood_pool_emitter_aura_enemy = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_player_buffs_blood_pool_shield = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_blood_pool = class(ItemBaseClass)

function modifier_player_buffs_blood_pool:GetIntrinsicModifierName()
    return "modifier_player_buffs_blood_pool"
end

function modifier_player_buffs_blood_pool:GetTexture() return "player_buffs/modifier_player_buffs_blood_pool" end
function modifier_player_buffs_blood_pool_emitter_aura:GetTexture() return "player_buffs/modifier_player_buffs_blood_pool" end
function modifier_player_buffs_blood_pool_emitter_aura_enemy:GetTexture() return "player_buffs/modifier_player_buffs_blood_pool" end
function modifier_player_buffs_blood_pool_shield:GetTexture() return "player_buffs/modifier_player_buffs_blood_pool" end
-------------
function modifier_player_buffs_blood_pool:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(12)
end

function modifier_player_buffs_blood_pool:OnIntervalThink()
    -- Create Placeholder Unit that holds the aura --
    local parent = self:GetParent()

    if not parent:IsAlive() then return end 

    EmitSoundOn("hero_bloodseeker.bloodRite", parent)

    local emitter = CreateUnitByName("outpost_placeholder_unit", parent:GetAbsOrigin(), false, parent, parent, parent:GetTeamNumber())
    emitter:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_blood_pool_emitter", { 
        duration = 6
    })
end
----------
function modifier_player_buffs_blood_pool_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_player_buffs_blood_pool_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_player_buffs_blood_pool_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = 600
    self.aura = "modifier_player_buffs_blood_pool_emitter_aura"

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_water_puddle_2.vpcf", PATTACH_POINT, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
end

function modifier_player_buffs_blood_pool_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_player_buffs_blood_pool_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_player_buffs_blood_pool_emitter:IsAura()
  return true
end

function modifier_player_buffs_blood_pool_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_player_buffs_blood_pool_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_player_buffs_blood_pool_emitter:GetAuraRadius()
  return self.radius
end

function modifier_player_buffs_blood_pool_emitter:GetModifierAura()
    return self.aura
end

function modifier_player_buffs_blood_pool_emitter:GetAuraEntityReject(ent) 
    if ent:GetTeam() ~= self:GetCaster():GetTeam() then
        self.aura = "modifier_player_buffs_blood_pool_emitter_aura_enemy"
    else
        self.aura = "modifier_player_buffs_blood_pool_emitter_aura"
    end

    return false
end
----------------------
function modifier_player_buffs_blood_pool_emitter_aura_enemy:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_player_buffs_blood_pool_emitter_aura_enemy:OnIntervalThink()
    local parent = self:GetParent()
    local damage = parent:GetHealth() * 0.05

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
end
----------------------
function modifier_player_buffs_blood_pool_emitter_aura:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_player_buffs_blood_pool_emitter_aura:OnIntervalThink()
    local parent = self:GetParent()
    local heal = parent:GetMaxHealth() * 0.05

    local healingAfter = parent:GetHealth() + heal
    local overheal = healingAfter - parent:GetMaxHealth()

    local maxShield = parent:GetMaxHealth()
    if overheal > maxShield then
        overheal = maxShield
    end

    local buff = parent:FindModifierByName("modifier_player_buffs_blood_pool_shield")
    if not buff then
        buff = parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_player_buffs_blood_pool_shield", {
            overhealPhysical = overheal,
        })
    end

    if buff then
        local shieldToAddPhysical = buff.overhealPhysical + overheal

        if shieldToAddPhysical > maxShield then
            shieldToAddPhysical = maxShield
        end

        if shieldToAddPhysical < 0 then
            shieldToAddPhysical = 0
        end

        buff.overhealPhysical = shieldToAddPhysical

        buff:ForceRefresh()
    end

    parent:Heal(heal, self:GetAbility())
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
end
---------------
function modifier_player_buffs_blood_pool_shield:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.overhealPhysical = params.overhealPhysical

    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()
end

function modifier_player_buffs_blood_pool_shield:OnRefresh()
    if not IsServer() then return end 

    self.shieldPhysical = self.overhealPhysical

    self:InvokeShield()
end

function modifier_player_buffs_blood_pool_shield:AddCustomTransmitterData()
    return
    {
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_player_buffs_blood_pool_shield:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_player_buffs_blood_pool_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_player_buffs_blood_pool_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
    }
end

function modifier_player_buffs_blood_pool_shield:GetModifierIncomingPhysicalDamageConstant(event)
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