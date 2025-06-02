LinkLuaModifier("modifier_treant_overgrowth_custom", "heroes/hero_treant/treant_overgrowth", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_overgrowth_custom_aura", "heroes/hero_treant/treant_overgrowth", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_overgrowth_custom_aura_enemy", "heroes/hero_treant/treant_overgrowth", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_overgrowth_custom_debuff", "heroes/hero_treant/treant_overgrowth", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_overgrowth_custom_debuff_cooldown", "heroes/hero_treant/treant_overgrowth", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

treant_overgrowth_custom = class(ItemBaseClass)
modifier_treant_overgrowth_custom = class(ItemBaseClass)
modifier_treant_overgrowth_custom_aura = class(ItemBaseClass)
modifier_treant_overgrowth_custom_aura_enemy = class(ItemBaseClassAura)
modifier_treant_overgrowth_custom_debuff = class(ItemBaseClassDebuff)
modifier_treant_overgrowth_custom_debuff_cooldown = class(ItemBaseClass)
-------------
function treant_overgrowth_custom:GetIntrinsicModifierName()
    return "modifier_treant_overgrowth_custom"
end

function treant_overgrowth_custom:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end

function treant_overgrowth_custom:ResetToggleOnRespawn()
    return true
end

function treant_overgrowth_custom:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_treant_overgrowth_custom_aura", {})
    else
        caster:RemoveModifierByName("modifier_treant_overgrowth_custom_aura")
    end
end
------------
function modifier_treant_overgrowth_custom_aura:GetEffectName()
    return "particles/units/heroes/hero_leshrac/leshrac_scepter_nihilism_caster.vpcf"
end

function modifier_treant_overgrowth_custom_aura:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_treant_overgrowth_custom_aura:OnIntervalThink()
    local cost = self:GetParent():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("mana_drain_pct")/100)
    if self:GetParent():GetMana() < cost then
        if self:GetAbility():GetToggleState() then self:GetAbility():ToggleAbility() end
        return
    end
    self:GetParent():SpendMana(cost, self:GetAbility())
end

function modifier_treant_overgrowth_custom_aura:IsAura()
  return true
end

function modifier_treant_overgrowth_custom_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_treant_overgrowth_custom_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_treant_overgrowth_custom_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_treant_overgrowth_custom_aura:GetModifierAura()
    return "modifier_treant_overgrowth_custom_aura_enemy"
end

function modifier_treant_overgrowth_custom_aura:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_treant_overgrowth_custom_aura:GetAuraEntityReject(target)
    return false
end
----------
function modifier_treant_overgrowth_custom_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }
    return funcs
end

function modifier_treant_overgrowth_custom_aura_enemy:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_pct")
end

function modifier_treant_overgrowth_custom_aura_enemy:OnCreated()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local delay = ability:GetSpecialValueFor("delay")
    local duration = ability:GetSpecialValueFor("duration")
    local cooldown = ability:GetSpecialValueFor("cooldown")

    if self.rootTimer == nil then
        self.rootTimer = Timers:CreateTimer(delay, function()
            if not parent:HasModifier("modifier_treant_overgrowth_custom_debuff_cooldown") then
                parent:AddNewModifier(self:GetCaster(), ability, "modifier_treant_overgrowth_custom_debuff", { duration = duration })
            end

            return delay
        end)
    end

    self:StartIntervalThink(0.25)
end

function modifier_treant_overgrowth_custom_aura_enemy:OnDestroy()
    if not IsServer() then return end
    
    if self.rootTimer ~= nil then
        Timers:RemoveTimer(self.rootTimer)
        self.rootTimer = nil
    end
end

function modifier_treant_overgrowth_custom_aura_enemy:IsDebuff()
    return true
end

function modifier_treant_overgrowth_custom_aura_enemy:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(), 
        attacker = self:GetCaster(), 
        damage = (self:GetAbility():GetSpecialValueFor("damage_tick") + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_damage_pct")/100)))/4, 
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL
    })
end
----------
function modifier_treant_overgrowth_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_treant_overgrowth_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_increase_debuff")
end

function modifier_treant_overgrowth_custom_debuff:OnCreated()
    if not IsServer() then return end

    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_treant_overgrowth_custom_debuff_cooldown", { duration = self:GetAbility():GetSpecialValueFor("cooldown") })

    EmitSoundOn("Hero_Treant.Overgrowth.Target", self:GetParent())

    self:StartIntervalThink(0.5)
end

function modifier_treant_overgrowth_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf"
end

function modifier_treant_overgrowth_custom_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(), 
        attacker = self:GetCaster(), 
        damage = self:GetAbility():GetSpecialValueFor("damage")/2, 
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL
    })
end

function modifier_treant_overgrowth_custom_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
    return state
end
----------