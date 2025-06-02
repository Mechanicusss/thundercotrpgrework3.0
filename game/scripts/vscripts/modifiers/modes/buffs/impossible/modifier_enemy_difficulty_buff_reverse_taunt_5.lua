LinkLuaModifier("modifier_enemy_difficulty_buff_reverse_taunt_5", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_reverse_taunt_5", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_reverse_taunt_5_taunted", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_reverse_taunt_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_reverse_taunt_5 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_reverse_taunt_5_taunted = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_reverse_taunt_5 = class(ItemBaseClass)

function enemy_difficulty_buff_reverse_taunt_5:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_reverse_taunt_5"
end

function modifier_enemy_difficulty_buff_reverse_taunt_5:GetTexture() return "taunt" end
function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:GetTexture() return "taunt" end

function modifier_enemy_difficulty_buff_reverse_taunt_5:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_enemy_difficulty_buff_reverse_taunt_5:OnCreated()
    if not IsServer() then return end
    self.cooldown = false
end

function modifier_enemy_difficulty_buff_reverse_taunt_5:OnAttackLanded(event)
    if not IsServer() then return end
    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
    if self.cooldown then return end
    if not RollPercentage(5) then return end

    local victim = event.target
    
    victim:AddNewModifier(event.attacker, nil, "modifier_enemy_difficulty_buff_reverse_taunt_5_taunted", {
        duration = 2
    })

    EmitSoundOn("Hero_Axe.Berserkers_Call", victim)
    self:PlayEffect(victim)

    self.cooldown = true
    Timers:CreateTimer(10.0, function()
        self.cooldown = false
    end)
end

function modifier_enemy_difficulty_buff_reverse_taunt_5:PlayEffect(target)
    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/axe/axe_ti9_immortal/axe_ti9_beserkers_call_owner.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------
function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    self.victim = nil

    if #victims < 2 then
        self.victim = parent
    else
        self.victim = victims[2]
    end

    parent:MoveToPosition(self.victim:GetAbsOrigin())
    self:StartIntervalThink(0.1)
    self:OnIntervalThink()
end

function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:OnIntervalThink()
    local parent = self:GetParent()
    if (parent:GetAbsOrigin() - self.victim:GetAbsOrigin()):Length2D() <= parent:Script_GetAttackRange() then
        parent:PerformAttack(
            self.victim,
            true,
            true,
            true,
            false,
            parent:IsRangedAttacker(),
            false,
            true
        )
        parent:RemoveModifierByName("modifier_enemy_difficulty_buff_reverse_taunt_5_taunted")
        self:StartIntervalThink(-1)
    end
end

function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT 
    }

    return funcs
end

function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true
    }
    return state
end

function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:GetModifierMoveSpeedBonus_Constant()
    return 2000
end

function modifier_enemy_difficulty_buff_reverse_taunt_5_taunted:GetEffectName()
    return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

