LinkLuaModifier("modifier_zombie_boss_decay", "heroes/bosses/zombie/zombie_boss_decay", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_boss_decay_debuff", "heroes/bosses/zombie/zombie_boss_decay", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

zombie_boss_decay = class(ItemBaseClass)
modifier_zombie_boss_decay = class(zombie_boss_decay)
modifier_zombie_boss_decay_debuff = class(ItemBaseClassDebuff)
-------------
function zombie_boss_decay:GetIntrinsicModifierName()
    return "modifier_zombie_boss_decay"
end
------------
function modifier_zombie_boss_decay:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_zombie_boss_decay:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not target:IsRealHero() then return end 

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local duration = ability:GetSpecialValueFor("duration")

    EmitSoundOn("Hero_Undying.Decay.Cast", parent)
    EmitSoundOn("Hero_Undying.Decay.Transfer", parent)

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(vfx, 0, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    local victims = FindUnitsInRadius(parent:GetTeam(), target:GetAbsOrigin(), nil,
            ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() then
            local debuff = victim:FindModifierByName("modifier_zombie_boss_decay_debuff")
            if not debuff then
                debuff = victim:AddNewModifier(parent, ability, "modifier_zombie_boss_decay_debuff", {
                    duration = duration
                })
            end

            if debuff then
                debuff:IncrementStackCount()
                debuff:ForceRefresh()
                victim:CalculateStatBonus(true)
            end

            EmitSoundOn("Hero_Undying.Decay.Target", victim)
        end
    end

    ability:UseResources(false, false, false, true)
end
------------
function modifier_zombie_boss_decay_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_zombie_boss_decay_debuff:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("strength_steal") * self:GetStackCount()
end