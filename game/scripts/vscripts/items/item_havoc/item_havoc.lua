LinkLuaModifier("modifier_item_havoc", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_havoc_stun_cooldown", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_havoc_stunned", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_havoc_slowed", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_havoc_buff", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_havoc_armor_debuff", "items/item_havoc/item_havoc", LUA_MODIFIER_MOTION_NONE)

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

item_havoc = class(ItemBaseClass)
item_havoc_2 = item_havoc
item_havoc_3 = item_havoc
item_havoc_4 = item_havoc
item_havoc_5 = item_havoc
item_havoc_6 = item_havoc
item_havoc_7 = item_havoc
item_havoc_8 = item_havoc
item_havoc_9 = item_havoc
modifier_item_havoc = class(item_havoc)
modifier_item_havoc_stunned = class(ItemBaseClassDebuff)
modifier_item_havoc_slowed = class(ItemBaseClassDebuff)
modifier_item_havoc_buff = class(ItemBaseClassDebuff)
modifier_item_havoc_stun_cooldown = class(ItemBaseClassDebuff)
modifier_item_havoc_armor_debuff = class(ItemBaseClassDebuff)
-------------
function item_havoc:GetIntrinsicModifierName()
    return "modifier_item_havoc"
end

function modifier_item_havoc:OnCreated()
    if not IsServer() then return end

    self.counter = {}
end

function modifier_item_havoc:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_item_havoc:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_havoc:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_havoc:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_havoc:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent or event.target == parent then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("damage") + (parent:GetStrength() * (ability:GetSpecialValueFor("damage_strength_pct")/100))
    local stun_duration = ability:GetSpecialValueFor("stun_duration")
    local slow_duration = ability:GetSpecialValueFor("slow_duration")
    local min_stun = ability:GetSpecialValueFor("min_stun_duration")

    local target = event.target

    if not RollPercentage(chance) then return end

    self:PlayEffects(target)

    -- Stun logic
    if not IsBossTCOTRPG(target) then
        if target:HasModifier("modifier_item_havoc_stunned") then
            self.counter[target:entindex()] = self.counter[target:entindex()] or 0
            self.counter[target:entindex()] = self.counter[target:entindex()] + 1
        end

        if self.counter[target:entindex()] ~= nil and self.counter[target:entindex()] > 0 and not target:HasModifier("modifier_item_havoc_stun_cooldown") then
            stun_duration = stun_duration - (ability:GetSpecialValueFor("stun_decrease") * self.counter[target:entindex()])
            if stun_duration <= min_stun then
                stun_duration = min_stun
                target:AddNewModifier(parent, ability, "modifier_item_havoc_stun_cooldown", {
                    duration = ability:GetSpecialValueFor("stun_cooldown")
                })
            end
        end

        if not target:HasModifier("modifier_item_havoc_stun_cooldown") then
            target:AddNewModifier(parent, ability, "modifier_item_havoc_stunned", {
                duration = stun_duration
            })
        end
    end

    -- Damage
    local victims = FindUnitsInRadius(parent:GetTeam(), event.target:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        ApplyDamage({
            victim = victim, 
            attacker = parent, 
            damage = damage, 
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })
        
        victim:AddNewModifier(parent, ability, "modifier_item_havoc_slowed", {
            duration = slow_duration+stun_duration
        })

        local armorDebuff = victim:FindModifierByName("modifier_item_havoc_armor_debuff")
        if not armorDebuff then
            armorDebuff = victim:AddNewModifier(parent, ability, "modifier_item_havoc_armor_debuff", {
                duration = ability:GetSpecialValueFor("armor_reduction_duration")
            })
        end

        if armorDebuff then
            if armorDebuff:GetStackCount() < ability:GetSpecialValueFor("armor_reduction_max_stacks") then
                armorDebuff:IncrementStackCount()
            end

            armorDebuff:ForceRefresh()
        end
    end

    local caster = self:GetCaster()

    -- Stacks 
    if RollPercentage(ability:GetSpecialValueFor("stack_chance")) then 
        local buff = caster:FindModifierByName("modifier_item_havoc_buff")
        if not buff then
            buff = caster:AddNewModifier(caster, ability, "modifier_item_havoc_buff", {
                duration = ability:GetSpecialValueFor("stack_duration")
            })
        end

        if buff then
            if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end
    end
end

function modifier_item_havoc:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/items5_fx/havoc_hammer.vpcf"
    local sound_cast = "DOTA_Item.HavocHammer.Cast"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
---
function modifier_item_havoc_stunned:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_item_havoc_stunned:GetTexture()
    return "havoc"
end

function modifier_item_havoc_stunned:GetEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end
------------
function modifier_item_havoc_slowed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_item_havoc_slowed:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_item_havoc_slowed:GetTexture()
    return "havoc"
end
------------------
function modifier_item_havoc_buff:IsDebuff() return false end

function modifier_item_havoc_buff:OnCreated()
    if not IsServer() then return end
    self.strength = self:GetParent():GetBaseStrength()
end

function modifier_item_havoc_buff:OnRefresh()
    if not IsServer() then return end
    self.strength = self:GetParent():GetBaseStrength()
end

function modifier_item_havoc_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Agility
    }

    return funcs
end

function modifier_item_havoc_buff:GetModifierBonusStats_Strength()
    if IsServer() and self.strength then
        if not self:GetCaster():HasItemInInventory(self:GetAbility():GetAbilityName()) then
            if self:GetCaster():HasModifier("modifier_item_havoc_buff") then
                self:GetCaster():RemoveModifierByNameAndCaster("modifier_item_havoc_buff", self:GetCaster())
            end
            return
        end
        
        local amount = (self.strength * (self:GetAbility():GetSpecialValueFor("stack_str_increase")/100)) * self:GetStackCount()
        local limit = 2147483647

        if amount > limit or amount < 0 then
            amount = limit
        end

        return amount
    end
end
-------------
function modifier_item_havoc_stun_cooldown:IsHidden() return true end

function modifier_item_havoc_stun_cooldown:OnRemoved()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_item_havoc")
    if not mod then return end 

    local parent = self:GetParent()

    mod.counter[parent:entindex()] = mod.counter[parent:entindex()] or 0
    mod.counter[parent:entindex()] = 0
end
------------
function modifier_item_havoc_armor_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_havoc_armor_debuff:GetModifierPhysicalArmorBonus()
    return self:GetParent():GetPhysicalArmorBaseValue() * ((self:GetAbility():GetSpecialValueFor("armor_reduction_pct")/100) * self:GetStackCount())
end