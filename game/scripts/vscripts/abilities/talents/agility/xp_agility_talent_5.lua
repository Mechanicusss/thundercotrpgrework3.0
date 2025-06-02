LinkLuaModifier("modifier_xp_agility_talent_5", "abilities/talents/agility/xp_agility_talent_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_5 = class(ItemBaseClass)
modifier_xp_agility_talent_5 = class(xp_agility_talent_5)
-------------
function xp_agility_talent_5:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_5"
end
-------------
function modifier_xp_agility_talent_5:OnCreated()
end

function modifier_xp_agility_talent_5:OnDestroy()
end

function modifier_xp_agility_talent_5:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_xp_agility_talent_5:OnAttackLanded(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if not parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 

    if not RollPercentage(8) then return end

    local victims = FindUnitsInRadius(parent:GetTeam(), target:GetAbsOrigin(), nil,
            400, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() then break end

        ApplyDamage({
            attacker = parent,
            victim = enemy,
            damage = event.damage * (2/100 * (self:GetStackCount())),
            damage_type = DAMAGE_TYPE_PURE
        })
    end

    self:PlayEffects(target)
end

function modifier_xp_agility_talent_5:PlayEffects(target)
    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    -- Get Resources
    local particle_cast = "particles/econ/items/lanaya/lanaya_epit_trap/templar_assassin_epit_trap_explode.vpcf"
    local sound_cast = "Hero_TemplarAssassin.Trap.Explode"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end