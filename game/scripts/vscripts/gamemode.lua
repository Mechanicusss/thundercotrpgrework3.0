-- This is the primary barebones gamemode script and should be used to assist in initializing your game mode
BAREBONES_VERSION = "2.0.16"

-- Selection library (by Noya) provides player selection inspection and management from server lua
require('libraries/selection')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')
-- filters.lua
require('filters')

require("util/shared")
require("util/other")
require("util/table")
require("util/debug")
require("util/string")
require("util/ability")
require("util/modifier")
require("util/item")
require("util/units")
require("util/playerresource")
require("util/math")
require("modules/dynamic_wearables/dynamic_wearables")
require("modules/neutrals/neutral_slot")
require("modules/greedy_goblin/goblin")
require("data/modifiers")
require("spawnunits")


require("modules/waves/main")
require("modules/effects/PlayerEffects")

require("bosses/skafian")
require("bosses/zombie")
require("bosses/spider")
require("bosses/mine")
require("bosses/lava")
require("bosses/lake")
require("bosses/divine")

require("modules/rune_manager/RuneManager")
--require("modules/talent_manager/TalentManager")
require("modules/wave_manager/WaveManager")
require("modules/xp_manager/XpManager")
require("modules/dps_manager/dpsmanager")
require("modules/player_buffs/PlayerBuffs")
require("heroes/bosses/destruction_lord/ai")
require("capture_point")

--//--


--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]


-- Подписываемся на событие покупки предмета
ListenToGameEvent("dota_item_purchased", OnItemPurchased, nil)
function barebones:PostLoadPrecache()
	DebugPrint("[BAREBONES] Performing Post-Load precache.")
	--PrecacheItemByNameAsync("item_example_item", function(...) end)
	--PrecacheItemByNameAsync("example_ability", function(...) end)

	--PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
	--PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
end

function barebones:LoadDonators()
  local req = CreateHTTPRequestScriptVM("GET", SERVER_URI.."/verifieradonation")

  req:Send(function(res)
      if not res.StatusCode == 201 then
          print("Failed to send data to server for donators, error: " .. res.StatusCode)
          return
      end

      if res.StatusCode == 201 then
          print("[Donators] Retrieved Donator Data")

          local data = json.decode(res.Body)

          for _,body in pairs(data) do
            table.insert(PLAYER_DONATOR_LIST, body.steam)
          end
      end
  end)
end
--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function barebones:OnAllPlayersLoaded()
  -- Force Random a hero for every player that didnt pick a hero when time runs out
  local delay = HERO_SELECTION_TIME + HERO_SELECTION_PENALTY_TIME + STRATEGY_TIME - 0.1
  if ENABLE_BANNING_PHASE then
    delay = delay + BANNING_PHASE_TIME
  end
  Timers:CreateTimer(delay, function()
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
      if PlayerResource:IsValidPlayerID(playerID) then
        -- If this player still hasn't picked a hero, random one
        -- PlayerResource:IsConnected(index) is custom-made! Can be found in 'player_resource.lua' library
        if not PlayerResource:HasSelectedHero(playerID) and PlayerResource:IsConnected(playerID) and not PlayerResource:IsBroadcaster(playerID) then
          PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection() -- this will cause an error if player is disconnected, that's why we check if player is connected
          PlayerResource:SetHasRandomed(playerID)
          PlayerResource:SetCanRepick(playerID, false)
          DebugPrint("[BAREBONES] Randomed a hero for a player number "..playerID)
        end
      end
    end
  end)

  -- Load donators 
  self:LoadDonators()


  -- Load attribute talents
  XpManager:Init()

  -- Load DPS meter
  DpsManager:Init()



  ----
  if tablelength(KILL_VOTE_RESULT) <= 0 then
    KILL_VOTE_RESULT = {tostring(KILL_VOTE_DEFAULT)} 
  end

  local killCountToEnd = maxFreq(KILL_VOTE_RESULT, tablelength(KILL_VOTE_RESULT), KILL_VOTE_DEFAULT)
  KILL_VOTE_RESULT = killCountToEnd

  --

  if tablelength(WAVE_VOTE_RESULT) <= 0 then
    WAVE_VOTE_RESULT = {tostring(WAVE_VOTE_DEFAULT)} 
  end

  local waveVote = maxFreq(WAVE_VOTE_RESULT, tablelength(WAVE_VOTE_RESULT), WAVE_VOTE_DEFAULT)
  --WAVE_VOTE_RESULT = waveVote
  WAVE_VOTE_RESULT = "DISABLE"

  --if KILL_VOTE_RESULT:upper() == "HARDCORE" then
    --WAVE_VOTE_RESULT = "ENABLE"
  --end

  local effectVote = maxFreq(EFFECT_VOTE_RESULT, tablelength(EFFECT_VOTE_RESULT), EFFECT_VOTE_DEFAULT)
  EFFECT_VOTE_RESULT = effectVote

  if KILL_VOTE_RESULT:upper() == "HARDCORE" or KILL_VOTE_RESULT:upper() == "HELL" or KILL_VOTE_RESULT:upper() == "IMPOSSIBLE" then
    EFFECT_VOTE_RESULT = "ENABLE"
  end

  if KILL_VOTE_RESULT:upper() == "HARDCORE" then
    local gamemode = GameRules:GetGameModeEntity()
    gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN, 0.05)
    gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0.0125)
    gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 0.075)
    gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA, 3)
    gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 10)
  end

  if WAVE_VOTE_RESULT == "DISABLE" then
    CustomGameEventManager:Send_ServerToAllClients("waves_disable", {})
  end

  ---
  if tablelength(FAST_BOSSES_VOTE_RESULT) <= 0 then
    FAST_BOSSES_VOTE_RESULT = {tostring(FAST_BOSSES_VOTE_DEFAULT)} 
  end

  local fastBossesVote = maxFreq(FAST_BOSSES_VOTE_RESULT, tablelength(FAST_BOSSES_VOTE_RESULT), FAST_BOSSES_VOTE_DEFAULT)
  FAST_BOSSES_VOTE_RESULT = fastBossesVote

  ---
  if tablelength(GOLD_VOTE_RESULT) <= 0 then
    GOLD_VOTE_RESULT = {tostring(GOLD_VOTE_DEFAULT)} 
  end

  local goldVote = maxFreq(GOLD_VOTE_RESULT, tablelength(GOLD_VOTE_RESULT), GOLD_VOTE_DEFAULT)
  GOLD_VOTE_RESULT = goldVote
  ---
  if tablelength(EXP_VOTE_RESULT) <= 0 then
    EXP_VOTE_RESULT = {tostring(GOLD_VOTE_DEFAULT)} 
  end

  local expVote = maxFreq(EXP_VOTE_RESULT, tablelength(EXP_VOTE_RESULT), EXP_VOTE_DEFAULT)
  EXP_VOTE_RESULT = expVote

  ---
  local enableEffects = EFFECT_VOTE_RESULT:upper() == "ENABLE"
  local t = {}
  local mode = KILL_VOTE_RESULT:upper()

  if enableEffects then
    SetBoonsAndBuffs(mode)
  end

  -- Print Chat Info --
  Timers:CreateTimer(1.0, function()
    if KILL_VOTE_RESULT:upper() == "EASY" or KILL_VOTE_RESULT:upper() == "NORMAL" then
      GameRules:SendCustomMessage("<font color='yellow'>=== DIFFICULTY [<b color='lightgreen'>"..KILL_VOTE_RESULT:upper().."</b>] ===</font>", 0, 0)
    else
      GameRules:SendCustomMessage("<font color='yellow'>=== DIFFICULTY [<b color='red'>"..KILL_VOTE_RESULT:upper().."</b>] ===</font>", 0, 0)
    end

    --if WAVE_VOTE_RESULT == "ENABLE" then
    --  GameRules:SendCustomMessage("<font color='yellow'>=== ENEMY FORCES [<b color='lightgreen'>ENABLED</b>] ===</font>", 0, 0)
    --else
    --  GameRules:SendCustomMessage("<font color='yellow'>=== ENEMY FORCES [<b color='red'>DISABLED</b>] ===</font>", 0, 0)
    --end

    if FAST_BOSSES_VOTE_RESULT == "ENABLE" then
      GameRules:SendCustomMessage("<font color='yellow'>=== INSTANT RESPAWN [<b color='lightgreen'>ENABLED</b>] ===</font>", 0, 0)
    else
      GameRules:SendCustomMessage("<font color='yellow'>=== INSTANT RESPAWN [<b color='red'>DISABLED</b>] ===</font>", 0, 0)
    end

    if GOLD_VOTE_RESULT == "ENABLE" then
      GameRules:SendCustomMessage("<font color='yellow'>=== DOUBLE GOLD [<b color='lightgreen'>ENABLED</b>] ===</font>", 0, 0)
    else
      GameRules:SendCustomMessage("<font color='yellow'>=== DOUBLE GOLD [<b color='red'>DISABLED</b>] ===</font>", 0, 0)
    end

    if EXP_VOTE_RESULT == "ENABLE" then
      GameRules:SendCustomMessage("<font color='yellow'>=== DOUBLE XP [<b color='lightgreen'>ENABLED</b>] ===</font>", 0, 0)
    else
      GameRules:SendCustomMessage("<font color='yellow'>=== DOUBLE XP [<b color='red'>DISABLED</b>] ===</font>", 0, 0)
    end

    if enableEffects then
      if #PLAYER_ALL_BOONS > 0 then
        GameRules:SendCustomMessageToTeam("<font color='lightgreen'>=== PLAYER EFFECTS THIS GAME ===</font>", DOTA_TEAM_GOODGUYS, 0, 0)
        for _,temp in ipairs(_G.DifficultyChatTablePlayers) do
          GameRules:SendCustomMessageToTeam("#DOTA_Tooltip_"..temp, DOTA_TEAM_GOODGUYS, 0, 0)
        end
      end

      if #DifficultyChatTableEnemies > 0 then
        GameRules:SendCustomMessageToTeam("<font color='red'><b>[EMPOWERED ENEMY BUFFS]</b></font>", DOTA_TEAM_GOODGUYS, 0, 0)
        for _,temp in ipairs(_G.DifficultyChatTableEnemies) do
          GameRules:SendCustomMessageToTeam("#DOTA_Tooltip_"..temp, DOTA_TEAM_GOODGUYS, 0, 0)
          --GameRules:SendCustomMessageToTeam("#DOTA_Tooltip_"..temp.."_Description", DOTA_TEAM_GOODGUYS, 0, 0)
        end
      end
    else
      GameRules:SendCustomMessage("<font color='yellow'>=== MODIFIERS [<b color='red'>DISABLED</b>] ===</font>", 0, 0)
    end
  end)
  --//--
  Timers:CreateTimer(1.5, function()
    SpawnAllUnits()
  end)
end

