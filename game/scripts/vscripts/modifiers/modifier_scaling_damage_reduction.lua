LinkLuaModifier("modifier_scaling_damage_reduction", "modifiers/modifier_scaling_damage_reduction", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

scaling_damage_reduction = class(ItemBaseClass)
modifier_scaling_damage_reduction = class(scaling_damage_reduction)

-----------------
function scaling_damage_reduction:GetIntrinsicModifierName()
    return "modifier_scaling_damage_reduction"
end
-----------------
function modifier_scaling_damage_reduction:AddCustomTransmitterData()
    return
    {
        damageReduction = self.fDamageReduction,
    }
end

function modifier_scaling_damage_reduction:HandleCustomTransmitterData(data)
    if data.damageReduction ~= nil then
        self.fDamageReduction = tonumber(data.damageReduction)
    end
end

function modifier_scaling_damage_reduction:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.timeAmount = 0

    self:StartIntervalThink(1)

    self.damageReduction = -(100-self:CalculateDamageReduction(1, 1)*100)

    self:InvokeDamageReduction()
end

function modifier_scaling_damage_reduction:CalculateDamageReduction(base, time)
  local stacks = (1 - (base/100))

  for i = 1, time, 1 do
      stacks = stacks * ((1 - (base/100)))
  end

  stacks = 1 - (1 - stacks)

  return stacks
end

function modifier_scaling_damage_reduction:OnIntervalThink()
    --self.timeAmount = self.timeAmount + 1

    --local time = self.timeAmount + (NEW_GAME_PLUS_DAMAGE_REDUCTION_SCALING_ADDITION*_G.NewGamePlusCounter)
    --local gameTime = time / 60
    local gameTime = math.floor(GameRules:GetGameTime() / 60)
    self.timeAmount = gameTime

    local time = self.timeAmount + (NEW_GAME_PLUS_DAMAGE_REDUCTION_SCALING_ADDITION*_G.NewGamePlusCounter)

    self.damageReduction = -(100-self:CalculateDamageReduction(DIFFICULTY_HARDCORE_SCALING_REDUCTION_CONSTANT, time)*100)
    self:InvokeDamageReduction()
end

function modifier_scaling_damage_reduction:OnRemoved()
    self.damageReduction = 0

    self:InvokeDamageReduction()
end

function modifier_scaling_damage_reduction:InvokeDamageReduction()
    if IsServer() == true then
        self.fDamageReduction = self.damageReduction

        self:SendBuffRefreshToClients()
    end
end

function modifier_scaling_damage_reduction:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP,
    }

    return funcs
end

function modifier_scaling_damage_reduction:GetModifierIncomingDamage_Percentage()
    return self.fDamageReduction
end

function modifier_scaling_damage_reduction:OnTooltip()
    return self.fDamageReduction
end

function modifier_scaling_damage_reduction:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_scaling_damage_reduction:GetTexture()
    return "blinkd"
end