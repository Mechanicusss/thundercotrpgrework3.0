LinkLuaModifier("modifier_necrolyte_reaper_form", "heroes/hero_necrolyte/necrolyte_reaper_form", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_reaper_form_buff", "heroes/hero_necrolyte/necrolyte_reaper_form", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ReaperFormClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

necrolyte_reaper_form = class(ItemBaseClass)
necrolyte_reaper_form_exit = class(ItemBaseClass)
modifier_necrolyte_reaper_form = class(necrolyte_reaper_form)
modifier_necrolyte_reaper_form_buff = class(ReaperFormClass)
-------------
function necrolyte_reaper_form_exit:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByNameAndCaster("modifier_necrolyte_reaper_form_buff", caster)
end
-------------
function necrolyte_reaper_form:GetIntrinsicModifierName()
    return "modifier_necrolyte_reaper_form"
end

function necrolyte_reaper_form:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function necrolyte_reaper_form:GetCooldown(level)
    if self:GetCaster():HasTalent("special_bonus_unique_necrolyte_1_custom") then
        return self.BaseClass.GetCooldown(self, level) - self:GetCaster():FindAbilityByName("special_bonus_unique_necrolyte_1_custom"):GetSpecialValueFor("value")
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function necrolyte_reaper_form:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    --[[
    local cost = self:GetSpecialValueFor("required_charges")
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges == nil or charges:GetStackCount() < cost then
        DisplayError(caster:GetPlayerID(), "#necrolyte_not_enough_corpse_charges")
        self:EndCooldown()
        return
    end
    --]]

    local ability = self
    
    caster:FadeGesture(ACT_DOTA_NECRO_GHOST_SHROUD)

    caster:AddNewModifier(caster, ability, "modifier_necrolyte_reaper_form_buff", {})

    --[[local exit = caster:AddAbility("necrolyte_reaper_form_exit")

    exit:SetLevel(1)
    exit:SetHidden(false)
    exit:StartCooldown(3)
    exit:SetActivated(true)
    exit:SetHidden(false)

    caster:SwapAbilities(
        "necrolyte_reaper_form_exit",
        "necrolyte_reaper_form",
        true,
        false
    )

    ability:SetActivated(false)
    ability:SetHidden(true)
    --]]

    caster:SetHealth(caster:GetMaxHealth())
end

function modifier_necrolyte_reaper_form:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_necrolyte_reaper_form:OnIntervalThink()
    local caster = self:GetParent()
    local aghs = caster:FindAbilityByName("necrolyte_aesthetics_death")

    if aghs == nil then return end

    if caster:HasScepter() and aghs:IsHidden() and caster:HasModifier("modifier_necrolyte_reaper_form_buff") then
        aghs:SetHidden(false)
        aghs:SetLevel(1)
    end

    if not caster:HasScepter() or not caster:HasModifier("modifier_necrolyte_reaper_form_buff") then
        aghs:SetHidden(true)
        aghs:SetLevel(0)
    end
end
------------
function modifier_necrolyte_reaper_form_buff:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_MODEL_SCALE,
         MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
         MODIFIER_PROPERTY_DISABLE_HEALING,
         MODIFIER_PROPERTY_MIN_HEALTH 
    }

    return funcs
end

function modifier_necrolyte_reaper_form_buff:GetMinHealth()
    return 1
end

function modifier_necrolyte_reaper_form_buff:GetDisableHealing()
    return 1
end

function modifier_necrolyte_reaper_form_buff:GetModifierModelScale()
    return 30
end

function modifier_necrolyte_reaper_form_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed")
end

function modifier_necrolyte_reaper_form_buff:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")

    self.effect = nil

    self.oldRenderColor = parent:GetRenderColor()

    self.increasedDrain = 0

    parent:SetRenderColor(104, 250, 226)

    self:PlayEffects(parent)

    self:StartIntervalThink(0.1)
    self:OnIntervalThink()

    Timers:CreateTimer(1.0, function()
        if not parent:HasModifier("modifier_necrolyte_reaper_form_buff") then
            self.increasedDrain = 0
            return
        end

        self.increasedDrain = self.increasedDrain + ability:GetSpecialValueFor("hp_drain_increase")
        return 1.0
    end)

    -- Abilities --
    --== Coil ==--
    local deathCoil = parent:FindAbilityByName("necrolyte_death_coil")

    if deathCoil ~= nil then
        local deathCoil_Reaper = parent:AddAbility("necrolyte_death_coil_reaper")

        local autoCast = deathCoil:GetAutoCastState()
        if autoCast then
            deathCoil:ToggleAutoCast()
        end

        parent:SwapAbilities(
            "necrolyte_death_coil",
            "necrolyte_death_coil_reaper",
            false,
            true
        )

        deathCoil_Reaper:SetLevel(deathCoil:GetLevel())
        if autoCast then
            deathCoil_Reaper:ToggleAutoCast()
        end

        deathCoil:SetActivated(false)
        deathCoil:SetHidden(true)
    end

    --== Aura ==--
    local deathAura = parent:FindAbilityByName("necrolyte_death_aura")
    
    if deathAura ~= nil then
        local deathAura_Reaper = parent:AddAbility("necrolyte_death_aura_reaper")

        parent:SwapAbilities(
            "necrolyte_death_aura",
            "necrolyte_death_aura_reaper",
            false,
            true
        )

        deathAura_Reaper:SetLevel(deathAura:GetLevel())

        deathAura:SetActivated(false)
        deathAura:SetHidden(true)

        parent:RemoveModifierByNameAndCaster("modifier_necrolyte_death_aura_emitter", parent)
    end

    --== Hollowed Ground ==--
    local hollowedGround = parent:FindAbilityByName("necrolyte_hollowed_ground")

    if hollowedGround ~= nil then
        local hollowedGround_Reaper = parent:AddAbility("necrolyte_hollowed_ground_reaper")

        parent:SwapAbilities(
            "necrolyte_hollowed_ground",
            "necrolyte_hollowed_ground_reaper",
            false,
            true
        )

        hollowedGround_Reaper:SetLevel(hollowedGround:GetLevel())

        hollowedGround:SetActivated(false)
        hollowedGround:SetHidden(true)
    end
