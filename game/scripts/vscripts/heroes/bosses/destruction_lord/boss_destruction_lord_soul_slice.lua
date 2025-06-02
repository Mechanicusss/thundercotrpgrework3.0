LinkLuaModifier("modifier_boss_destruction_lord_soul_slice", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_slice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_destruction_lord_soul_slice_debuff", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_slice", LUA_MODIFIER_MOTION_NONE)

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

boss_destruction_lord_soul_slice = class(ItemBaseClass)
modifier_boss_destruction_lord_soul_slice = class(boss_destruction_lord_soul_slice)
modifier_boss_destruction_lord_soul_slice_debuff = class(ItemBaseClassDebuff)
-------------
function boss_destruction_lord_soul_slice:GetIntrinsicModifierName()
    return "modifier_boss_destruction_lord_soul_slice"
end

function modifier_boss_destruction_lord_soul_slice:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_boss_destruction_lord_soul_slice:OnCreated()
    self.parent = self:GetParent()
end

function modifier_boss_destruction_lord_soul_slice:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if event.attacker ~= parent then
        return
    end  

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local damage = ability:GetLevelSpecialValueFor("edge_damage", (ability:GetLevel() - 1))

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim, 
            ability = ability,
            attacker = caster, 
            damage = damage/3, 
            damage_type = DAMAGE_TYPE_MAGICAL
        })

        ApplyDamage({
            victim = victim, 
            ability = ability,
            attacker = caster, 
            damage = damage/3, 
            damage_type = DAMAGE_TYPE_PURE
        })

        ApplyDamage({
            victim = victim, 
            ability = ability,
            attacker = caster, 
            damage = damage/3, 
            damage_type = DAMAGE_TYPE_PHYSICAL
        })

        local debuff = victim:FindModifierByName("modifier_boss_destruction_lord_soul_slice_debuff")
        if not debuff then
            debuff = victim:AddNewModifier(caster, ability, "modifier_boss_destruction_lord_soul_slice_debuff", { duration = ability:GetSpecialValueFor("duration") })
        end

        if debuff then
            if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                debuff:IncrementStackCount()
                debuff:ForceRefresh()
            else
                victim:Kill(ability, caster)
            end
        end

        self:PlayEffects(victim, radius)
    end

    EmitSoundOnLocationWithCaster( caster:GetOrigin(), "Hero_Centaur.DoubleEdge", caster )

    ability:UseResources(false, false, false, true)
end

--------------------------------------------------------------------------------
function modifier_boss_destruction_lord_soul_slice:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/econ/items/centaur/centaur_ti9/centaur_double_edge_ti9_2.vpcf"
    local sound_cast = "Hero_Centaur.DoubleEdge"

    -- Get Data
    local forward = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

    local offset = 100
    local caster = self:GetCaster()
    local origin = caster:GetOrigin()
    local direction_normalized = (target:GetOrigin() - origin):Normalized()
    local final_position = origin + Vector(direction_normalized.x * offset, direction_normalized.y * offset, 0)
    local radius = self:GetAbility():GetSpecialValueFor("radius")

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 2, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 3, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 6, Vector(radius, radius, radius))
    ParticleManager:SetParticleControlForward(effect_cast, 1, (origin - final_position):Normalized())
    ParticleManager:ReleaseParticleIndex(effect_cast)
end