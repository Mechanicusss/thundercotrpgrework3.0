LinkLuaModifier("modifier_item_ancient_yhols_sword", "items/item_ancient_yhols_sword/item_ancient_yhols_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_yhols_sword_armor_debuff", "items/item_ancient_yhols_sword/item_ancient_yhols_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_yhols_sword_battle_rage_buff", "items/item_ancient_yhols_sword/item_ancient_yhols_sword.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_ancient_yhols_sword = class(ItemBaseClass)
item_ancient_yhols_sword_2 = item_ancient_yhols_sword
item_ancient_yhols_sword_3 = item_ancient_yhols_sword
item_ancient_yhols_sword_4 = item_ancient_yhols_sword
item_ancient_yhols_sword_5 = item_ancient_yhols_sword
modifier_item_ancient_yhols_sword = class(ItemBaseClass)
modifier_item_ancient_yhols_sword_armor_debuff = class(ItemBaseClassDebuff)
modifier_item_ancient_yhols_sword_battle_rage_buff = class(ItemBaseClassBuff)
-------------
function item_ancient_yhols_sword:GetIntrinsicModifierName()
    return "modifier_item_ancient_yhols_sword"
end
-------------
function modifier_item_ancient_yhols_sword:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,

        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_ancient_yhols_sword:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("armor_corruption_duration")

    target:AddNewModifier(parent, ability, "modifier_item_ancient_yhols_sword_armor_debuff", { duration = duration })

    -- Cleave
    local radius = ability:GetSpecialValueFor("cleave_radius")
    local enemies = FindUnitsInRadius(parent:GetTeam(), target:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemies) do
        if enemy:IsAlive() and enemy ~= target then
            -- Apply armor reduction to these enemies too
            enemy:AddNewModifier(parent, ability, "modifier_item_ancient_yhols_sword_armor_debuff", { duration = duration })

            ApplyDamage({
                victim = enemy, 
                attacker = parent, 
                damage = (event.damage * (ability:GetSpecialValueFor("cleave_damage")/100)), 
                damage_type = DAMAGE_TYPE_PHYSICAL,
                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
            })
        end
    end

    self:PlayCleaveEffects(target)

    -- Lifesteal
    if ability:IsCooldownReady() then
        local lifestealAmount = ability:GetSpecialValueFor("holy_lifesteal")
        local heal = event.damage * (lifestealAmount/100)

        if heal < 0 or heal > INT_MAX_LIMIT then
            heal = parent:GetMaxHealth()
        end

        parent:Heal(heal, nil)

        EmitSoundOn("Hero_Omniknight.HammerOfPurity.Crit", parent)

        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            0,
            parent,
            PATTACH_ABSORIGIN_FOLLOW,
            "attach_hitloc",
            parent:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:ReleaseParticleIndex( effect_cast )

        parent:Purge(false, true, false, true, false)

        ability:UseResources(false, false, false, true)
    end

    -- Battle Rage
    if ability:GetLevel() < 5 then return end

    if self.currentTarget ~= target and parent:HasModifier("modifier_item_ancient_yhols_sword_battle_rage_buff") then
        parent:RemoveModifierByName("modifier_item_ancient_yhols_sword_battle_rage_buff")
    end

    local battleRageDuration = ability:GetSpecialValueFor("battle_rage_duration")
    local battleRageMaxStacks = ability:GetSpecialValueFor("battle_rage_max_stacks")

    local buff = parent:FindModifierByName("modifier_item_ancient_yhols_sword_battle_rage_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_item_ancient_yhols_sword_battle_rage_buff", { duration = battleRageDuration })
    end

    if buff then
        if buff:GetStackCount() < battleRageMaxStacks then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    self.currentTarget = target
end

function modifier_item_ancient_yhols_sword:PlayCleaveEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/faceless_void/faceless_void_weapon_bfury/faceless_void_weapon_bfury_cleave.vpcf"
    local sound_cast = "Hero_Sven.GreatCleave"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlForward( effect_cast, 0, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_item_ancient_yhols_sword:GetModifierTotalDamageOutgoing_Percentage(event)
    if IsServer() then
        if IsBossTCOTRPG(event.target) then
            return self:GetAbility():GetSpecialValueFor("bonus_damage_boss_pct")
        end
    end
end

function modifier_item_ancient_yhols_sword:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_ancient_yhols_sword:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_ancient_yhols_sword:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_ancient_yhols_sword:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_ancient_yhols_sword:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end
------------
function modifier_item_ancient_yhols_sword_armor_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS   
    }
end

function modifier_item_ancient_yhols_sword_armor_debuff:OnCreated()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.armor = (parent:GetPhysicalArmorBaseValue() * (ability:GetSpecialValueFor("armor_corruption_pct")/100))
end

function modifier_item_ancient_yhols_sword_armor_debuff:GetModifierPhysicalArmorBonus()
    return self.armor
end
------------
function modifier_item_ancient_yhols_sword_battle_rage_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_item_ancient_yhols_sword_battle_rage_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("battle_rage_damage_pct") * self:GetStackCount()
end

function modifier_item_ancient_yhols_sword_battle_rage_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("battle_rage_movespeed_pct") * self:GetStackCount()
end