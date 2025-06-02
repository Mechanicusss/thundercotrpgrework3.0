LinkLuaModifier("modifier_item_cloak_of_incineration", "items/item_cloak_of_incineration/item_cloak_of_incineration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cloak_of_incineration_self", "items/item_cloak_of_incineration/item_cloak_of_incineration", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cloak_of_incineration_bonus", "items/item_cloak_of_incineration/item_cloak_of_incineration", LUA_MODIFIER_MOTION_NONE)

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

item_cloak_of_incineration = class(ItemBaseClass)
item_cloak_of_incineration2 = item_cloak_of_incineration
item_cloak_of_incineration3 = item_cloak_of_incineration
item_cloak_of_incineration4 = item_cloak_of_incineration
item_cloak_of_incineration5 = item_cloak_of_incineration
item_cloak_of_incineration6 = item_cloak_of_incineration
item_cloak_of_incineration7 = item_cloak_of_incineration
item_cloak_of_incineration8 = item_cloak_of_incineration
item_cloak_of_incineration9 = item_cloak_of_incineration
modifier_item_cloak_of_incineration_self = class(item_cloak_of_incineration)
modifier_item_cloak_of_incineration = class(ItemBaseClassDebuff)
modifier_item_cloak_of_incineration_bonus = class(ItemBaseClassDebuff)
-------------
function item_cloak_of_incineration:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_cloak_of_incineration:GetIntrinsicModifierName()
    return "modifier_item_cloak_of_incineration_self"
end

function item_cloak_of_incineration:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local radius = self:GetSpecialValueFor("radius")

    local nFXIndex = ParticleManager:CreateParticle( "particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_arcana_fire.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, point)
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius"), 0))
    ParticleManager:SetParticleControl( nFXIndex, 3, point)
    ParticleManager:SetParticleControl( nFXIndex, 5, Vector(375, 375, 0))
    ParticleManager:ReleaseParticleIndex( nFXIndex )
    
    EmitSoundOn("Ability.LightStrikeArray", caster)

    local victims = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        local debuff = victim:FindModifierByName("modifier_item_cloak_of_incineration")
        if not debuff then
            debuff = victim:AddNewModifier(caster, self, "modifier_item_cloak_of_incineration", {
                duration = self:GetSpecialValueFor("duration")
            })
        end

        if debuff then
            debuff:ForceRefresh()
        end

        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = self:GetSpecialValueFor("damage"),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })
    end
end
--------------
function modifier_item_cloak_of_incineration:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_item_cloak_of_incineration:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local stacks = self:GetStackCount()
    local max = ability:GetSpecialValueFor("max_stacks")

    local mult = 1

    if parent:HasModifier("modifier_item_cloak_of_incineration_bonus") then
        mult = ability:GetSpecialValueFor("stack_bonus_mult")
    end

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = ability:GetSpecialValueFor("damage_per_stack") * self:GetStackCount() * mult,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    if stacks < max then
        self:IncrementStackCount()
    end

    if stacks >= max then
        parent:AddNewModifier(caster, ability, "modifier_item_cloak_of_incineration_bonus", {
            duration = ability:GetSpecialValueFor("stack_bonus_duration")
        })
    end
end

function modifier_item_cloak_of_incineration:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_cloak_of_incineration:GetEffectName()
    return "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_wraithfireblast_debuff_2.vpcf"
end
-----------------
function modifier_item_cloak_of_incineration_bonus:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_arcana_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("Hero_Alchemist.UnstableConcoction.Stun", parent)
end
------------
function modifier_item_cloak_of_incineration_self:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_item_cloak_of_incineration_self:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_cloak_of_incineration_self:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_cloak_of_incineration_self:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end