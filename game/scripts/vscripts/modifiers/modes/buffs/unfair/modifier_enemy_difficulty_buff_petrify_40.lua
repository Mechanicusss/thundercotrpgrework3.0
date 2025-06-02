LinkLuaModifier("modifier_enemy_difficulty_buff_petrify_40", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_petrify_40", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_petrify_40_petrified", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_petrify_40", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_petrify_40 = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_petrify_40_petrified = class({
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_petrify_40 = class(ItemBaseClass)

function enemy_difficulty_buff_petrify_40:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_petrify_40"
end

function modifier_enemy_difficulty_buff_petrify_40:GetTexture() return "stone" end
function modifier_enemy_difficulty_buff_petrify_40_petrified:GetTexture() return "stone" end
-------------
function modifier_enemy_difficulty_buff_petrify_40:OnCreated()
    if not IsServer() then return end

    self.cooldown = false
end

function modifier_enemy_difficulty_buff_petrify_40:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_enemy_difficulty_buff_petrify_40:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
    if self.cooldown then return end
    if not RollPercentage(40) then return end

    if event.target:HasModifier("modifier_enemy_difficulty_buff_petrify_40_petrified") then
        return
    end

    event.target:AddNewModifier(event.attacker, nil, "modifier_enemy_difficulty_buff_petrify_40_petrified", { duration = 1.0 })

    self.cooldown = true
    
    Timers:CreateTimer(4, function()
        self.cooldown = false
    end)
end
----
function modifier_enemy_difficulty_buff_petrify_40_petrified:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }

    return state
end

function modifier_enemy_difficulty_buff_petrify_40_petrified:OnCreated()
    if not IsServer() then return end

    self:PlayEffects()
end

function modifier_enemy_difficulty_buff_petrify_40_petrified:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_enemy_difficulty_buff_petrify_40_petrified:StatusEffectPriority(  )
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_enemy_difficulty_buff_petrify_40_petrified:PlayEffects()
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