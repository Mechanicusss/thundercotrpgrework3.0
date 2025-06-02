--[[
    Thanks to the Dota IMBA team for the code! Credits go to them.
    https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_mars
]]--
LinkLuaModifier("modifier_mars_bulwark_custom", "heroes/hero_mars/mars_bulwark_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_bulwark_custom_toggle", "heroes/hero_mars/mars_bulwark_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

mars_bulwark_custom = class(ItemBaseClass)
modifier_mars_bulwark_custom = class(mars_bulwark_custom)
modifier_mars_bulwark_custom_toggle = class(ItemBaseClassBuff)
-------------
function mars_bulwark_custom:GetIntrinsicModifierName()
    return "modifier_mars_bulwark_custom"
end

function mars_bulwark_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    if self:GetToggleState() then
        caster:AddNewModifier(caster, ability, "modifier_mars_bulwark_custom_toggle", {})
    else
        caster:RemoveModifierByNameAndCaster("modifier_mars_bulwark_custom_toggle", caster)
    end
end
-------------
function modifier_mars_bulwark_custom_toggle:OnCreated( kv )
    -- references
    self.reduction_front = self:GetAbility():GetSpecialValueFor( "physical_damage_reduction" )
    self.reduction_side = self:GetAbility():GetSpecialValueFor( "physical_damage_reduction_side" )
    self.angle_forward = self:GetAbility():GetSpecialValueFor( "forward_angle" )
    self.angle_side = self:GetAbility():GetSpecialValueFor( "side_angle" )

    if not IsServer() then return end

    local caster = self:GetCaster()
    if caster:HasTalent("special_bonus_unique_mars_1_custom") then
        self.reduction_front = self.reduction_front + caster:FindAbilityByName("special_bonus_unique_mars_1_custom"):GetSpecialValueFor("value")
        self.reduction_side = self.reduction_side + caster:FindAbilityByName("special_bonus_unique_mars_1_custom"):GetSpecialValueFor("value")
    end
end

function modifier_mars_bulwark_custom_toggle:OnRefresh( kv )
    self.reduction_front = self:GetAbility():GetSpecialValueFor( "physical_damage_reduction" )
    self.reduction_side = self:GetAbility():GetSpecialValueFor( "physical_damage_reduction_side" )
    self.angle_forward = self:GetAbility():GetSpecialValueFor( "forward_angle" )
    self.angle_side = self:GetAbility():GetSpecialValueFor( "side_angle" )

    if not IsServer() then return end

    local caster = self:GetCaster()
    if caster:HasTalent("special_bonus_unique_mars_1_custom") then
        self.reduction_front = self.reduction_front + caster:FindAbilityByName("special_bonus_unique_mars_1_custom"):GetSpecialValueFor("value")
        self.reduction_side = self.reduction_side + caster:FindAbilityByName("special_bonus_unique_mars_1_custom"):GetSpecialValueFor("value")
    end
end

function modifier_mars_bulwark_custom_toggle:OnRemoved( kv )
    if not IsServer() then return end

    local ability = self:GetAbility()
    if ability:GetToggleState() then
        ability:ToggleAbility()
    end
end

function modifier_mars_bulwark_custom_toggle:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end

function modifier_mars_bulwark_custom_toggle:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS, 
    }

    return funcs
end

function modifier_mars_bulwark_custom_toggle:GetActivityTranslationModifiers()
    return "bulwark"
end

function modifier_mars_bulwark_custom_toggle:GetModifierIgnoreCastAngle()
    return 1
end

function modifier_mars_bulwark_custom_toggle:GetModifierDisableTurning()
    return 1
end

function modifier_mars_bulwark_custom_toggle:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("redirect_speed_penatly")
end

function modifier_mars_bulwark_custom_toggle:GetModifierPhysical_ConstantBlock(params)
    if params.inflictor then return 0 end

    -- cancel if break
    if params.target:PassivesDisabled() then return 0 end

    -- get data
    local parent = params.target
    local attacker = params.attacker
    local ability = self:GetAbility()
    local reduction = 0

    -- Check target position
    local facing_direction = parent:GetAnglesAsVector().y
    local attacker_vector = (attacker:GetOrigin() - parent:GetOrigin())
    local attacker_direction = VectorToAngles( attacker_vector ).y
    local angle_diff = math.abs( AngleDiff( facing_direction, attacker_direction ) )

    -- calculate damage reduction
    if angle_diff < self.angle_forward then
        reduction = self.reduction_front
        self:PlayEffects( true, attacker_vector )
    elseif angle_diff < self.angle_side then
        reduction = self.reduction_side
        self:PlayEffects( false, attacker_vector )
    end

    local damage_blocked = reduction * params.damage / 100

    --- Shard ---
    if IsServer() and parent:HasModifier("modifier_item_aghanims_shard") then
        local reflectRadius = ability:GetSpecialValueFor("redirect_range")
        local reflectPct = ability:GetSpecialValueFor("redirect_pct")

        local enemies = FindUnitsInRadius(
            parent:GetTeamNumber(),    -- int, your team number
            parent:GetOrigin(),    -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            reflectRadius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_BOTH,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        for _,enemy in pairs(enemies) do
            -- get distance percentage damage
            local distance = (enemy:GetOrigin()-parent:GetOrigin()):Length2D()
            local pct = (reflectRadius-distance)/(reflectRadius-1)
            pct = math.min( pct, 1 )

            local damage = (params.damage-damage_blocked) * pct * reflectPct/100

            if enemy:GetTeamNumber() ~= parent:GetTeamNumber() then
                -- apply damage
                local damageTable = {
                    attacker = parent,
                    victim = enemy,
                    damage = damage,
                    ability = self:GetAbility(),
                    damage_type = params.damage_type,
                    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION, --Optional.
                }

                ApplyDamage(damageTable)
            else
                if parent:HasTalent("special_bonus_unique_mars_3_custom") and enemy ~= parent then
                    enemy:Heal(damage, self:GetAbility())
                    SendOverheadEventMessage(
                        nil,
                        OVERHEAD_ALERT_HEAL,
                        enemy,
                        damage,
                        nil
                    )
                end
            end
        end
    end
    -------------

    return damage_blocked
end

function modifier_mars_bulwark_custom_toggle:PlayEffects(front)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_shield_of_mars.vpcf"
    local sound_cast = "Hero_Mars.Shield.Block"

    if not front then
        particle_cast = "particles/units/heroes/hero_mars/mars_shield_of_mars_small.vpcf"
        sound_cast = "Hero_Mars.Shield.BlockSmall"
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    self:GetParent():EmitSound(sound_cast)
end