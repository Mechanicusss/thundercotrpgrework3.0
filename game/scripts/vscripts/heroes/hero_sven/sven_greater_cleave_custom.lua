LinkLuaModifier("modifier_sven_greater_cleave_custom", "heroes/hero_sven/sven_greater_cleave_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sven_greater_cleave_custom_debuff", "heroes/hero_sven/sven_greater_cleave_custom", LUA_MODIFIER_MOTION_NONE)

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

sven_greater_cleave_custom = class(ItemBaseClass)
modifier_sven_greater_cleave_custom = class(sven_greater_cleave_custom)
modifier_sven_greater_cleave_custom_debuff = class(ItemBaseClassDebuff)
-------------
function sven_greater_cleave_custom:GetIntrinsicModifierName()
    return "modifier_sven_greater_cleave_custom"
end

function sven_greater_cleave_custom:GetAbilityTextureName()
    local texture = "greatercleave"

    if self:GetCaster():HasModifier("modifier_sven_gods_strength_custom") and self:GetCaster():HasScepter() then
        texture = "greatercleave_godsstrength"
    end

    return texture
end

function modifier_sven_greater_cleave_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED   
    }
    return funcs
end

function modifier_sven_greater_cleave_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    local isUlt = caster:HasModifier("modifier_sven_gods_strength_custom")
    local particle = "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave.vpcf"

    local damage = (attacker:GetAverageTrueAttackDamage(attacker) * (ability:GetSpecialValueFor("cleave_pct")/100))

    if isUlt and caster:HasScepter() then
        particle = "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf"
        damage = (attacker:GetAverageTrueAttackDamage(attacker) * (ability:GetSpecialValueFor("gods_strength_cleave_pct")/100))
    end

    local effect_cast = ParticleManager:CreateParticle( particle, PATTACH_POINT_FOLLOW, attacker )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Sven.GreatCleave.ti7", attacker)
    
    --- 
    -- Cleave
    ---
    local radius = ability:GetSpecialValueFor("cleave_radius")

    local start_radius = ability:GetSpecialValueFor("start_radius")
    local end_radius = ability:GetSpecialValueFor("end_radius")
    local distance = ability:GetSpecialValueFor("distance")

    local direction = victim:GetOrigin()-caster:GetOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local targets = self:FindUnitsInCone(
        caster:GetTeamNumber(), -- nTeamNumber
        victim:GetOrigin(), -- vCenterPos
        caster:GetOrigin(), -- vStartPos
        caster:GetOrigin() + direction*distance,    -- vEndPos
        start_radius,   -- fStartRadius
        end_radius, -- fEndRadius
        nil,    -- hCacheUnit
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- nTeamFilter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- nTypeFilter
        0,  -- nFlagFilter
        FIND_CLOSEST,   -- nOrderFilter
        false   -- bCanGrowCache
    )

    for _,target in ipairs(targets) do
        if target:IsAlive() then
            if target ~= victim then
                ApplyDamage({
                    victim = target, 
                    attacker = attacker, 
                    damage = damage, 
                    damage_type = DAMAGE_TYPE_PHYSICAL
                })
            end

            if isUlt and caster:HasScepter() then
                local debuff = target:FindModifierByName("modifier_sven_greater_cleave_custom_debuff")
                if not debuff then
                    target:AddNewModifier(caster, ability, "modifier_sven_greater_cleave_custom_debuff", {
                        duration = ability:GetSpecialValueFor("gods_strength_debuff_duration")
                    })
                end

                if debuff then
                    debuff:ForceRefresh()
                end
            end
        end
    end
end

function modifier_sven_greater_cleave_custom:FindUnitsInCone(nTeamNumber, vCenterPos, vStartPos, vEndPos, fStartRadius, fEndRadius, hCacheUnit, nTeamFilter, nTypeFilter, nFlagFilter, nOrderFilter, bCanGrowCache)
    -- vCenterPos is used to determine searching center (FIND_CLOSEST will refer to units closest to vCenterPos)

    -- get cast direction and length distance
    local direction = vEndPos-vStartPos
    direction.z = 0

    local distance = direction:Length2D()
    direction = direction:Normalized()

    -- get max radius circle search
    local big_radius = distance + math.max(fStartRadius, fEndRadius)

    -- find enemies closest to primary target within max radius
    local units = FindUnitsInRadius(
        nTeamNumber,    -- int, your team number
        vCenterPos, -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        big_radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        nTeamFilter,    -- int, team filter
        nTypeFilter,    -- int, type filter
        nFlagFilter,    -- int, flag filter
        nOrderFilter,   -- int, order filter
        bCanGrowCache   -- bool, can grow cache
    )

    -- Filter within cone
    local targets = {}
    for _,unit in pairs(units) do

        -- get unit vector relative to vStartPos
        local vUnitPos = unit:GetOrigin()-vStartPos

        -- get projection scalar of vUnitPos onto direction using dot-product
        local fProjection = vUnitPos.x*direction.x + vUnitPos.y*direction.y + vUnitPos.z*direction.z

        -- clamp projected scalar to [0,distance]
        fProjection = math.max(math.min(fProjection,distance),0)
        
        -- get projected vector of vUnitPos onto direction
        local vProjection = direction*fProjection

        -- calculate distance between vUnitPos and the projected vector
        local fUnitRadius = (vUnitPos - vProjection):Length2D()

        -- calculate interpolated search radius at projected vector
        local fInterpRadius = (fProjection/distance)*(fEndRadius-fStartRadius) + fStartRadius

        -- if unit is within distance, add them
        if fUnitRadius<=fInterpRadius then
            table.insert( targets, unit )
        end
    end

    return targets
end
---------------
function modifier_sven_greater_cleave_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_sven_greater_cleave_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("gods_strength_debuff_armor")
end