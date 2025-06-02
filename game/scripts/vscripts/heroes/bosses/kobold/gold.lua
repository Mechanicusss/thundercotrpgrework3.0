LinkLuaModifier("modifier_boss_mine_gold_steal", "heroes/bosses/kobold/gold", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_mine_gold_steal = class(ItemBaseClass)
modifier_boss_mine_gold_steal = class(boss_mine_gold_steal)
-------------
function boss_mine_gold_steal:GetIntrinsicModifierName()
    return "modifier_boss_mine_gold_steal"
end


function modifier_boss_mine_gold_steal:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_boss_mine_gold_steal:OnCreated()
    self.parent = self:GetParent()
end

function modifier_boss_mine_gold_steal:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if not victim:IsRealHero() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local gold = victim:GetGold() * (ability:GetSpecialValueFor("gold_pct") / 100)
    
    victim:ModifyGold(-gold, true, 0) 

    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim)   
    ParticleManager:SetParticleControlEnt(midas_particle, 1, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetAbsOrigin(), false)

    ApplyDamage({
        victim = victim,
        attacker = caster,
        damage = gold,
        damage_type = DAMAGE_TYPE_PURE
    })

    ability:UseResources(false,false,false,true)
end