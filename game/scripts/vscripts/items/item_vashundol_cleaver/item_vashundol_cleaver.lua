LinkLuaModifier("modifier_vashundol_cleaver", "items/item_vashundol_cleaver/item_vashundol_cleaver", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vashundol_cleaver_disarmor", "items/item_vashundol_cleaver/item_vashundol_cleaver", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vashundol_cleaver_buff", "items/item_vashundol_cleaver/item_vashundol_cleaver", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

item_vashundol_cleaver = class(ItemBaseClass)
item_vashundol_cleaver_2 = item_vashundol_cleaver
item_vashundol_cleaver_3 = item_vashundol_cleaver
item_vashundol_cleaver_4 = item_vashundol_cleaver
item_vashundol_cleaver_5 = item_vashundol_cleaver
item_vashundol_cleaver_6 = item_vashundol_cleaver
item_vashundol_cleaver_7 = item_vashundol_cleaver
item_vashundol_cleaver_8 = item_vashundol_cleaver
modifier_vashundol_cleaver = class(item_vashundol_cleaver)
modifier_vashundol_cleaver_disarmor = class(ItemDebuff)
modifier_vashundol_cleaver_buff = class(ItemBuff)
-------------
function item_vashundol_cleaver:GetIntrinsicModifierName()
    return "modifier_vashundol_cleaver"
end

function item_vashundol_cleaver:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

   --[[ if caster:IsRangedAttacker() then
        return
    end--]]

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    target:CutDown(caster:GetTeamNumber())
end
------------
function modifier_vashundol_cleaver:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL
    }

    return funcs
end

function modifier_vashundol_cleaver:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_hp_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mp_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_vashundol_cleaver:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.quelling_damage = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus", (self:GetAbility():GetLevel() - 1)) 
    self.quelling_damage_ranged = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus_ranged", (self:GetAbility():GetLevel() - 1)) 
    self.cleave_creep = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_creep", (self:GetAbility():GetLevel() - 1))
    self.cleave_hero = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_hero", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_vashundol_cleaver:OnRemoved()
    if not IsServer() then return end
end

function modifier_vashundol_cleaver:GetModifierProcAttack_BonusDamage_Physical(params)
    if IsServer() then
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        if not IsCreepTCOTRPG(target) then return 0 end

        local parent = self:GetParent()
        local ability = self:GetAbility()
        local quell = ability:GetSpecialValueFor("quell_bonus_damage_pct")
        local damage = parent:GetAverageTrueAttackDamage(parent)
        
        return (damage * (quell/100))
    end
end

function modifier_vashundol_cleaver:OnDeath(event)
    if not IsServer() then return end
    if event.attacker ~= self:GetParent() then return end
    if event.attacker == event.unit then return end

    local ability = self:GetAbility()

    local buff = event.attacker:FindModifierByName("modifier_vashundol_cleaver_buff")
    if buff == nil then
        buff = event.attacker:AddNewModifier(event.attacker, ability, "modifier_vashundol_cleaver_buff", {
            duration = ability:GetSpecialValueFor("damage_buff_duration")
        })
    end

    if buff:GetStackCount() < ability:GetSpecialValueFor("damage_buff_max_stacks") then
        buff:IncrementStackCount()
    end

    buff:ForceRefresh()
end

function modifier_vashundol_cleaver:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local attack_damage = event.damage
    local ability = self:GetAbility()

    if self:GetCaster() ~= attacker then
        return
    end

    --[[if attacker:IsRangedAttacker() then
        return
    end--]]

    if not UnitIsNotMonkeyClone(attacker) or not attacker:IsRealHero() or attacker:IsIllusion() then return end
    if event.inflictor ~= nil then return end -- Should block abilities from proccing it? 

    local disarmor = victim:FindModifierByName("modifier_vashundol_cleaver_disarmor")
    if disarmor == nil then
        disarmor = victim:AddNewModifier(attacker, ability, "modifier_vashundol_cleaver_disarmor", {
            duration = ability:GetSpecialValueFor("corruption_duration")
        })
    end

    if disarmor ~= nil then
        disarmor:ForceRefresh()
    end
    --- 
    -- Cleave
    ---
    local radius = ability:GetSpecialValueFor("cleave_radius")
    local targets = FindUnitsInRadius(attacker:GetTeam(), victim:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,target in ipairs(targets) do
        if target:IsAlive() and target ~= victim then
            local distance = (victim:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
            local multiplier = 1 - (distance / radius)
            if multiplier <= 0 then
                multiplier = 0.1
            end

            ApplyDamage({
                victim = target, 
                attacker = attacker, 
                damage = (attacker:GetAverageTrueAttackDamage(attacker) * (ability:GetSpecialValueFor("cleave_damage")/100)) * multiplier, 
                damage_type = DAMAGE_TYPE_PHYSICAL
            })

            local disarmor = target:FindModifierByName("modifier_vashundol_cleaver_disarmor")
            if disarmor == nil then
                disarmor = target:AddNewModifier(attacker, ability, "modifier_vashundol_cleaver_disarmor", {
                    duration = ability:GetSpecialValueFor("corruption_duration")
                })
            end
        end
    end

    self:PlayEffects(victim)
end

function modifier_vashundol_cleaver:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/faceless_void/faceless_void_weapon_bfury/faceless_void_weapon_bfury_cleave.vpcf"
    local sound_cast = "Hero_Sven.GreatCleave"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ROOTBONE_FOLLOW, target )
    ParticleManager:SetParticleControlForward( effect_cast, 0, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
------------
function modifier_vashundol_cleaver_disarmor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS   
    }

    return funcs
end

function modifier_vashundol_cleaver_disarmor:OnCreated()
    self.armor = self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("base_corruption_amount_pct")/100)
end

function modifier_vashundol_cleaver_disarmor:GetModifierPhysicalArmorBonus()
    return self.armor
end
----------
function modifier_vashundol_cleaver_buff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_vashundol_cleaver_buff:OnIntervalThink()
    if not self:GetAbility() then self:Destroy() end
end

function modifier_vashundol_cleaver_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE    
    }

    return funcs
end

function modifier_vashundol_cleaver_buff:GetModifierPreAttack_BonusDamage()
    local ability = self:GetAbility()
    if not ability then return end 

    return ability:GetSpecialValueFor("damage_buff_pct") * self:GetStackCount()
end