LinkLuaModifier("modifier_trigger_hypothermia", "hypothermia", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return true end,
}

trigger_hypothermia = class(BaseClass)
modifier_trigger_hypothermia = class(trigger_hypothermia)

function trigger_hypothermia:GetIntrinsicModifierName()
    return "modifier_trigger_hypothermia"
end

function OnStartTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if not player:HasModifier("modifier_trigger_hypothermia") then
        player:AddNewModifier(player, nil, "modifier_trigger_hypothermia", {})
    end
end

function OnEndTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if player:HasModifier("modifier_trigger_hypothermia") then
        player:RemoveModifierByName("modifier_trigger_hypothermia")
    end
end
------------
function modifier_trigger_hypothermia:DeclareFunctions()
     return {
         MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
         MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE   
     }
end

function modifier_trigger_hypothermia:GetTexture()
     return "hypothermia"
end

function modifier_trigger_hypothermia:OnCreated()
     if not IsServer() then return end
end

function modifier_trigger_hypothermia:GetModifierAttackSpeedPercentage()
    if not self:GetParent():HasModifier("modifier_item_warm_mint_tea_buff") then
        return -30
    end
end

function modifier_trigger_hypothermia:GetModifierIncomingDamage_Percentage()
    if not self:GetParent():HasModifier("modifier_item_warm_mint_tea_buff") then
        return 15
    end
end

function modifier_trigger_hypothermia:GetEffectName()
     return "particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf"
end