end

function modifier_necrolyte_reaper_form_buff:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self.ability

    local drain = ability:GetSpecialValueFor("hp_drain_pct")

    if parent:HasTalent("special_bonus_unique_necrolyte_2_custom") then
        drain = drain + parent:FindAbilityByName("special_bonus_unique_necrolyte_2_custom"):GetSpecialValueFor("value")
    end

    local damage = parent:GetMaxHealth() * ((drain+self.increasedDrain)/100) * 0.1
    local damageTaken = parent:GetHealth() - damage

    if parent:GetHealth() <= 1 or damageTaken <= 1 then
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    else
        parent:SetHealth(damageTaken)
    end
    
    --[[
    ApplyDamage({
        victim = parent,
        attacker = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION  + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
    })
    --]]
end

function modifier_necrolyte_reaper_form_buff:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    --[[
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges ~= nil then
        charges:SetStackCount(0)
    end
    --]]

    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)
    ParticleManager:DestroyParticle(self.effect2, true)
    ParticleManager:ReleaseParticleIndex(self.effect2)

    --[[caster:SwapAbilities(
        "necrolyte_reaper_form_exit",
        "necrolyte_reaper_form",
        false,
        true
    )--]]

    local reaperFormExit = caster:FindAbilityByName("necrolyte_reaper_form_exit")
    if reaperFormExit ~= nil then
        caster:RemoveAbilityByHandle(reaperFormExit)
    end

    local reaperForm = caster:FindAbilityByName("necrolyte_reaper_form")
    if reaperForm ~= nil then
        reaperForm:SetActivated(true)
        reaperForm:SetHidden(false)
    end

    -- Abilities --
    --== Coil ==--
    local deathCoil = caster:FindAbilityByName("necrolyte_death_coil")
    local deathCoil_Reaper = caster:FindAbilityByName("necrolyte_death_coil_reaper")

    if deathCoil ~= nil then
        deathCoil:SetActivated(true)
        deathCoil:SetHidden(false)

        if autoCast then
            deathCoil:ToggleAutoCast()
        end
    end

    if deathCoil_Reaper ~= nil then
        local autoCast = deathCoil_Reaper:GetAutoCastState()
        if autoCast then
            deathCoil_Reaper:ToggleAutoCast()
        end

        caster:SwapAbilities(
            "necrolyte_death_coil",
            "necrolyte_death_coil_reaper",
            true,
            false
        )

        caster:RemoveAbilityByHandle(deathCoil_Reaper)
    end

    --== Aura ==--
    local deathAura = caster:FindAbilityByName("necrolyte_death_aura")
    local deathAura_Reaper = caster:FindAbilityByName("necrolyte_death_aura_reaper")

    if deathAura ~= nil then
        deathAura:SetActivated(true)
        deathAura:SetHidden(false)
    end

    if deathAura_Reaper ~= nil then
        caster:SwapAbilities(
            "necrolyte_death_aura",
            "necrolyte_death_aura_reaper",
            true,
            false
        )

        caster:RemoveModifierByNameAndCaster("modifier_necrolyte_death_aura_reaper_emitter", caster)
        caster:RemoveAbilityByHandle(deathAura_Reaper)
    end

    --== Hollowed Ground ==--
    local hollowedGround = caster:FindAbilityByName("necrolyte_hollowed_ground")
    local hollowedGround_Reaper = caster:FindAbilityByName("necrolyte_hollowed_ground_reaper")

    if hollowedGround ~= nil then
        hollowedGround:SetActivated(true)
        hollowedGround:SetHidden(false)
    end

    if hollowedGround_Reaper ~= nil then
        caster:SwapAbilities(
            "necrolyte_hollowed_ground",
            "necrolyte_hollowed_ground_reaper",
            true,
            false
        )

        caster:RemoveAbilityByHandle(hollowedGround_Reaper)
    end

    -- Reset the cooldown to it's max value, otherwise it'll keep ticking down while the ability is in use,
    -- causing the cooldown to be very low when it ends.
    self.ability:UseResources(true, false, false, true)
end

function modifier_necrolyte_reaper_form_buff:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:SetHealth(parent:GetMaxHealth() * (ability:GetSpecialValueFor("duration_end_hp_restored_pct")/100))
end

function modifier_necrolyte_reaper_form_buff:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/reaper/necrolyte_spirit.vpcf"
    local sound_cast = "Hero_Necrolyte.SpiritForm.Cast"

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect, 0, target:GetOrigin() )

    -- Create Sound
    EmitSoundOn( sound_cast, target )

    self:PlayEffects2(target)
end

function modifier_necrolyte_reaper_form_buff:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/reaper/ghosts/wraith_king_ghosts_ambient.vpcf"

    -- Create Particle
    self.effect2 = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect2,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect2, 0, target:GetOrigin() )
end