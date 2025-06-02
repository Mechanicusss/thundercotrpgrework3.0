LinkLuaModifier("modifier_plague_ward_corrosion", "heroes/hero_shadow_shaman/plague_ward_corrosion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_plague_ward_corrosion_debuff", "heroes/hero_shadow_shaman/plague_ward_corrosion", LUA_MODIFIER_MOTION_NONE)

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

plague_ward_corrosion = class(ItemBaseClass)
modifier_plague_ward_corrosion = class(plague_ward_corrosion)
modifier_plague_ward_corrosion_debuff = class(ItemBaseClassDebuff)
-------------
function plague_ward_corrosion:GetIntrinsicModifierName()
    return "modifier_plague_ward_corrosion"
end

function modifier_plague_ward_corrosion:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_plague_ward_corrosion:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = parent:GetOwner()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() then
        return
    end

    local buff = victim:FindModifierByName("modifier_plague_ward_corrosion_debuff")
    if buff == nil then
        buff = victim:AddNewModifier(caster, self:GetAbility(), "modifier_plague_ward_corrosion_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_plague_ward_corrosion_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
    return funcs
end

function modifier_plague_ward_corrosion_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("corruption") * self:GetStackCount()
end

function modifier_plague_ward_corrosion_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_plague_ward_corrosion_debuff:OnCreated()
    if not IsServer() then return end

    local target = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_latent_poison_debuff.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 2, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 3, target:GetAbsOrigin() )

    local interval = self:GetAbility():GetSpecialValueFor("damage_interval")
    
    self:StartIntervalThink(interval)
end

function modifier_plague_ward_corrosion_debuff:OnIntervalThink()
    local damage = (self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))) * self:GetStackCount()

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetParent(), damage, nil)
end

function modifier_plague_ward_corrosion_debuff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end