LinkLuaModifier("modifier_furion_living_roots_custom", "heroes/hero_furion/furion_living_roots", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_living_roots_custom_debuff", "heroes/hero_furion/furion_living_roots", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_living_roots_custom_debuff_root", "heroes/hero_furion/furion_living_roots", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_living_roots_custom_buff", "heroes/hero_furion/furion_living_roots", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

local AbilityClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local AbilityClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local AbilityClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return false end,
}

furion_living_roots_custom = class(AbilityClass)
modifier_furion_living_roots_custom_debuff = class(AbilityClassDebuff)
modifier_furion_living_roots_custom_debuff_root = class(AbilityClassDebuff)
modifier_furion_living_roots_custom_buff = class(AbilityClassBuff)

function furion_living_roots_custom:GetIntrinsicModifierName()
  return "modifier_furion_living_roots_custom"
end

function furion_living_roots_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function furion_living_roots_custom:OnSpellStart()
    if not IsServer() then return end
    
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()
    local ability = self

    local radius = ability:GetEffectiveCastRange(point, nil)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_curse_of_forest_cast.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(particle, 0, point)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(particle)

    EmitSoundOn("Hero_Furion.CurseOfTheForest.Cast", caster)

    local units = FindUnitsInRadius(caster:GetTeam(), point, nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST, false)

    if #units > 0 then
        for _,unit in ipairs(units) do
            unit:AddNewModifier(caster, ability, "modifier_furion_living_roots_custom_debuff", { duration = duration })
            EmitSoundOn("Hero_Furion.CurseOfTheForest.Target", unit)
        end
    end
end
---------------------
function modifier_furion_living_roots_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_furion_living_roots_custom_debuff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_furion_living_roots_custom_debuff:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit
    local attacker = event.attacker

    if victim ~= parent then return end
    if victim == attacker then return end
    if attacker ~= self:GetCaster() then return end

    local buff = attacker:FindModifierByName("modifier_furion_living_roots_custom_buff")
    if not buff then
        buff = attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_furion_living_roots_custom_buff", {})
    end

    if buff then
        buff:IncrementStackCount()
    end
end

function modifier_furion_living_roots_custom_debuff:OnCreated()
    if not IsServer() then return end

    local victim = self:GetParent()

    victim:Stop() -- Stop all channels

    self.interval = self:GetAbility():GetLevelSpecialValueFor("damage_interval", (self:GetAbility():GetLevel() - 1))

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_curse_of_forest_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim)
    ParticleManager:SetParticleControl(self.particle, 0, victim:GetAbsOrigin())

    victim:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_furion_living_roots_custom_debuff_root", {})

    self:StartIntervalThink(self.interval)
end

function modifier_furion_living_roots_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not parent:IsAlive() or parent:GetHealth() < 1 or not ability or ability:IsNull() then
        self:StartIntervalThink(-1)
        return
    end

    local dot = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1)) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    local damage = {
        victim = parent,
        attacker = caster,
        damage = dot * self.interval,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    ApplyDamage(damage)

    EmitSoundOn("Hero_Furion.CurseOfTheForest.Damage", parent)
end

function modifier_furion_living_roots_custom_debuff:OnDestroy()
    if not IsServer() then return end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end
-------
function modifier_furion_living_roots_custom_debuff_root:OnCreated()
    if not IsServer() then return end

    local victim = self:GetParent()

    victim:Stop() -- Stop all channels

    self.delay = self:GetAbility():GetLevelSpecialValueFor("duration", (self:GetAbility():GetLevel() - 1))
    self.rooted = false

    self:StartIntervalThink(self.delay)
end

function modifier_furion_living_roots_custom_debuff_root:OnIntervalThink()
    if not self.rooted then
        self.rooted = true
        self:GetParent():EmitSound("Hero_Treant.NaturesGrasp.Spawn")
        self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("root_duration"))
        return
    else
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end

function modifier_furion_living_roots_custom_debuff_root:CheckState()
    local states = {}

    if self.rooted then
        states = {
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_DISARMED] = true
        }
    end

    return states
end

function modifier_furion_living_roots_custom_debuff_root:GetEffectName()
    if self.rooted then
        return "particles/units/heroes/hero_treant/treant_bramble_root.vpcf"
    end
end

function modifier_furion_living_roots_custom_debuff_root:IsHidden()
    return not self.rooted
end
----------
function modifier_furion_living_roots_custom_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_furion_living_roots_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_TOOLTIP  
    }
end

function modifier_furion_living_roots_custom_buff:GetModifierProcAttack_BonusDamage_Magical(params)
    if not IsServer() then return end

    local target = params.target if target==nil then target = params.unit end
    if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
        return 0
    end

    local total = self:GetAbility():GetSpecialValueFor("damage_per_kill") * self:GetStackCount()

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, total, nil)

    ApplyDamage({
        victim = target,
        attacker = self:GetParent(),
        damage = total,
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL,
    })

    return 0
end

function modifier_furion_living_roots_custom_buff:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("damage_per_kill") * self:GetStackCount()
end