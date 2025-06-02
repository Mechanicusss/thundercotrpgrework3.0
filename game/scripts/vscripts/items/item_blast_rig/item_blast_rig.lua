LinkLuaModifier("modifier_item_blast_rig", "items/item_blast_rig/item_blast_rig", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_blast_rig = class(ItemBaseClass)
modifier_item_blast_rig = class(item_blast_rig)
-------------
function item_blast_rig:GetIntrinsicModifierName()
    return "modifier_item_blast_rig"
end
-------------
function modifier_item_blast_rig:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_blast_rig:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.target then return end 

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    local radius = ability:GetSpecialValueFor("radius")

    local damage = parent:GetPrimaryStatValue() * ability:GetSpecialValueFor("primary_attribute_damage_multiplier")

    if not RollPercentage(chance) then return end 

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

        ApplyDamage({
            victim = enemy,
            attacker = parent,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })
    end

    self:PlayEffects()
end

function modifier_item_blast_rig:PlayEffects()
    local parent = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/items3_fx/black_powder_bag.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    EmitSoundOn("Item.BlackPowder", parent)
end