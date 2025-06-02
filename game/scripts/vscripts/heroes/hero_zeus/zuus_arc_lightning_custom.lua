LinkLuaModifier("modifier_zuus_arc_lightning_custom", "heroes/hero_zeus/zuus_arc_lightning_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_arc_lightning_custom_slow_debuff", "heroes/hero_zeus/zuus_arc_lightning_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_arc_lightning_custom_magic_reduction_debuff", "heroes/hero_zeus/zuus_arc_lightning_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

zuus_arc_lightning_custom = class(ItemBaseClass)
modifier_zuus_arc_lightning_custom = class(zuus_arc_lightning_custom)
modifier_zuus_arc_lightning_custom_slow_debuff = class(ItemBaseClassDebuff)
modifier_zuus_arc_lightning_custom_magic_reduction_debuff = class(ItemBaseClassDebuff)
-------------
function zuus_arc_lightning_custom:GetIntrinsicModifierName()
    return "modifier_zuus_arc_lightning_custom"
end

function zuus_arc_lightning_custom:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    self.ability = self
    self.caster = caster
    self.magicReductionDuration = self:GetSpecialValueFor("static_field_magic_reduction_duration")
    self.jump_count = self:GetSpecialValueFor("jump_count")
    self.jump_delay = self:GetSpecialValueFor("jump_delay")
    self.damage = self:GetSpecialValueFor("arc_damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))
    self.radius = self:GetSpecialValueFor("radius")
    self.hasShard = caster:HasModifier("modifier_item_aghanims_shard")
    self.lightningBoltDamage = self:GetSpecialValueFor("lightning_bolt_damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))
    self.lightningBoltStun = self:GetSpecialValueFor("lightning_bolt_stun")

    if self.caster:HasModifier("modifier_zuus_transcendence_custom_transport") then
        self:EndCooldown()
        return
    end

    self:CreateArcLightning(caster, target)

    EmitSoundOn("Hero_Zuus.ArcLightning.Cast", caster)

    -- cancel if Linken
    if target:TriggerSpellAbsorb( self ) then
        return
    end

    -- load data
    local radius = self.radius
    local bounces = self.jump_count

    -- find units in inital radius around target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        target:GetAbsOrigin(),    -- point, center point
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
    self:bounce( caster, target, targets_tbl, radius, bounces )
end

function zuus_arc_lightning_custom:bounce( caster, current, init_targets, radius, bounce )
    EmitSoundOn("Hero_Zuus.ArcLightning.Cast", current)

    ApplyDamage({
        victim = current, 
        attacker = caster, 
        damage = self.damage, 
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    })

    if self.hasShard then
        self:CreateLightningBolt(current, current:GetAbsOrigin())

        ApplyDamage({
            victim = current, 
            attacker = caster, 
            damage = self.lightningBoltDamage, 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self.ability
        })
        current:AddNewModifier(caster, nil, "modifier_stunned", {
            duration = self.lightningBoltStun
        })
    end

    -- Supercharge --
    self.superchargeStacks = self.caster:FindModifierByName("modifier_zuus_static_field_custom_stacks")
    if self.superchargeStacks ~= nil then
        local superchargesNeeded = self.ability:GetSpecialValueFor("static_field_charges")
        if self.superchargeStacks:GetAbility():GetToggleState() and superchargesNeeded <= self.superchargeStacks:GetStackCount() then
            current:AddNewModifier(self.caster, self.ability, "modifier_zuus_arc_lightning_custom_magic_reduction_debuff", {
                duration = self.magicReductionDuration
            })

            self.superchargeStacks:SetStackCount(self.superchargeStacks:GetStackCount()-superchargesNeeded)
        end
    end
    --

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

function zuus_arc_lightning_custom:CreateArcLightning(caster, target)
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf"
    local sound_cast = "Hero_Zuus.ArcLightning.Target"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:ReleaseParticleIndex(effect_cast)

    --ParticleManager:SetParticleControl(effect_cast, 0, pos) -- Who it bounces to
    --ParticleManager:SetParticleControl(effect_cast, 1, originalPos) -- Where it bounces from

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function zuus_arc_lightning_custom:CreateLightningBolt(target, pos)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt"

    -- Create Particle
    local effect = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, target)

    ParticleManager:SetParticleControl(effect, 0, Vector(pos.x, pos.y, pos.z))
    ParticleManager:SetParticleControl(effect, 1, Vector(pos.x, pos.y, 2000))
    ParticleManager:SetParticleControl(effect, 2, Vector(pos.x, pos.y, pos.z))

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

----
function modifier_zuus_arc_lightning_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }

    return funcs
end

function modifier_zuus_arc_lightning_custom:OnAttack(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local ability = self:GetAbility()

    if not ability:GetAutoCastState() then return end
    if event.attacker:IsSilenced() or not ability:IsCooldownReady() or ability:GetManaCost(-1) > event.attacker:GetMana() then return end
    if not IsCreepTCOTRPG(event.target) and not IsBossTCOTRPG(event.target) then return end

    SpellCaster:Cast(ability, event.target, true)
end
----------
function modifier_zuus_arc_lightning_custom_magic_reduction_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_zuus_arc_lightning_custom_magic_reduction_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("static_field_magic_reduction")
end