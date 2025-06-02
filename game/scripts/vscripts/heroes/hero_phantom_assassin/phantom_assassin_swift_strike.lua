LinkLuaModifier("modifier_phantom_assassin_swift_strike", "heroes/hero_phantom_assassin/phantom_assassin_swift_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phantom_assassin_swift_strike_attack_buff", "heroes/hero_phantom_assassin/phantom_assassin_swift_strike", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDoubleAttackClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

phantom_assassin_swift_strike = class(ItemBaseClass)
modifier_phantom_assassin_swift_strike = class(phantom_assassin_swift_strike)
modifier_phantom_assassin_swift_strike_attack_buff = class(ItemBaseDoubleAttackClass)
-------------
function modifier_phantom_assassin_swift_strike_attack_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }

    return funcs
end

function modifier_phantom_assassin_swift_strike_attack_buff:GetModifierAttackSpeed_Limit()
    return 1
end

function modifier_phantom_assassin_swift_strike_attack_buff:GetModifierAttackSpeedBonus_Constant()
    return 450
end

function phantom_assassin_swift_strike:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_swift_strike"
end

function modifier_phantom_assassin_swift_strike:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_phantom_assassin_swift_strike:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.hits = 0
end

function modifier_phantom_assassin_swift_strike:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    
    if self:GetCaster() ~= attacker then return end

    local ability = self:GetAbility()

    -- Echo proc works only on melee
    if UnitIsNotMonkeyClone(attacker) and attacker:IsRealHero() then
        self.hits = self.hits + 1
        if self.hits > ability:GetSpecialValueFor("max_attacks") then
            attacker:RemoveModifierByNameAndCaster("modifier_phantom_assassin_swift_strike_attack_buff", attacker)
            self.hits = 0
        end

        if not ability:IsCooldownReady() then return end

        -- We allow the hit count to work when cd is up but it won't ever apply the modifier
        attacker:AddNewModifier(attacker, ability, "modifier_phantom_assassin_swift_strike_attack_buff", {
            enemyEntIndex = victim:GetEntityIndex()
        })

        ability:UseResources(false, false, false, true)

        Timers:CreateTimer(ability:GetCooldownTimeRemaining(), function()
            -- Remove the modifier when the cooldown becomes ready again
            attacker:RemoveModifierByName("modifier_phantom_assassin_swift_strike_attack_buff")
            self.hits = 0
        end)
    end
end
