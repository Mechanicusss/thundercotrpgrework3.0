LinkLuaModifier("modifier_player_difficulty_boon_misfire_30", "modifiers/modes/buffs/hard/modifier_player_difficulty_boon_misfire_30", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_misfire_30_illusion", "modifiers/modes/buffs/hard/modifier_player_difficulty_boon_misfire_30", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_misfire_30 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_misfire_30_illusion = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
})

modifier_player_difficulty_boon_misfire_30 = class(ItemBaseClass)


function player_difficulty_boon_misfire_30:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_misfire_30"
end

function modifier_player_difficulty_boon_misfire_30:GetTexture() return "ninjafinish" end
-------------
function modifier_player_difficulty_boon_misfire_30:OnCreated()
    if not IsServer() then return end

    self.cooldown = false
end

function modifier_player_difficulty_boon_misfire_30:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_player_difficulty_boon_misfire_30:OnAttack(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if self.cooldown then return end
    if not RollPercentage(30) then return end

    Timers:CreateTimer(0.1, function()
        CLONE_UNIT = CreateIllusions(event.attacker, event.attacker, {
            outgoing_damage = 200,
            incoming_damage = 0,
            outgoing_damage_roshan = 100,
            outgoing_damage_structure = 100
        }, 1, 0, false, false)

        CLONE_UNIT[1]:AddNewModifier(CLONE_UNIT[1], nil, "modifier_player_difficulty_boon_misfire_30_illusion", { duration = 0.5 })

        CLONE_UNIT[1]:SetAbsOrigin(Vector(event.attacker:GetAbsOrigin().x+RandomInt(1, 100), event.attacker:GetAbsOrigin().y+RandomInt(1, 100), event.attacker:GetAbsOrigin().z))

        CLONE_UNIT[1]:SetForwardVector(-event.attacker:GetForwardVector())

        CLONE_UNIT[1]:PerformAttack(
            event.attacker,
            true,
            true,
            true,
            false,
            event.attacker:IsRangedAttacker(),
            false,
            true
        )

        CLONE_UNIT[1]:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        self.cooldown = true

        Timers:CreateTimer(4, function()
            self.cooldown = false
        end)
    end)
end
---
function modifier_player_difficulty_boon_misfire_30_illusion:DeclareFunctions()
    local funcs = {}
    return funcs
end

function modifier_player_difficulty_boon_misfire_30_illusion:OnRemoved()
    if not IsServer() then return end

    self:GetParent():ForceKill(false)
end

function modifier_player_difficulty_boon_misfire_30_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    return state
end

function modifier_player_difficulty_boon_misfire_30_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_player_difficulty_boon_misfire_30_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_player_difficulty_boon_misfire_30_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_player_difficulty_boon_misfire_30_illusion:StatusEffectPriority()
    return 10001
end