function barebones:OnFirstPlayerLoaded()
  CustomGameEventManager:RegisterListener("wave_manager_request_leaderboard_data", function(userId, event)
      local id = event.PlayerID
      local player = PlayerResource:GetPlayer(id)

      if not player or player == nil or player:IsNull() then return end

      local req = CreateHTTPRequestScriptVM("GET", SERVER_URI.."/hamtaalla")

      req:Send(function(res)
          if not res.StatusCode == 201 then
              print("Failed to send data to server for leaderboard, error: " .. res.StatusCode)
              return
          end

          if res.StatusCode == 201 then
              print("[Leaderboard] Retrieved Leaderboard Data")

              CustomGameEventManager:Send_ServerToPlayer(player, "wave_manager_request_leaderboard_data_complete", {
                  leaderboard = res.Body,
                  a = RandomFloat(1,1000),
                  b = RandomFloat(1,1000),
                  c = RandomFloat(1,1000),
              })
          end
      end)
  end)

  CustomGameEventManager:RegisterListener("killvote", function(userId, event)
    -- This is chosen by host now so we can truncate the table to make it possible for them to re-select
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      KILL_VOTE_RESULT = {}
      table.insert(KILL_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("wavevote", function(userId, event)
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      WAVE_VOTE_RESULT = {}
      table.insert(WAVE_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("effectvote", function(userId, event)
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      EFFECT_VOTE_RESULT = {}
      table.insert(EFFECT_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("fastbossesvote", function(userId, event)
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      FAST_BOSSES_VOTE_RESULT = {}
      table.insert(FAST_BOSSES_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("goldvote", function(userId, event)
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      GOLD_VOTE_RESULT = {}
      table.insert(GOLD_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("expvote", function(userId, event)
    local accountID = PlayerResource:GetSteamAccountID(event.user)
    if _G.PlayerIsHost[accountID] then
      EXP_VOTE_RESULT = {}
      table.insert(EXP_VOTE_RESULT, tostring(event.option):upper())
    end
  end)

  CustomGameEventManager:RegisterListener("auto_pickup", function(userId, event)
    local state = tostring(event.option)

    if state == "on" then
      _G.autoPickup[event.playerID] = AUTOLOOT_ON
    elseif state == "off" then
      _G.autoPickup[event.playerID] = AUTOLOOT_OFF
    else
      _G.autoPickup[event.playerID] = AUTOLOOT_ON_NO_SOULS
    end
  end)

  CustomGameEventManager:RegisterListener("ability_selection_change", function(userId, event)
    local ability = event.ability
    local player = EntIndexToHScript(event.user)

    local abilitySelection = {}

    -- Makes sure the ability is valid (not scepter, shard, or linked) and 
    -- that it's not an ability the player already has.
    --todo: find a way to check if it's shrd or aghs and then remove it from the table...
    function isAbilityValid(name)
      for i=0, player:GetAbilityCount()-1 do
          local abil = player:GetAbilityByIndex(i)
          if abil ~= nil then
            if abil:GetAbilityName() == name then 
              return false
            end
          end
      end

      return true
    end

    -- Makes sure the player can't get shown an ability they're not supposed to get
    function isAbilityBanned(name)
      if player:GetUnitName() == "npc_dota_hero_chen" then
        return false
      else
        for _,ban in ipairs(BOOK_ABILITY_SELECTION_EXCEPTIONS) do
          if ban == name then return true end
        end

        return false
      end
    end

    -- Can the ability be changed again once obtained?
    function canAbilityBeChanged(name)
      -- Merge these tables so you cant get abilities you cant change from random books
      for k,v in pairs(BOOK_ABILITY_CHANGE_PROHIBITED) do BOOK_ABILITY_CHANGE_PROHIBITED[k] = v end

      if player:GetUnitName() == "npc_dota_hero_chen" then
        return false
      else
        for _,ban in ipairs(BOOK_ABILITY_CHANGE_PROHIBITED) do
          if ban == name then return false end
        end

        return true
      end
    end

    -- Remove all non-valid abilities from the selection list
    for i = 1, #BOOK_ABILITY_SELECTION, 1 do 
      if isAbilityValid(BOOK_ABILITY_SELECTION[i]) and not isAbilityBanned(BOOK_ABILITY_SELECTION[i]) then
        table.insert(abilitySelection, BOOK_ABILITY_SELECTION[i])
      end
    end


    -- Random the selection out of the available abilities
    local randomSelection = {}

    --_G.PlayerBookRandomAbilities[player:GetPlayerID()] = nil

    local tempAbilitySelection = abilitySelection
    for i = 1, #abilitySelection, 1 do
      --local randomIndex = RandomInt(1, #tempAbilitySelection)
      local newRandomAbility = tempAbilitySelection[i]
      table.insert(randomSelection, newRandomAbility)

      tempAbilitySelection[i] = nil -- Remove it so we dont get dupes
    end

    -- Add the names of the abilities that can be changed into a new table
    local changableAbilities = {}
    for i = 1, #randomSelection, 1 do 
      if canAbilityBeChanged(randomSelection[i]) then
        table.insert(changableAbilities, randomSelection[i])
      end
    end


    local accountID = PlayerResource:GetSteamAccountID(player:GetPlayerID())
    _G.PlayerBookRandomAbilities[accountID] = randomSelection

    --todo: filterto make sure you can't get abilities you already have
    --also: make sure you can't get excluded abilities (make new table to define what those are)
    --remove the abilities the player has from this temp table (including new ones they get with the books)
    --random the 4 abilities in lua and send the names to the client. and when the client sends back the picks, validate 
    --them to make sure its an ability that's one of the 4 the server sent (use global user variable?)
    CustomNetTables:SetTableValue("ability_selection_open_replace", "game_info", { 
      oldAbility = ability, 
      userEntIndex = event.user, 
      abilities = abilitySelection, 
      selection = randomSelection,
      changableAbilities = changableAbilities,
      a = RandomFloat(1, 1000),
      b = RandomFloat(1, 1000),
      c = RandomFloat(1, 1000),
    })
  end)

  CustomGameEventManager:RegisterListener("ability_selection_change_final", function(userId, event)
    local oldAbility = event.oldAbility
    local ability = event.ability
    local player = EntIndexToHScript(event.user)

    --todo:
    --make sure abilities you replace aren't aghs or shard.
    --make sure the new abilities you can choose from aren't aghs and shard, or useless stuff like icarus dive cancel.

    function isSelectionValid(name)
      local accountID = PlayerResource:GetSteamAccountID(player:GetPlayerID())
      if _G.PlayerBookRandomAbilities[accountID] == nil then return false end

      for i = 1, #_G.PlayerBookRandomAbilities[accountID], 1 do
        local valid = _G.PlayerBookRandomAbilities[accountID][i]
        if valid == name then return true end
      end

      return false
    end

    if not isSelectionValid(ability) then DisplayError(player:GetPlayerID(), "Invalid Ability Selected") return end

    local accountID = PlayerResource:GetSteamAccountID(player:GetPlayerID())

    if _G.PlayerStoredAbilities[accountID] == nil then
      _G.PlayerStoredAbilities[accountID] = {}
    end

    table.insert(_G.PlayerStoredAbilities[accountID], ability)

    for i = 1, #_G.PlayerStoredAbilities[accountID], 1 do
      if _G.PlayerStoredAbilities[accountID][i] == oldAbility then
        table.remove(_G.PlayerStoredAbilities[accountID], i)
      end
    end

    -- Check so that the old ability exists
    -- Important to prevent infinite ability abuse
    local hOldAbility = player:FindAbilityByName(oldAbility)
    if hOldAbility == nil then 
      DisplayError(player:GetPlayerID(), "Ability Does Not Exist")
      return
    end

    -- Get the old ability points which we refund later
    local oldAbilityPoints = hOldAbility:GetLevel()
    
    -- Un-toggle all toggled abilities or they will persist after removal
    if hOldAbility ~= nil and hOldAbility:GetToggleState() then
      hOldAbility:ToggleAbility()
    end

    --player:SwapAbilities(oldAbility, ability, false, true)
    player:RemoveAbilityByHandle(hOldAbility)
    player:RemoveAbility(oldAbility)

    -- Check their abilities after removing the old one 
    -- If they're abusing shit they will still have too many
    -- We check if it's more than 9 since 10 is the max. 10 - 1 (the one just removed)
    local currentAbilities = GetPlayerAbilities(player)
    if #currentAbilities < 1 or #currentAbilities > 9 then DisplayError(player:GetPlayerID(), "Exceeded Max Ability Limit") return end

    -- Add the new ability and unhide it in case it's a scepter/shard ability
    local newlySelectedAbility = player:AddAbility(ability)
    newlySelectedAbility:SetHidden(false)

    -- Refund ability points
    player:SetAbilityPoints(player:GetAbilityPoints()+oldAbilityPoints)
  end)

  CustomGameEventManager:RegisterListener("ability_selection_swap_position_final", function(userId, event)
    local ability = event.ability
    local player = EntIndexToHScript(event.user)

    CustomNetTables:SetTableValue("ability_selection_swap_position_replace", "game_info", { oldAbility = ability, userEntIndex = event.user })
  end)

  CustomGameEventManager:RegisterListener("ability_selection_swap_position_final_complete", function(userId, event)
    local oldAbility = event.oldAbility
    local ability = event.ability
    local player = EntIndexToHScript(event.user)

    --todo:
    --make sure abilities you replace aren't aghs or shard.
    --make sure the new abilities you can choose from aren't aghs and shard, or useless stuff like icarus dive cancel.

    player:SwapAbilities(oldAbility, ability, true, true)
  end)

  CustomGameEventManager:RegisterListener("select_custom_hero", function(userId, event)
    local player = EntIndexToHScript(event.user)

    SwapHeroWithTCOTRPG(player, event.hero, event.dummy)
    
    CustomNetTables:SetTableValue("select_custom_hero", "game_info", {
      userEntIndex = event.user
    })
  end)

  -- For New Game+ --
  CustomGameEventManager:RegisterListener("new_game_plus_vote", function(userId, event)
    local player = EntIndexToHScript(event.user)

    local steam = tostring(event.steamId)
    local vote = tostring(event.vote)

    table.insert(NEW_GAME_PLUS_VOTE_RESULT, vote)
    
    CustomNetTables:SetTableValue("new_game_plus_voted", "game_info", {
      userEntIndex = event.user,
      vote = vote,
      steam = steam,
      a = RandomInt(1,10000),
      b = RandomInt(1,10000),
      c = RandomInt(1,10000),
    })
  end)

  CustomGameEventManager:RegisterListener("new_game_plus_vote_complete", function(userId, event)
    local steam = tostring(event.steamId)

    if type(NEW_GAME_PLUS_VOTE_RESULT) == "table" then
      if #NEW_GAME_PLUS_VOTE_RESULT <= 0 then
        NEW_GAME_PLUS_VOTE_RESULT = {tostring(NEW_GAME_PLUS_VOTE_DEFAULT)} 
      end
    else
      NEW_GAME_PLUS_VOTE_RESULT = {tostring(NEW_GAME_PLUS_VOTE_RESULT)} 
    end

    local newGamePlusVote = maxFreq(NEW_GAME_PLUS_VOTE_RESULT, tablelength(NEW_GAME_PLUS_VOTE_RESULT), NEW_GAME_PLUS_VOTE_DEFAULT)
    NEW_GAME_PLUS_VOTE_RESULT = newGamePlusVote

    CustomNetTables:SetTableValue("new_game_plus_vote_finished", "game_info", {
      userEntIndex = event.user,
      steam = steam,
      a = RandomInt(1,10000),
      b = RandomInt(1,10000),
      c = RandomInt(1,10000),
    })

    if NEW_GAME_PLUS_VOTE_RESULT == "1" then
      --[[
        --0. multiply armor, damage and magic res. 
        --1. respawn all mobs with correct stats and modifiers somehow + Reset outposts
        --2. Reset certain global variables
        --3. remove items (including aghs and shard)
        --4. enable modifiers, add additional modifiers to bosses
        --5. Give some tomes based on NW, and give extra life if playing on harder diff
      ]]--
      _G.NewGamePlusCounter = _G.NewGamePlusCounter + 1

      -- Activate modifiers 
      EFFECT_VOTE_RESULT = "ENABLE"
      local mode = KILL_VOTE_RESULT:upper()

      if #_G.DifficultyEnemyBuffs < 1 or _G.DifficultyEnemyBuffs == nil then
        print("[New Game Plus] No enemy modifiers detected, creating...")
        SetBoonsAndBuffs(mode)
      end

      -- Boss modifiers 
      local t = ENEMY_ALL_BUFFS
      local limit = 1 -- Should be 1. Old modifiers aren't removed from enemies so we should not increase this every time.
      _G.NewGamePlusBonusBossEffects = {}

      -- Go through the buff table and remove duplicates
      for i,tt in ipairs(t) do
        if tt == _G.NewGamePlusBonusBossEffects[i] then
          table.remove(t, i)
        end
      end

      -- Add another modifier
      for i = 1,limit,1 do
        local index = RandomInt(1, #t)
        table.insert(_G.NewGamePlusBonusBossEffects, t[index])
      end

      -- Reload enemy modifiers and stats
      CustomNetTables:SetTableValue("new_game_plus_vote_reload_enemies", "game_info", {
        newGamePlus = "1",
        a = RandomInt(1,10000),
        b = RandomInt(1,10000),
        c = RandomInt(1,10000),
      })

      -- Reset certain global variables
      _G.SummonedZeusDeaths = 0
      _G.ItemDroppedAsanBlade1 = false
      _G.ItemDroppedAsanBlade2 = false
      _G.ItemDroppedAsanBlade3 = false
      _G.ItemDroppedMeteoriteSword = false
      _G.ItemDroppedFrozenCrystal = false
      _G.ItemDroppedAkashaConversion = false
      _G.ItemDroppedCarlConversion = false
      _G.ItemDroppedEnrageCrystal = false

      -- Clear hero inventories, set lives, etc.
      ResetHeroes()
      
      if (_G.NewGamePlusCounter == 1 or _G.HephaestusKilled) and _G.HephaestusKilledInitially then
        boss_hephaestus:Spawn("boss_hephaestus")
      end

      -- We're Done
      local resetTime = 5
      Timers:CreateTimer(resetTime, function()
        _G.AghanimsProcEnd = false

        CustomNetTables:SetTableValue("new_game_plus_vote_reload_enemies", "game_info", {
            newGamePlus = "0",
            a = RandomInt(1,10000),
            b = RandomInt(1,10000),
            c = RandomInt(1,10000),
        })
      end)
    elseif NEW_GAME_PLUS_VOTE_RESULT == "0" then
      GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
    end
  end)
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function barebones:OnGameInProgress()
	--[[if not _G.DebugEnabled and (not IsDedicatedServer() or GameRules:IsCheatMode()) then
    GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
    GameRules:SendCustomMessage("<font color='red'>Game cannot be played on a local server or with cheats enabled. Please restart the game with a dedicated server without cheats.</font>", 0, 0)
    return
    --- do not let them in
  end
  --]]
  PlayerBuffs:Init()



  
  CustomGameEventManager:Send_ServerToAllClients("duel_timer_changed", { isDuelActive = KILL_VOTE_RESULT:upper() })

  Timers:CreateTimer(5.0, function()
    CustomGameEventManager:Send_ServerToAllClients("duel_timer_changed", { isDuelActive = KILL_VOTE_RESULT:upper() })
    return 5.0
  end)


  Timers:CreateTimer(0.5, function()
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
      if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() then
        _G.PerformanceHeroesTable[hero:entindex()] = _G.PerformanceHeroesTable[hero:entindex()] or nil

        if hero:IsAlive() then
          _G.PerformanceHeroesTable[hero:entindex()] = hero:GetAbsOrigin()
        else
          _G.PerformanceHeroesTable[hero:entindex()] = nil
        end
      end
    end

    
    for _,unit in pairs(_G.PerformanceUnitsTable) do
      if unit ~= nil and type(unit) == "table" and type(unit) ~= "none" and type(unit) ~= "nil" and not unit:IsNull() then
        if not unit:HasModifier("modifier_wave_manager_unit_ai") then
          local shouldHide = true
          local unitOrigin = unit:GetAbsOrigin()

          for _,heroPos in pairs(_G.PerformanceHeroesTable) do
            if heroPos ~= nil then
              if ((unitOrigin - heroPos):Length2D() < 2100) then
                shouldHide = false
              end
            end
          end

          if shouldHide then
            unit:AddNewModifier(unit, nil, "modifier_creep_antilag_phased", {})
          else
            unit:RemoveModifierByName("modifier_creep_antilag_phased")
          end
        end
      end
    end

    return 0.5
  end)

  Timers:CreateTimer(2.0, function() 
    if IsPvP() then
      capture_point:Init()
    end

    Timers:CreateTimer(1.0, function()
      Timers:CreateTimer(2.0, function()
        _G.PlayerList = GetSteamIDPlayerList()
      end)

      boss_destruction_lord:Spawn("boss_destruction_lord")

      -- Aghanim's Portal
      local aghanimPortalSpawnPoint = Entities:FindByName(nil, "trigger_entrance_aghanim")
      if aghanimPortalSpawnPoint ~= nil then
        _G.AghanimGateUnit = CreateUnitByName("outpost_placeholder_unit", aghanimPortalSpawnPoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
        _G.AghanimGateUnit:AddNewModifier(_G.AghanimGateUnit, nil, "modifier_aghanim_portal", {})
      end

      -- CHICKEN 
      local chickenUnitSpawnPoint = Entities:FindByName(nil, "secret_hero_chicken_spawn")
      if chickenUnitSpawnPoint ~= nil then
        local chicken = CreateUnitByName("npc_dota_tcotrpg_unit_chicken", chickenUnitSpawnPoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
        chicken:AddNewModifier(chicken, nil, "modifier_chicken", {})
      end

      -- TIMMY 
      local timmyUnitSpawnPoint = Entities:FindByName(nil, "trigger_timmy_spawn")
      if timmyUnitSpawnPoint ~= nil then
        local timmy = CreateUnitByName("npc_dota_tcotrpg_unit_timmy", timmyUnitSpawnPoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
        timmy:AddNewModifier(timmy, nil, "modifier_timmy", {})
      end
      
      -- Asan special drop --
      local asanSpecialDrop = Entities:FindByName(nil, "trigger_asan_part_drop")
      if asanSpecialDrop ~= nil and not _G.ItemDroppedAsanBlade1 then
        local asanBlade1 = CreateItem("item_asan_dagger_1", nil, nil)
        if asanBlade1 ~= nil then
          asanBlade1:SetStacksWithOtherOwners(true)
          CreateItemOnPositionForLaunch(asanSpecialDrop:GetAbsOrigin(), asanBlade1)
          _G.ItemDroppedAsanBlade1 = true
        end
      end
      --

      -- Spawn zone
      local spawnEmitter = Entities:FindByName(nil, "starting_zone_emitter")
      if spawnEmitter ~= nil then
        CreateUnitByNameAsync("outpost_placeholder_unit", spawnEmitter:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS, function(unit)
          unit:AddNewModifier(unit, nil, "modifier_spawn_healing", {})
        end)
      end
      --

      -- Aghanim Crystals --
      local crystalEnts = Entities:FindAllByName("spawn_aghanim_crystal")
      for _,crystalEnt in ipairs(crystalEnts) do
        if crystalEnt ~= nil then
          CreateUnitByNameAsync("npc_tcotrpg_aghanim_crystal_activator", crystalEnt:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            unit:AddNewModifier(unit, nil, "modifier_aghanim_crystal_activator", {})
          end)
        end
      end
      --

      if IsPvP() then
        local killLimit = GetRealHeroCount() * KILLS_PER_PLAYER_TO_END_GAME_FOR_TEAM
        if SHOW_KILLS_ON_TOPBAR then
          GameRules:GetGameModeEntity():SetCustomRadiantScore(killLimit)
          GameRules:GetGameModeEntity():SetCustomDireScore(killLimit)
        end
      end

      RuneManager:Init()
      --TalentManager:Init()
    end)
  end)

  if GetMapName() == "tcotrpgv3" or GetMapName() == "tcotrpgv2" or GetMapName() == "tcotrpg" then
    local twinGates = Entities:FindAllByModel("models/props_gameplay/team_portal/team_portal.vmdl")
    for _,gate in ipairs(twinGates) do
      gate:AddNewModifier(gate, nil, "modifier_twin_gate_custom", {})
    end

    local aghanimTowers = Entities:FindAllByModel("models/props_structures/radiant_checkpoint_01.vmdl")
    for _,tower in ipairs(aghanimTowers) do
      tower:AddNewModifier(tower, nil, "modifier_aghanim_tower", {})
    end

    local outposts = Entities:FindAllByModel("models/props_structures/outpost.vmdl")
    for _,outpost in ipairs(outposts) do
      outpost:RemoveModifierByName("modifier_invulnerable")
    end
  end
  --

	-- If the day/night is not changed at 00:00, uncomment the following line:
	GameRules:SetTimeOfDay(0.75)
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function barebones:InitGameMode()
	DebugPrint("[BAREBONES] Starting to load Game Rules.")

	-- Setup rules
	GameRules:SetSameHeroSelectionEnabled(ALLOW_SAME_HERO_SELECTION)
	GameRules:SetUseUniversalShopMode(UNIVERSAL_SHOP_MODE)
	GameRules:SetHeroRespawnEnabled(ENABLE_HERO_RESPAWN)

	GameRules:SetHeroSelectionTime(HERO_SELECTION_TIME) -- THIS IS IGNORED when "EnablePickRules" is "1" in 'addoninfo.txt' !
	GameRules:SetHeroSelectPenaltyTime(HERO_SELECTION_PENALTY_TIME)

	GameRules:SetPreGameTime(PRE_GAME_TIME)
	GameRules:SetPostGameTime(POST_GAME_TIME)
	GameRules:SetShowcaseTime(SHOWCASE_TIME)
	GameRules:SetStrategyTime(STRATEGY_TIME)

	GameRules:SetTreeRegrowTime(TREE_REGROW_TIME)
  GameRules:SetFilterMoreGold(true)

	if USE_CUSTOM_HERO_LEVELS then
		GameRules:SetUseCustomHeroXPValues(true)
	end

	--GameRules:SetGoldPerTick(GOLD_PER_TICK) -- Doesn't work 24.2.2020
	--GameRules:SetGoldTickTime(GOLD_TICK_TIME) -- Doesn't work 24.2.2020
	GameRules:SetStartingGold(NORMAL_START_GOLD)

	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		GameRules:SetUseBaseGoldBountyOnHeroes(false) -- if true Heroes will use their default base gold bounty which is similar to creep gold bounty, rather than DOTA specific formulas
	end

	GameRules:SetHeroMinimapIconScale(MINIMAP_ICON_SIZE)
	GameRules:SetCreepMinimapIconScale(MINIMAP_CREEP_ICON_SIZE)
	GameRules:SetRuneMinimapIconScale(MINIMAP_RUNE_ICON_SIZE)
	GameRules:SetFirstBloodActive(ENABLE_FIRST_BLOOD)
	GameRules:SetHideKillMessageHeaders(HIDE_KILL_BANNERS)
	GameRules:LockCustomGameSetupTeamAssignment(LOCK_TEAMS)

	-- This is multi-team configuration stuff
	if USE_AUTOMATIC_PLAYERS_PER_TEAM then
		local num = math.floor(10/MAX_NUMBER_OF_TEAMS)
		local count = 0
		for team, number in pairs(TEAM_COLORS) do
			if count >= MAX_NUMBER_OF_TEAMS then
				GameRules:SetCustomGameTeamMaxPlayers(team, 0)
			else
				GameRules:SetCustomGameTeamMaxPlayers(team, num)
			end
			count = count + 1
		end
	else
		local count = 0
		for team, number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
			if count >= MAX_NUMBER_OF_TEAMS then
				GameRules:SetCustomGameTeamMaxPlayers(team, 0)
			else
				GameRules:SetCustomGameTeamMaxPlayers(team, number)
			end
			count = count + 1
		end
	end

	if USE_CUSTOM_TEAM_COLORS then
		for team, color in pairs(TEAM_COLORS) do
			SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
		end
	end


	DebugPrint("[BAREBONES] Done with setting Game Rules.")

	-- Event Hooks / Listeners
	DebugPrint("[BAREBONES] Setting Event Hooks / Listeners.")
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(barebones, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(barebones, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(barebones, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(barebones, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(barebones, 'OnDisconnect'), self)
  ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(barebones, 'OnItemPickedUp'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(barebones, 'OnItemPurchased'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(barebones, 'OnLastHit'), self)
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(barebones, 'OnRuneActivated'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(barebones, 'OnTreeCut'), self)
  --ListenToGameEvent("dota_player_killed", Dynamic_Wrap(barebones, 'OnPlayerDeath'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(barebones, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(barebones, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(barebones, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(barebones, 'OnPlayerPickHero'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(barebones, 'OnPlayerReconnect'), self)
	ListenToGameEvent("player_chat", Dynamic_Wrap(barebones, 'OnPlayerChat'), self)

	ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(barebones, 'OnTowerKill'), self)
	ListenToGameEvent("dota_player_selected_custom_team", Dynamic_Wrap(barebones, 'OnPlayerSelectedCustomTeam'), self)
	ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(barebones, 'OnNPCGoalReached'), self)
  ListenToGameEvent("dota_item_combined", Dynamic_Wrap(barebones, 'OnItemCombined'), self)

	-- Change random seed for math.random function
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	DebugPrint("[BAREBONES] Setting Filters.")

	local gamemode = GameRules:GetGameModeEntity()

  -- Set default hud because custom HUDs overlap our own panorama elements
  gamemode:SetForcedHUDSkin("reborn")

	-- Setting the Order filter 
	gamemode:SetExecuteOrderFilter(Dynamic_Wrap(barebones, "OrderFilter"), self)

	-- Setting the Damage filter
	gamemode:SetDamageFilter(Dynamic_Wrap(barebones, "DamageFilter"), self)

	-- Setting the Modifier filter
	gamemode:SetModifierGainedFilter(Dynamic_Wrap(barebones, "ModifierFilter"), self)

	-- Setting the Experience filter
	gamemode:SetModifyExperienceFilter(Dynamic_Wrap(barebones, "ExperienceFilter"), self)

	-- Setting the Tracking Projectile filter
	gamemode:SetTrackingProjectileFilter(Dynamic_Wrap(barebones, "ProjectileFilter"), self)

	-- Setting the bounty rune pickup filter
	gamemode:SetBountyRunePickupFilter(Dynamic_Wrap(barebones, "BountyRuneFilter"), self)

	-- Setting the Healing filter
	gamemode:SetHealingFilter(Dynamic_Wrap(barebones, "HealingFilter"), self)

  gamemode:SetNeutralStashEnabled(false)
  gamemode:SetAllowNeutralItemDrops(false)
  gamemode:SetCustomBackpackSwapCooldown(0)
  gamemode:SetNeutralItemHideUndiscoveredEnabled(true)

	-- Setting the Gold Filter
	gamemode:SetModifyGoldFilter(Dynamic_Wrap(barebones, "GoldFilter"), self)

	-- Setting the Inventory filter
	gamemode:SetItemAddedToInventoryFilter(Dynamic_Wrap(barebones, "InventoryFilter"), self)


	DebugPrint("[BAREBONES] Done with setting Filters.")

	-- Global Lua Modifiers
	LinkLuaModifier("modifier_custom_invulnerable", "modifiers/modifier_custom_invulnerable", LUA_MODIFIER_MOTION_NONE)

	print("[BAREBONES] initialized.")
	DebugPrint("[BAREBONES] Done loading the game mode!\n\n")
	
	-- Increase/decrease maximum item limit per hero
	Convars:SetInt('dota_max_physical_items_purchase_limit', 64)

	-- stuff --

end

-- A player has reconnected to the game. This function can be used to repaint Player-based particles or change state as necessary
function barebones:OnPlayerReconnect(keys)
  DebugPrint("[BAREBONES] A Player has reconnected.")
  --PrintTable(keys)

  local new_state = GameRules:State_Get()
  if new_state > DOTA_GAMERULES_STATE_HERO_SELECTION then
    local playerID = keys.PlayerID or keys.player_id
    
    if not playerID or not PlayerResource:IsValidPlayerID(playerID) then
      print("OnPlayerReconnect - Reconnected player ID isn't valid!")
    end

    if PlayerResource:HasSelectedHero(playerID) or PlayerResource:HasRandomed(playerID) then
      -- This playerID already had a hero before disconnect
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if hero ~= nil then
          local unitName = hero:GetUnitName()
          local player = PlayerResource:GetPlayer(playerID)

          if hero:IsAlive() then
            hero:RespawnHero(false, false)
          end

          Timers:CreateTimer(5.0, function()
            CustomGameEventManager:Send_ServerToAllClients("duel_timer_changed", { isDuelActive = KILL_VOTE_RESULT:upper() })
            
            --TalentManager:ResetTalents(player, hero)

            XpManager:LoadPlayerTalentData(hero)

            local accountID = PlayerResource:GetSteamAccountID(playerID)
            CustomGameEventManager:Send_ServerToPlayer(player, "player_buff_selection_connect", {
              buffs = _G.PlayerBuffList[accountID],
              a = RandomFloat(1,1000),
              b = RandomFloat(1,1000),
              c = RandomFloat(1,1000),
            })

            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "autopickup_register", {
                autoloot = _G.autoPickup[playerID],
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })

            --[[
            Timers:CreateTimer(1.0, function()
              local data = TalentManager:LoadKVDataForHero(hero:GetUnitName())
              local exists = 0 
      
              if data ~= nil then
                  exists = 1
              end
      
              CustomGameEventManager:Send_ServerToPlayer(player, "talent_manager_send_verify_talent_exists_for_hero", {
                  exists = exists,
                  a = RandomFloat(1,1000),
                  b = RandomFloat(1,1000),
                  c = RandomFloat(1,1000),
              })
      
              return 10.0
            end)
            --]]
          end)
      end
    else
      -- PlayerResource:IsConnected(playerID) is custom-made; can be found in 'player_resource.lua' library
      if PlayerResource:IsConnected(playerID) and not PlayerResource:IsBroadcaster(playerID) then
        PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
        PlayerResource:SetHasRandomed(playerID)
        PlayerResource:SetCanRepick(playerID, false)
        DebugPrint("[BAREBONES] OnPlayerReconnect - Randomed a hero for a player ID "..playerID.." that reconnected.")
      end
    end
  end

  if IsServer() then
    local accountID = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)

    _G.PlayerGoldBank[accountID] = _G.PlayerGoldBank[accountID] or 0
  end
end

-- A player leveled up an ability; Note: IT DOESN'T TRIGGER WHEN YOU USE SetLevel() ON THE ABILITY!
function barebones:OnPlayerLearnedAbility(keys)
  local player
  if keys.player then
    player = EntIndexToHScript(keys.player)
  end

  local ability_name = keys.abilityname

  local playerID
  if player then
    playerID = player:GetPlayerID()
  else
    playerID = keys.PlayerID
  end

  -- PlayerResource:GetBarebonesAssignedHero(index) is custom-made; can be found in 'player_resource.lua' library
  -- This could return a wrong hero if you change your hero often during gameplay
  --[[
  local hero = PlayerResource:GetBarebonesAssignedHero(playerID)
  local talentsExist = TalentManager:LoadKVDataForHero(hero:GetUnitName())

  if string.match(ability_name, "special_bonus") and talentsExist ~= nil then
    hero:RemoveAbility(ability_name)
  end
  --]]
  -- Remove talents
  local hero = PlayerResource:GetBarebonesAssignedHero(playerID)
  if string.match(ability_name, "special_bonus") then
    hero:RemoveAbility(ability_name)
  end
end

function barebones:ExperienceFilter(event) 
  local playerID = event.player_id_const
  if playerID == nil or not playerID then return false end

  local player = PlayerResource:GetPlayer(playerID)
  if not player or player == nil then return false end
  hero = player:GetAssignedHero()

  if EXP_VOTE_RESULT:upper() == "ENABLE" then
    event.experience = event.experience * 2
  end

  if hero:HasModifier("modifier_effect_private") then
    event.experience = event.experience * DONATOR_BONUS_XP
  end

  if hero:HasModifier("modifier_chicken_ability_1_target_transmute") and event.reason_const ~= 99 then
    -- We make sure so the chicken gets gold when he has infested someone --
    local mod = hero:FindModifierByName("modifier_chicken_ability_1_target_transmute")
    if mod ~= nil then
      local chicken = mod:GetCaster()
      if not chicken or chicken == nil then return end
      if not chicken:IsAlive() then return end

      chicken:AddExperience(event.experience, 99, false, true)
    end
  end

  return true
end

function barebones:GoldFilter(event)
  local playerID = event.player_id_const
  if playerID == nil or not playerID then return false end

  local rPlayer = PlayerResource:GetPlayer(playerID)
  if not rPlayer or rPlayer == nil then return false end

  local player = rPlayer:GetAssignedHero()
  if not player or player == nil then return false end

  if event.reason_const == DOTA_ModifyGold_AbandonedRedistribute then return false end
  if event.reason_const == DOTA_ModifyGold_PurchaseItem then return true end

  if event.reason_const == DOTA_ModifyGold_SellItem then
    local accountID = PlayerResource:GetSteamAccountID(player:GetPlayerID())
    if player:GetGold() >= 99999 then 
      _G.PlayerGoldBank[accountID] = _G.PlayerGoldBank[accountID] + event.gold
    elseif player:GetGold()+event.gold >= 99999 then
      _G.PlayerGoldBank[accountID] = _G.PlayerGoldBank[accountID] + (event.gold - (99999 - player:GetGold()))
    end

    CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
      userEntIndex = player:GetEntityIndex(),
      amount = _G.PlayerGoldBank[accountID],
    })
    return true 
  end

  if IsPvP() then
    if event.reason_const == DOTA_ModifyGold_CreepKill or event.reason_const == DOTA_ModifyGold_NeutralKill then
      local gameTime = math.floor(GameRules:GetGameTime() / 60)
      local formula = 1.07^gameTime
      event.gold = event.gold * formula
    end
  end

  if player:HasModifier("modifier_chicken_ability_1_target_transmute") and event.reason_const ~= 99 and (event.reason_const == DOTA_ModifyGold_CreepKill or event.reason_const == DOTA_ModifyGold_HeroKill or event.reason_const == DOTA_ModifyGold_NeutralKill) and event.gold > 0 then
    -- We make sure so the chicken gets gold when he has infested someone --
    local mod = player:FindModifierByName("modifier_chicken_ability_1_target_transmute")
    if mod ~= nil then
      local chicken = mod:GetCaster()
      if not chicken or chicken == nil then return end
      if not chicken:IsAlive() then return end

      chicken:ModifyGoldFiltered(event.gold, false, 99)
    end
  end

  if player:HasModifier("modifier_chicken_ability_1_self_transmute") and event.reason_const ~= 99 and (event.reason_const == DOTA_ModifyGold_CreepKill or event.reason_const == DOTA_ModifyGold_HeroKill or event.reason_const == DOTA_ModifyGold_NeutralKill) and event.gold > 0 then
    -- We make sure so the host gets gold if chicken kills a mob
    -- But be careful with summons since they're not heroes, we don't give them gold
    local mod = player:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if mod ~= nil then
      local host = mod:GetCaster()
      if not host or host == nil then return end
      if not host:IsAlive() then return end
      if host:IsHero() then
        host:ModifyGoldFiltered(event.gold, false, 99)
      end
    end
  end

  if (event.reason_const == 99 or event.reason_const == DOTA_ModifyGold_NeutralKill or event.reason_const == DOTA_ModifyGold_BountyRune) and event.gold > 0 then
    if GOLD_VOTE_RESULT:upper() == "ENABLE" then
      event.gold = event.gold * 2
    end
  end

  if player:HasModifier("modifier_effect_private") then
    event.gold = event.gold * DONATOR_BONUS_GOLD
  end

  if (event.reason_const == 99 or event.reason_const == DOTA_ModifyGold_NeutralKill or event.reason_const == DOTA_ModifyGold_CreepKill or event.reason_const == DOTA_ModifyGold_BountyRune) and event.gold > 0 then
    if (player:GetGold() + event.gold) >= 99999 then
      local remaining = event.gold
      local goldBankLimit = GOLD_BANK_MAX_LIMIT

      local accountID = PlayerResource:GetSteamAccountID(player:GetPlayerID())

      if (_G.PlayerGoldBank[accountID] + remaining) >= INT_MAX_LIMIT then
        _G.PlayerGoldBank[accountID] = INT_MAX_LIMIT
      else
        if ((_G.PlayerGoldBank[accountID] + remaining) > goldBankLimit) or (_G.PlayerGoldBank[accountID] > goldBankLimit) then
          _G.PlayerGoldBank[accountID] = goldBankLimit
        else
          _G.PlayerGoldBank[accountID] = _G.PlayerGoldBank[accountID] + remaining
        end
      end

      CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
        userEntIndex = player:GetEntityIndex(),
        amount = _G.PlayerGoldBank[accountID],
      })
    end
  end

  return true
end

function barebones:OnItemPurchased(keys)
  local playerID = keys.PlayerID
  local prePlayer = PlayerResource:GetPlayer(playerID)
  if not prePlayer or prePlayer == nil then return end

  local player = prePlayer:GetAssignedHero()

  if not player or player == nil then return end

  --[[
  -- GOLD BANK LOGIC --
  local accountID = PlayerResource:GetSteamAccountID(playerID)
  if not _G.PlayerGoldBank[accountID] or _G.PlayerGoldBank[accountID] == nil then return true end 
  
  local maxGold = 99999
  local playerDefaultGold = player:GetGold()
  
  local cost = keys.itemcost
  local playerGoldBank = tonumber(_G.PlayerGoldBank[accountID])

  if playerGoldBank > 0 then
    local spaceForGold = maxGold - cost -- how much room they have left for more gold
    local takeFromBank = playerGoldBank - cost

    if playerGoldBank < takeFromBank then
        takeFromBank = playerGoldBank
    end

    if takeFromBank < 0 then return true end
    
    player:ModifyGold(takeFromBank, false, 98)

    if takeFromBank == playerGoldBank then
      takeFromBank = playerGoldBank - cost
    end

    _G.PlayerGoldBank[accountID] = takeFromBank

    CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
      userEntIndex = player:GetEntityIndex(),
      amount = _G.PlayerGoldBank[accountID]
    })
  end
  --]]
end

local totalDeadCount = 0

function barebones:OnDisconnect(event)
  local playerID = event.PlayerID
  if playerID == nil or not playerID then return end

  local rPlayer = PlayerResource:GetPlayer(playerID)
  if not rPlayer or rPlayer == nil then return false end

  local player = rPlayer:GetAssignedHero()
  if not player or player == nil then return false end

  _G.PerformanceHeroesTable[player:entindex()] = _G.PerformanceHeroesTable[player:entindex()] or nil
  _G.PerformanceHeroesTable[player:entindex()] = nil
end



function barebones:OnEntityKilled(keys)
  local killed_entity_index = keys.entindex_killed
  local attacker_entity_index = keys.entindex_attacker
  local inflictor_index = keys.entindex_inflictor -- it can be nil if not killed by an item/ability

  -- Find the entity that was killed
  local killed_unit
  if killed_entity_index then
    killed_unit = EntIndexToHScript(killed_entity_index)
  end

  -- Find the entity (killer) that killed the entity mentioned above
  local killer_unit
  if attacker_entity_index then
    killer_unit = EntIndexToHScript(attacker_entity_index)
  end

  if killed_unit == nil or killer_unit == nil then
    -- Don't continue if killer or killed entity doesn't exist
    return
  end
  -- Find the ability/item used to kill, or nil if not killed by an item/ability
  local killing_ability
  if inflictor_index then
    killing_ability = EntIndexToHScript(inflictor_index)
  end

  -- For Meepo clones, find the original
  if killed_unit:IsClone() then
    if killed_unit:GetCloneSource() then
      killed_unit = killed_unit:GetCloneSource()
    end
  end

  if killed_unit ~= nil and not IsSummonTCOTRPG(killed_unit) then
    if IsBossTCOTRPG(killed_unit) then
      if killed_unit:GetUnitName() == "npc_dota_creature_roshan_boss" and not _G.BossesKilled["roshan"] then
        _G.BossesKilled["roshan"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_ROSHAN)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_30_boss" and not _G.BossesKilled["forest"] then
        _G.BossesKilled["forest"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_FOREST)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_40_boss" and not _G.BossesKilled["spider"] then
        _G.BossesKilled["spider"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_SPIDER)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_130_boss_death" and not _G.BossesKilled["lake"] then
        _G.BossesKilled["lake"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_LAKE)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_70_boss" and not _G.BossesKilled["wraith"] then
        _G.BossesKilled["wraith"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_WRAITH)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_80_boss" and not _G.BossesKilled["winter"] then
        _G.BossesKilled["winter"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_WINTER)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_100_boss" and not _G.BossesKilled["lava"] then
        _G.BossesKilled["lava"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_LAVA)
      elseif killed_unit:GetUnitName() == "npc_dota_creature_150_boss_last" and not _G.BossesKilled["heaven"] then
        _G.BossesKilled["heaven"] = true
        XpManager:AddExperienceAllPlayers(DIFFICULTY_GPOINTS_REWARD_HEAVEN)
      end
    end

    -- We have to do this because we allow units to respawn (garbage collection issue)
    -- which also means we have to remove them manually or the dead corpse will kinda float under ground and remain buggy (depends on model)
    if IsCreepTCOTRPG(killed_unit) or IsBossTCOTRPG(killed_unit) then
      if killed_unit:UnitCanRespawn() then
        Timers:CreateTimer(3.0, function()
          if killed_unit == nil or not killed_unit or killed_unit:IsNull() then return end 

          killed_unit:AddNoDraw()
        end)

        Timers:CreateTimer(60.0, function()
          if killed_unit == nil or not killed_unit or killed_unit:IsNull() then return end 

          UTIL_Remove(killed_unit)
        end)
      end
    end

    if IsCreepTCOTRPG(killed_unit) then
      _G.PerformanceUnitsTable[killed_unit:entindex()] = _G.PerformanceUnitsTable[killed_unit:entindex()] or {}
      _G.PerformanceUnitsTable[killed_unit:entindex()] = nil
    end

    if IsCreepTCOTRPG(killed_unit) and (killer_unit:IsRealHero() or IsShamanWard(killer_unit) or killer_unit:GetUnitName() == "npc_dota_carl_forged_spirit" or killer_unit:GetUnitName() == "npc_dota_necronomicon_archer_custom") then
      local selectionTable = NEUTRAL_ITEM_DROP_TABLE_COMMON
      local selectionPool = {}
      local minutesPassedSinceGameStart = math.floor(GameRules:GetGameTime() / 60)
      local rand = RandomFloat(0.0, 1.0)

      if IsShamanWard(killer_unit) or (killer_unit:IsControllableByAnyPlayer() and not killer_unit:IsRealHero() and not killer_unit:GetOwner() ~= nil) then
        killer_unit = killer_unit:GetOwner()
      end

      if killer_unit:IsConsideredHero() and killer_unit:GetUnitName() == "npc_dota_necronomicon_archer_custom" then
        killer_unit = killer_unit:GetOwner()
      end

      if (killer_unit:GenerateDropChance() <= 4.0) then
        local goldBag = DropNeutralItemAtPositionForHero("item_gold_bag", killed_unit:GetAbsOrigin(), killed_unit, -1, true)
        goldBag:SetModelScale(1.25)
      end

      if (RandomFloat(0.0, 100.0) <= 1.0) and killed_unit:GetUnitName() ~= "npc_dota_creature_greedy_goblin" and not _G.FinalGameWavesEnabled then
        GreedyGoblin:Spawn(killed_unit:GetAbsOrigin())
      end
    end

    if not IsPvP() and (KILL_VOTE_RESULT:upper() == "IMPOSSIBLE" or KILL_VOTE_RESULT:upper() == "HELL" or KILL_VOTE_RESULT:upper() == "HARDCORE" or KILL_VOTE_RESULT:upper() == "APOCALYPSE") and killed_unit:IsRealHero() and not killed_unit:IsReincarnating() and not killed_unit:WillReincarnate() then
      local mod = killed_unit:FindModifierByNameAndCaster("modifier_limited_lives", killed_unit)
      if mod ~= nil then
        mod:DecrementStackCount()

        if mod:GetStackCount() <= 0 then
          killed_unit:RemoveModifierByNameAndCaster("modifier_limited_lives", killed_unit)
          killed_unit:SetRespawnsDisabled(true)

          return false
        end
      end
    end
  end

  if killed_unit:IsRealHero() and killed_unit:HasModifier("modifier_wave_manager_player") and not IsSummonTCOTRPG(killed_unit) then
    local tombstoneItem = CreateItem("item_tombstone", killed_unit, killed_unit)
    if (tombstoneItem) then
      local tombstone = SpawnEntityFromTableSynchronous("dota_item_tombstone_drop", {})
      tombstone:SetContainedItem(tombstoneItem)
      tombstone:SetAngles(0, RandomFloat(0, 360), 0)
      FindClearSpaceForUnit(tombstone, killed_unit:GetAbsOrigin(), true)
    end
  end

  -- This is for the default respawn times --
  if killed_unit:IsRealHero() and not killed_unit:HasModifier("modifier_wave_manager_player") and not IsSummonTCOTRPG(killed_unit) then
    if not killed_unit:IsReincarnating() and not killed_unit:WillReincarnate() then
      killed_unit:SetTimeUntilRespawn(MAX_RESPAWN_TIME)

      if IsPvP() then
        local killLimit = GetRealHeroCount() * KILLS_PER_PLAYER_TO_END_GAME_FOR_TEAM
        
        if SHOW_KILLS_ON_TOPBAR then
          GameRules:GetGameModeEntity():SetCustomRadiantScore(killLimit-GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
          GameRules:GetGameModeEntity():SetCustomDireScore(killLimit-GetTeamHeroKills(DOTA_TEAM_BADGUYS))
        end

        if END_GAME_ON_KILLS and (killLimit-GetTeamHeroKills(killer_unit:GetTeam())) <= 0 then
          GameRules:SetGameWinner(killer_unit:GetTeam())
        end
      end
    end
  end
end


function barebones:OnItemCombined(event)
  --[[
  local purchasableLostItems = {
    "item_kings_guard_7",
    "item_mercure7",
    "item_rebels_sword",
    "item_octarine_core6",
    "item_trident_custom_6",
    "item_veil_of_discord6",
    "item_last_soul",
  }

  for _,lostItem in ipairs(purchasableLostItems) do
    if event.itemname == lostItem then
      if _G.lostItems[event.PlayerID] >= 1 then
        DisplayError(event.PlayerID, "#one_lost_soul_item_error")
        return false
      end

      _G.lostItems[event.PlayerID] = 1
    end
  end
  --]]
end

function barebones:InventoryFilter(event)
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME or GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
    return false
  end

  if not event.item_entindex_const then return end
  if not event.inventory_parent_entindex_const then return end

  local itemIndex = event.item_entindex_const
  local item = EntIndexToHScript(itemIndex)
  if not item or item:IsNull() then return true end

  local itemName = item:GetAbilityName()
  
  local player = EntIndexToHScript(event.inventory_parent_entindex_const)
  if not player then return true end
  if player:IsNull() then return end
  if not player:IsRealHero() then return true end


  if itemName == "item_swiftness_boots" or itemName == "item_arena_invuln" then
    event.suggested_slot = DOTA_ITEM_TP_SCROLL
    return true
  end

  local noPurchaseTimeItems = {
    "item_flicker",
    "item_ninja_gear",
    "item_the_leveller",
    "item_minotaur_horn",
    "item_spy_gadget",
    "item_trickster_cloak",
    "item_stormcrafter",
    "item_penta_edged_sword",
    "item_ascetic_cap",
    "item_illusionsts_cape",
    "item_heavy_blade",
    "item_quickening_charm",
    "item_spider_legs",
    "item_pupils_gift",
    "item_imp_claw",
    "item_paladin_sword",
    "item_orb_of_destruction",
    "item_titan_sliver",
    "item_mind_breaker",
    "item_enchanted_quiver",
    "item_elven_tunic",
    "item_ceremonial_robe",
    "item_ring_of_aquila",
    "item_psychic_headband",
    "item_black_powder_bag",
    "item_vambrace",
    "item_grove_bow",
    "item_misericorde",
    "item_quicksilver_amulet",
    "item_essence_ring",
    "item_nether_shawl",
    "item_bullwhip",
    "item_keen_optic",
    "item_ironwood_tree",
    "item_ocean_heart",
    "item_broom_handle",
    "item_faded_broach",
    "item_arcane_ring",
    "item_chipped_vest",
    "item_possessed_mask",
    "item_mysterious_hat",
    "item_philosophers_stone",
    "item_unstable_wand",
    "item_pogo_stick",
    "item_paintball",
    "item_royal_jelly",
    "item_force_boots",
    "item_seer_stone",
    "item_apex",
    "item_fallen_sky",
    "item_pirate_hat",
    "item_force_field",
    "item_vengeances_shadow",
    "item_timeless_relic",
    "item_spell_prism",
    "item_charged_essence"
  }

  for _,npItem in ipairs(noPurchaseTimeItems) do
    if item:GetAbilityName() == npItem then
      item:SetPurchaseTime(0)
      return true
    end
  end
  
  -- Neutral slot item --
  if NeutralSlot:NeedToNeutralSlot( item:GetName() ) and not player:IsCourier() then
    local slotIndex = NeutralSlot:GetSlotIndex()
    local itemInSlot = player:GetItemInSlot(slotIndex)

    if not itemInSlot then
      -- just practical heuristic, when hero take item from another unit/from ground event.item_parent_entindex_const != event.inventory_parent_entindex_const
      -- never ask me about this dirty hack.
      local isStash = event.item_parent_entindex_const == event.inventory_parent_entindex_const

      if not isStash or player:IsInRangeOfShop(DOTA_SHOP_HOME, true) then
        event.suggested_slot = slotIndex
      end
    end
  end

  if item.ForceShareable then
    item:SetPurchaser( player )
  end

  -- Check if a rune is added to inventory and if so, remove it and add it to the rune inventory
  local playerID = player:GetPlayerID()
  local isSocketable = string.match(itemName, "item_socket_rune")
  local isLegendarySocketable = string.match(itemName, "item_socket_rune_legendary")

  if isSocketable then
    _G.PlayerRuneInventory[playerID] = _G.PlayerRuneInventory[playerID] or {}
    table.insert(_G.PlayerRuneInventory[playerID], {
      uId = DoUniqueString("item_socket_rune"),
      name = itemName,
      isLegendary = isLegendarySocketable
    })

    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "rune_manager_rune_send", {
        runes = _G.PlayerRunes[playerID],
        runeInventory = _G.PlayerRuneInventory[playerID],
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
    
    Timers:CreateTimer(-1, function()
      player:TakeItem(item)
    end)
    
    return true
  end

  return true
end

-- A player picked or randomed a hero, it actually happens on spawn (this is sometimes happening before OnHeroInGame).
function barebones:OnPlayerPickHero(keys)
  DebugPrint("[BAREBONES] OnPlayerPickHero event")
  --PrintTable(keys)

  local hero_name = keys.hero
  local hero_entity
  if keys.heroindex then
    hero_entity = EntIndexToHScript(keys.heroindex)
  end
  local player
  if keys.player then
    player = EntIndexToHScript(keys.player)
  end

  Timers:CreateTimer(0.5, function()
    if not hero_entity or hero_entity:IsNull() then
      return
    end
    
    local playerID = hero_entity:GetPlayerID() -- or player:GetPlayerID() if player is not disconnected
    if PlayerResource:IsFakeClient(playerID) then
      -- This is happening only for bots when they spawn for the first time or if they use custom hero-create spells (Custom Illusion spells)
    else
      if not PlayerResource.PlayerData[playerID] and PlayerResource:IsValidPlayerID(playerID) then
        PlayerResource:InitPlayerDataForID(playerID)
      end
      if PlayerResource.PlayerData[playerID].already_assigned_hero == true then
        -- This is happening only when players create new heroes or replacing heroes
        DebugPrint("[BAREBONES] OnPlayerPickHero - Player with playerID "..playerID.." got another hero: "..hero_entity:GetUnitName())
      else
        PlayerResource:AssignHero(playerID, hero_entity)
        PlayerResource.PlayerData[playerID].already_assigned_hero = true
      end
    end
  end)
end

function barebones:HealingFilter(event)
  if not IsServer() then return end

  local target = EntIndexToHScript(event.entindex_target_const)
  local healer = nil 
 
  if event.entindex_healer_const ~= nil then
    healer = EntIndexToHScript(event.entindex_healer_const)
  end

  if event.heal < 0 or event.heal > INT_MAX_LIMIT then
    --print("Limit heal out of bonds at: ", event.heal)
    event.heal = target:GetMaxHealth()
  end

  if target:GetUnitName() == "npc_dota_hero_huskar" then
    local mayhem = target:FindAbilityByName("huskar_mayhem_custom")
    if mayhem ~= nil and mayhem:GetLevel() > 0 then
      local threshold = mayhem:GetSpecialValueFor("max_hp_threshold")
      local forcedHeal = event.heal * (threshold / 100) 
      local maxAllowedHealth = target:GetMaxHealth() * (threshold / 100)
      local expectedHealing = target:GetHealth() + forcedHeal

      if expectedHealing > maxAllowedHealth then
        if target:IsAlive() then
          local modifiedHealth = target:GetHealth() + (expectedHealing - (expectedHealing - maxAllowedHealth))
          if modifiedHealth > maxAllowedHealth then
            modifiedHealth = maxAllowedHealth
          end
          target:ModifyHealth(modifiedHealth, nil, false, 0)
        end

        return false
      end

      event.heal = forcedHeal
    end
  end

  if target:HasModifier("modifier_player_buffs_vulnerable") and (healer == nil or (healer ~= nil and healer == target)) then
    event.heal = 0
  end

  if target:HasModifier("modifier_player_difficulty_boon_reduced_healing_50") then
    event.heal = event.heal * 0.5
  end

  if target:HasModifier("modifier_player_difficulty_boon_reduced_healing_40") then
    event.heal = event.heal * 0.60
  end

  if target:HasModifier("modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75") then
    event.heal = event.heal * 0.25
  end

  if healer ~= nil then
    local falsePromise = healer:FindAbilityByName("oracle_false_promise_custom")
    if falsePromise and falsePromise:GetLevel() > 0 then
      local chance = falsePromise:GetSpecialValueFor("chance")
      if RollPercentage(chance) then
        local falsePromiseMod = healer:FindModifierByName("modifier_oracle_false_promise_custom")
        if falsePromiseMod then
          falsePromiseMod:TriggerHealingEvent(target)
        end
      end
    end
  end

  return true
end

local bountyTaken = {}

function barebones:BountyRuneFilter(keys)
  if not IsServer() then return end

  local playerID = keys["player_id_const"]

  if bountyTaken[playerID] then return true end
  bountyTaken[playerID] = bountyTaken[playerID] or {}
  
  keys.gold_bounty = 0

  local gameTime = math.floor(GameRules:GetGameTime() / 60)
  local baseGold = 200
  local formula = 1.10^gameTime
  local goldBounty = baseGold * formula
  
  local player = PlayerResource:GetPlayer(keys.player_id_const):GetAssignedHero()

  keys.xp_bounty = 200 * formula

  if player:HasModifier("modifier_player_difficulty_buff_bounty_rune_200") then
    goldBounty = goldBounty * 2
    keys.xp_bounty = keys.xp_bounty * 2
  end

  local greed = player:FindAbilityByName("alchemist_chemical_gold_transfusion_custom")
  if greed ~= nil and greed:GetLevel() > 0 then
    if greed:IsCooldownReady() and greed:IsFullyCastable() then
      goldBounty = goldBounty * greed:GetSpecialValueFor("rune_multi")
      greed:UseResources(true, false, false, true)
    end
  end

  if goldBounty > 1000000 then 
    goldBounty = 1000000
  end

  player:ModifyGoldFiltered(goldBounty, true, DOTA_ModifyGold_BountyRune) 
  SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, player, goldBounty, nil)

  bountyTaken[playerID] = true

  Timers:CreateTimer(1.0, function()
    bountyTaken[playerID] = false
  end)

  return true
end

function barebones:ModifierFilter(event)
  local victim = EntIndexToHScript(event.entindex_parent_const)
  if not victim or victim == nil then return false end

  if not event.entindex_caster_const or event.entindex_caster_const == nil then return false end
  local caster = EntIndexToHScript(event.entindex_caster_const)
  if not caster or caster == nil then return false end

  local modifier = event.name_const
  if victim:IsAlive() and event.duration > 0 and modifier ~= nil then
    local resistance = victim:GetStatusResistance()
    local hModifier = victim:FindModifierByName(modifier)

    if hModifier and hModifier:IsDebuff() and victim ~= caster then
      if IsCreepTCOTRPG(victim) or IsBossTCOTRPG(victim) then
        local overlordMod = victim:FindModifierByName("modifier_item_overlord_helmet_aura")
        
        if overlordMod then
          local overlordRes = overlordMod.units[victim:entindex()]
          
          if overlordRes ~= nil then
            resistance = overlordRes/100
          end
        end
      end

      local status = event.duration * (1 - resistance)
      event.duration = status
    end
  end
  
  if modifier ~= nil and IsBossTCOTRPG(victim) then
    for _,ban in ipairs(BANNED_BOSS_MODIFIERS) do
      if modifier == ban then return false end
    end
  end 

  if victim:FindAbilityByName("boss_shell_custom") then
    if event.entindex_caster_const ~= event.entindex_parent_const then
      -- check if the modifier is allowed to stack forever --
      for _,modifierException in ipairs(BOSS_LIMITED_MODIFIERS) do
        if modifierException ~= event.name_const then return true end
      end

      if event.name_const == "modifier_bristleback_quill_spray_custom_stack" or event.name_const == "modifier_bristleback_quill_spray_custom" then return true end
      
      

      if event.duration > 3 or event.duration == -1 then
        event.duration = 3
      end

      local mod = victim:FindModifierByNameAndCaster(event.name_const, EntIndexToHScript(event.entindex_caster_const))
      Timers:CreateTimer(3.0, function()
        if mod ~= nil and not victim:IsNull() and victim ~= nil and victim:IsAlive() then
          victim:RemoveModifierByName(event.name_const)
        end
      end)
    end
    --event.duration = 3
  end

  return true
end

LinkLuaModifier( "modifier_windranger_windrun_custom_autocast", "heroes/hero_windrunner/windrun_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lina_laguna_blade_custom_autocast_strike", "heroes/hero_lina/laguna_blade.lua", LUA_MODIFIER_MOTION_NONE )

function barebones:OrderFilter(event)
    if event.order_type == DOTA_UNIT_ORDER_BUYBACK then
      return false
    end

    if event.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
      local target = EntIndexToHScript(event.entindex_target)
      local player = PlayerResource:GetSelectedHeroEntity(event.issuer_player_id_const)

      if target ~= nil and player ~= nil then
        if player:IsRealHero() and UnitIsNotMonkeyClone(player) and not IsCreepTCOTRPG(player) and not IsBossTCOTRPG(player) and (target.GetUnitName and (target:GetUnitName() == "npc_dota_unit_twin_gate_custom" or target:GetUnitName() == "npc_dota_unit_aghanim_tower_custom")) then
          local distance = (player:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
          local channelAbilityName = "twin_gate_portal_warp_custom"

          if target:GetUnitName() == "npc_dota_unit_aghanim_tower_custom" then
            channelAbilityName = "aghanim_tower_capture"
          end

          local targetChannelAbility = player:FindAbilityByName(channelAbilityName)
          if targetChannelAbility ~= nil then
            if distance <= 200 then
              ExecuteOrderFromTable({
                UnitIndex = player:entindex(),
                OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                AbilityIndex = targetChannelAbility:entindex(),
                TargetIndex = target:entindex()
              })
            else
              player:MoveToPosition(target:GetAbsOrigin())
              player:CastAbilityOnTarget(target, targetChannelAbility, -1)
            end

            return false
          end
        end
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
      local purchasedPlayerIssuer = EntIndexToHScript(event.units["0"])
      local purchasedItemName = event.shop_item_name
      if purchasedPlayerIssuer ~= nil and purchasedItemName == "item_book_of_lies" then
        local accountID = PlayerResource:GetSteamAccountID(purchasedPlayerIssuer:GetPlayerID())
        _G.BookOfLiesPurchases[accountID] = _G.BookOfLiesPurchases[accountID] or 0

        if _G.BookOfLiesPurchases[accountID] ~= nil then
          if _G.BookOfLiesPurchases[accountID] >= 3 then
            DisplayError(purchasedPlayerIssuer:GetPlayerID(), "Max Purchases Reached.")
            return false
          end
        end
        
        _G.BookOfLiesPurchases[accountID] = _G.BookOfLiesPurchases[accountID] + 1
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
      local target = EntIndexToHScript(event.entindex_target)
      local player = PlayerResource:GetSelectedHeroEntity(event.issuer_player_id_const)
      
      if target == nil then return end

      if player == nil then return end

      if target:GetUnitName() == "npc_dota_unit_twin_gate_custom" or target:GetUnitName() == "npc_dota_unit_aghanim_tower_custom" then 
        if not player:IsRealHero() or not UnitIsNotMonkeyClone(player) or IsCreepTCOTRPG(player) or IsBossTCOTRPG(player) then
          return false
        end
        
        return true 
      end

      if player:HasModifier("modifier_zuus_transcendence_custom_transport") then
        DisplayError(player:GetPlayerID(), "You Cannot Do That.")
        return false
      end

      if target:GetUnitName() == "npc_dota_treasure_chest_building" then return false end

      if target:GetName() == "outpost_zone_skafian" and player:GetLevel() < 15 then
        DisplayError(player:GetPlayerID(), "Level 15 Is Required To Capture This Outpost.")
        return false
      end

      if target:GetName() == "outpost_zone_spider" and player:GetLevel() < 30 then
        DisplayError(player:GetPlayerID(), "Level 30 Is Required To Capture This Outpost.")
        return false
      end

      if target:GetName() == "outpost_zone_reef" and player:GetLevel() < 50 then
        DisplayError(player:GetPlayerID(), "Level 50 Is Required To Capture This Outpost.")
        return false
      end

      if target:GetName() == "outpost_zone_mine" and player:GetLevel() < 75 then
        DisplayError(player:GetPlayerID(), "Level 75 Is Required To Capture This Outpost.")
        return false
      end

      if target:GetName() == "outpost_zone_zeus" and player:GetLevel() < 100 then
        DisplayError(player:GetPlayerID(), "Level 100 Is Required To Capture This Outpost.")
        return false
      end

      if IsBossTCOTRPG(target) then
        local ability = EntIndexToHScript(event.entindex_ability)
        if ability == nil then return end
        
        for _,ban in ipairs(BANNED_BOSS_ABILITIES) do
          if ability:GetAbilityName() == ban then
            return false
          end
        end
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
      local ability = EntIndexToHScript(event.entindex_ability)
      if ability == nil then return end

      local caster = ability:GetCaster()

      if caster:HasModifier("modifier_zuus_transcendence_custom_transport") then
        DisplayError(caster:GetPlayerID(), "You Cannot Do That.")
        return false
      end

      if ability:GetAbilityName() == "dawnbreaker_daybreak" then
        if GameRules:IsDaytime() then
            DisplayError(caster:GetPlayerID(), "#dawnbreaker_daybreak_cannot_use")
            return false
        end
      end

      if ability:GetAbilityName() == "lycan_shapeshift_custom" then
        if not GameRules:IsDaytime() then
            DisplayError(caster:GetPlayerID(), "#lycan_shapeshift_cannot_use")
            return false
        end
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
      local ability = EntIndexToHScript(event.entindex_ability)
      if ability == nil then return end
      local caster = ability:GetCaster()
      local abilityName = ability:GetAbilityName()
      local modifierName = nil

      if abilityName == "windrunner_windrun"  then modifierName = "modifier_windranger_windrun_custom_autocast" end
      if abilityName == "lina_light_strike_array"  then modifierName = "modifier_lina_laguna_blade_custom_autocast_strike" end
      if abilityName == "bloodseeker_bloodrage_custom"  then modifierName = "modifier_bloodseeker_bloodrage_custom_autocast" end
      if abilityName == "dazzle_shadow_wave"  then modifierName = "modifier_dazzle_shadow_wave_autocast" end
      if abilityName == "bristleback_quill_spray_custom"  then modifierName = "modifier_bristleback_quill_spray_custom_autocast" end
      if abilityName == "bristleback_viscous_nasal_goo_custom"  then modifierName = "modifier_bristleback_viscous_nasal_goo_custom_autocast" end

      if not ability:GetAutoCastState() then
        caster:AddNewModifier(caster, ability, modifierName, {})
      else
        caster:RemoveModifierByNameAndCaster(modifierName, caster)
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_CAST_TOGGLE then
      local ability = EntIndexToHScript(event.entindex_ability)
      if ability == nil then return end

      local caster = ability:GetCaster()
      if caster:GetUnitName() == "npc_dota_hero_huskar" then
        local mayhem = caster:FindAbilityByName("huskar_mayhem_custom")
        if mayhem ~= nil and mayhem:GetLevel() > 0 then
          if string.find(ability:GetAbilityName(), "armlet") then
            return false
          end
        end
      end

      if ability:GetAbilityName() == "oracle_fates_edict_custom" and not ability:IsCooldownReady() then
        DisplayError(caster:GetPlayerID(), "#dota_hud_error_ability_in_cooldown")
        return false
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_CAST_POSITION then
      local ability = EntIndexToHScript(event.entindex_ability)
      if ability == nil then return end

      local caster = ability:GetCaster()
      if caster:GetUnitName() == "npc_dota_hero_riki" and ability:GetAbilityName() == "riki_decoy" then
        local tricks = caster:FindAbilityByName("tricks_of_the_trade_custom")
        if tricks and not tricks:IsNull() then
          if tricks:IsChanneling() then
            local position = Vector(event.position_x, event.position_y, event.position_z)

            if (position - caster:GetAbsOrigin()):Length() <= ability:GetSpecialValueFor("radius") then
              if ability:IsCooldownReady() then
                caster:SetCursorPosition(position)
                ability:OnSpellStart()
                ability:UseResources(true, false, false, true)
                return false
              end
            end
          end
        end
      end
    end

    local playerID = event.issuer_player_id_const

    if event.units["0"] and event.order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
      if _G.FinalGameWavesEnabled then
        return false
      end

      local purchasedPlayerIssuer = EntIndexToHScript(event.units["0"])
      local purchasedItemName = event.shop_item_name
      if purchasedItemName == "item_roshan_soul" and not _G.BossesKilled["roshan"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_roshan")
        return false
      elseif purchasedItemName == "item_forest_soul" and not _G.BossesKilled["forest"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_forest")
        return false
      elseif purchasedItemName == "item_spider_soul" and not _G.BossesKilled["spider"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_spider")
        return false
      elseif purchasedItemName == "item_reef_soul" and not _G.BossesKilled["lake"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_lake")
        return false
      elseif purchasedItemName == "item_warlock_soul" and not _G.BossesKilled["wraith"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_wraith")
        return false
      elseif purchasedItemName == "item_elder_soul" and not _G.BossesKilled["winter"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_winter")
        return false
      elseif purchasedItemName == "item_last_soul" and not _G.BossesKilled["lava"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_lava")
        return false
      elseif purchasedItemName == "item_zeus_soul" and not _G.BossesKilled["heaven"] then
        DisplayError(purchasedPlayerIssuer:GetPlayerID(), "#error_boss_alive_heaven")
        return false
      end
    end

    if event.order_type == DOTA_UNIT_ORDER_MOVE_ITEM then
      local player = PlayerResource:GetSelectedHeroEntity(event.issuer_player_id_const)
      if not player or player == nil then return false end

      local itemIndex = event.entindex_ability
      local hItem = EntIndexToHScript(itemIndex)
      local slot = event.entindex_target
      local neutralSlotIndex = NeutralSlot:GetSlotIndex()

      -- Do not allow people to move items in Eternal Torment
      if _G.FinalGameWavesEnabled and slot < 0 then 
        DisplayError(player:GetPlayerID(), "You Cannot Do That Right Now.")
        return false 
      end


      if NeutralSlot:NeedToNeutralSlot(hItem:GetName()) and not player:IsCourier() then
        if slot >= DOTA_ITEM_SLOT_1 and slot <= DOTA_ITEM_SLOT_6 then
          if player:GetItemInSlot(neutralSlotIndex) == nil then
            event.entindex_target = neutralSlotIndex
          else
            if player:GetItemInSlot(DOTA_ITEM_SLOT_7) == nil then
              event.entindex_target = DOTA_ITEM_SLOT_7
            elseif player:GetItemInSlot(DOTA_ITEM_SLOT_8) == nil then
              event.entindex_target = DOTA_ITEM_SLOT_8
            elseif player:GetItemInSlot(DOTA_ITEM_SLOT_9) == nil then
              event.entindex_target = DOTA_ITEM_SLOT_9
            else
              player:DropItemAtPositionImmediate(hItem, player:GetAbsOrigin())
            end
          end
        end
      end
    end

    --[[
    if (event.order_type == DOTA_UNIT_ORDER_MOVE_ITEM and event.entindex_target > 5 and event.entindex_target ~= DOTA_ITEM_NEUTRAL_SLOT) or event.order_type == DOTA_UNIT_ORDER_SELL_ITEM or event.order_type == DOTA_UNIT_ORDER_DROP_ITEM or event.order_type == DOTA_UNIT_ORDER_GIVE_ITEM or event.order_type == DOTA_UNIT_ORDER_DISASSEMBLE_ITEM or event.order_type == DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN then
      local player = PlayerResource:GetSelectedHeroEntity(event.issuer_player_id_const)
      if not player or player == nil then return false end
      -- In this order filter we check if we are dealing with an item that has runes socketed into it
      -- Basically if an item with runes is sold, moved, etc. or altered in any way that makes it so
      -- you shouldn't have the effects of the runes anymore.

      local itemIndex = event.entindex_ability
      local runes = {}

      -- Loop through the equipment that has runes (if any)
      -- If it finds a rune, it will remove it and add the name of the rune to a temporary table,
      -- which we later loop to add it to the rune inventory
      if _G.PlayerRuneItems[playerID] ~= nil then
        _G.PlayerRuneItems[playerID][itemIndex] = nil -- Remove the item from the UI inventory
      end

      if _G.PlayerRunes[playerID] ~= nil then
        if _G.PlayerRunes[playerID][itemIndex] ~= nil then
          for i = 1, 2, 1 do
            if _G.PlayerRunes[playerID][itemIndex][i] ~= nil then
              local rune = _G.PlayerRunes[playerID][itemIndex][i]
              table.insert(runes, rune)

              local assignedHero = PlayerResource:GetPlayer(playerID):GetAssignedHero()

              RuneManager:RemoveRuneModifier(assignedHero, rune.name)

              _G.PlayerRunes[playerID][itemIndex][i] = nil
            end
          end
        end
      end

      -- Add the removed runes back into the rune inventory
      _G.PlayerRuneInventory[playerID] = _G.PlayerRuneInventory[playerID] or {}
      if #runes > 0 then
        for _,rune in pairs(runes) do
          table.insert(_G.PlayerRuneInventory[playerID], {
            uId = DoUniqueString("item_socket_rune"),
            name = rune.name,
            isLegendary = rune.isLegendary
          }) 
        end
      end

      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "rune_manager_rune_send", {
          items = _G.PlayerRuneItems[playerID],
          runes = _G.PlayerRunes[playerID],
          runeInventory = _G.PlayerRuneInventory[playerID],
          a = RandomFloat(1,1000),
          b = RandomFloat(1,1000),
          c = RandomFloat(1,1000),
      })
    end
    --]]

    --[[
    if event.order_type == DOTA_UNIT_ORDER_DROP_ITEM or event.order_type == DOTA_UNIT_ORDER_GIVE_ITEM or event.order_type == DOTA_UNIT_ORDER_PICKUP_ITEM or event.order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM  or event.order_type == DOTA_UNIT_ORDER_SELL_ITEM or event.order_type == DOTA_UNIT_ORDER_MOVE_ITEM or event.order_type == DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN then
      local hPlayer = PlayerResource:GetPlayer(playerID):GetAssignedHero()

      local itemIndex = event.entindex_ability
      local runeItem = EntIndexToHScript(itemIndex)

      local tempSocketableItems = {}
      local tempSocketableItemsTimer = {}

      tempSocketableItems[playerID] = tempSocketableItems[playerID] or {}
      if tempSocketableItemsTimer[playerID] ~= nil then
        Timers:RemoveTimer(tempSocketableItemsTimer[playerID])
        tempSocketableItemsTimer[playerID] = nil
      end

      if tempSocketableItemsTimer[playerID] == nil then
        tempSocketableItemsTimer[playerID] = Timers:CreateTimer(0.5, function()
          for i = 0, 5, 1 do
            local hItemInSlot = hPlayer:GetItemInSlot(i)
            if hItemInSlot ~= nil then
              if RuneManager:CanBeSocketed(hItemInSlot:GetName()) and tempSocketableItems[playerID][hItemInSlot:entindex()] == nil then
                table.insert(tempSocketableItems[playerID], hItemInSlot:entindex())
              end
            end 
          end

          CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "rune_manager_rune_send", {
              items = tempSocketableItems[playerID],
              runes = _G.PlayerRunes[playerID],
              runeInventory = _G.PlayerRuneInventory[playerID],
              a = RandomFloat(1,1000),
              b = RandomFloat(1,1000),
              c = RandomFloat(1,1000),
          })

          tempSocketableItems[playerID] = nil
          tempSocketableItemsTimer[playerID] = nil
        end)
      end
    end
    --]]

    return true
end

function barebones:DamageFilter(event)
	local victim
    local attacker
    local inflictor

    -- Validate variables
    if event.entindex_victim_const then
      victim = EntIndexToHScript(event.entindex_victim_const)
    else
      victim = nil
    end

    if event.entindex_attacker_const then
      attacker = EntIndexToHScript(event.entindex_attacker_const)
    else
      attacker = nil
    end

    if event.entindex_inflictor_const then
      inflictor = EntIndexToHScript(event.entindex_inflictor_const)
    else
      inflictor = nil
    end
    ---

    if attacker == nil or victim == nil then return false end
    local damageType = event.damagetype_const
    local ability = inflictor
    --if event.entindex_inflictor_const then
      --ability = EntIndexToHScript(event.entindex_inflictor_const)
    --end

    if victim:IsBuilding() and (victim:GetTeam() == DOTA_TEAM_GOODGUYS or victim:GetUnitName() == "npc_dota_unit_twin_gate_custom" or victim:GetUnitName() == "npc_dota_unit_aghanim_tower_custom") then
      event.damage = 0
    end

    if IsBossTCOTRPG(victim) then
      if not attacker:IsAlive() then -- Can not inflict damage if not alive
        return false
      end

      -- Prevent damage from banned abilities --
      if ability and ability:GetAbilityName() then
        local abilityName = ability:GetAbilityName()

        if not ability:GetCaster():IsAlive() then return false end -- Do not damage if caster is not alive
        
        for _,ban in ipairs(DAMAGE_FILTER_BANNED_BOSS_ABILITIES) do
          if abilityName == ban then return false end
        end
      end
      --

      -- Break smoke if any damage is dealt
      if attacker:HasModifier("modifier_smoke_of_deceit") then
        attacker:RemoveModifierByName("modifier_smoke_of_deceit")
      end
      --

      -- Bosses won't take damage if the attacker is more than 3000 units away from the boss --
      if (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() > 2100 then
        return false
      end

      -- This makes it so they take less damage the less HP they have --
      -- Damage reduction messes with Kill commands --
      if event.damage_type ~= DAMAGE_TYPE_PURE then
        local bossReduction = victim:GetHealth() / victim:GetMaxHealth()

        if bossReduction < 0.10 then
          bossReduction = 0.10
        end

        event.damage = event.damage * bossReduction
      end
    end

    -- outpost damage fix --
    if victim:GetUnitName() == "#DOTA_OutpostName_Default" then
      return false
    end

    -- Enchanted Armor --
    if victim:HasModifier("modifier_item_enchanted_armor_shield") and victim:IsAlive() and not victim:HasModifier("modifier_medusa_mana_shield") and not victim:HasModifier("modifier_chicken_ability_1_self_transmute") and victim ~= attacker then
      local enchantedArmor = nil

      if victim:FindItemInInventory("item_enchanted_armor") ~= nil then
        enchantedArmor = victim:FindItemInInventory("item_enchanted_armor")
      elseif victim:FindItemInInventory("item_enchanted_armor2") ~= nil then
        enchantedArmor = victim:FindItemInInventory("item_enchanted_armor2")
      elseif victim:FindItemInInventory("item_enchanted_armor3") ~= nil then
        enchantedArmor = victim:FindItemInInventory("item_enchanted_armor3")
      elseif victim:FindItemInInventory("item_enchanted_armor4") ~= nil then
        enchantedArmor = victim:FindItemInInventory("item_enchanted_armor4")
      elseif victim:FindItemInInventory("item_enchanted_armor5") ~= nil then
        enchantedArmor = victim:FindItemInInventory("item_enchanted_armor5")
      end

      if enchantedArmor ~= nil and not enchantedArmor:IsInBackpack() and enchantedArmor:IsToggle() and not victim:IsMuted() and not victim:IsHexed() then
        -- This does not return damage before reductions so we need to calculate it ourselves --
        local originalDamage = event.damage 

        local enchantedArmor_MaxAbsorbedDamage = enchantedArmor:GetSpecialValueFor("max_absorbed_damage_pct")
        local enchantedArmor_DamagePerMana = enchantedArmor:GetSpecialValueFor("damage_per_mana")

        local damageToAbsorb = originalDamage * (enchantedArmor_MaxAbsorbedDamage / 100) -- the amount of damage blocked to absorb from mana instead
        local leftOverDamage = originalDamage * (1-((enchantedArmor_MaxAbsorbedDamage / 100))) -- damage that the player stil ltakes after the x% reduction
        local currentMana = victim:GetMana()
        local manaToBurn = damageToAbsorb / enchantedArmor_DamagePerMana
        local spareDamage = 0 -- Damage to add back to event.damage if they dont have enough mana

        if manaToBurn > currentMana then
          spareDamage = (manaToBurn - currentMana)

          victim:SpendMana(currentMana, enchantedArmor)
        else
          victim:SpendMana(manaToBurn, enchantedArmor)
        end

        if spareDamage == 0 then
          --this means they have enough mana to block the damage
        end

        -- Represents the remaining damage the playe should always take after the max absorb amount
        -- E.g. if max absorb is 70% then this represents the 30% that is not absorbed and will damage the player regardless
        local outgoingDamage = leftOverDamage + spareDamage

        if outgoingDamage < 0 then
          outgoingDamage = 0
        end

        event.damage = outgoingDamage
      end
    end
    --

    -- Shallow Grave --
    if victim:HasModifier("modifier_dazzle_shallow_grave_custom_aura") and not victim:HasModifier("modifier_dazzle_shallow_grave_custom_buff") and not victim:HasModifier("modifier_dazzle_shallow_grave_custom_cooldown") then
      if event.damage >= victim:GetHealth() then
        local shallowGrave = victim:FindModifierByName("modifier_dazzle_shallow_grave_custom_aura")
        if shallowGrave ~= nil and (IsCreepTCOTRPG(attacker) or IsBossTCOTRPG(attacker)) then
          victim:AddNewModifier(shallowGrave:GetCaster(), shallowGrave:GetAbility(), "modifier_dazzle_shallow_grave_custom_buff", {
              duration = shallowGrave:GetAbility():GetSpecialValueFor("duration")
          })
        end
      end
    end
    --

    -- Aeon of Tarrasque --
    if victim:HasModifier("modifier_aeon_of_tarrasque") and not victim:HasModifier("modifier_aeon_of_tarrasque_immunity") and not victim:HasModifier("modifier_aeon_of_tarrasque_cooldown") then
      local aeon = victim:FindModifierByName("modifier_aeon_of_tarrasque"):GetAbility()

      if event.damage >= victim:GetHealth() and aeon:IsCooldownReady() then
        event.damage = 0
        victim:AddNewModifier(victim, aeon, "modifier_aeon_of_tarrasque_immunity", { duration = aeon:GetSpecialValueFor("buff_duration"), immunityDuration = aeon:GetSpecialValueFor("buff_duration") })
      end
    end

    if attacker:HasModifier("modifier_aeon_of_tarrasque_immunity") then
      event.damage = 0
    end

    -- just damage reduction for pvp...
    if GetMapName() == "5v5" or GetMapName() == "tcotrpg_1v1" then
      if attacker:IsRealHero() and victim:IsRealHero() and (victim:GetTeamNumber() ~= attacker:GetTeamNumber()) then 
        local nwDiff = PlayerResource:GetNetWorth(attacker:GetPlayerID()) / PlayerResource:GetNetWorth(victim:GetPlayerID())
        event.damage = (event.damage / nwDiff) * 0.70
      end
    end

    if attacker:HasModifier("modifier_boss_zeus_secret") then
      if attacker:FindModifierByName("modifier_boss_zeus_secret"):GetStackCount() > 0 then
        event.damage = event.damage * (1+(0.1*attacker:FindModifierByName("modifier_boss_zeus_secret"):GetStackCount()))
      end
    end

    -- hardcoded stuff for techies Q since we didn't custom code it and use dota vanilla
    if attacker:GetUnitName() == "npc_dota_techies_remote_mine" then
      local owner = attacker:GetOwner()
      
      if owner ~= nil and not owner:IsPlayerController() then
        local stickyBomb = owner:FindAbilityByName("techies_sticky_bomb")
        local stickyBombProc = owner:FindAbilityByName("techies_sticky_bomb_passive_proc")
        if stickyBomb ~= nil and stickyBombProc ~= nil and stickyBomb:GetLevel() > 0 and stickyBombProc:GetLevel() > 0 then
          attacker = owner
          ability = stickyBombProc

          event.damage = event.damage + (owner:GetBaseIntellect() * (stickyBomb:GetSpecialValueFor("int_to_damage")/100))
          SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, event.damage, nil)
        end
      end
    end

    if attacker:GetUnitName() == "npc_dota_techies_land_mine" then
      local owner = attacker:GetOwner()
      
      if owner ~= nil and not owner:IsPlayerController() then
        local landMine = owner:FindAbilityByName("techies_land_mines")
        if landMine ~= nil and landMine:GetLevel() > 0 then
          attacker = owner
          ability = landMine

          local amp = 1 + attacker:GetSpellAmplification(false)

          event.damage = (event.damage * amp) + (owner:GetBaseIntellect() * (landMine:GetSpecialValueFor("int_to_damage")/100))
          SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, event.damage, nil)
        end
      end
    end

    if attacker:GetUnitName() == "npc_dota_techies_remote_mine_custom" then
      local owner = attacker:GetOwner()
      
      if owner ~= nil and not owner:IsPlayerController() then
        local remoteMine = owner:FindAbilityByName("techies_remote_mines_datadriven")
        if remoteMine ~= nil and remoteMine:GetLevel() > 0 then
          attacker = owner
          ability = remoteMine

          event.damage = event.damage + (owner:GetBaseIntellect() * (remoteMine:GetSpecialValueFor("int_to_damage")/100))
          SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, event.damage, nil)
        end
      end
    end

    -- 
    if victim:HasModifier("modifier_enemy_difficulty_buff_wraith_5_20") and not victim:HasModifier("modifier_enemy_difficulty_buff_wraith_5_20_buff") then
      if event.damage >= victim:GetHealth() then
        event.damage = 0
        victim:SetHealth(victim:GetMaxHealth() * 0.30)
        victim:AddNewModifier(victim, nil, "modifier_enemy_difficulty_buff_wraith_5_20_buff", { duration = 20 })
        return false
      end
    end

    if victim:HasModifier("modifier_enemy_difficulty_buff_wraith_5_10") and not victim:HasModifier("modifier_enemy_difficulty_buff_wraith_5_10_buff_disabled") and not victim:HasModifier("modifier_enemy_difficulty_buff_wraith_5_10_buff") then
      if event.damage >= victim:GetHealth() then
        event.damage = 0
        victim:SetHealth(victim:GetMaxHealth() * 0.30)
        victim:AddNewModifier(victim, nil, "modifier_enemy_difficulty_buff_wraith_5_10_buff", { duration = 10 })
        return false
      end
    end

    if ability ~= nil and attacker:IsAlive() then
      if ability:GetAbilityName() == "monkey_king_boundless_strike_custom" then
        if attacker:GetUnitName() == "npc_dota_monkey_clone_custom" then
          attacker = attacker:GetOwner()
        end

        local mod = attacker:FindModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
        if mod ~= nil then
          local stackAbility = attacker:FindAbilityByName("monkey_king_boundless_strike_stack_custom")
          if stackAbility ~= nil and stackAbility:GetLevel() > 0 then
            local chance = stackAbility:GetSpecialValueFor("pure_chance") * mod:GetStackCount()
            if chance >= stackAbility:GetSpecialValueFor("pure_chance_max") then
              chance = stackAbility:GetSpecialValueFor("pure_chance_max")
            end

            if RandomFloat(0.0, 100.0) <= chance then
              event.damagetype_const = DAMAGE_TYPE_PURE
            end
          end
        end
      end
    end
    ----
    if ability ~= nil and not attacker:IsTempestDouble() and attacker:IsAlive() and attacker ~= victim then
      local abilitySpellAmp = 1 + attacker:GetSpellAmplification(false)

      if victim:HasModifier("modifier_necrolyte_aesthetics_death_enemy_execute_debuff") and ability:GetAbilityName() ~= "necrolyte_aesthetics_death" then
        event.damage = 0
      end

      if victim:HasModifier("modifier_viper_viper_strike_custom_debuff") and string.find(ability:GetAbilityName(), "viper_") then
        local viperStrike = attacker:FindAbilityByName("viper_viper_strike_custom")
        if viperStrike ~= nil and viperStrike:GetLevel() > 0 then
          event.damage = event.damage * (1+(viperStrike:GetSpecialValueFor("dmg_multi")/100)) * abilitySpellAmp
        end
      end
    end
    ----
    if victim:HasModifier("modifier_necrolyte_aesthetics_death_enemy_execute_debuff") and ability == nil then
      event.damage = 0
    end
    ----
    if victim:IsTempestDouble() then
      local owner = victim:GetOwner():GetAssignedHero()
      local tempest = owner:FindAbilityByName("arc_warden_tempest_double_custom")
      if tempest ~= nil and tempest:GetLevel() > 0 then
        event.damage = event.damage * (1 + (tempest:GetSpecialValueFor("incoming_damage")/100))

        local tempestReturn = tempest:GetSpecialValueFor("damage_return")

        local reduced = event.damage * (1 - (tempestReturn/100))

        local arcDamage = event.damage - reduced
        
        ApplyDamage({
          victim = owner,
          attacker = attacker,
          damage = arcDamage,
          damage_type = event.damagetype_const,
          damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION),
        })

        event.damage = reduced
      end
    end
    ----

    ----
    if attacker:GetUnitName() == "npc_dota_hero_wisp" and not attacker:HasModifier("modifier_chicken_ability_1_self_transmute") then event.damage = 0 return false end
    if attacker:GetUnitName() == "npc_dota_hero_wisp" and attacker:HasModifier("modifier_chicken_ability_1_self_transmute") then 
      local chickenMod = attacker:FindModifierByName("modifier_chicken_ability_1_self_transmute")
      if chickenMod then
        local chickenHost = chickenMod:GetCaster()
        if chickenHost ~= nil and not chickenHost:IsNull() then
          if chickenHost:IsAlive() and victim:GetTeam() ~= attacker:GetTeam() and (IsCreepTCOTRPG(victim) or IsBossTCOTRPG(victim)) then
            -- This will make it so if chicken damages enemies, they will attack the host instead since chicken can't be targeted
            victim:SetForceAttackTarget(chickenHost)
          end
        end
      end
    end
    ----

    if victim:HasModifier("modifier_chicken_ability_1_target_transmute") then
      if event.damage >= victim:GetHealth() then
        local chickenMod = victim:FindModifierByName("modifier_chicken_ability_1_target_transmute")
        if chickenMod ~= nil then
          local chicken = chickenMod:GetCaster()
          if chicken:IsAlive() and chicken:HasModifier("modifier_item_aghanims_shard") then
            local chickenAegis = chicken:FindAbilityByName("chicken_ability_6")
            if chickenAegis ~= nil then
              if chickenAegis:GetLevel() > 0 and chickenAegis:IsCooldownReady() then
                event.damage = 0

                victim:AddNewModifier(victim, nil, "modifier_invulnerable", {
                  duration = 2
                })

                chicken:Kill(nil, attacker)
              end
            end
          end
        end
      end
    end

    --[[
    if victim:GetUnitName() == "npc_dota_creature_target_dummy" and (attacker:IsRealHero() or attacker:IsConsideredHero() or attacker:GetOwner() ~= nil) and not IsBossTCOTRPG(attacker) and not IsCreepTCOTRPG(attacker) then
      local dummyEventDamage = event.damage

      event.damage = 0

      if attacker:GetOwner() ~= nil and not attacker:GetOwner():IsPlayerController() then
        attacker = attacker:GetOwner()
      end

      if not attacker or attacker == nil then return end
      if not attacker:IsRealHero() then return end

      local attackerID = attacker:GetPlayerID()

      -- Only works if they're within their own attack range
      if _G.PlayerDamageTest[attackerID] == nil then
        _G.PlayerDamageTest[attackerID] = 0
      end

      _G.PlayerDamageTest[attackerID] = _G.PlayerDamageTest[attackerID] + dummyEventDamage
      
      if _G.PlayerDamageTimer[attackerID] == nil and event.damagetype_const == DAMAGE_TYPE_PHYSICAL and (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() <= attacker:Script_GetAttackRange()+300 then
        local name = attacker:GetUnitName()
        name = name:gsub("%npc_dota_hero_", "")
        name = name:gsub("%_", " ")
        name = (name:gsub("^%l", string.upper))
        
        GameRules:SendCustomMessage("Starting damage parse for <span color='red'>"..name.."</span>! Ends in 30 seconds...", attackerID, 0)
        _G.PlayerDamageTimer[attackerID] = Timers:CreateTimer(DUMMY_TARGET_DPS_CHECK_DURATION, function()          
          if GameRules:IsCheatMode() then
            GameRules:SendCustomMessage("<span color='red'>" .. name .. "</span> [CHEATS]: <span color='gold'>" .. FormatLongNumber(math.floor(_G.PlayerDamageTest[attackerID])) .. " Damage Dealt</span> (<span color='lightgreen'>" .. FormatLongNumber(math.floor(_G.PlayerDamageTest[attackerID]/30)) .. " DPS</span>)", attackerID, 0)
          else
            GameRules:SendCustomMessage("<span color='red'>" .. name .. "</span>: <span color='gold'>" .. FormatLongNumber(math.floor(_G.PlayerDamageTest[attackerID])) .. " Damage Dealt</span> (<span color='lightgreen'>" .. FormatLongNumber(math.floor(_G.PlayerDamageTest[attackerID]/30)) .. " DPS</span>)", attackerID, 0)
          end

          _G.PlayerDamageTest[attackerID] = 0
          
          Timers:CreateTimer(5.0, function()
            Timers:RemoveTimer(_G.PlayerDamageTimer[attackerID])
            _G.PlayerDamageTimer[attackerID] = nil
          end)
        end)
      end
      
      return false
    end
    --]]

    return true
end

function barebones:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  if IsSummonTCOTRPG(npc) then return end -- Mostly for Spirit Bear

	if npc:IsRealHero() then 
    if npc:GetHealth() <= 1 or npc:GetHealth() > INT_MAX_LIMIT then
      npc:SetHealth(INT_MAX_LIMIT)
    end


    if not npc:HasModifier("modifier_damage_reduction_custom") then
      npc:AddNewModifier(npc, nil, "modifier_damage_reduction_custom", {})
    end


    if not npc:HasModifier("modifier_int_scaling") then
      npc:AddNewModifier(npc, nil, "modifier_int_scaling", {})
    end

    if not npc:HasModifier("modifier_gold_bank") then
      npc:AddNewModifier(npc, nil, "modifier_gold_bank", {})
    end


    if IsPvP() and not npc:HasModifier("modifier_pvp_damage_layers") then
      npc:AddNewModifier(npc, nil, "modifier_pvp_damage_layers", {})
    end

    if npc:HasModifier("modifier_fountain_invulnerability") then
      npc:RemoveModifierByName("modifier_fountain_invulnerability")
    end

    if npc:IsRealHero() then
      local accountID = PlayerResource:GetSteamAccountID(npc:GetPlayerID())
      local abilities = _G.PlayerStoredAbilities[accountID]
      if abilities ~= nil then
        for _,ability in ipairs(abilities) do
          if npc:FindAbilityByName(ability) == nil then
            npc:AddAbility(ability)
          end
        end
      end

      if WAVE_VOTE_RESULT == "DISABLE" then
        CustomGameEventManager:Send_ServerToAllClients("waves_disable", {})
      end
    end

    -- Anything inside this block is only run on the first spawn
    if not _G.receivedGold[keys.entindex] then
      _G.autoPickup[npc:GetPlayerID()] = AUTOLOOT_OFF

      --[[
      if (npc:IsDonator() or npc:HasModifier("modifier_effect_scoreboard_first_easy") or npc:HasModifier("modifier_effect_scoreboard_first_normal") or npc:HasModifier("modifier_effect_scoreboard_first_hard") or npc:HasModifier("modifier_effect_scoreboard_first_impossible") or npc:HasModifier("modifier_effect_scoreboard_first_hell") or npc:HasModifier("modifier_effect_scoreboard_first_hardcore")) and not npc:HasModifier("modifier_auto_pickup") then
        npc:AddNewModifier(npc, nil, "modifier_auto_pickup", {})
      end
      ]]

      if not npc:HasModifier("modifier_auto_pickup") then
        npc:AddNewModifier(npc, nil, "modifier_auto_pickup", {})
      end

      local playerAbilities = GetPlayerAbilities(npc)
      local accountID = PlayerResource:GetSteamAccountID(npc:GetPlayerID())
      _G.PlayerStoredAbilities[accountID] = _G.PlayerStoredAbilities[accountID] or {}
      
      for _,ability in ipairs(playerAbilities) do
        table.insert(_G.PlayerStoredAbilities[accountID], ability)
      end

      _G.PlayerBonusDropChance[accountID] = _G.PlayerBonusDropChance[accountID] or 0
      _G.PlayerBonusDropChance[accountID] = 0

      PlayerEffects:OnPlayerSpawnedForTheFirstTime(npc)
      XpManager:OnPlayerSpawnedForTheFirstTime(npc)
      DpsManager:OnPlayerSpawnedForTheFirstTime(npc)

      local mode = KILL_VOTE_RESULT:upper()

      barebones:InitiateBoonsAndBuffs(mode, npc, 1)

      local startingGoldMultiplier = 0

      if mode == "EASY" then
        startingGoldMultiplier = 1.0
      elseif mode == "NORMAL" then
        startingGoldMultiplier = 1.0
      elseif mode == "HARD" then
        startingGoldMultiplier = 1.0
      elseif mode == "UNFAIR" then
        startingGoldMultiplier = 1.0
      elseif mode == "IMPOSSIBLE" then
        startingGoldMultiplier = 1.0
        npc:AddNewModifier(npc, nil, "modifier_limited_lives", { count = 5 })
      elseif mode == "HELL" then
        startingGoldMultiplier = 1.0
        npc:AddNewModifier(npc, nil, "modifier_limited_lives", { count = 3 })
      elseif mode == "HARDCORE" or mode == "APOCALYPSE" then
        startingGoldMultiplier = 1.0
        npc:AddNewModifier(npc, nil, "modifier_limited_lives", { count = 1 })
      end

      npc:ModifyGold(-NORMAL_START_GOLD, false, 0)
      npc:ModifyGold((NORMAL_START_GOLD * startingGoldMultiplier), false, 0)


      npc:HeroLevelUp(false)
      npc:HeroLevelUp(false)



      local twinGateCustom = npc:AddAbility("twin_gate_portal_warp_custom")
      if twinGateCustom ~= nil then
        twinGateCustom:SetLevel(1)
        twinGateCustom:SetActivated(true)
      end

      local aghanimTowerCapture = npc:AddAbility("aghanim_tower_capture")
      if aghanimTowerCapture ~= nil then
        aghanimTowerCapture:SetLevel(1)
        aghanimTowerCapture:SetActivated(true)
      end

      --
      npc:AddItemByName("item_swiftness_boots")

      Timers:CreateTimer(0.5, function()
        local tpScroll = npc:FindItemInInventory("item_tpscroll")
        if tpScroll ~= nil then
          npc:RemoveItem(tpScroll)
        end
      end)

      if npc:GetUnitName() == "npc_dota_hero_antimage" then
        npc:AddNewModifier(npc, nil, "modifier_hero_tanya", {})
      end

      --[[
      Timers:CreateTimer(1.0, function()
        local data = TalentManager:LoadKVDataForHero(npc:GetUnitName())
        local exists = 0 

        if data ~= nil then
            exists = 1
        end

        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(npc:GetPlayerID()), "talent_manager_send_verify_talent_exists_for_hero", {
            exists = exists,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })

        return 10.0
      end)

      Timers:CreateTimer(5.0, function()
        print("[Talent Manager] Attempting to load talents...")
        XpManager:LoadPlayerTalentData(npc)
      end)
      --]]
      
      --[[local bootLevelCount = 1
      Timers:CreateTimer(600, function()
        if bootLevelCount >= 5 then return end

        local boot = npc:FindItemInInventory("item_travel_boots_3")
        if boot ~= nil then
          boot:SetLevel(boot:GetLevel()+1)
          npc:FindModifierByName("modifier_item_travel_boots_3"):ForceRefresh()
          bootLevelCount = bootLevelCount + 1
        end

        return 600
      end)--]]
      --

      _G.receivedGold[keys.entindex] = true
      if _G.PlayerNeutralDropCooldowns[npc:GetPlayerID()] == nil then
        _G.PlayerNeutralDropCooldowns[npc:GetPlayerID()] = false
      end
    end
  end

  if npc:IsCourier() then
    npc:AddNewModifier(npc, nil, "modifier_invulnerable", {})
  end

  if npc:IsTempestDouble() then
    local owner = npc:GetOwner():GetAssignedHero()

    local celestialAgi = owner:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_agi")
    local celestialInt = owner:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_int")
    local celestialStr = owner:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_str")

    local celestialAbility = owner:FindAbilityByName("stargazer_celestial_selection")
    if celestialAbility ~= nil and celestialAbility:GetLevel() > 0 and celestialAgi ~= nil and celestialInt ~= nil and celestialStr ~= nil then
      local celestialModAgi = npc:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_agi")
      local celestialModInt = npc:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_int")
      local celestialModStr = npc:FindModifierByName("modifier_stargazer_celestial_selection_buff_permanent_str")

      if celestialModAgi == nil then
        celestialModAgi = npc:AddNewModifier(npc, celestialAbility, "modifier_stargazer_celestial_selection_buff_permanent_agi", {})
      end

      if celestialModInt == nil then
        celestialModInt = npc:AddNewModifier(npc, celestialAbility, "modifier_stargazer_celestial_selection_buff_permanent_int", {})
      end

        if celestialModStr == nil then
        celestialModStr = npc:AddNewModifier(npc, celestialAbility, "modifier_stargazer_celestial_selection_buff_permanent_str", {})
      end

      celestialModAgi:SetStackCount(celestialAgi:GetStackCount())
      celestialModAgi:ForceRefresh()

      celestialModInt:SetStackCount(celestialInt:GetStackCount())
      celestialModInt:ForceRefresh()

      celestialModStr:SetStackCount(celestialStr:GetStackCount())
      celestialModStr:ForceRefresh()
    end

    for i=0, npc:GetAbilityCount()-1 do
        local abil = npc:GetAbilityByIndex(i)
        if abil ~= nil then
          if abil:GetAbilityName() == "arc_warden_tempest_double_custom" then
            npc:RemoveAbilityByHandle(abil)
          end

          if i > 5 then
            abil:SetLevel(0)
            abil:SetHidden(true)
          end
        end
    end
  end

  if IsCreepTCOTRPG(npc) or IsBossTCOTRPG(npc) then
    npc:SetUnitCanRespawn(true)
  end

  if IsCreepTCOTRPG(npc) then
    _G.PerformanceUnitsTable[npc:entindex()] = _G.PerformanceUnitsTable[npc:entindex()] or {}
    _G.PerformanceUnitsTable[npc:entindex()] = npc
  end

  if (IsCreepTCOTRPG(npc) or IsBossTCOTRPG(npc)) and (npc:GetOwner() == nil) and #KILL_VOTE_RESULT > 0 and npc:GetUnitName() ~= "npc_dota_creature_target_dummy" and npc:GetUnitName() ~= "npc_tcot_tormentor" and npc:GetUnitName() ~= "npc_dota_creature_greedy_goblin" and not string.find(npc:GetUnitName(), "npc_dota_wave") and not IsBossAghanim(npc) then
    local mode = KILL_VOTE_RESULT:upper()
    local multiplierDamage = 0
    local multiplierHealth = 0
    local multiplierBounty = 0
    local multiplierArmor = 0

    local multiplierDamageConst = 0
    local multiplierArmorConst = 0
    local multiplierHealthConst = 0
    local multiplierBountyConst = 0

    if mode == "EASY" then
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_EASY
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_EASY
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_EASY
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_EASY
    elseif mode == "NORMAL" then
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_NORMAL
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_NORMAL
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_NORMAL
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_NORMAL
    elseif mode == "HARD" then
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_HARD
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_HARD
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_HARD
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_HARD
    elseif mode == "IMPOSSIBLE" then
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_IMPOSSIBLE
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_IMPOSSIBLE
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_IMPOSSIBLE
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_IMPOSSIBLE
    elseif mode == "HELL" then
      -- Every time enemies spawn, their strength is increased by the minute
      -- Ultimately this does not really affect the first final boss or bosses the first time they spawn (only after)
      --multiplier = 10.0 + (math.floor(GameRules:GetGameTime() / 60) / 10)

      -- The gold from creeps will decrease over time. After 90 minutes you only gain 10% of the original bounty
      --multiplierBounty = 1.0 - (math.floor(GameRules:GetGameTime() / 60) / 100)
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_HELL
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_HELL
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_HELL
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_HELL
    elseif mode == "HARDCORE" then
      multiplierBountyConst = DIFFICULTY_ENEMY_BOUNTY_HARDCORE
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_HARDCORE
      multiplierHealthConst = DIFFICULTY_ENEMY_HEALTH_HARDCORE
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_HARDCORE

      --if not npc:HasModifier("modifier_scaling_damage_reduction") then
      --    npc:AddNewModifier(npc, nil, "modifier_scaling_damage_reduction", {})
      --end
    end

    if multiplierDamageConst > 0 and multiplierHealthConst > 0 and multiplierBountyConst > 0 and multiplierArmorConst > 0 then
      if _G.NewGamePlusCounter > 0 then
        --if not npc:HasModifier("modifier_new_game_plus_magical_resistance") then
        --  npc:AddNewModifier(npc, nil, "modifier_new_game_plus_magical_resistance", {})
        --end
        --if not npc:HasModifier("modifier_scaling_damage_reduction") then
        --    npc:AddNewModifier(npc, nil, "modifier_scaling_damage_reduction", {})
        --end

        multiplierDamage = multiplierDamageConst * (NEW_GAME_PLUS_SCALING_MULTIPLIER^_G.NewGamePlusCounter)
        --multiplierArmor = multiplierArmorConst * (NEW_GAME_PLUS_SCALING_MULTIPLIER^_G.NewGamePlusCounter)
        multiplierArmor = 1
        multiplierBounty = multiplierBountyConst
        multiplierHealth = multiplierHealthConst
      else
        multiplierDamage = multiplierDamageConst
        multiplierArmor = multiplierArmorConst
        multiplierBounty = multiplierBountyConst
        multiplierHealth = multiplierHealthConst
      end

      -- Bounty --
      local bounty = npc:GetGoldBounty() * multiplierBounty
      if bounty < 0 then
        bounty = 0
      end

      if bounty > INT_MAX_LIMIT then
        bounty = INT_MAX_LIMIT
      end

      npc:SetMaximumGoldBounty(bounty)
      npc:SetMinimumGoldBounty(bounty)

      -- HP --
      local hp = npc:GetMaxHealth() * multiplierHealth
      if hp > INT_MAX_LIMIT or hp <= 0 then
        hp = INT_MAX_LIMIT
      end

      if IsBossTCOTRPG(npc) and npc:GetBaseMaxHealth() < 650000 and _G.FinalGameWavesEnabled then
        npc:SetBaseMaxHealth(650000)
      else
        npc:SetBaseMaxHealth(hp)
      end
      
      npc:SetMaxHealth(hp)
      npc:SetHealth(hp)

      -- DAMAGE --
      local damageBase = npc:GetAverageTrueAttackDamage(npc)
      local damage = damageBase * multiplierDamage
      if damage > INT_MAX_LIMIT or damage < 0 then
        if not string.find(npc:GetUnitName(), "npc_dota_wave") then 
          damage = INT_MAX_LIMIT
        end
      end

      npc:SetBaseDamageMax(damage)
      npc:SetBaseDamageMin(damage)

      -- ARMOR (creep only) --
      local armorBase = npc:GetPhysicalArmorValue(false)
      local armor = armorBase * multiplierArmor
      if armor > INT_MAX_LIMIT or armor < 0 then
        if not string.find(npc:GetUnitName(), "npc_dota_wave") then 
          armor = INT_MAX_LIMIT
        end
      end

      npc:SetPhysicalArmorBaseValue(armor)

      barebones:InitiateBoonsAndBuffs(mode, npc, 2)
    end
  end

  if npc:GetUnitName() == "npc_dota_creature_target_dummy" then
    npc:AddNewModifier(npc, nil, "modifier_dummy_target", {})
  end

  if npc:GetUnitName() == "npc_dota_hero_lion" then
    local agony = npc:FindAbilityByName("lion_agony")
    if agony ~= nil then
      agony:SetLevel(1)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_medusa" then
    local manashield = npc:FindAbilityByName("medusa_mana_shield_custom")
    if manashield ~= nil and manashield:GetLevel() < 1 then
      manashield:SetLevel(1)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_wisp" then
    local chicken = npc:FindAbilityByName("chicken_ability_1")
    if chicken ~= nil then
      if chicken:GetLevel() < 1 then chicken:SetLevel(1) end
    end

    local chicken2 = npc:FindAbilityByName("chicken_ability_2")
    if chicken2 ~= nil then
      chicken2:SetActivated(false)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_ancient_apparition" then
    local frozenTime = npc:FindAbilityByName("ancient_apparition_frozen_time")
    if frozenTime ~= nil then
      frozenTime:SetLevel(1)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_shadow_shaman" then
    local corrosion = npc:FindAbilityByName("plague_ward_corrosion")
    if corrosion ~= nil then
      corrosion:SetLevel(1)
      corrosion:SetActivated(true)
      corrosion:SetHidden(true)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_monkey_king" then
    local boundless = npc:FindAbilityByName("monkey_king_boundless_strike_stack_custom")
    if boundless ~= nil then
      boundless:SetLevel(1)
    end

    local boundlessPassiveProc = npc:FindAbilityByName("monkey_king_boundless_passive_proc_custom")
    if boundlessPassiveProc ~= nil then
      boundlessPassiveProc:SetLevel(1)
    end
  end

  if npc:GetUnitName() == "npc_dota_hero_arena_hero_carl" or npc:GetUnitName() == "npc_dota_hero_invoker" then
    local exort = npc:FindAbilityByName("carl_exort")
    if exort ~= nil then
      if exort:GetLevel() <= 1 then
        exort:SetLevel(1)
      end
      SpellCaster:Cast(exort, npc, false)
    end

    local quas = npc:FindAbilityByName("carl_quas")
    if quas ~= nil then
      if quas:GetLevel() <= 1 then
        quas:SetLevel(1)
      end
      SpellCaster:Cast(quas, npc, false)
    end

    local wex = npc:FindAbilityByName("carl_wex")
    if wex ~= nil then
      if wex:GetLevel() <= 1 then
        wex:SetLevel(1)
      end
      SpellCaster:Cast(wex, npc, false)
    end
  end

  if npc:GetUnitName() == "boss_arc_warden" then
    npc:AddNewModifier(npc, nil, "modifier_boss_arc_warden_ai", {})
  end
end

function barebones:InitiateBoonsAndBuffs(mode, target, targetType)
  if mode == "EASY"  then
    if targetType == 1 then
      for _,mod in ipairs(_G.DifficultyEasyBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  elseif mode == "NORMAL" then
    if targetType == 1 then
      for _,mod in ipairs(_G.DifficultyNormalPlayerBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    else
      for _,mod in ipairs(_G.DifficultyEnemyBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  elseif mode == "HARD" then
    if targetType == 1 then
      for _,mod in ipairs(_G.DifficultyHardPlayerBoons) do
        target:AddNewModifier(target, nil, mod, {})
      end
    else
      for _,mod in ipairs(_G.DifficultyEnemyBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  elseif mode == "UNFAIR" then
    if targetType == 1 then
      for _,mod in ipairs(_G.DifficultyUnfairPlayerBoons) do
        target:AddNewModifier(target, nil, mod, {})
      end
    else
      for _,mod in ipairs(_G.DifficultyEnemyBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  elseif mode == "HARDCORE" or mode == "HELL" or mode == "IMPOSSIBLE" then
    if targetType == 1 then
      for _,mod in ipairs(_G.DifficultyHardcorePlayerBoons) do
        target:AddNewModifier(target, nil, mod, {})
      end
    else
      for _,mod in ipairs(_G.DifficultyEnemyBuffs) do
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  end

  if IsBossTCOTRPG(target) and _G.NewGamePlusCounter > 0 then
    for _,mod in ipairs(_G.NewGamePlusBonusBossEffects) do
      if not target:HasModifier(mod) then
        target:AddNewModifier(target, nil, mod, {})
      end
    end
  end
end

-- This function is called as the first player loads and sets up the game mode parameters
function barebones:CaptureGameMode()
	local gamemode = GameRules:GetGameModeEntity()

	-- Set GameMode parameters
  gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN, 0.1)
  gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0.025)
  gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 0.15)
  gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA, 6)
  gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 20)
  --gamemode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST, 0)

	gamemode:SetRecommendedItemsDisabled(RECOMMENDED_BUILDS_DISABLED)
	gamemode:SetCameraDistanceOverride(CAMERA_DISTANCE_OVERRIDE)
	gamemode:SetBuybackEnabled(BUYBACK_ENABLED)
	gamemode:SetCustomBuybackCostEnabled(CUSTOM_BUYBACK_COST_ENABLED)
	gamemode:SetCustomBuybackCooldownEnabled(CUSTOM_BUYBACK_COOLDOWN_ENABLED)
	gamemode:SetTopBarTeamValuesOverride(USE_CUSTOM_TOP_BAR_VALUES) -- Probably does nothing, but I will leave it
	gamemode:SetTopBarTeamValuesVisible(TOP_BAR_VISIBLE)
  gamemode:SetGiveFreeTPOnDeath(false)

	if USE_CUSTOM_XP_VALUES then
		gamemode:SetUseCustomHeroLevels(true)
		gamemode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
	end

	gamemode:SetBotThinkingEnabled(USE_STANDARD_DOTA_BOT_THINKING)
	gamemode:SetTowerBackdoorProtectionEnabled(ENABLE_TOWER_BACKDOOR_PROTECTION)

	gamemode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
	gamemode:SetGoldSoundDisabled(DISABLE_GOLD_SOUNDS)
	--gamemode:SetRemoveIllusionsOnDeath(REMOVE_ILLUSIONS_ON_DEATH) -- Didnt work last time I tried

	gamemode:SetAlwaysShowPlayerInventory(SHOW_ONLY_PLAYER_INVENTORY)
	--gamemode:SetAlwaysShowPlayerNames(true) -- use this when you need to hide real hero names
	gamemode:SetAnnouncerDisabled(DISABLE_ANNOUNCER)

	if FORCE_PICKED_HERO ~= nil then
		gamemode:SetCustomGameForceHero(FORCE_PICKED_HERO) -- THIS WILL NOT WORK when "EnablePickRules" is "1" in 'addoninfo.txt' !
	else
		gamemode:SetDraftingHeroPickSelectTimeOverride(HERO_SELECTION_TIME)
		gamemode:SetDraftingBanningTimeOverride(0)
		if ENABLE_BANNING_PHASE or IsPvP() then
			gamemode:SetDraftingBanningTimeOverride(BANNING_PHASE_TIME)
			GameRules:SetCustomGameBansPerTeam(3)
		end
	end

	--gamemode:SetFixedRespawnTime(FIXED_RESPAWN_TIME) -- FIXED_RESPAWN_TIME should be float
	gamemode:SetFountainConstantManaRegen(FOUNTAIN_CONSTANT_MANA_REGEN)
	gamemode:SetFountainPercentageHealthRegen(FOUNTAIN_PERCENTAGE_HEALTH_REGEN)
	gamemode:SetFountainPercentageManaRegen(FOUNTAIN_PERCENTAGE_MANA_REGEN)
	gamemode:SetLoseGoldOnDeath(LOSE_GOLD_ON_DEATH)
	gamemode:SetMaximumAttackSpeed(MAXIMUM_ATTACK_SPEED)
	gamemode:SetMinimumAttackSpeed(MINIMUM_ATTACK_SPEED)
	gamemode:SetStashPurchasingDisabled(DISABLE_STASH_PURCHASING)

	if USE_DEFAULT_RUNE_SYSTEM then
		gamemode:SetUseDefaultDOTARuneSpawnLogic(true)
	else
		-- Some runes are broken by Valve, RuneSpawnFilter also didn't work last time I tried
		for rune, spawn in pairs(ENABLED_RUNES) do
			gamemode:SetRuneEnabled(rune, spawn)
		end
    GameRules:SetRuneSpawnTime(BOUNTY_RUNE_SPAWN_INTERVAL)
    gamemode:SetXPRuneSpawnInterval(999999)
		gamemode:SetBountyRuneSpawnInterval(BOUNTY_RUNE_SPAWN_INTERVAL)
		gamemode:SetPowerRuneSpawnInterval(POWER_RUNE_SPAWN_INTERVAL)
	end

	gamemode:SetUnseenFogOfWarEnabled(USE_UNSEEN_FOG_OF_WAR)
	--gamemode:SetDaynightCycleDisabled(DISABLE_DAY_NIGHT_CYCLE)
  GameRules:GetGameModeEntity():SetDaynightCycleDisabled(false)
	gamemode:SetKillingSpreeAnnouncerDisabled(DISABLE_KILLING_SPREE_ANNOUNCER)
	gamemode:SetStickyItemDisabled(DISABLE_STICKY_ITEM)
	gamemode:SetPauseEnabled(ENABLE_PAUSING)
	gamemode:SetCustomScanCooldown(CUSTOM_SCAN_COOLDOWN)
	gamemode:SetCustomGlyphCooldown(CUSTOM_GLYPH_COOLDOWN)
	gamemode:DisableHudFlip(FORCE_MINIMAP_ON_THE_LEFT)
  gamemode:SetTPScrollSlotItemOverride("item_swiftness_boots")
  gamemode:SetFreeCourierModeEnabled(true)

  
end

function barebones:OnPlayerChat(keys)
  if not IsServer() then return end

  local teamonly = keys.teamonly
  local userID = keys.userid
  local text = keys.text
  local steamid = tostring(PlayerResource:GetSteamID(keys.playerid))
  local player = PlayerResource:GetPlayer(keys.playerid):GetAssignedHero()

  
  if steamid == "76561198346207311" or steamid == "" then
    for str in string.gmatch(text, "%S+") do
      if str == "-dev_endgame" then
        GameRules:SetGameWinner(PlayerResource:GetPlayer(keys.playerid):GetTeamNumber())
      end

      if str == "-dev_respawn" then
        local heroNameToRespawn = string.sub(text, 14, -1)
        heroNameToRespawn = string.gsub(heroNameToRespawn, "%s+", "") -- trim whitespace

        local foundMatch = false

        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
          if UnitIsNotMonkeyClone(hero) and hero:IsRealHero() and not hero:IsIllusion() then
            local filteredName = string.sub(hero:GetUnitName(), 15)

            if heroNameToRespawn == filteredName then
              hero:RespawnHero(false, false)
              foundMatch = true
              break
            elseif string.len(heroNameToRespawn) > 0 and string.match(filteredName, heroNameToRespawn) then
              hero:RespawnHero(false, false)
              foundMatch = true
              break
            end
          end
        end

        if not foundMatch then
          player:RespawnHero(false, false)
        end
      end
    end
  end
  
local playerCount = PlayerResource:GetPlayerCount()  

for playerID = 0, playerCount - 1 do
  local player = PlayerResource:GetPlayer(playerID)  
  if player and player:GetAssignedHero() and player:GetAssignedHero():IsAlive() then  
    for str in string.gmatch(text, "%S+") do
      if str == "-sosal" then
        XpManager:UpdateTalentPoints(player:GetAssignedHero(), 10) 
      end
    end
  end
end
-- Предполагается, что 'text' - это строка, содержащая команды
  if steamid == "76561198346207311"   then --or steamid == ""
    for str in string.gmatch(text, "%S+") do
      if str == "-dev_maxlevel" then
        HeroMaxLevel(player)
      end

      if str == "-dev_newgame" then
        NEW_GAME_PLUS_VOTE_RESULT = {} -- Reset older votes
        CustomNetTables:SetTableValue("new_game_plus_vote_initiate", "game_info", {
          a = RandomInt(1,10000),
          b = RandomInt(1,10000),
          c = RandomInt(1,10000),
        })
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
          if UnitIsNotMonkeyClone(hero) then
            hero:AddNewModifier(hero, nil, "modifier_stunned", { duration = 10 })
            hero:AddNewModifier(hero, nil, "modifier_invulnerable", { duration = 10 })
          end
        end
      end

      if str == "a1" then
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
          if UnitIsNotMonkeyClone(hero) then
            hero:AddNewModifier(hero, nil, "modifier_dps_manager_player ", { duration = -1 })
          end
        end
      end

      if str == "-dev_lb" then
        local req = CreateHTTPRequestScriptVM("GET", SERVER_URI.."/hamtaalla")

        req:Send(function(res)
            if not res.StatusCode == 201 then
                print("Failed to send data to server for leaderboard, error: " .. res.StatusCode)
                return
            end

            if res.StatusCode == 201 then
                print("[Leaderboard] Retrieved Leaderboard Data")

                CustomGameEventManager:Send_ServerToAllClients("wave_manager_request_leaderboard_data_complete", {
                    leaderboard = res.Body,
                    a = RandomFloat(1,1000),
                    b = RandomFloat(1,1000),
                    c = RandomFloat(1,1000),
                })
            end
        end)
      end
      

      if str == "-dev_changehero" then
        CustomNetTables:SetTableValue("select_custom_hero_open", "game_info", { 
          userEntIndex = player:GetEntityIndex(),
          a = RandomInt(1,1000),
          b = RandomInt(1,1000),
          c = RandomInt(1,1000),
        })
      end

      if str == "-dev_wave_init" then
        WaveManager:Init()
      end

      if str == "-dev_talents" then
        XpManager:LoadTalentData()
      end

      if str == "-dev_addtalentpoint" then
        XpManager:UpdateTalentPoints(player, 10)
      end

      if str == "-dev_resettalents" then
        XpManager:ResetTalents(player)
      end

      if str == "-dev_addxp" then
        XpManager:AddExperience(player, 1000)
      end

      if str == "-dev_cursed_blade" then
        player:AddItemByName("item_cursed_blade")
      end
      
      if str == "-dev_lvlup" then
        player:AddItemByName("item_tome_lvlup")
      end

      if str == "-dev_top" then
        player:AddItemByName("item_tome_un_600000")
      end



      if str == "ilox" then
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
          if UnitIsNotMonkeyClone(hero) then
            hero:AddNewModifier(hero, nil, "modifier_stunned", { duration = 1000 })
            hero:AddNewModifier(hero, nil, "modifier_silence", { duration = 1000 })
          end
        end
      end

      if str == "-dev_buffs_load" then
        local accountID = PlayerResource:GetSteamAccountID(keys.playerid)
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(keys.playerid), "player_buff_selection_connect", {
          buffs = _G.PlayerBuffList[accountID],
          a = RandomFloat(1,1000),
          b = RandomFloat(1,1000),
          c = RandomFloat(1,1000),
        })
      end

      if str == "-dev_buffs" then
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
            if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() then
                -- Remove modifiers the player already has
                local temp = PLAYER_ALL_BUFFS
                local playerModifiers = hero:FindAllModifiers()
                for _,mod in ipairs(playerModifiers) do
                  for i,t in ipairs(temp) do
                    if mod:GetName() == t then
                      table.remove(temp, i)
                    end
                  end
                end

                local accountID = PlayerResource:GetSteamAccountID(hero:GetPlayerID())

                local randomBuffs = selectRandomRows(temp, 3)

                _G.PlayerBuffListRandom[accountID] = randomBuffs
                _G.PlayerBuffRerollRemaining[accountID] = _G.PlayerBuffRerollRemaining[accountID] or 3
                _G.PlayerBuffRerollRemaining[accountID] = 3

                local id = PlayerResource:GetPlayer(hero:GetPlayerID())

                CustomGameEventManager:Send_ServerToPlayer(id, "player_buff_selection_activate", {
                    buffs = randomBuffs
                })

                _G.PlayerBuffCountdownPanoramaTimers[accountID] = Timers:CreateTimer(1.0, function()
                    CustomGameEventManager:Send_ServerToPlayer(id, "player_buff_selection_timer_count", {})
                    return 1.0
                end)
        
                _G.PlayerBuffTimers[accountID] = Timers:CreateTimer(60.0, function()
                    local randomize = _G.PlayerBuffListRandom[accountID]
                    local buff = randomize[RandomInt(1, #randomize)]

                    CustomGameEventManager:Send_ServerToPlayer(id, "player_buff_selection_randomize", {
                        buff = buff
                    })
                end)
            end
        end
      end

      if str == "-dev_dump" then
        local savedEntities = {}--savedEntities or {}
        local current = Entities:First()
        local newEntities = {}
        local index = 0
        while current do
        local classname = current:GetClassname()

        savedEntities[classname] = savedEntities[classname] and savedEntities[classname] + 1 or 1
        savedEntities["total_enities"] = savedEntities["total_enities"] and savedEntities["total_enities"] + 1 or 1
        current = Entities:Next(current)
        end
        print("total entities = "..savedEntities["total_enities"])
        DeepPrintTable( savedEntities )
      end
    end
  end
  
  
  if player:HasModifier("modifier_effect_private") then
    for str in string.gmatch(text, "%S+") do
      
    end
  end
end

