LinkLuaModifier("modifier_spectre_spectral_dagger_custom", "heroes/hero_spectre/spectre_spectral_dagger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_dagger_custom_debuff", "heroes/hero_spectre/spectre_spectral_dagger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_dagger_custom_illusion", "heroes/hero_spectre/spectre_spectral_dagger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_reality_custom_buff", "heroes/hero_spectre/spectre_reality_custom", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_spectre_spectral_strike_custom_crit", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassIllusion = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_spectral_dagger_custom = class(ItemBaseClass)
modifier_spectre_spectral_dagger_custom = class(spectre_spectral_dagger_custom)
modifier_spectre_spectral_dagger_custom_debuff = class(ItemBaseClassDebuff)
modifier_spectre_spectral_dagger_custom_illusion = class(ItemBaseClassIllusion)
-------------
function spectre_spectral_dagger_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function spectre_spectral_dagger_custom:CreateSingleDagger(target)
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Spectre.DaggerCast", caster)

    local proj = {
        Target = target,
        vSourceLoc = caster:GetAbsOrigin(),
        iMoveSpeed = 800,
        bIgnoreObstructions = true,
        bVisibleToEnemies = true,
        EffectName = "particles/units/heroes/hero_spectre/spectre_spectral_dagger_tracking.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = 200,
        iVisionTeamNumber = caster:GetTeam()
    }

    ProjectileManager:CreateTrackingProjectile(proj)
end

function spectre_spectral_dagger_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local radius = self:GetSpecialValueFor("radius")
    local daggers = self:GetSpecialValueFor("max_daggers")

    local count = 0

    EmitSoundOn("Hero_Spectre.DaggerCast", caster)

    local proj = {
        vSourceLoc = caster:GetAbsOrigin(),
        iMoveSpeed = 800,
        bIgnoreObstructions = true,
        bVisibleToEnemies = true,
        EffectName = "particles/units/heroes/hero_spectre/spectre_spectral_dagger_tracking.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = 200,
        iVisionTeamNumber = caster:GetTeam()
    }

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or not victim:CanEntityBeSeenByMyTeam(caster) or count >= daggers then break end

        proj.Target = victim

        ProjectileManager:CreateTrackingProjectile(proj)

        count = count + 1
    end
end

function spectre_spectral_dagger_custom:OnProjectileHit(target, location)
    local caster = self:GetCaster()

    target:AddNewModifier(caster, self, "modifier_spectre_spectral_dagger_custom_debuff", {
        duration = self:GetSpecialValueFor("duration")
    })

    self:CreateNemesis(target)

    ApplyDamage({
        attacker = caster,
        victim = target,
        damage = caster:GetAverageTrueAttackDamage(caster) * (self:GetSpecialValueFor("damage_from_attack")/100),
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self
    })

    EmitSoundOn("Hero_Spectre.DaggerImpact", target)
    EmitSoundOn("Hero_Spectre.HauntCast", caster)
end

function spectre_spectral_dagger_custom:CreateNemesis(target)
    local parent = self:GetCaster()

    -- Used in the spectral dagger talent to detect whether she has used the ability or not
    parent:AddNewModifier(parent, self, "modifier_spectre_spectral_dagger_custom", {
        duration = self:GetSpecialValueFor("illusion_duration")
    })

    local modifierKeys = {
        outgoing_damage = self:GetSpecialValueFor("illusion_outgoing"),
        incoming_damage = self:GetSpecialValueFor("illusion_incoming"),
        bounty_base = 0,
        outgoing_damage_structure = self:GetSpecialValueFor("illusion_outgoing"),
        outgoing_damage_roshan = self:GetSpecialValueFor("illusion_outgoing")
    }

    local illusions = CreateIllusions(parent, parent, modifierKeys, 1, 0, false, true)
    for _,illusion in ipairs(illusions) do
        EmitSoundOn("Hero_Spectre.Haunt", target)

        illusion:AddNewModifier(parent, self, "modifier_spectre_spectral_dagger_custom_illusion", {
            target = target:GetEntityIndex(),
            duration = self:GetSpecialValueFor("illusion_duration")
        })

        illusion:AddNewModifier(illusion, nil, "modifier_movement_speed_uba", { speed = 2000 })
        illusion:AddNewModifier(illusion, nil, "modifier_max_movement_speed", {})
    end
end

----------------
function modifier_spectre_spectral_dagger_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_spectre_spectral_dagger_custom_debuff:GetEffectName()
    return "particles/econ/items/spectre/spectre_transversant_soul/spectre_transversant_spectral_dagger_path_owner_2.vpcf"
end

function modifier_spectre_spectral_dagger_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
-------------
function modifier_spectre_spectral_dagger_custom_illusion:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE 
    }
