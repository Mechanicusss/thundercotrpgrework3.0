LinkLuaModifier("modifier_spectre_spectral_nemesis_custom", "heroes/hero_spectre/spectre_spectral_nemesis_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_nemesis_custom_illusion", "heroes/hero_spectre/spectre_spectral_nemesis_custom", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassIllusion = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_spectral_nemesis_custom = class(ItemBaseClass)
modifier_spectre_spectral_nemesis_custom = class(ItemBaseClassBuff)
modifier_spectre_spectral_nemesis_custom_illusion = class(ItemBaseClassIllusion)
-------------
function spectre_spectral_nemesis_custom:GetIntrinsicModifierName()
    return "modifier_spectre_spectral_nemesis_custom"
end
-------------
function modifier_spectre_spectral_nemesis_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_spectre_spectral_nemesis_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local ability = self:GetAbility()

    self.hits = 0
    self:SetStackCount(0)
end

function modifier_spectre_spectral_nemesis_custom:SetHits(amount)
    self.hits = amount 
    self:SetStackCount(amount)
end

function modifier_spectre_spectral_nemesis_custom:CreateNemesis(target)
    local parent = self:GetParent()

    local modifierKeys = {
        outgoing_damage = 100,
        incoming_damage = 0,
        bounty_base = 0,
        outgoing_damage_structure = 100,
        outgoing_damage_roshan = 100
    }

    local illusions = CreateIllusions(parent, parent, modifierKeys, 1, 0, false, true)
    for _,illusion in ipairs(illusions) do
        --EmitSoundOn("Hero_Spectre.Haunt", target)

        illusion:AddNewModifier(parent, self:GetAbility(), "modifier_spectre_spectral_nemesis_custom_illusion", {
            target = target:GetEntityIndex(),
            duration = self:GetAbility():GetSpecialValueFor("illusion_duration")
        })

        illusion:AddNewModifier(illusion, nil, "modifier_movement_speed_uba", { speed = 2000 })
        illusion:AddNewModifier(illusion, nil, "modifier_max_movement_speed", {})
    end
end

function modifier_spectre_spectral_nemesis_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent ~= event.attacker then return end
    if parent:IsIllusion() or not parent:IsRealHero() or parent:HasModifier("modifier_spectre_reality_custom_illusion") or parent:HasModifier("modifier_spectre_spectral_nemesis_custom_illusion") then return end
    if not ability:IsActivated() then return end
    
    local maxHits = ability:GetSpecialValueFor("number_of_hits")
    local target = event.target

    if self.hits >= maxHits then
        self:PlayEffects(target)
        self:CreateNemesis(target)
        self:SetHits(0)

        EmitSoundOn("Hero_Spectre.HauntCast", parent)
    else
        self:SetHits(self.hits + 1)
    end
end

function modifier_spectre_spectral_nemesis_custom:PlayEffects(target)
    local particle_cast = "particles/units/heroes/hero_spectre/spectre_death.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------
function modifier_spectre_spectral_nemesis_custom_illusion:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_spectre_spectral_nemesis_custom_illusion:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

    local outgoing = self:GetAbility():GetSpecialValueFor("illusion_critical_damage") + (self:GetCaster():GetAgility() * (self:GetAbility():GetSpecialValueFor("illusion_critical_damage_bonus_per_agility")/100))
    
    if IsServer() then
        local caster = self:GetCaster()

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, event.target, event.original_damage*(outgoing/100), nil)
    end
    
    return outgoing
end

function modifier_spectre_spectral_nemesis_custom_illusion:OnCreated(params)
    if not IsServer() then return end

    local attacker = self:GetParent()
    local ability = self:GetAbility()

    local caster = self:GetCaster() --owner

    -- Tome stuff because this isn't added normally --
    local tome_Agility = caster:FindModifierByName("tome_consumed_agi")
    local tome_Strength = caster:FindModifierByName("tome_consumed_str")
    local tome_Intellect = caster:FindModifierByName("tome_consumed_int")

    if tome_Agility ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Agility:GetAbility(), tome_Agility:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Agility:GetStackCount())
        end
    end

    if tome_Strength ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Strength:GetAbility(), tome_Strength:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Strength:GetStackCount())
        end
    end

    if tome_Intellect ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Intellect:GetAbility(), tome_Intellect:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Intellect:GetStackCount())
        end
    end

    self.target = EntIndexToHScript(params.target)

    Timers:CreateTimer(0.1, function()
        if self.target == nil then return end

        local position = self.target:GetAbsOrigin() - 150 * self.target:GetForwardVector()

        FindClearSpaceForUnit(attacker, position, false)
        attacker:SetForceAttackTarget(self.target)
    end)

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_spectre_spectral_nemesis_custom_illusion:OnIntervalThink()
    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_spectre_spectral_nemesis_custom") then self:Destroy() return end

    local parent = self:GetParent()

    if self.target ~= nil and not self.target:IsAlive() then
        self:Destroy()
    end
end

function modifier_spectre_spectral_nemesis_custom_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end

function modifier_spectre_spectral_nemesis_custom_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_spectre_spectral_nemesis_custom_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spectre_spectral_nemesis_custom_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_spectre_spectral_nemesis_custom_illusion:StatusEffectPriority()
    return 10001
end

function modifier_spectre_spectral_nemesis_custom_illusion:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local vfx = ParticleManager:CreateParticle("particles/econ/items/spectre/spectre_arcana/spectre_arcana_illusion_killed_smoke_dark.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    if not parent:IsNull() then
        parent:ForceKill(false)
    end
end