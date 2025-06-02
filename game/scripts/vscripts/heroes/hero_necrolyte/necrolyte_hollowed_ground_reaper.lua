LinkLuaModifier("modifier_necrolyte_hollowed_ground_reaper", "heroes/hero_necrolyte/necrolyte_hollowed_ground_reaper", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_hollowed_ground_reaper_emitter", "heroes/hero_necrolyte/necrolyte_hollowed_ground_reaper", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_hollowed_ground_reaper_emitter_aura", "heroes/hero_necrolyte/necrolyte_hollowed_ground_reaper", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

necrolyte_hollowed_ground_reaper = class(ItemBaseClass)
modifier_necrolyte_hollowed_ground_reaper = class(necrolyte_hollowed_ground_reaper)
modifier_necrolyte_hollowed_ground_reaper_emitter = class(ItemBaseClass)
modifier_necrolyte_hollowed_ground_reaper_emitter_aura = class(ItemBaseAura)
-------------
function necrolyte_hollowed_ground_reaper:GetIntrinsicModifierName()
    return "modifier_necrolyte_hollowed_ground_reaper"
end

function necrolyte_hollowed_ground_reaper:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function necrolyte_hollowed_ground_reaper:OnSpellStart()
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


    if charges:GetStackCount() >= cost then
        charges:SetStackCount(charges:GetStackCount()-cost)
    end
    --]]

    local pos = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local ability = self

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", pos, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNoDraw()
    emitter:AddNewModifier(caster, ability, "modifier_necrolyte_hollowed_ground_reaper_emitter", { duration = duration })
    -- --

    Timers:CreateTimer(duration, function()
        UTIL_RemoveImmediate(emitter)
    end)
end

function modifier_necrolyte_hollowed_ground_reaper:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
    self:OnIntervalThink()
end

function modifier_necrolyte_hollowed_ground_reaper:OnIntervalThink()
    local caster = self:GetParent()
    local ability = self:GetAbility()

    if caster:GetMana() < ability:GetManaCost(-1) or caster:IsSilenced() or not ability:GetAutoCastState() or not ability:IsCooldownReady() then return end

    SpellCaster:Cast(ability, nil, true)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local pos = parent:GetAbsOrigin()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    -- Particle --
    self.vfx = ParticleManager:CreateParticle("particles/econ/items/necrolyte/necro_ti9_immortal/necro_ti9_immortal_shroud.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(self.vfx, 0, pos)
    -- --

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:OnRemoved(params)
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.vfx, true)
    ParticleManager:ReleaseParticleIndex(self.vfx)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability or ability == nil then
        UTIL_RemoveImmediate(parent)
        return
    end

    local damageDistance = ability:GetSpecialValueFor("min_damage_distance")

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            local distance = (parent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
            local damage = self.damage + (caster:GetBaseIntellect() * (self.intToDamage/100))

            if distance <= damageDistance then
                damage = damage * (1 + (ability:GetSpecialValueFor("center_damage_multi")/100))
            end

            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = damage * self.interval,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })
        end
    end
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:CheckState()
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
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:IsAura()
  return true
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:GetAuraRadius()
  return self.radius
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:GetModifierAura()
    return "modifier_necrolyte_hollowed_ground_reaper_emitter_aura"
end

function modifier_necrolyte_hollowed_ground_reaper_emitter:GetAuraEntityReject(ent) 
    return false
end
--------------
function modifier_necrolyte_hollowed_ground_reaper_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_necrolyte_hollowed_ground_reaper_emitter_aura:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self:PlayEffects(parent)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter_aura:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)
end

function modifier_necrolyte_hollowed_ground_reaper_emitter_aura:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_necrolyte/necrolyte_spirit_debuff.vpcf"

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
end

function modifier_necrolyte_hollowed_ground_reaper_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    if not self:GetAbility() or self:GetAbility() == nil then return end
    
    return self:GetAbility():GetSpecialValueFor("slow")
end