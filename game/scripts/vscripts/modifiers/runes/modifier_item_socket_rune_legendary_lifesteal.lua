LinkLuaModifier("modifier_item_socket_rune_legendary_lifesteal", "modifiers/runes/modifier_item_socket_rune_legendary_lifesteal", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_lifesteal = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_lifesteal:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_item_socket_rune_legendary_lifesteal:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker or self:GetParent() == event.unit then
        return
    end

    local lifestealAmount = 30 * self:GetStackCount()

    if self:GetParent():GetHealthPercent() < 50 then
        lifestealAmount = lifestealAmount * 2
    end

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.unit:IsOther() or event.unit:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local pfx_name = "particles/items3_fx/octarine_core_lifesteal.vpcf"

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        pfx_name = "particles/generic_gameplay/generic_lifesteal.vpcf"
    end

    local particle = ParticleManager:CreateParticle(pfx_name, PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end