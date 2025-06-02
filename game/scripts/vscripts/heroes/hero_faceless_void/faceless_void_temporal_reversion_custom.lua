LinkLuaModifier("modifier_faceless_void_temporal_reversion_custom", "heroes/hero_faceless_void/faceless_void_temporal_reversion_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_temporal_reversion_custom_debuff", "heroes/hero_faceless_void/faceless_void_temporal_reversion_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

faceless_void_temporal_reversion_custom = class(ItemBaseClass)
modifier_faceless_void_temporal_reversion_custom = class(ItemBaseClassBuff)
modifier_faceless_void_temporal_reversion_custom_debuff = class(ItemBaseClassDebuff)
-------------
function faceless_void_temporal_reversion_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function faceless_void_temporal_reversion_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")

    if caster:HasModifier("modifier_faceless_void_temporal_reversion_custom") then
        caster:RemoveModifierByName("modifier_faceless_void_temporal_reversion_custom")
    end

    caster:AddNewModifier(caster, self, "modifier_faceless_void_temporal_reversion_custom", {
        duration = duration
    })
end
-------------
function modifier_faceless_void_temporal_reversion_custom:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_faceless_void_temporal_reversion_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local parent = self:GetParent()

    local duration = ability:GetSpecialValueFor("debuff_duration")

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() then break end

        enemy:AddNewModifier(parent, ability, "modifier_faceless_void_temporal_reversion_custom_debuff", {
            duration = duration
        })
    end

    self:PlayEffects(radius)

    -- Reduce CDs --
    for i=0, parent:GetAbilityCount()-1 do
        local abil = parent:GetAbilityByIndex(i)
        if abil ~= nil then
            local pass = true
            if bit.band(abil:GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_INVULNERABLE) ~= 0 or abil == ability then pass = false end

            if pass then
                local oldCd = abil:GetCooldownTimeRemaining()
                local newCd = oldCd - ability:GetSpecialValueFor("cooldown_reduction")

                if newCd > 0 and oldCd > 0 then
                    abil:EndCooldown()

                    abil:StartCooldown(newCd)
                end
            end
        end
    end

    for i=DOTA_ITEM_SLOT_1,DOTA_ITEM_SLOT_6 do
        local item = parent:GetItemInSlot(i)
        if item ~= nil then
            local pass = true
            if bit.band(item:GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_INVULNERABLE) ~= 0 then pass = false end

            if pass then
                local oldCd = item:GetCooldownTimeRemaining()
                local newCd = oldCd - ability:GetSpecialValueFor("cooldown_reduction")

                if newCd > 0 then
                    item:EndCooldown()

                    item:StartCooldown(newCd)
                end
            end
        end
    end
end

function modifier_faceless_void_temporal_reversion_custom:PlayEffects(radius)
    local target = self:GetParent()
    
    -- Get Resources
    local particle_cast = "particles/econ/items/faceless_void/faceless_void__2bracers_of_aeons/fv_bracers_of_aeons_timedialate.vpcf"
    local sound_cast = "Hero_FacelessVoid.TimeDilation.Cast.ti7"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_POINT_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
------------
function modifier_faceless_void_temporal_reversion_custom_debuff:GetEffectName()
    return "particles/econ/items/faceless_void/faceless_void_bracers_of_aeons/fv_bracers_of_aeons_dialatedebuf.vpcf"
end

function modifier_faceless_void_temporal_reversion_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_faceless_void_temporal_reversion_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_faceless_void_temporal_reversion_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("increased_damage_taken")
end