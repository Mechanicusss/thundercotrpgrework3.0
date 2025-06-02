LinkLuaModifier("modifier_chicken_ability_5", "heroes/chicken/chicken_ability_5.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_5_chicken", "heroes/chicken/chicken_ability_5.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_5_debuff", "heroes/chicken/chicken_ability_5.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

chicken_ability_5 = class(ItemBaseClass)
modifier_chicken_ability_5 = class(chicken_ability_5)
modifier_chicken_ability_5_chicken = class(ItemBaseClassBuff)
modifier_chicken_ability_5_debuff = class(ItemBaseClassBuff)

function chicken_ability_5:GetIntrinsicModifierName()
    return "modifier_chicken_ability_5"
end

function modifier_chicken_ability_5:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_chicken_ability_5:OnTakeDamage(event)
    if not IsServer() or not event or not event.unit or not event.attacker then return end

    local parent = self:GetParent()
    if parent ~= event.unit then return end  -- Убедитесь, что это курица, которая наносит урон

    local ability = self:GetAbility()
    if not ability or not ability:IsCooldownReady() then return end
    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    self:SummonChicken(event.attacker:GetAbsOrigin())
    ability:UseResources(false, false, false, true)
end

function modifier_chicken_ability_5:SummonChicken(targetPoint)
    local caster = self:GetCaster()
    local chicken = CreateUnitByName("chicken_scepter_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())

    if chicken then
        chicken:AddNewModifier(caster, self:GetAbility(), "modifier_chicken_ability_5_chicken", {
            x = targetPoint.x,
            y = targetPoint.y,
            z = targetPoint.z
        })

        chicken:MoveToPosition(targetPoint)
    else
        print("Failed to create chicken unit")
    end
end

function modifier_chicken_ability_5_chicken:OnCreated(params)
    if not IsServer() then return end

    self.endLoc = Vector(params.x, params.y, params.z)
    self:StartIntervalThink(0.1)
end

function modifier_chicken_ability_5_chicken:OnIntervalThink()
    local parent = self:GetParent()
    local pos = parent:GetAbsOrigin()

    if (pos - self.endLoc):Length2D() < 50 then
        self:Explode()
    else
        parent:MoveToPosition(self.endLoc)
    end
end

function modifier_chicken_ability_5_chicken:Explode()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("damage") + (caster:GetIntellect() * (ability:GetSpecialValueFor("int_to_damage") / 100))

    local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)
    EmitSoundOn("Hero_Techies.RemoteMine.Detonate", parent)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _, victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() then
            ApplyDamage({
                victim = victim, 
                attacker = caster, 
                damage = damage, 
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })

            victim:AddNewModifier(caster, ability, "modifier_chicken_ability_5_debuff", {
                duration = ability:GetSpecialValueFor("duration")
            })
        end
    end

    parent:ForceKill(false)
end

function modifier_chicken_ability_5_debuff:IsDebuff() return true end
function modifier_chicken_ability_5_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_chicken_ability_5_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_increase_pct")
end