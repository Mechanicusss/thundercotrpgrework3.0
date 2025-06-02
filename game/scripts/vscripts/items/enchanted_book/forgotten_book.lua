local ItemBaseClass = {
  IsPurgable = function(self) return false end,
  RemoveOnDeath = function(self) return false end,
  IsHidden = function(self) return true end,
  IsStackable = function(self) return false end,
}

item_forgotten_book = class(ItemBaseClass)



function item_forgotten_book:OnSpellStart()
if not IsServer() then return end

local caster = self:GetCaster()
if IsSummonTCOTRPG(caster) then return end
if caster:GetUnitName() == "npc_dota_hero_invoker" then
  DisplayError(caster:GetPlayerID(), "This Hero Cannot Use This.")
  return
end

if _G.TowerActive then
  DisplayError(caster:GetPlayerID(), "Cannot Be Used In The Tower.")
  return
end

local accountID = PlayerResource:GetSteamAccountID(caster:GetPlayerID())
local allPlayerAbilities = GetPlayerAbilities(caster)

if _G.PlayerAddedAbilityCount[accountID] == nil then
    _G.PlayerAddedAbilityCount[accountID] = 1
else
    if (allPlayerAbilities ~= nil and #allPlayerAbilities >= 10) then DisplayError(caster:GetPlayerID(), "Limit Reached") return end

    _G.PlayerAddedAbilityCount[accountID] = _G.PlayerAddedAbilityCount[accountID] + 1
end

local abilities = {}

function canAbilityBeChanged(name)
  -- Merge these tables so you cant get abilities you cant change from random books
  for k,v in pairs(BOOK_ABILITY_CHANGE_PROHIBITED) do BOOK_ABILITY_CHANGE_PROHIBITED[k] = v end

  if caster:GetUnitName() == "npc_dota_hero_chen" then
    return false
  else
    for _,ban in ipairs(BOOK_ABILITY_CHANGE_PROHIBITED) do
      if ban == name then return false end
    end

    return true
  end
end

-- Make sure they dont get duplicates
function isAbilityValid(name)
  for i=0, caster:GetAbilityCount()-1 do
      local abil = caster:GetAbilityByIndex(i)
      if abil ~= nil then
        if abil:GetAbilityName() == name then 
          return false
        end
      end
  end

  return true
end

function isAbilityAllowed(name)
  local pass = true 

  for _,ban in ipairs(BOOK_ABILITY_SELECTION_EXCEPTIONS) do
    pass = true 

    if ban == name then
      pass = false
      break
    end
  end

  return pass
end

for i = 1, #BOOK_ABILITY_SELECTION, 1 do
    local name = BOOK_ABILITY_SELECTION[i]
    if isAbilityValid(name) and isAbilityAllowed(name) and canAbilityBeChanged(name) then
        table.insert(abilities, name)
    end
end

local randomAbility = abilities[RandomInt(1, #abilities)]
local newAbility = caster:AddAbility(randomAbility)

newAbility:SetHidden(false)

if _G.PlayerStoredAbilities[accountID] == nil then
  _G.PlayerStoredAbilities[accountID] = {}
end

if newAbility ~= nil then
  table.insert(_G.PlayerStoredAbilities[accountID], newAbility:GetAbilityName())
end

if self:GetCurrentCharges() > 1 then
    self:SetCurrentCharges(self:GetCurrentCharges()-1)
else
    caster:TakeItem(self)
end
end