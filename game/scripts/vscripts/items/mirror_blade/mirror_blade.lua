LinkLuaModifier("modifier_mirror_blade", "items/mirror_blade/mirror_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_doubleattack", "items/mirror_blade/mirror_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_doubleattack_debuff", "items/mirror_blade/mirror_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_illusion_modifier", "items/mirror_blade/mirror_blade", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseDoubleAttackClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_mirror_blade = class(ItemBaseClass)
modifier_mirror_blade_illusion_modifier = class(ItemBaseClass)
item_mirror_blade_2 = item_mirror_blade
item_mirror_blade_3 = item_mirror_blade
item_mirror_blade_4 = item_mirror_blade
item_mirror_blade_5 = item_mirror_blade
item_mirror_blade_6 = item_mirror_blade
item_mirror_blade_7 = item_mirror_blade
item_mirror_blade_8 = item_mirror_blade
modifier_mirror_blade_doubleattack = class(ItemBaseDoubleAttackClass)
modifier_mirror_blade_doubleattack_debuff = class(ItemBaseDebuffClass)
modifier_mirror_blade = class(item_mirror_blade)
-------------
function item_mirror_blade:GetIntrinsicModifierName()
    return "modifier_mirror_blade"
end
------------
function modifier_mirror_blade_doubleattack:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA  
end

function modifier_mirror_blade_doubleattack:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT 
    }

    return funcs
end

function modifier_mirror_blade_doubleattack:GetModifierBaseAttackTimeConstant()
    return 0.5
end

function modifier_mirror_blade_doubleattack:GetModifierAttackSpeedBonus_Constant()
    return 450
end

