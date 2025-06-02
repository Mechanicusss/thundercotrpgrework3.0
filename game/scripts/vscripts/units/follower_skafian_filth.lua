LinkLuaModifier("modifier_follower_skafian_filth", "units/follower_skafian_filth", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_skafian_filth_debuff", "units/follower_skafian_filth", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

follower_skafian_filth = class(BaseClass)
modifier_follower_skafian_filth = class(follower_skafian_filth)
modifier_follower_skafian_filth_debuff = class(BaseClassDebuff)
-------------
function follower_skafian_filth:GetIntrinsicModifierName()
    return "modifier_follower_skafian_filth"
end

function modifier_follower_skafian_filth:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_follower_skafian_filth:OnCreated()
    if not IsServer() then return end
end

function modifier_follower_skafian_filth:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent ~= event.attacker then return end

    local victim = event.target
    if not victim:IsAlive() then return end

    local filth = victim:FindModifierByName("modifier_follower_skafian_filth_debuff")
    if filth ~= nil then 
        filth:ForceRefresh()
    else
        victim:AddNewModifier(parent, self:GetAbility(), "modifier_follower_skafian_filth_debuff", { duration = self:GetAbility():GetSpecialValueFor("duration"), slow = self:GetAbility():GetSpecialValueFor("slow_pct") })
    end
    
    
end
---------
function modifier_follower_skafian_filth_debuff:GetTexture()
    return "meepo_geostrike"
end

function modifier_follower_skafian_filth_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }
    return funcs
end

function modifier_follower_skafian_filth_debuff:OnCreated(props)
    if not IsServer() then return end

    --EmitSoundOn("Hero_Meepo.Geostrike", self:GetParent())
end

function modifier_follower_skafian_filth_debuff:OnRefresh(props)
    if not IsServer() then return end

    --EmitSoundOn("Hero_Meepo.Geostrike", self:GetParent())
end

function modifier_follower_skafian_filth_debuff:GetModifierMoveSpeedBonus_Percentage()
    if not IsServer() then return end

    if not self:GetCaster() then return end
    
    if not self:GetCaster():IsAlive() then return end

    return self:GetAbility():GetSpecialValueFor("slow_pct")
end

function modifier_follower_skafian_filth_debuff:GetHeroEffectName()
    return "particles/units/heroes/hero_meepo/meepo_geostrike.vpcf"
end