local ItemBaseClass = {
  IsPurgable = function(self) return false end,
  RemoveOnDeath = function(self) return false end,
  IsHidden = function(self) return true end,
  IsStackable = function(self) return false end,
}

item_enchanted_book = class(ItemBaseClass)

function item_enchanted_book:OnSpellStart()
  if not IsServer() then return end

  local caster = self:GetCaster()

  function canAbilityBeChanged(name)
    for _,ban in ipairs(BOOK_ABILITY_CHANGE_PROHIBITED) do
      if ban == name then return false end
    end

    return true
  end

  local abilities = {}

  for i=0, caster:GetAbilityCount()-1 do
      local abil = caster:GetAbilityByIndex(i)
      if abil ~= nil then
          --local isScepter = abil:GetAbilityKeyValues()["IsGrantedByScepter"]
          --local isShard = abil:GetAbilityKeyValues()["IsGrantedByShard"]

          --todo: make it so you can't replacy YOUR OWN innate aghs/shard skills, but can for other heroes.
          if canAbilityBeChanged(abil:GetAbilityName()) then
              table.insert(abilities, abil:GetAbilityName())
          end
      end
  end

  CustomNetTables:SetTableValue("ability_selection_open", "game_info", { abilities = abilities, userEntIndex = caster:GetEntityIndex(), r = RandomInt(1, 999), z = RandomInt(1, 999)})
  
  UTIL_Remove(self)
end