LinkLuaModifier("modifier_item_scorched_orchid", "items/item_scorched_orchid/item_scorched_orchid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_scorched_orchid_debuff", "items/item_scorched_orchid/item_scorched_orchid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_scorched_orchid_stored_damage", "items/item_scorched_orchid/item_scorched_orchid", LUA_MODIFIER_MOTION_NONE)

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

item_scorched_orchid = class(ItemBaseClass)
item_scorched_orchid2 = item_scorched_orchid
item_scorched_orchid3 = item_scorched_orchid
item_scorched_orchid4 = item_scorched_orchid
item_scorched_orchid5 = item_scorched_orchid
item_scorched_orchid6 = item_scorched_orchid
item_scorched_orchid7 = item_scorched_orchid
item_scorched_orchid8 = item_scorched_orchid
item_scorched_orchid9 = item_scorched_orchid
modifier_item_scorched_orchid = class(item_scorched_orchid)
modifier_item_scorched_orchid_debuff = class(ItemBaseClassDebuff)
modifier_item_scorched_orchid_stored_damage = class(ItemBaseClassDebuff)
-------------
function item_scorched_orchid:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_scorched_orchid:GetIntrinsicModifierName()
    return "modifier_item_scorched_orchid"
end

function item_scorched_orchid:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    EmitSoundOn("DOTA_Item.Orchid.Activate", target)
    EmitSoundOn("DOTA_Item.EtherealBlade.Activate", target)

    local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
    self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() and not victim:HasModifier("modifier_item_witch_blade_custom_poison") then
            victim:AddNewModifier(caster, self, "modifier_item_scorched_orchid_debuff", {
                duration = self:GetSpecialValueFor("duration")
            })
        end
    end
end
-------------
function modifier_item_scorched_orchid:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_scorched_orchid:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    if not event.unit:IsSilenced() then return end

    local ability = self:GetAbility()

    if event.inflictor == ability then return end

    -- crit stuff --
    local chance = ability:GetSpecialValueFor("ethereal_crit_chance")
    local critdamage = ability:GetSpecialValueFor("ethereal_crit_damage")

    local witchBlade = parent:FindModifierByName("modifier_item_witch_blade_custom")
    if witchBlade ~= nil and event.unit:HasModifier("modifier_item_witch_blade_custom_poison") then
        local witchBladeItem = witchBlade:GetAbility()
        if witchBladeItem ~= nil then
            critdamage = critdamage + witchBladeItem:GetSpecialValueFor("poison_critical_multiplier")
        end
    end

    if RollPercentage(chance) then
        local damage = event.damage * (critdamage/100)

        ApplyDamage({
            attacker = parent,
            victim = event.unit,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
            ability = ability
        })

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, event.unit, damage, nil)
    end
end

function modifier_item_scorched_orchid:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_scorched_orchid:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_scorched_orchid:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_scorched_orchid:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_scorched_orchid:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_scorched_orchid:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_scorched_orchid:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed_flat")
end

function modifier_item_scorched_orchid:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end
----------
function modifier_item_scorched_orchid_debuff:GetStatusEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_item_scorched_orchid_debuff:GetEffectName()
    return "particles/items2_fx/orchid.vpcf"
end

function modifier_item_scorched_orchid_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_item_scorched_orchid_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_scorched_orchid_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("ethereal_slow")
end

function modifier_item_scorched_orchid_debuff:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    parent:AddNewModifier(caster, self:GetAbility(), "modifier_item_scorched_orchid_stored_damage", {
        duration = 0.5,
        damage = self.stored
    })
end

function modifier_item_scorched_orchid_debuff:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local ability = self:GetAbility()

    local update = self.stored + ((event.damage) * (ability:GetSpecialValueFor("stored_damage_pct")/100))

    if update >= INT_MAX_LIMIT then
        update = INT_MAX_LIMIT
    end

    self.stored = update
end

function modifier_item_scorched_orchid_debuff:GetAbsoluteNoDamagePhysical()
    if self:GetCaster() == self:GetParent() then return 1
    else return nil end
end

function modifier_item_scorched_orchid_debuff:GetModifierMagicalResistanceDecrepifyUnique( params )
    return self:GetAbility():GetSpecialValueFor("magic_amp_pct") * (-1)
end

function modifier_item_scorched_orchid_debuff:CheckState()
    return
        {
            --[MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_ATTACK_IMMUNE] = true,
            [MODIFIER_STATE_SILENCED] = true,
        }
end

-- IntervalThink to remove active if magic immune (so you can't stack the two)
-- Thanks to dota imba for the ethereal logic!
function modifier_item_scorched_orchid_debuff:OnCreated()
    if not IsServer() then return end

    EmitSoundOn("DOTA_Item.EtherealBlade.Target", self:GetParent())

    self.stored = 0

    EmitSoundOn("Hero_Pugna.Decrepify", self:GetParent())
    self:StartIntervalThink(FrameTime())
end

function modifier_item_scorched_orchid_debuff:OnIntervalThink()
    if not IsServer() then return end
    if self:GetParent():IsMagicImmune() then self:Destroy() end
end
-------------------
function modifier_item_scorched_orchid_stored_damage:OnCreated(params)
    if not IsServer() then return end

    self.damage = params.damage
end

function modifier_item_scorched_orchid_stored_damage:OnDestroy(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, 
        ability = self:GetAbility()
    })

    local effect_cast = ParticleManager:CreateParticle( "particles/items2_fx/orchid_pop.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControl( effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end