LinkLuaModifier("modifier_large_mine_ogre_bash", "creeps/large_mine_ogre_bash", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

large_mine_ogre_bash = class(ItemBaseClass)
modifier_large_mine_ogre_bash = class(large_mine_ogre_bash)
-------------
function large_mine_ogre_bash:GetIntrinsicModifierName()
    return "modifier_large_mine_ogre_bash"
end
-------------
function modifier_large_mine_ogre_bash:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_large_mine_ogre_bash:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    local damage = ability:GetSpecialValueFor("damage_pct")
    local radius = ability:GetSpecialValueFor("radius")

    if not RollPercentage(chance) then return end

    EmitSoundOn("n_creep_OgreBruiser.Smash.Stun", parent)

    self.effect_cast = ParticleManager:CreateParticle( "particles/neutral_fx/ogre_bruiser_smash.vpcf", PATTACH_WORLDORIGIN, parent )
	ParticleManager:SetParticleControl( self.effect_cast, 0, event.target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),	-- int, your team number
		event.target:GetAbsOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

    for _,enemy in ipairs(enemies) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end 

        ApplyDamage({
            attacker = parent,
            victim = enemy,
            damage = parent:GetAverageTrueAttackDamage(parent) * (damage/100),
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })

        enemy:AddNewModifier(parent, self:GetAbility(), "modifier_stunned", {
            duration = self:GetAbility():GetSpecialValueFor("stun_duration")
        })
    end
end