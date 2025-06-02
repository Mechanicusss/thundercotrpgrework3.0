LinkLuaModifier("modifier_luna_moon_beam_custom", "heroes/hero_luna/luna_moon_beam_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_scepter", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

luna_moon_beam_custom = class(ItemBaseClass)
modifier_luna_moon_beam_custom = class(luna_moon_beam_custom)
-------------
function luna_moon_beam_custom:GetAbilityTextureName()
    local talent = self:GetCaster():FindAbilityByName("talent_luna_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return "luna_beam_gold"
    else
        return "luna_beam_default"
    end
end

function luna_moon_beam_custom:GetBehavior()
    local caster = self:GetCaster()
    local runeMoonBeam = caster:HasModifier("modifier_item_socket_rune_legendary_luna_moon_beam")
    if runeMoonBeam then
        return DOTA_ABILITY_BEHAVIOR_PASSIVE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    end
end

function luna_moon_beam_custom:GetManaCost()
    local caster = self:GetCaster()
    local runeMoonBeam = caster:HasModifier("modifier_item_socket_rune_legendary_luna_moon_beam")
    if runeMoonBeam then
        return 0
    end
end

function luna_moon_beam_custom:GetCooldown()
    local caster = self:GetCaster()
    local runeMoonBeam = caster:HasModifier("modifier_item_socket_rune_legendary_luna_moon_beam")
    if runeMoonBeam then
        return 0
    end
end

function luna_moon_beam_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    self.count = 0

    self:CastBeam(target)
end

function luna_moon_beam_custom:CastBeam(target)
    local caster = self:GetCaster()

    AddFOWViewer(caster:GetTeam(), target:GetAbsOrigin(), 300, 1, false)
    
    EmitSoundOn("Hero_Luna.LucentBeam.Cast", caster)

    local intellectDamage = self:GetSpecialValueFor("int_to_damage")
    local damage = self:GetSpecialValueFor("damage") + (caster:GetAgility() * (intellectDamage/100))

    local damageType = DAMAGE_TYPE_MAGICAL

    local particle = "particles/econ/items/luna/luna_lucent_ti5/luna_lucent_beam_moonfall.vpcf"

    local talent = caster:FindAbilityByName("talent_luna_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        damageType = DAMAGE_TYPE_PURE
        particle = "particles/econ/items/luna/luna_lucent_ti5_gold/luna_lucent_beam_moonfall_gold.vpcf"
    end
    
    local effect_cast = ParticleManager:CreateParticle( particle, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(effect_cast)

    damage = damage * (1+(self.count * (self:GetSpecialValueFor("consec_dmg_increase")/100)))

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = damageType,
        ability = self,
    })

    EmitSoundOn("Hero_Luna.LucentBeam.Target", target)

    self.count = self.count + 1

    if target:HasModifier("modifier_luna_moon_beam_custom") then return end

    local mod = target:AddNewModifier(caster, self, "modifier_luna_moon_beam_custom", {})
end
-----------
function modifier_luna_moon_beam_custom:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local castPoint = ability:GetCastPoint()

    self:StartIntervalThink(castPoint)
end

function modifier_luna_moon_beam_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local chance = caster:GetBaseIntellect() * ability:GetSpecialValueFor("int_point_chance_repeat")
    local maxChance = ability:GetSpecialValueFor("int_point_max_chance")

    if chance > maxChance then
        chance = maxChance
    end

    if not RollPercentage(chance) then 
        ability.count = 0
        self:Destroy()
        return 
    end

    -- Stacks --
    local motm = caster:FindAbilityByName("luna_might_of_the_moon_custom")
    if motm ~= nil then
        local buff = caster:FindModifierByName("modifier_luna_might_of_the_moon_custom_stacks")
        
        if not buff then
            buff = caster:AddNewModifier(caster, motm, "modifier_luna_might_of_the_moon_custom_stacks", {})
        end

        if buff then
            if buff:GetStackCount() < motm:GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            if buff:GetStackCount() == motm:GetSpecialValueFor("max_stacks") then
                motm:SetActivated(true)

                if parent:HasScepter() and not parent:HasModifier("modifier_luna_might_of_the_moon_custom_scepter") then
                    parent:AddNewModifier(parent, motm, "modifier_luna_might_of_the_moon_custom_scepter", {
                        duration = motm:GetSpecialValueFor("scepter_duration")
                    })
                end
            end

            buff:ForceRefresh()
        end

        --- Damage 
        local bonusDamage = caster:FindModifierByName("modifier_luna_might_of_the_moon_custom_damage")

        if not bonusDamage then
            bonusDamage = caster:AddNewModifier(caster, motm, "modifier_luna_might_of_the_moon_custom_damage", {
                duration = motm:GetSpecialValueFor("duration")
            })
        end

        if bonusDamage then
            if bonusDamage:GetStackCount() < motm:GetSpecialValueFor("max_stacks") then
                bonusDamage:IncrementStackCount()
            end

            bonusDamage:ForceRefresh()
        end
    end

    ability:CastBeam(parent)
end