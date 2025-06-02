LinkLuaModifier("modifier_trigger_super_hypothermia", "super_hypothermia", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_trigger_super_hypothermia_debuff", "super_hypothermia", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

trigger_super_hypothermia = class(BaseClass)
modifier_trigger_super_hypothermia = class(trigger_super_hypothermia)
modifier_trigger_super_hypothermia_debuff = class(BaseClassDebuff)

function trigger_super_hypothermia:GetIntrinsicModifierName()
    return "modifier_trigger_super_hypothermia"
end

function OnStartTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if not player:HasModifier("modifier_trigger_super_hypothermia") then
        player:AddNewModifier(player, nil, "modifier_trigger_super_hypothermia", {})
    end
end

function OnEndTouch(ent)
    local player = ent.activator
    if player == nil then return end
    local owner = player:GetOwner()
    if not owner or owner == nil then return end
    if not owner:IsPlayerController() or not player:IsRealHero() then return end

    if player:HasModifier("modifier_trigger_super_hypothermia") then
        player:RemoveModifierByName("modifier_trigger_super_hypothermia")
    end
end
------------
function modifier_trigger_super_hypothermia:GetTexture()
     return "frostbite"
end

function modifier_trigger_super_hypothermia:DeclareFunctions()
     return {
         MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
         MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE   
     }
end

function modifier_trigger_super_hypothermia:GetModifierAttackSpeedPercentage()
     return -30
end

function modifier_trigger_super_hypothermia:GetModifierIncomingDamage_Percentage()
     return 15
end

function modifier_trigger_super_hypothermia:OnCreated()
     if not IsServer() then return end

     self:StartIntervalThink(5)
end

function modifier_trigger_super_hypothermia:OnIntervalThink()
     if not IsServer() then return end

     local parent = self:GetParent()
     if parent:HasModifier("modifier_chicken_ability_1_self_transmute") then return end

     if self:GetParent():HasModifier("modifier_item_warm_mint_tea_buff") then return end

     parent:AddNewModifier(parent, nil, "modifier_trigger_super_hypothermia_debuff", {
        duration = 3
     })

     EmitSoundOn("hero_Crystal.frostbite", parent)
end
----------
function modifier_trigger_super_hypothermia_debuff:GetEffectName()
     return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_trigger_super_hypothermia_debuff:CheckState()
     return {
        [MODIFIER_STATE_STUNNED] = true
     }
end

function modifier_trigger_super_hypothermia_debuff:GetTexture()
     return "frostbite"
end