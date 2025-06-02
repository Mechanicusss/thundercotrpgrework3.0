LinkLuaModifier("modifier_item_sacrificial_cloak", "items/item_sacrificial_cloak/item_sacrificial_cloak", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_sacrificial_cloak = class(ItemBaseClass)
modifier_item_sacrificial_cloak = class(item_sacrificial_cloak)
-------------
function item_sacrificial_cloak:GetIntrinsicModifierName()
    return "modifier_item_sacrificial_cloak"
end
-------------
function modifier_item_sacrificial_cloak:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_sacrificial_cloak:OnCreated()
end

function modifier_item_sacrificial_cloak:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local target = event.unit 

    if target:GetTeam() == parent:GetTeam() then return end 

    local ability = self:GetAbility()

    if event.inflictor == ability then return end 

    -- Lifesteal
    if parent:FindAllModifiersByName(self:GetName())[1] == self and (event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL or event.damage_type == DAMAGE_TYPE_MAGICAL) and event.inflictor and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL and event.damage_flags ~= 1280 then
        local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
        ParticleManager:ReleaseParticleIndex(particle)

        if event.attacker:IsAlive() and event.attacker:GetHealth() > 0 then
            local lifestealCreep = ability:GetSpecialValueFor("lifesteal")
            local healAmount = math.max(event.damage, 0) * lifestealCreep * 0.01
            if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                healAmount = parent:GetMaxHealth()
            end
            event.attacker:Heal(healAmount, event.attacker)
        end
    end
end

function modifier_item_sacrificial_cloak:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    return self:GetAbility():GetSpecialValueFor("bonus_magical_damage_pct")
end

function modifier_item_sacrificial_cloak:OnAbilityExecuted(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    if event.target ~= nil then
        if event.target:GetTeam() == parent:GetTeam() then return end
    end

    if event.ability == nil then return end 

    if string.match(event.ability:GetAbilityName(), "item_") then return end

    local damage = parent:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("ability_max_health_cost_pct")/100)

    if damage >= parent:GetHealth() then return end

    ApplyDamage({
        attacker = parent,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
        ability = self:GetAbility()
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, parent, damage, nil)
end