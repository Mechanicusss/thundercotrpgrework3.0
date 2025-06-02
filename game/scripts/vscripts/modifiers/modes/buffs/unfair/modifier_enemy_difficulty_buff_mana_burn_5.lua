LinkLuaModifier("modifier_enemy_difficulty_buff_mana_burn_5", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_mana_burn_5", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_mana_burn_5_cooldown", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_mana_burn_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_mana_burn_5 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})


modifier_enemy_difficulty_buff_mana_burn_5_cooldown = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

modifier_enemy_difficulty_buff_mana_burn_5 = class(ItemBaseClass)


function enemy_difficulty_buff_mana_burn_5:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_mana_burn_5"
end

function modifier_enemy_difficulty_buff_mana_burn_5:GetTexture() return "manaburn" end
-------------
function modifier_enemy_difficulty_buff_mana_burn_5:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.damageTable = {
        attacker = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    }
end

function modifier_enemy_difficulty_buff_mana_burn_5:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_enemy_difficulty_buff_mana_burn_5:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
    if event.target:HasModifier("modifier_enemy_difficulty_buff_mana_burn_5_cooldown") then return end
        
    local burn = event.target:GetMaxMana() * 0.05

    self.damageTable.victim = event.target
    self.damageTable.damage = burn

    ApplyDamage(self.damageTable)

    event.target:SpendMana(burn, self:GetAbility())

    local effect_cast = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN, event.target)
    ParticleManager:ReleaseParticleIndex(effect_cast)
    EmitSoundOn("Hero_Antimage.ManaBreak", event.target)

    event.target:AddNewModifier(event.attacker, nil, "modifier_enemy_difficulty_buff_mana_burn_5_cooldown", {
        duration = 1.5
    })
end
---