local ItemBaseClass = {
  IsPurgable = function(self) return false end,
  RemoveOnDeath = function(self) return false end,
  IsHidden = function(self) return true end,
  IsStackable = function(self) return false end,
}

item_blessed_book = class(ItemBaseClass)



function item_blessed_book:OnSpellStart()
  if not IsServer() then return end

  local caster = self:GetCaster()

  if _G.PlayerAddedAbilityCount[caster:GetUnitName()] == nil then
      _G.PlayerAddedAbilityCount[caster:GetUnitName()] = 1
  else
      if _G.PlayerAddedAbilityCount[caster:GetUnitName()] >= 5 then DisplayError(caster:GetPlayerID(), "Max Abilities Reached") return end

      _G.PlayerAddedAbilityCount[caster:GetUnitName()] = _G.PlayerAddedAbilityCount[caster:GetUnitName()] + 1
  end

  local abilities = {}

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
    for _,ban in ipairs(BOOK_ABILITY_SELECTION_EXCEPTIONS) do
      if ban == name then return false end
    end

    return true
  end

  for i = 1, #BOOK_ABILITY_SELECTION, 1 do
      if isAbilityValid(BOOK_ABILITY_SELECTION[i]) and isAbilityAllowed(BOOK_ABILITY_SELECTION[i]) then
          table.insert(abilities, BOOK_ABILITY_SELECTION[i])
      end
  end

  local randomAbility = abilities[RandomInt(1, #abilities)]
  local newAbility = caster:AddAbility(randomAbility)
  print(randomAbility)

  if _G.PlayerStoredAbilities[caster:GetUnitName()] == nil then
    _G.PlayerStoredAbilities[caster:GetUnitName()] = {}
  end

  table.insert(_G.PlayerStoredAbilities[caster:GetUnitName()], newAbility:GetAbilityName())
  
  UTIL_Remove(self)
end