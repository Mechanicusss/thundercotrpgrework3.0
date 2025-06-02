LinkLuaModifier("modifier_ursa_earthshock_custom", "heroes/hero_ursa/ursa_earthshock_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_earthshock_custom_debuff", "heroes/hero_ursa/ursa_earthshock_custom", LUA_MODIFIER_MOTION_NONE)

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

ursa_earthshock_custom = class(ItemBaseClass)
modifier_ursa_earthshock_custom = class(ursa_earthshock_custom)
modifier_ursa_earthshock_custom_debuff = class(ItemBaseClassDebuff)
-------------
function ursa_earthshock_custom:GetIntrinsicModifierName()
    return "modifier_ursa_earthshock_custom"
end
---------
function modifier_ursa_earthshock_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_ursa_earthshock_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.no_attack_cooldown then return end
    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetSpecialValueFor("duration")

    if not RollPercentage(chance) then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.vfx, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 1, Vector(900, radius, 225) )
    ParticleManager:ReleaseParticleIndex(self.vfx)
    EmitSoundOn("Hero_Ursa.EarthShock", parent)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() then break end

        enemy:AddNewModifier(parent, ability, "modifier_ursa_earthshock_custom_debuff", {
            duration = duration
        })

        ApplyDamage({
            victim = enemy,
            attacker = parent,
            damage = ability:GetSpecialValueFor("damage") + (parent:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100)),
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })

        if parent:HasShard() then
            local furySwipes = parent:FindAbilityByName("ursa_fury_swipes_custom")
            if furySwipes ~= nil and furySwipes:GetLevel() > 0 then
                local mod = parent:FindModifierByName("modifier_ursa_fury_swipes_custom")
                if mod then
                    mod:FurySwipeLogic(enemy)
                end
            end
        end
    end
end
---------------
function modifier_ursa_earthshock_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_ursa_earthshock_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("armor_reduction_pct")/100)
end

function modifier_ursa_earthshock_custom_debuff:GetModifierMiss_Percentage()
    return (self:GetAbility():GetSpecialValueFor("miss_chance"))
end

function modifier_ursa_earthshock_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return (self:GetAbility():GetSpecialValueFor("slow"))
end