function modifier_mirror_blade_doubleattack:GetModifierProcAttack_BonusDamage_Pure(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        local parent = self:GetParent()
        local multi = self:GetAbility():GetSpecialValueFor("bonus_attack_strike_damage_mult")
        local attack = params.damage * (multi/100)

        return attack
    end
end
------------
function modifier_mirror_blade_doubleattack_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,--GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_mirror_blade_doubleattack_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -100
end
------------
function modifier_mirror_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_mirror_blade:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_mirror_blade_doubleattack")
end

function modifier_mirror_blade:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.illusionOutgoing = ability:GetLevelSpecialValueFor("illusion_damage_pct", (ability:GetLevel() - 1))
    self.illusionIncoming = ability:GetLevelSpecialValueFor("illusion_damage_taken_pct", (ability:GetLevel() - 1))
    self.illusionDuration = ability:GetLevelSpecialValueFor("illusion_duration", (ability:GetLevel() - 1))
    self.cooldown = ability:GetLevelSpecialValueFor("tooltip_cooldown", (ability:GetLevel() - 1))
    self.slowDuration = ability:GetLevelSpecialValueFor("slow_duration", (ability:GetLevel() - 1))
    self.canSummonMirror = true
    self.hits = 0
end

function modifier_mirror_blade:OnAttack(event)
    if not IsServer() then return end
    local attacker = event.attacker
    local victim = event.target
    
    if self:GetCaster() ~= attacker then return end
    if event.inflictor ~= nil then return end

    local ability = self:GetAbility()

    -- Echo proc works only on melee
    if UnitIsNotMonkeyClone(attacker) and attacker:IsRealHero() then
        if self.hits >= 3 then
            attacker:RemoveModifierByName("modifier_mirror_blade_doubleattack")
            self.hits = 0
        else
            self.hits = self.hits + 1
        end

        -- We allow the hit count to work when cd is up but it won't ever apply the modifier
        if not ability:IsCooldownReady() then return end
        attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_mirror_blade_doubleattack", {
            enemyEntIndex = victim:GetEntityIndex()
        })
        victim:AddNewModifier(victim, self:GetAbility(), "modifier_mirror_blade_doubleattack_debuff", { duration = self.slowDuration })

        ability:UseResources(false, false, false, true)

        Timers:CreateTimer(ability:GetCooldownTimeRemaining(), function()
            -- Remove the modifier when the cooldown becomes ready again
            attacker:RemoveModifierByName("modifier_mirror_blade_doubleattack")
            self.hits = 0
        end)
    end

    if not self.canSummonMirror then return end

    -- Should not make illusions of non-heroes, bosses, other illusions etc.
    if not attacker:IsHero() or attacker:IsIllusion() or victim:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() then return end

    local owner = attacker
    --[[
    if attacker:GetTeamNumber() == DOTA_TEAM_BADGUYS then
        owner = Entities:FindByName(nil, "ent_dota_fountain_bad")
    elseif attacker:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        owner = Entities:FindByName(nil, "ent_dota_fountain_good")
    end
    --]]

    if not owner then return end

    local modifierKeys = {
        outgoing_damage = self.illusionOutgoing,
        incoming_damage = self.illusionIncoming,
        bounty_base = 0.0,
        outgoing_damage_structure = self.illusionOutgoing,
        outgoing_damage_roshan = self.illusionOutgoing
    }

    local enemies = FindUnitsInRadius(attacker:GetTeam(), attacker:GetAbsOrigin(), nil,
        attacker:Script_GetAttackRange()+100, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #enemies < 1 then return end

    local illusions = CreateIllusions(EntIndexToHScript(attacker:entindex()), attacker, modifierKeys, 1, 0, false, true)
    for _,illusion in ipairs(illusions) do
        illusion:AddNewModifier(owner, nil, "modifier_mirror_blade_illusion_modifier", {
            tEnt = victim:GetEntityIndex()
        })
        illusion:AddNewModifier(illusion, nil, "modifier_movement_speed_uba", { speed = 2000 })
        
        Timers:CreateTimer(self.illusionDuration, function()
            if not illusion or illusion:IsNull() or illusion == nil then return end
            if not illusion:IsAlive() then return end

            illusion:RemoveModifierByName("modifier_mirror_blade_illusion_modifier")
            if not illusion:IsNull() then
                UTIL_RemoveImmediate(illusion)
            end
        end)
    end

    self.canSummonMirror = false
    Timers:CreateTimer(self.cooldown, function()
        self.canSummonMirror = true
    end)
end

function modifier_mirror_blade:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
----------
function modifier_mirror_blade_illusion_modifier:DeclareFunctions()
    local funcs = {}
    return funcs
end

function modifier_mirror_blade_illusion_modifier:OnCreated(params)
    if not IsServer() then return end

    local attacker = self:GetParent()

    local caster = self:GetCaster() --owner

    -- Tome stuff because this isn't added normally --
    local tome_Agility = caster:FindModifierByName("tome_consumed_agi")
    local tome_Strength = caster:FindModifierByName("tome_consumed_str")
    local tome_Intellect = caster:FindModifierByName("tome_consumed_int")

    if tome_Agility ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Agility:GetAbility(), tome_Agility:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Agility:GetStackCount())
        end
    end

    if tome_Strength ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Strength:GetAbility(), tome_Strength:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Strength:GetStackCount())
        end
    end

    if tome_Intellect ~= nil then
        local _t = attacker:AddNewModifier(attacker, tome_Intellect:GetAbility(), tome_Intellect:GetName(), {})
        if _t ~= nil then
            _t:SetStackCount(tome_Intellect:GetStackCount())
        end
    end

    self.target = EntIndexToHScript(params.tEnt)

    Timers:CreateTimer(0.1, function()
        if self.target == nil then return end

        local position = self.target:GetAbsOrigin() - self.target:Script_GetAttackRange() * self.target:GetForwardVector()

        FindClearSpaceForUnit(attacker, position, false)
        attacker:SetForceAttackTarget(self.target)
    end)

    self:OnIntervalThink()
    self:StartIntervalThink(0.5)
end

function modifier_mirror_blade_illusion_modifier:OnIntervalThink()
    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_mirror_blade") then self:Destroy() return end

    local attacker = self:GetParent()

    if self.target ~= nil and not self.target:IsAlive() then
        UTIL_RemoveImmediate(attacker)
        self:StartIntervalThink(-1)
        return
    end
end

function modifier_mirror_blade_illusion_modifier:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    }

    return state
end

function modifier_mirror_blade_illusion_modifier:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_mirror_blade_illusion_modifier:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mirror_blade_illusion_modifier:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_mirror_blade_illusion_modifier:StatusEffectPriority()
    return 10001
end

function modifier_mirror_blade_illusion_modifier:OnDestroy()
    if not IsServer() then return end

    if not self:GetParent():IsNull() then
        UTIL_RemoveImmediate(self:GetParent())
    end
end