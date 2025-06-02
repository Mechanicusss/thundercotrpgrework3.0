LinkLuaModifier("modifier_xp_agility_talent_16", "abilities/talents/agility/xp_agility_talent_16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_16_aura", "abilities/talents/agility/xp_agility_talent_16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_16_aura_self", "abilities/talents/agility/xp_agility_talent_16", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_16_buff", "abilities/talents/agility/xp_agility_talent_16", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_16 = class(ItemBaseClass)
modifier_xp_agility_talent_16 = class(xp_agility_talent_16)
modifier_xp_agility_talent_16_aura = class(ItemBaseClassBuff)
modifier_xp_agility_talent_16_aura_self = class(ItemBaseClassBuff)
modifier_xp_agility_talent_16_buff = class(ItemBaseClassBuff)
-------------
function xp_agility_talent_16:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_16"
end
-------------
function modifier_xp_agility_talent_16:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_xp_agility_talent_16:OnIntervalThink()
    local parent = self:GetParent()

    if parent:IsRangedAttacker() then return end

    local mod = parent:FindModifierByName("modifier_xp_agility_talent_16_aura_self")

    if mod == nil or (mod ~= nil and mod:GetStackCount() <= 1) then
        if not parent:HasModifier("modifier_xp_agility_talent_16_buff") then
            parent:AddNewModifier(parent, nil, "modifier_xp_agility_talent_16_buff", {})
        end
    elseif mod ~= nil and mod:GetStackCount() > 0 then
        if parent:HasModifier("modifier_xp_agility_talent_16_buff") then
            parent:RemoveModifierByName("modifier_xp_agility_talent_16_buff")
        end
    end
end

function modifier_xp_agility_talent_16:OnDestroy()
end

function modifier_xp_agility_talent_16:IsAura()
    if self:GetCaster():IsIllusion() then return false end
    if self:GetCaster():IsRangedAttacker() then return false end
    return true
  end
  
  function modifier_xp_agility_talent_16:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
  end
  
  function modifier_xp_agility_talent_16:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
  end
  
  function modifier_xp_agility_talent_16:GetAuraRadius()
    return 300
  end
  
  function modifier_xp_agility_talent_16:GetModifierAura()
      return "modifier_xp_agility_talent_16_aura"
  end
  
  function modifier_xp_agility_talent_16:GetAuraSearchFlags()
    return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
  end
  
  function modifier_xp_agility_talent_16:GetAuraEntityReject(target)
      return false
  end
  ---------
  function modifier_xp_agility_talent_16_aura:OnCreated()
      if not IsServer() then return end
  
      local caster = self:GetCaster()
      local parent = self:GetParent()
  
      local buff = caster:FindModifierByName("modifier_xp_agility_talent_16_aura_self")
      if not buff then
          buff = caster:AddNewModifier(caster, nil, "modifier_xp_agility_talent_16_aura_self", {})
      end
  
      if buff then
          buff:IncrementStackCount()
      end
  end
  
  function modifier_xp_agility_talent_16_aura:OnDestroy()
      if not IsServer() then return end
  
      local caster = self:GetCaster()
      local parent = self:GetParent()
  
      local buff = caster:FindModifierByName("modifier_xp_agility_talent_16_aura_self")
      if buff then
          buff:DecrementStackCount()
          if buff:GetStackCount() < 1 then
              buff:Destroy()
          end
      end
  end
-------
function modifier_xp_agility_talent_16_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_xp_agility_talent_16_buff:GetModifierDamageOutgoing_Percentage()
    return 40
end