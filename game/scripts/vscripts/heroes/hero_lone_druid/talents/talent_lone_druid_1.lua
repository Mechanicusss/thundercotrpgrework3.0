-- Credits to the Dota IMBA team for the Meteor Hammer code <3
-- https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/items/item_meteor_hammer
LinkLuaModifier("modifier_talent_lone_druid_1", "heroes/hero_lone_druid/talents/talent_lone_druid_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_lone_druid_1 = class(ItemBaseClass)
modifier_talent_lone_druid_1 = class(talent_lone_druid_1)
-------------
function talent_lone_druid_1:GetIntrinsicModifierName()
    return "modifier_talent_lone_druid_1"
end
-------------
function modifier_talent_lone_druid_1:OnCreated()
    if not IsServer() then return end 

    self.abilities = {
        "lone_druid_claw_strike_custom",
        "lone_druid_destructive_claws_custom"
    }

    self:StartIntervalThink(0.1)
end

function modifier_talent_lone_druid_1:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    for _,abil in ipairs(self.abilities) do 
        local temp = parent:FindAbilityByName(abil)
        if temp ~= nil then
            if not ability or (ability ~= nil and ability:GetLevel() > 1) then
                temp:SetHidden(false)
                temp:SetActivated(true)
                temp:SetLevel(1)
            else
                temp:SetHidden(true)
                temp:SetActivated(false)
            end
        end
    end 
end

function modifier_talent_lone_druid_1:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    for _,abil in ipairs(self.abilities) do 
        local temp = parent:FindAbilityByName(abil)
        if temp ~= nil then
            temp:SetHidden(true)
            temp:SetActivated(false)
        end
    end 
end

function modifier_talent_lone_druid_1:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_talent_lone_druid_1:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end
    
    local landTime = 0.5
    local targetPos = target:GetAbsOrigin()

    local radius = ability:GetSpecialValueFor("radius")
    local damage = parent:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100)

    EmitSoundOn("DOTA_Item.MeteorHammer.Cast", parent)

    self.meteorParticle	= ParticleManager:CreateParticle("particles/items4_fx/meteor_hammer_spell.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.meteorParticle, 0, targetPos + Vector(0, 0, 1000)) -- 1000 feels kinda arbitrary but it also feels correct
    ParticleManager:SetParticleControl(self.meteorParticle, 1, targetPos)
    ParticleManager:SetParticleControl(self.meteorParticle, 2, Vector(landTime, 0, 0))
    ParticleManager:ReleaseParticleIndex(self.meteorParticle)

    Timers:CreateTimer(landTime, function()
        EmitSoundOnLocationWithCaster(targetPos, "DOTA_Item.MeteorHammer.Impact", parent)

        local enemies = FindUnitsInRadius(parent:GetTeam(), targetPos, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,enemy in ipairs(enemies) do
            if not enemy:IsAlive() then break end

            EmitSoundOn("DOTA_Item.MeteorHammer.Damage", enemy)

            ApplyDamage({
                attacker = parent,
                victim = enemy,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })
        end
    end)
end