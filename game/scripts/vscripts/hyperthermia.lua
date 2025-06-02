LinkLuaModifier("modifier_trigger_hyperthermia", "hyperthermia", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return true end,
}

trigger_hyperthermia = class(BaseClass)
modifier_trigger_hyperthermia = class(trigger_hyperthermia)

function trigger_hyperthermia:GetIntrinsicModifierName()
    return "modifier_trigger_hyperthermia"
end

function OnStartTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if not player:HasModifier("modifier_trigger_hyperthermia") then
        player:AddNewModifier(player, nil, "modifier_trigger_hyperthermia", {})
    end
end

function OnEndTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if player:HasModifier("modifier_trigger_hyperthermia") then
        player:RemoveModifierByName("modifier_trigger_hyperthermia")
    end
end
------------
function modifier_trigger_hyperthermia:DeclareFunctions()
     return {
         MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
     }
end

function modifier_trigger_hyperthermia:GetTexture()
     return "hyperthermia"
end

function modifier_trigger_hyperthermia:OnCreated()
     if not IsServer() then return end

     self:StartIntervalThink(3)
end

function modifier_trigger_hyperthermia:OnIntervalThink()
    if self:GetParent():HasModifier("modifier_item_refreshing_spring_water_buff") then return end

    local player = self:GetParent()

     ApplyDamage({
        attacker = player,
        victim = player,
        damage = player:GetMaxHealth() * 0.15,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
     })
end

function modifier_trigger_hyperthermia:GetModifierDamageOutgoing_Percentage()
    if not self:GetParent():HasModifier("modifier_item_refreshing_spring_water_buff") then
        return -40
    end
end

function modifier_trigger_hyperthermia:GetEffectName()
     return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ground_heat.vpcf"
end