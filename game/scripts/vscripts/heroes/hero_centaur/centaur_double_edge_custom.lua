LinkLuaModifier("modifier_centaur_double_edge_custom", "heroes/hero_centaur/centaur_double_edge_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

centaur_double_edge_custom = class(ItemBaseClass)
modifier_centaur_double_edge_custom = class(centaur_double_edge_custom)
-------------
function centaur_double_edge_custom:GetIntrinsicModifierName()
    return "modifier_centaur_double_edge_custom"
end


function modifier_centaur_double_edge_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_centaur_double_edge_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_centaur_double_edge_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if not parent:HasModifier("modifier_item_aghanims_shard") then
        if event.attacker ~= parent then
            return
        end
    else
        if event.attacker ~= parent and event.attacker ~= event.target and event.target ~= parent then
            return
        end
    end    

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local isAttacker = (unit == caster)
    local isVictim = (victim == caster)

    local ability = self:GetAbility()
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local damage = ability:GetLevelSpecialValueFor("edge_damage", (ability:GetLevel() - 1))
    local hpDamage = caster:GetMaxHealth() * (ability:GetLevelSpecialValueFor("hp_damage", (ability:GetLevel() - 1))/100)
    local strengthMulti = ability:GetLevelSpecialValueFor("strength_damage", (ability:GetLevel() - 1))
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then return end

    local searchTarget = nil 
    
    if isAttacker then
        searchTarget = victim 
    elseif isVictim then
        searchTarget = unit 
    end


    local victims = FindUnitsInRadius(caster:GetTeam(), searchTarget:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim, 
            ability = ability,
            attacker = caster, 
            damage = damage + hpDamage + (caster:GetStrength() * (strengthMulti / 100)), 
            damage_type = DAMAGE_TYPE_MAGICAL
        })

        self:PlayEffects(victim, radius)
    end

    EmitSoundOnLocationWithCaster( caster:GetOrigin(), "Hero_Centaur.DoubleEdge", caster )
end

--------------------------------------------------------------------------------
function modifier_centaur_double_edge_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/econ/items/centaur/centaur_ti9/centaur_double_edge_ti9.vpcf"
    local sound_cast = "Hero_Centaur.DoubleEdge"

    -- Get Data
    local forward = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

    local offset = 100
    local caster = self:GetCaster()
    local origin = caster:GetOrigin()
    local direction_normalized = (target:GetOrigin() - origin):Normalized()
    local final_position = origin + Vector(direction_normalized.x * offset, direction_normalized.y * offset, 0)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 2, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 3, target:GetAbsOrigin())
    ParticleManager:SetParticleControlForward(effect_cast, 1, (origin - final_position):Normalized())
    ParticleManager:ReleaseParticleIndex(effect_cast)
end