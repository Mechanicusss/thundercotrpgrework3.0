LinkLuaModifier("modifier_boss_sf_raze", "heroes/bosses/sf/raze", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_sf_raze_debuff", "heroes/bosses/sf/raze", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_sf_raze = class(ItemBaseClass)
modifier_boss_sf_raze = class(boss_sf_raze)
modifier_boss_sf_raze_debuff = class(ItemBaseClassDebuff)
-------------
function modifier_boss_sf_raze_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_boss_sf_raze_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("dmg_reduce_pct")
end
-------------
function boss_sf_raze:GetIntrinsicModifierName()
    return "modifier_boss_sf_raze"
end

function modifier_boss_sf_raze:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_boss_sf_raze:OnCreated()
    self.parent = self:GetParent()
end

function modifier_boss_sf_raze:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    if victim:IsMagicImmune() then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        150, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

        ApplyDamage({
            victim = enemy, 
            attacker = caster, 
            damage = enemy:GetMaxHealth() * (ability:GetSpecialValueFor("damage_hp_pct")/100), 
            damage_type = DAMAGE_TYPE_MAGICAL
        })

        enemy:AddNewModifier(caster, ability, "modifier_boss_sf_raze_debuff", { duration = ability:GetSpecialValueFor("duration") })
    end
    
    self:PlayEffects(victim)

    ability:UseResources(false, false, false, true)
end

function modifier_boss_sf_raze:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"
    local sound_cast = "Hero_Nevermore.Shadowraze.Arcana"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
