LinkLuaModifier("modifier_clinkz_skeleton_archer_custom", "heroes/hero_clinkz/modifier_clinkz_skeleton_archer_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_clinkz_skeleton_archer_custom = class(ItemBaseClass)
------------------------------------
function modifier_clinkz_skeleton_archer_custom:RemoveOnDeath() return true end

function modifier_clinkz_skeleton_archer_custom:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local hits = ability:GetSpecialValueFor("max_hits")
    self.point_override = nil

    if params.x ~= nil and params.y ~= nil and params.z ~= nil then
        self.point_override = Vector(params.x, params.y, params.z)
    end

    EmitSoundOn("Hero_Clinkz.Skeleton_Archer.Spawn", parent)

    parent:SetBaseMaxHealth(hits)
    parent:SetMaxHealth(hits)
    parent:SetHealth(hits)

    self.target = nil

    self.burningBarrage = parent:FindAbilityByName("clinkz_burning_spear_custom")

    if not self.burningBarrage then return end
    
    if self.burningBarrage ~= nil then
        local caster = self:GetCaster()
        local caster_BurningBarrage = caster:FindAbilityByName("clinkz_burning_spear_custom")
        if caster_BurningBarrage ~= nil then
            self.burningBarrage:SetLevel(caster_BurningBarrage:GetLevel())
        end
    end

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_burning_army.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        self.vfx,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self:StartIntervalThink(FrameTime())
end

function modifier_clinkz_skeleton_archer_custom:IsFiringBurningBarrage(target)
    return target:HasModifier("modifier_clinkz_burning_spear_custom_casting")
end

function modifier_clinkz_skeleton_archer_custom:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if self.point_override and self.burningBarrage then
        if not self:IsFiringBurningBarrage(parent) then
            parent:SetForwardVector(self.point_override)

            SpellCaster:Cast(self.burningBarrage, self.point_override)
        end

        return -- We don't want any of the below logic to apply afterwards
    end

    if not self.target and self.burningBarrage then
        local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self.burningBarrage:GetEffectiveCastRange(parent:GetAbsOrigin(), parent), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,unit in ipairs(units) do
            if unit ~= nil and unit:IsAlive() and parent:CanEntityBeSeenByMyTeam(unit) then
                if self:IsFiringBurningBarrage(parent) then
                    parent:Stop()
                    parent:InterruptChannel()
                end

                self.target = unit 
                break
            end 
        end
    end

    if self.target ~= nil then
        if not self.target:IsAlive() then
            self.target = nil 
            return
        end

        if not self:IsFiringBurningBarrage(parent) then
            local forward = self.target:GetAbsOrigin()

            parent:SetForwardVector(forward)

            SpellCaster:Cast(self.burningBarrage, self.target, true)
        end
    end
end

function modifier_clinkz_skeleton_archer_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_PROPERTY_DISABLE_HEALING,
    }

    return funcs
end

function modifier_clinkz_skeleton_archer_custom:OnAttacked( params )
    if IsServer() then
        if self:GetParent() == params.target then
            if params.attacker then
                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 1, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_clinkz_skeleton_archer_custom:GetDisableHealing()
    return 1
end

function modifier_clinkz_skeleton_archer_custom:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_clinkz_skeleton_archer_custom:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_clinkz_skeleton_archer_custom:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_clinkz_skeleton_archer_custom:GetEffectName()
    return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
end

function modifier_clinkz_skeleton_archer_custom:GetModifierProjectileName() 
    return "particles/econ/items/clinkz/clinkz_maraxiform/clinkz_ti9_summon_projectile_arrow.vpcf"
end

function modifier_clinkz_skeleton_archer_custom:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if parent ~= nil and parent:IsAlive() then
        parent:ForceKill(false)
    end

    EmitSoundOn("Hero_Clinkz.Skeleton_Archer.Destroy", parent)
end

function modifier_clinkz_skeleton_archer_custom:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    }
end