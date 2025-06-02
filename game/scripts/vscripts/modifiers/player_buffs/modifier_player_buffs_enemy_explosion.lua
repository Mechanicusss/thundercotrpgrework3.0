LinkLuaModifier("modifier_player_buffs_enemy_explosion", "modifiers/player_buffs/modifier_player_buffs_enemy_explosion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_enemy_explosion = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_enemy_explosion = class(ItemBaseClass)

function modifier_player_buffs_enemy_explosion:GetIntrinsicModifierName()
    return "modifier_player_buffs_enemy_explosion"
end

function modifier_player_buffs_enemy_explosion:GetTexture() return "player_buffs/modifier_player_buffs_enemy_explosion" end
-------------
function modifier_player_buffs_enemy_explosion:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_player_buffs_enemy_explosion:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    if not RollPercentage(25) then return end 

    local unit = event.unit

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, unit )
    ParticleManager:SetParticleControl( effect_cast, 0, unit:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Techies.StickyBomb.Detonate", unit)

    local victims = FindUnitsInRadius(parent:GetTeam(), unit:GetAbsOrigin(), nil,
        300, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if 
            victim:IsAlive() and 
            not victim:IsMagicImmune()
        then
            local dmg = unit:GetMaxHealth() * 0.05

            ApplyDamage({
                victim = victim,
                attacker = parent,
                damage = dmg,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility(),
            })
        end
    end
end