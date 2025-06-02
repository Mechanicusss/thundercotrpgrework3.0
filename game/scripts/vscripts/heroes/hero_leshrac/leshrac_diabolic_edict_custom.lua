LinkLuaModifier("modifier_leshrac_diabolic_edict_custom", "heroes/hero_leshrac/leshrac_diabolic_edict_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_leshrac_diabolic_edict_custom_debuff", "heroes/hero_leshrac/leshrac_diabolic_edict_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

leshrac_diabolic_edict_custom = class(ItemBaseClass)
modifier_leshrac_diabolic_edict_custom = class(leshrac_diabolic_edict_custom)
modifier_leshrac_diabolic_edict_custom_debuff = class(ItemBaseClassDebuff)
-------------
function leshrac_diabolic_edict_custom:GetIntrinsicModifierName()
    return "modifier_leshrac_diabolic_edict_custom"
end

function modifier_leshrac_diabolic_edict_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_leshrac_diabolic_edict_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if attacker ~= parent then return end
    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end
    if not event.inflictor then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() or not string.find(event.inflictor:GetAbilityName(), "leshrac_") then return end
    end
    if not caster:IsAlive() or caster:PassivesDisabled() then return end
    local ability = self:GetAbility()
    
    local debuff = victim:FindModifierByName("modifier_leshrac_diabolic_edict_custom_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(attacker, ability, "modifier_leshrac_diabolic_edict_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-----------------------
function modifier_leshrac_diabolic_edict_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_leshrac_diabolic_edict_custom_debuff:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
end

function modifier_leshrac_diabolic_edict_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()

    EmitSoundOn("Hero_Leshrac.Diabolic_Edict", parent)

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = parent,
        damage = (self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))) * self:GetStackCount(),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_diabolic_edict.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_leshrac_diabolic_edict_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_leshrac_diabolic_edict_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_reduction")
end

function modifier_leshrac_diabolic_edict_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
