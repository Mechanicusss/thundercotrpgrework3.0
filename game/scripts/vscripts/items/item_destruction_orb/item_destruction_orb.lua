LinkLuaModifier("modifier_item_destruction_orb", "items/item_destruction_orb/item_destruction_orb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_destruction_orb_debuff", "items/item_destruction_orb/item_destruction_orb", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_destruction_orb = class(ItemBaseClass)
modifier_item_destruction_orb = class(item_destruction_orb)
modifier_item_destruction_orb_debuff = class(ItemBaseClassDebuff)
-------------
function item_destruction_orb:GetIntrinsicModifierName()
    return "modifier_item_destruction_orb"
end
-------------
function modifier_item_destruction_orb:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_destruction_orb:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local debuff = target:FindModifierByName("modifier_item_destruction_orb_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, ability, "modifier_item_destruction_orb_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end
    ---------
    local debuffSelf = parent:FindModifierByName("modifier_item_destruction_orb_debuff")
    if not debuffSelf then
        debuffSelf = parent:AddNewModifier(parent, ability, "modifier_item_destruction_orb_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuffSelf then
        debuffSelf:ForceRefresh()
    end
end
----------------
function modifier_item_destruction_orb_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_item_destruction_orb_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_item_destruction_orb_debuff:OnDeath(event)
    if not IsServer() then return end 

    if event.unit ~= self:GetParent() then return end

    local attacker = event.attacker
    local unit = event.unit

    local radius = self:GetAbility():GetSpecialValueFor("radius")
    local damage = self:GetAbility():GetSpecialValueFor("explosion_damage_pct")/100

    local ability = self:GetAbility()

    function Explode(team, loc, hp)
        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, unit )
        ParticleManager:SetParticleControl( effect_cast, 0, unit:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex( effect_cast )
        EmitSoundOn("Hero_Techies.StickyBomb.Detonate", unit)

        local victims = FindUnitsInRadius(team, loc, nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if 
                victim:IsAlive() and 
                not victim:IsMagicImmune()
            then
                local dmg = hp * damage

                ApplyDamage({
                    victim = victim,
                    attacker = unit,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = ability,
                })
            end
        end
    end

    Explode(unit:GetTeam(), unit:GetAbsOrigin(), unit:GetMaxHealth())
end