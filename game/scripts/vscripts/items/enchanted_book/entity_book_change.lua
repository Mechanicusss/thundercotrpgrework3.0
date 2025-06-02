local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_entity_book_change = class(ItemBaseClass)

function item_entity_book_change:OnSpellStart()
    
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
    local abilities = {}

    for _,ability in ipairs(_G.PlayerStoredAbilities[accountID]) do
        table.insert(abilities, ability)
    end

    CustomNetTables:SetTableValue("ability_selection_open", "game_info", { abilities = abilities, userEntIndex = caster:GetEntityIndex(), r = RandomInt(1, 999), z = RandomInt(1, 999)})
    
    if self:GetCurrentCharges() > 1 then
        self:SetCurrentCharges(self:GetCurrentCharges()-1)
    else
        caster:TakeItem(self)
    end
end