end

function modifier_spectre_spectral_dagger_custom_illusion:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_spectre_spectral_dagger_custom_illusion:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_spectre_spectral_dagger_custom_illusion:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_spectre_spectral_dagger_custom_illusion:OnAbilityFullyCast(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if not event.target then return end
    if event.ability:GetAbilityName() ~= "spectre_reality_custom" then return end
    if event.target ~= parent then return end

    self:Destroy()
end

function modifier_spectre_spectral_dagger_custom_illusion:OnCreated(params)
    if not IsServer() then return end

    local attacker = self:GetParent()
    local ability = self:GetAbility()

    local caster = self:GetCaster() --owner

    local talent = caster:FindAbilityByName("talent_spectre_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        local spectralStrike = caster:FindAbilityByName("spectre_spectral_strike_custom")
        if spectralStrike ~= nil and spectralStrike:GetLevel() > 0 then
            attacker:AddNewModifier(caster, spectralStrike, "modifier_spectre_spectral_strike_custom_crit", {})
        end

        -- Talent stuff 
        if talent:GetLevel() > 2 then
            local talentBuff = caster:FindModifierByName("modifier_spectre_reality_custom_buff")
            if not talentBuff then
                talentBuff = caster:AddNewModifier(caster, talent, "modifier_spectre_reality_custom_buff", {
                    duration = talent:GetSpecialValueFor("damage_buff_duration"),
                })
            end

            if talentBuff then
                talentBuff:IncrementStackCount()
            end
        end
    end

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

function modifier_spectre_spectral_dagger_custom_illusion:OnIntervalThink()
    local caster = self:GetCaster()

    if not caster:FindAbilityByName("spectre_spectral_dagger_custom") then self:Destroy() return end

    local parent = self:GetParent()

    --- Repeat for illusion tbh 
    local talent = caster:FindAbilityByName("talent_spectre_1")
    if talent ~= nil and talent:GetLevel() > 2 then
        local casterStacks = caster:FindModifierByName("modifier_spectre_reality_custom_buff")
        if casterStacks ~= nil then
            local talentBuffNemesis = parent:FindModifierByName("modifier_spectre_reality_custom_buff")
            if not talentBuffNemesis then
                talentBuffNemesis = parent:AddNewModifier(parent, talent, "modifier_spectre_reality_custom_buff", {
                    duration = talent:GetSpecialValueFor("damage_buff_duration"),
                })
            end

            if talentBuffNemesis and talentBuffNemesis:GetStackCount() ~= casterStacks:GetStackCount() then
                talentBuffNemesis:SetStackCount(casterStacks:GetStackCount())
            end
        end
    end

    if self.target ~= nil and not self.target:IsAlive() then
        self:Destroy()
    end
end

function modifier_spectre_spectral_dagger_custom_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        --[MODIFIER_STATE_UNSELECTABLE] = true,
        --[MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end

function modifier_spectre_spectral_dagger_custom_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_spectre_spectral_dagger_custom_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_spectre_spectral_dagger_custom_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_spectre_spectral_dagger_custom_illusion:StatusEffectPriority()
    return 10001
end

function modifier_spectre_spectral_dagger_custom_illusion:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent:IsNull() then
        parent:ForceKill(false)
    end

    parent:RemoveModifierByName("modifier_spectre_spectral_dagger_custom")
end