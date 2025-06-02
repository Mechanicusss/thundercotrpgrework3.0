LinkLuaModifier("modifier_player_buffs_sanguine_clarity", "modifiers/player_buffs/modifier_player_buffs_sanguine_clarity", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_sanguine_clarity = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_sanguine_clarity = class(ItemBaseClass)

function modifier_player_buffs_sanguine_clarity:GetIntrinsicModifierName()
    return "modifier_player_buffs_sanguine_clarity"
end

function modifier_player_buffs_sanguine_clarity:GetTexture() return "player_buffs/modifier_player_buffs_sanguine_clarity" end
-------------
function modifier_player_buffs_sanguine_clarity:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_player_buffs_sanguine_clarity:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_player_buffs_sanguine_clarity:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local unit = event.unit

    local victims = FindUnitsInRadius(parent:GetTeam(), unit:GetAbsOrigin(), nil,
        600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if 
            victim:IsAlive() and victim:IsRealHero()
        then
            local heal = unit:GetMaxHealth() * 0.25
            victim:Heal(heal, self:GetAbility())
            self:PlayEffects(victim)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, victim, heal, nil)
        end
    end
end