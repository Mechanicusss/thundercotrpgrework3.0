LinkLuaModifier("modifier_lina_sun_ray_custom", "heroes/hero_lina/lina_sun_ray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_sun_ray_custom_debuff", "heroes/hero_lina/lina_sun_ray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_sun_ray_custom_debuff_burning", "heroes/hero_lina/lina_sun_ray_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

lina_sun_ray_custom = class(ItemBaseClass)
modifier_lina_sun_ray_custom = class(lina_sun_ray_custom)
modifier_lina_sun_ray_custom_debuff = class(ItemBaseClassDebuff)
modifier_lina_sun_ray_custom_debuff_burning = class(ItemBaseClassDebuff)
-------------
function lina_sun_ray_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_lina_sun_ray_custom", {
        x = point.x,
        y = point.y,
        z = point.z
    })
end

function lina_sun_ray_custom:GetChannelTime()
    return 7
end

function lina_sun_ray_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_lina_sun_ray_custom")
end
-------------
function modifier_lina_sun_ray_custom:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local cursorPos = Vector(params.x, params.y, params.z)
    local width = ability:GetSpecialValueFor("radius")

    local attach_point = parent:ScriptLookupAttachment( "attach_head" )
    local tick_interval = ability:GetSpecialValueFor("tick_interval")

    local endpoint = parent:GetAbsOrigin() + (cursorPos - parent:GetAbsOrigin()):Normalized() * ability:GetSpecialValueFor("beam_range")
    endpoint.z = GetGroundHeight(endpoint, nil) + 92

    self.effect = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf", PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControl(self.effect, 0, parent:GetAttachmentOrigin(attach_point))
    ParticleManager:SetParticleControl(self.effect, 1, endpoint)
    ParticleManager:SetParticleControl(self.effect, 4, Vector(width, width, width))

    StartSoundEvent("Hero_Phoenix.SunRay.Beam", parent)
    StartSoundEvent("Hero_Phoenix.SunRay.Cast", parent)
    StartSoundEvent("Hero_Phoenix.SunRay.Loop", parent)

    self:StartIntervalThink(tick_interval)
end

function modifier_lina_sun_ray_custom:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, true)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    StopSoundEvent("Hero_Phoenix.SunRay.Beam", parent)
    StopSoundEvent("Hero_Phoenix.SunRay.Cast", parent)
    StopSoundEvent("Hero_Phoenix.SunRay.Loop", parent)

    EmitSoundOn("Hero_Phoenix.SunRay.Stop", parent)
end

function modifier_lina_sun_ray_custom:OnIntervalThink()
    local caster = self:GetCaster()
    local casterOrigin = caster:GetAbsOrigin()
    local casterForward = caster:GetForwardVector()
    local ability = self:GetAbility()
    local beamRange = ability:GetSpecialValueFor("beam_range")
    local tick_interval = ability:GetSpecialValueFor("tick_interval")

    local endcapPos = casterOrigin + casterForward * beamRange
    endcapPos = GetGroundPosition( endcapPos, nil )
    endcapPos.z = endcapPos.z + 92

    local units = FindUnitsInLine(caster:GetTeamNumber(),
        caster:GetAbsOrigin() + caster:GetForwardVector() * 32 ,
        endcapPos,
        nil,
        ability:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE)

    for _,unit in pairs(units) do
        local ray = unit:AddNewModifier(caster, ability, "modifier_lina_sun_ray_custom_debuff", {
            duration = ability:GetSpecialValueFor("tick_interval")
        })

        local burn = unit:FindModifierByName("modifier_lina_sun_ray_custom_debuff_burning")
        if not burn then
            burn = unit:AddNewModifier(caster, ability, "modifier_lina_sun_ray_custom_debuff_burning", {
                duration = ability:GetSpecialValueFor("burn_duration")
            })
        end

        if burn then
            burn:ForceRefresh()
        end
    end

    local numVision = math.ceil( beamRange / 300 )

    for i=1, numVision do
        AddFOWViewer(caster:GetTeamNumber(), ( casterOrigin + casterForward * ( 300 * 2 * (i-1) ) ), 300, tick_interval, false)
    end
end
-----------
function modifier_lina_sun_ray_custom_debuff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    ApplyDamage({
        attacker = caster,
        victim = parent,
        ability = ability,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL
    })
end
-----------
function modifier_lina_sun_ray_custom_debuff_burning:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.effect = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_sunray_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.effect, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect, 3, parent:GetAbsOrigin())

    local interval = ability:GetSpecialValueFor("burn_interval")
    self:StartIntervalThink(interval)
end

function modifier_lina_sun_ray_custom_debuff_burning:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local damage = (parent:GetHealth() * (ability:GetSpecialValueFor("burn_current_hp_pct")/100)) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    ApplyDamage({
        attacker = caster,
        victim = parent,
        ability = ability,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL
    })
end

function modifier_lina_sun_ray_custom_debuff_burning:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, true)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end
end