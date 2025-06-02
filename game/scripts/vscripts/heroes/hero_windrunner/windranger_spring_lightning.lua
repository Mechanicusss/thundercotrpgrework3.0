LinkLuaModifier("modifier_windranger_spring_lightning", "heroes/hero_windrunner/windranger_spring_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_spring_lightning_buff", "heroes/hero_windrunner/windranger_spring_lightning", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

windranger_spring_lightning = class(BaseClass)
modifier_windranger_spring_lightning = class(windranger_spring_lightning)
modifier_windranger_spring_lightning_buff = class(BaseClassBuff)

function windranger_spring_lightning:GetIntrinsicModifierName()
    return "modifier_windranger_spring_lightning"
end
----------
function modifier_windranger_spring_lightning:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_windranger_spring_lightning:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    self.caster = caster

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() then
        return
    end

    if event.attacker:IsIllusion() then return end

    self.ability = self:GetAbility()
    local chance = self.ability:GetSpecialValueFor("chance")

    if not self.ability:IsCooldownReady() then return end
    --if not RollPercentage(chance) then return end

    local multiplier = 0

    local buff = victim:FindModifierByName("modifier_windranger_spring_lightning_buff")
    if buff == nil then
        buff = victim:AddNewModifier(caster, self.ability, "modifier_windranger_spring_lightning_buff", {
            duration = self.ability:GetSpecialValueFor("buff_duration")
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < self.ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end
        
        buff:ForceRefresh()

        multiplier = buff:GetStackCount()
    end

    
    self.jump_count = self.ability:GetSpecialValueFor("jump_count")
    self.jump_delay = self.ability:GetSpecialValueFor("jump_delay")
    self.damage = (self.ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (self.ability:GetSpecialValueFor("int_to_damage")/100))) * (1+(multiplier * (self.ability:GetSpecialValueFor("buff_dmg_increase_pct")/100)))
    self.radius = self.ability:GetSpecialValueFor("radius")

    -- load data
    local radius = self.radius
    local bounces = self.jump_count

    -- find units in inital radius around target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        victim:GetAbsOrigin(),    -- point, center point
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

    self:CreateVFX(self.caster, victim)

    -- recursive bounce
    self:bounce( caster, victim, targets_tbl, radius, bounces )

    self.ability:UseResources(false, false, false, true)

    EmitSoundOn("Item.Maelstrom.Chain_Lightning", caster)
end

function modifier_windranger_spring_lightning:bounce( caster, current, init_targets, radius, bounce )
    ApplyDamage({
        victim = current, 
        attacker = caster, 
        damage = self.damage, 
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
            self:CreateVFX(current, nexttgt)
            self:bounce( caster, nexttgt, init_targets, radius, bounce )
        end)
    end
end

function modifier_windranger_spring_lightning:CreateVFX(caster, target)
    local particle_cast = "particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf"
    local sound_cast = "Item.Maelstrom.Chain_Lightning.Jump"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    --ParticleManager:SetParticleControl(effect_cast, 0, pos) -- Who it bounces to
    --ParticleManager:SetParticleControl(effect_cast, 1, originalPos) -- Where it bounces from

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
----
function modifier_windranger_spring_lightning_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end