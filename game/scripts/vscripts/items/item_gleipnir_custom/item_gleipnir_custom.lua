LinkLuaModifier("modifier_item_gleipnir_custom", "items/item_gleipnir_custom/item_gleipnir_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_gleipnir_custom = class(ItemBaseClass)
modifier_item_gleipnir_custom = class(item_gleipnir_custom)
-------------
function item_gleipnir_custom:GetIntrinsicModifierName()
    return "modifier_item_gleipnir_custom"
end

function modifier_item_gleipnir_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_item_gleipnir_custom:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_gleipnir_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_gleipnir_custom:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_gleipnir_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_gleipnir_custom:OnCreated()
    if not IsServer() then return end

    self.canProcLightning = true
end

function modifier_item_gleipnir_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local target = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:IsMuted() then
        return
    end

    local ability = self:GetAbility()

    self.ability = ability
    self.caster = caster
    self.jump_count = ability:GetSpecialValueFor("chain_strikes")
    self.jump_delay = ability:GetSpecialValueFor("chain_delay")
    self.chance = ability:GetSpecialValueFor("chain_chance")
    self.cooldown = ability:GetSpecialValueFor("chain_cooldown")
    self.damage = ((caster:GetBaseDamageMax() + caster:GetBaseDamageMin())/2) * (ability:GetSpecialValueFor("chain_damage_from_base_damage")/100)
    self.radius = ability:GetSpecialValueFor("chain_radius")

    if not RollPercentage(self.chance) or not self.canProcLightning then return end

    -- load data
    local radius = self.radius
    local bounces = self.jump_count

    -- find units in inital radius around target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        caster:GetAbsOrigin(),    -- point, center point
        nil,
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- change table form to (unit,bool)
    local targets_tbl = {}
    for _,unit in pairs(targets) do
        targets_tbl[unit] = false
    end

    -- recursive bounce
    self:CreateArcLightning(caster, target)
    self:bounce( caster, target, targets_tbl, radius, bounces )

    self.canProcLightning = false
    Timers:CreateTimer(self.cooldown, function()
        self.canProcLightning = true
    end)
end

function modifier_item_gleipnir_custom:bounce( caster, current, init_targets, radius, bounce )
    -- Do damage here! below
    ApplyDamage({
        victim = current, 
        attacker = caster, 
        damage = 100, 
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    })

    -- find next target in double radius, in case the current target is on the edge from first target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        current:GetOrigin(),    -- point, center point
        nil,
        radius,
        --radius*2,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- check bounce num
    bounce = bounce-1
    if bounce<=0 then return end

    local nexttgt = nil
    for i,unit in ipairs(targets) do
        -- not bounce unto itself
        -- check if the next target is within the initial radius of initial target
        if unit~=current and (init_targets[unit] == nil or init_targets[unit] == false) and self.caster:CanEntityBeSeenByMyTeam(unit) then
            nexttgt = unit
            break
        end
    end

    init_targets[current] = true

    if nexttgt then
        Timers:CreateTimer(self.jump_delay, function()
            if bounce<=0 then return end
            self:CreateArcLightning(current, nexttgt)
            self:bounce( caster, nexttgt, init_targets, radius, bounce )
        end)
    end
end

function modifier_item_gleipnir_custom:CreateArcLightning(caster, target)
    local particle_cast = "particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf"
    local sound_cast = "Hero_Zuus.ArcLightning.Target"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end