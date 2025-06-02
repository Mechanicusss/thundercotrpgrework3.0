LinkLuaModifier("modifier_gold_bank", "modifiers/modifier_gold_bank", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

gold_bank = class(ItemBaseClass)
modifier_gold_bank = class(gold_bank)
-------------
function gold_bank:GetIntrinsicModifierName()
    return "modifier_gold_bank"
end

function modifier_gold_bank:OnCreated()
   if not IsServer() then return end

   local parent = self:GetParent()

   self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

   if _G.PlayerGoldBank[self.accountID] == nil then return end
   
   self:StartIntervalThink(FrameTime()) 
end

function modifier_gold_bank:OnIntervalThink()
    local parent = self:GetParent()
    local player = PlayerResource:GetPlayer(parent:GetPlayerID()):GetAssignedHero()

    if player:GetGold() < 99999 then
        local takeFromBank = 99999 - player:GetGold()

        if _G.PlayerGoldBank[self.accountID] < takeFromBank then
            takeFromBank = _G.PlayerGoldBank[self.accountID]
        end

        if takeFromBank < 0 then return end

        _G.PlayerGoldBank[self.accountID] = _G.PlayerGoldBank[self.accountID] - takeFromBank
        player:ModifyGold(takeFromBank, false, 98)

        CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
          userEntIndex = player:GetEntityIndex(),
          amount = _G.PlayerGoldBank[self.accountID],
          r = RandomInt(1, 999), 
          z = RandomInt(1, 999)
        })
    end
end