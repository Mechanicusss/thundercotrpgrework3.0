LinkLuaModifier("modifier_troll_warlord_battle_trance_custom", "heroes/hero_troll_warlord/troll_warlord_battle_trance_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

troll_warlord_battle_trance_custom = class(ItemBaseClass)
modifier_troll_warlord_battle_trance_custom = class(ItemBaseClassBuff)
-------------
function troll_warlord_battle_trance_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_troll_warlord_battle_trance_custom", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_TrollWarlord.BattleTrance.Cast", caster)
end
----------
function modifier_troll_warlord_battle_trance_custom:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl( self.effect_cast, 0, caster:GetOrigin() )
end

function modifier_troll_warlord_battle_trance_custom:OnDestroy()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_troll_warlord_battle_trance_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_troll_warlord_battle_trance_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_troll_warlord_battletrance.vpcf"
end

function modifier_troll_warlord_battle_trance_custom:GetMinHealth()
    return 1
end

function modifier_troll_warlord_battle_trance_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed_pct")
end

function modifier_troll_warlord_battle_trance_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_troll_warlord_battle_trance_custom:GetModifierDamageOutgoing_Percentage()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end

function modifier_troll_warlord_battle_trance_custom:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    if target:GetUnitName() == "npc_tcot_tormentor" then return end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("bonus_lifesteal")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end

    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end