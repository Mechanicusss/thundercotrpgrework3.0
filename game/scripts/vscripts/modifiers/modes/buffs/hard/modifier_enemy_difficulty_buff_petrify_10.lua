LinkLuaModifier("modifier_enemy_difficulty_buff_petrify_10", "modifiers/modes/buffs/hard/modifier_enemy_difficulty_buff_petrify_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_petrify_10_petrified", "modifiers/modes/buffs/hard/modifier_enemy_difficulty_buff_petrify_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_petrify_10_cooldown", "modifiers/modes/buffs/hard/modifier_enemy_difficulty_buff_petrify_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_petrify_10 = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_petrify_10_petrified = class({
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_petrify_10_cooldown = class({
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
})

modifier_enemy_difficulty_buff_petrify_10 = class(ItemBaseClass)

function enemy_difficulty_buff_petrify_10:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_petrify_10"
end

function modifier_enemy_difficulty_buff_petrify_10:GetTexture() return "stone" end
function modifier_enemy_difficulty_buff_petrify_10_petrified:GetTexture() return "stone" end
-------------
function modifier_enemy_difficulty_buff_petrify_10:OnCreated()
    if not IsServer() then return end
end

function modifier_enemy_difficulty_buff_petrify_10:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_enemy_difficulty_buff_petrify_10:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
    if not RollPercentage(10) then return end
    if event.target:HasModifier("modifier_enemy_difficulty_buff_petrify_10_cooldown") then return end

    if event.target:HasModifier("modifier_enemy_difficulty_buff_petrify_10_petrified") then
        return
    end

    event.target:AddNewModifier(event.attacker, nil, "modifier_enemy_difficulty_buff_petrify_10_petrified", { duration = 1.0 })
    event.target:AddNewModifier(event.attacker, nil, "modifier_enemy_difficulty_buff_petrify_10_cooldown", { duration = 10.0 })
end
----
function modifier_enemy_difficulty_buff_petrify_10_petrified:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }

    return state
end

function modifier_enemy_difficulty_buff_petrify_10_petrified:OnCreated()
    if not IsServer() then return end

    self:PlayEffects()
end

function modifier_enemy_difficulty_buff_petrify_10_petrified:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_enemy_difficulty_buff_petrify_10_petrified:StatusEffectPriority(  )
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_enemy_difficulty_buff_petrify_10_petrified:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0,0,0 ), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end