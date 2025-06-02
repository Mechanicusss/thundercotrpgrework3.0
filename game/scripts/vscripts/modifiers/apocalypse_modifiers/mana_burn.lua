LinkLuaModifier("modifier_apocalypse_mana_burn", "modifiers/apocalypse_modifiers/mana_burn", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_mana_burn = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_mana_burn = class(ItemBaseClass)

function modifier_apocalypse_mana_burn:GetIntrinsicModifierName()
    return "modifier_apocalypse_mana_burn"
end

function modifier_apocalypse_mana_burn:GetTexture() return "manaburn" end
-------------
function modifier_apocalypse_mana_burn:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.damageTable = {
        attacker = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    }
end

function modifier_apocalypse_mana_burn:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_apocalypse_mana_burn:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end

    local multiplier = 0.05
        
    local burn = event.target:GetMaxMana() * multiplier

    self.damageTable.victim = event.target
    self.damageTable.damage = burn

    ApplyDamage(self.damageTable)

    event.target:SpendMana(burn, self:GetAbility())

    local effect_cast = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN, event.target)
    ParticleManager:ReleaseParticleIndex(effect_cast)
    EmitSoundOn("Hero_Antimage.ManaBreak", event.target)
end