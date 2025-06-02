LinkLuaModifier("modifier_gabriel_purity", "heroes/hero_gabriel/gabriel_purity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_purity_debuff", "heroes/hero_gabriel/gabriel_purity", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

gabriel_purity = class(ItemBaseClass)
modifier_gabriel_purity = class(gabriel_purity)
modifier_gabriel_purity_debuff = class(ItemBaseClassDebuff)
-------------
function gabriel_purity:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local mod = "modifier_gabriel_purity"

    if not self:GetToggleState() then
        caster:RemoveModifierByName(mod)
    else
        caster:AddNewModifier(caster, self, mod, {})
    end
end
-------------
function modifier_gabriel_purity:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_overhead_debuff.vpcf"
end

function modifier_gabriel_purity:OnCreated()
    if not IsServer() then return end

    self.shardProc = false
end

function modifier_gabriel_purity:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }
end

function modifier_gabriel_purity:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_gabriel_purity:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
    if not event.record then return end

    local target = event.target
    local parent = self:GetParent()

    local armorIgnore = self:GetAbility():GetSpecialValueFor("armor_ignore_pct")

    if self.shardProc then
        armorIgnore = armorIgnore * 2
    end

    local armor = (target:GetPhysicalArmorBaseValue() * (armorIgnore/100)) + self:GetAbility():GetSpecialValueFor("armor_ignore")
    local manaCost = math.abs(armor * self:GetAbility():GetSpecialValueFor("mana_cost_multiplier"))

    if self.shardProc then
        manaCost = manaCost * 2
    end

    if manaCost > parent:GetMana() then
        return
    end

    local ignore = armorIgnore

    return ignore
end

function modifier_gabriel_purity:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    if not self.shardProc then return end

    self.shardProc = false
end

function modifier_gabriel_purity:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    if not RollPercentage(self:GetAbility():GetSpecialValueFor("ignore_chance")) then return end
    self.shardProc = true
end

function modifier_gabriel_purity:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local target = event.target
    local debuff = target:FindModifierByName("modifier_gabriel_purity_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, self:GetAbility(), "modifier_gabriel_purity_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    self:PlayEffects(target)
    self:PlayEffects2(target)

    local armorIgnore = self:GetAbility():GetSpecialValueFor("armor_ignore_pct")
    if self.shardProc then
        armorIgnore = armorIgnore * 2
    end

    local armor = (target:GetPhysicalArmorBaseValue() * (armorIgnore/100)) + self:GetAbility():GetSpecialValueFor("armor_ignore")
    local manaCost = math.abs(armor * self:GetAbility():GetSpecialValueFor("mana_cost_multiplier"))

    if self.shardProc then
        manaCost = manaCost * 2
    end

    if manaCost > parent:GetMana() then
        return
    end

    ApplyDamage({
        victim = target,
        attacker = parent,
        damage = event.damage * (math.abs(armorIgnore)/100),
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
    })

    parent:SpendMana(manaCost, self:GetAbility())
end

function modifier_gabriel_purity:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity__2target.vpcf"
    EmitSoundOn("Hero_Omniknight.HammerOfPurity.Crit", target)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_gabriel_purity:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_hammer_of_purity_detonation.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        3,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
--------------------
function modifier_gabriel_purity_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }

    return funcs
end

function modifier_gabriel_purity_debuff:GetModifierIncomingDamage_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("incoming_damage_debuff") * self:GetStackCount()
end
--------------------