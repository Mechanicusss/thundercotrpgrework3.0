LinkLuaModifier("modifier_fenrir_avalanche", "heroes/hero_fenrir/fenrir_avalanche", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fenrir_avalanche_overheal", "heroes/hero_fenrir/fenrir_avalanche", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

fenrir_avalanche = class(ItemBaseClass)
modifier_fenrir_avalanche = class(fenrir_avalanche)
modifier_fenrir_avalanche_overheal = class(ItemBaseClass)
-------------
function fenrir_avalanche:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = self:GetChannelTime()

    caster:AddNewModifier(caster, self, "modifier_fenrir_avalanche", {
        duration = duration
    })

    EmitSoundOn("hero_Crystal.freezingField.wind", caster)
    EmitSoundOn("Hero_Crystal_Persona.Ult_Howl", caster)
end

function fenrir_avalanche:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function fenrir_avalanche:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_fenrir_avalanche")

    caster:FadeGesture(ACT_DOTA_CHANNEL_ABILITY_4)
end
------------
function modifier_fenrir_avalanche:CheckState()
    if not self:GetCaster():HasScepter() then return end
    return {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }
end

function modifier_fenrir_avalanche:GetEffectName()
    if not self:GetCaster():HasScepter() then return end
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_fenrir_avalanche:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    
    self.ability = self:GetAbility()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden_persona/cm_persona_freezing_field_cliff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.particle,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    local interval = self.ability:GetSpecialValueFor("interval")

    self.radius = self.ability:GetSpecialValueFor("radius")
    self.speed = self.ability:GetSpecialValueFor("knockback_speed")
    self.heal = parent:GetMaxHealth() * (self.ability:GetSpecialValueFor("max_hp_heal")/100)

    self:StartIntervalThink(interval)
end

function modifier_fenrir_avalanche:OnIntervalThink()
    local parent = self:GetParent()

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        if victim:GetTeamNumber() ~= parent:GetTeamNumber() then
            local vector = (victim:GetOrigin()-parent:GetOrigin())
            local dist = vector:Length2D()
            vector.z = 0
            vector = vector:Normalized()

            local knockback = victim:AddNewModifier(
                self:GetCaster(), -- player source
                self.ability, -- ability source
                "modifier_generic_knockback_lua", -- modifier name
                {
                    direction_x = vector.x,
                    direction_y = vector.y,
                    distance = self.radius/2,
                    duration = self.radius/self.speed,
                    IsStun = true,
                    IsFlail = false,
                } -- kv
            )
        else
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, victim, self.heal, nil)

            local healingAfter = victim:GetHealth() + self.heal
            local overheal = healingAfter - victim:GetMaxHealth()

            local maxShield = parent:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("shield_max_from_hp")/100)
            if overheal > maxShield then
                overheal = maxShield
            end

            local buff = victim:FindModifierByName("modifier_fenrir_avalanche_overheal")
            if not buff then
                buff = victim:AddNewModifier(victim, self:GetAbility(), "modifier_fenrir_avalanche_overheal", {
                    overhealPhysical = overheal,
                    overhealMagic = overheal,
                    duration = self:GetAbility():GetSpecialValueFor("overheal_duration")
                })
            end

            if buff then
                local shieldToAddPhysical = buff.overhealPhysical + overheal
                local shieldToAddMagical = buff.overhealMagic + overheal

                if shieldToAddPhysical > maxShield then
                    shieldToAddPhysical = maxShield
                end

                if shieldToAddMagical > maxShield then
                    shieldToAddMagical = maxShield
                end

                if shieldToAddPhysical < 0 then
                    shieldToAddPhysical = 0
                end

                if shieldToAddMagical < 0 then
                    shieldToAddMagical = 0
                end

                buff.overhealPhysical = shieldToAddMagical
                buff.overhealMagic = shieldToAddMagical

                buff:ForceRefresh()
            end

            victim:Heal(self.heal, self.ability)
        end
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden_persona/cm_persona_nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        particle,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("Hero_Crystal.CrystalNova", parent)
end

function modifier_fenrir_avalanche:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end

    StopSoundOn("hero_Crystal.freezingField.wind", parent)
    StopSoundOn("Hero_Crystal_Persona.Ult_Howl", parent)
end
---------------
function modifier_fenrir_avalanche_overheal:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("shield_damage_reduction")

    self.overhealMagic = params.overhealMagic
    self.overhealPhysical = params.overhealPhysical

    self.shieldMagic = self.overhealMagic
    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()
end

function modifier_fenrir_avalanche_overheal:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_fenrir_avalanche_overheal:OnRefresh()
    if not IsServer() then return end 

    self.shieldMagic = self.overhealMagic
    self.shieldPhysical = self.overhealPhysical

    self:InvokeShield()
end

function modifier_fenrir_avalanche_overheal:AddCustomTransmitterData()
    return
    {
        shieldMagic = self.fShieldMagic,
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_fenrir_avalanche_overheal:HandleCustomTransmitterData(data)
    if data.shieldMagic ~= nil and data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
        self.fShieldMagic = tonumber(data.shieldMagic)
    end
end

function modifier_fenrir_avalanche_overheal:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical
        self.fShieldMagic = self.shieldMagic

        self:SendBuffRefreshToClients()
    end
end

function modifier_fenrir_avalanche_overheal:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT 
    }
end

function modifier_fenrir_avalanche_overheal:GetModifierIncomingPhysicalDamageConstant(event)
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

function modifier_fenrir_avalanche_overheal:GetModifierIncomingSpellDamageConstant(event)
    if not IsServer() then
        return self.fShieldMagic
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.overhealMagic <= 0 then return end

    local block = 0
    local negated = self.overhealMagic - event.damage 

    if negated <= 0 then
        block = self.overhealMagic
    else
        block = event.damage
    end

    self.overhealMagic = negated

    if self.overhealMagic <= 0 then
        self.overhealMagic = 0
        self.shieldMagic = 0
    else
        self.shieldMagic = self.overhealMagic
    end

    self:InvokeShield()

    return -block
end