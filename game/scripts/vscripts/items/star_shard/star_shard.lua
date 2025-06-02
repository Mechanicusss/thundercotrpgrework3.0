--[[
    Credit to Dota IMBA team for Starfall code
]]--
LinkLuaModifier("modifier_item_star_shard", "items/star_shard/star_shard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_star_shard_active", "items/star_shard/star_shard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_star_shard_debuff", "items/star_shard/star_shard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_star_shard_buff", "items/star_shard/star_shard.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_star_shard = class(ItemBaseClass)
item_star_shard_2 = item_star_shard
item_star_shard_3 = item_star_shard
item_star_shard_4 = item_star_shard
item_star_shard_5 = item_star_shard
item_star_shard_6 = item_star_shard
item_star_shard_7 = item_star_shard
item_star_shard_8 = item_star_shard
modifier_item_star_shard = class(ItemBaseClass)
modifier_item_star_shard_active = class(ItemBaseClassActive)
modifier_item_star_shard_debuff = class(ItemDebuff)
modifier_item_star_shard_buff = class(ItemDebuff)
-------------
function item_star_shard:GetIntrinsicModifierName()
    return "modifier_item_star_shard"
end

function item_star_shard:GetAOERadius()
    return self:GetSpecialValueFor("star_aoe")
end

function item_star_shard:Precache(context)
    PrecacheResource( "particle", "particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf", context )
end

function item_star_shard:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    caster:AddNewModifier(caster, ability, "modifier_item_star_shard_active", { duration = duration })
end
---
function modifier_item_star_shard_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS , --GetModifierMagicalResistanceBonus
    }
    return funcs
end

function modifier_item_star_shard_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("star_magic_res")
end

function modifier_item_star_shard:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
    }

    return funcs
end

function StarfallWave(caster, ability, caster_position, radius, damage)
    local particle_starfall = "particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf"
    local hit_delay = 0.57
    local sound_impact = "Ability.StarfallImpact"

    EmitSoundOn("Ability.Starfall", caster)

    -- Find enemies in radius
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
        caster_position,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_ANY_ORDER,
        false)

    for _,enemy in pairs(enemies) do

        -- Does not hit magic immune enemies
        if not enemy:IsMagicImmune() then

            -- Add starfall effect
            local particle_starfall_fx = ParticleManager:CreateParticle(particle_starfall, PATTACH_ABSORIGIN_FOLLOW, enemy)
            ParticleManager:SetParticleControl(particle_starfall_fx, 0, enemy:GetAbsOrigin())
            ParticleManager:SetParticleControl(particle_starfall_fx, 1, enemy:GetAbsOrigin())
            ParticleManager:SetParticleControl(particle_starfall_fx, 3, enemy:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(particle_starfall_fx)

            -- Wait for the star to get to the target
            Timers:CreateTimer(hit_delay, function()
                -- Deal damage if the target did not become magic immune
                if not enemy:IsMagicImmune() then

                    -- Play impact sound
                    EmitSoundOn(sound_impact, enemy)

                    local damageTable = {victim = enemy,
                        damage = damage,
                        damage_type = DAMAGE_TYPE_MAGICAL,
                        attacker = caster,
                        ability = ability
                    }

                    -- Apply magic shred debuff before damage is applied
                    enemy:AddNewModifier(caster, ability, "modifier_item_star_shard_debuff", { duration = ability:GetSpecialValueFor("star_magic_res_duration") })

                    ApplyDamage(damageTable)

                    -- Stacks 
                    if RollPercentage(ability:GetSpecialValueFor("stack_chance")) then 
                        local buff = caster:FindModifierByName("modifier_item_star_shard_buff")
                        if not buff then
                            buff = caster:AddNewModifier(caster, ability, "modifier_item_star_shard_buff", {
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
            end)
        end
    end
end

function modifier_item_star_shard:OnAbilityFullyCast(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end
    if self:GetAbility() == event.ability then return end

    local target = self:GetParent()
    local attacker = event.unit
    local ability = self:GetAbility()
    local abilityName = ability:GetAbilityName()

    if string.match(abilityName, "item_") then
        return
    end

    if not RollPercentage(ability:GetSpecialValueFor("star_chance")) then return end

    local damage = attacker:GetMaxMana() * (ability:GetSpecialValueFor("active_agi_as_damage_pct")/100)
    
    StarfallWave(
        attacker,
        ability,
        target:GetAbsOrigin(),
        ability:GetSpecialValueFor("star_aoe"),
        damage
    )
end

function modifier_item_star_shard:OnAttack(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("star_chance")) then return end

    local damage = attacker:GetMaxMana() * (ability:GetSpecialValueFor("active_agi_as_damage_pct")/100)
    
    StarfallWave(
        attacker,
        ability,
        target:GetAbsOrigin(),
        ability:GetSpecialValueFor("star_aoe"),
        damage
    )
end

function modifier_item_star_shard:GetModifierPreAttack_BonusDamage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_star_shard:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_star_shard:GetModifierSpellAmplify_Percentage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_item_star_shard:GetModifierAttackSpeedBonus_Constant()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_star_shard:GetModifierMoveSpeedBonus_Percentage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("movement_speed_percent_bonus")
end

function modifier_item_star_shard:GetModifierConstantManaRegen()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("mana_regen")
end
--

function modifier_item_star_shard:OnCreated()
    if not IsServer() then return end
end
---
function modifier_item_star_shard_active:OnCreated()
    if not IsServer() then return end

    self.ability = self:GetAbility()

    local interval = self.ability:GetSpecialValueFor("active_interval")

    self.attacker = self:GetParent()
    self.damage = self.ability:GetSpecialValueFor("star_damage") + (self.attacker:GetMaxMana() * (self.ability:GetSpecialValueFor("active_agi_as_damage_pct")/100))

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_item_star_shard_active:OnIntervalThink()
    StarfallWave(
        self.attacker,
        self.ability,
        self.attacker:GetAbsOrigin(),
        self.ability:GetSpecialValueFor("star_aoe"),
        self.damage
    )
end
----------------
function modifier_item_star_shard_buff:IsDebuff() return false end

function modifier_item_star_shard_buff:OnCreated()
    if not IsServer() then return end
    self.intellect = self:GetParent():GetBaseIntellect()
end

function modifier_item_star_shard_buff:OnRefresh()
    if not IsServer() then return end
    self.intellect = self:GetParent():GetBaseIntellect()
end

function modifier_item_star_shard_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
    }

    return funcs
end

function modifier_item_star_shard_buff:GetModifierBonusStats_Intellect()
    if IsServer() and self.intellect then
        if not self:GetCaster():HasItemInInventory(self:GetAbility():GetAbilityName()) then
            if self:GetCaster():HasModifier("modifier_item_star_shard_buff") then
                self:GetCaster():RemoveModifierByNameAndCaster("modifier_item_star_shard_buff", self:GetCaster())
            end
            return
        end
        
        local amount = (self.intellect * (self:GetAbility():GetSpecialValueFor("stack_int_increase")/100)) * self:GetStackCount()
        local limit = 2147483647

        if amount > limit or amount < 0 then
            amount = limit
        end

        return amount
    end
end