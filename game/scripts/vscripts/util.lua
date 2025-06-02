function table_eq(table1, table2)
   local avoid_loops = {}
   local function recurse(t1, t2)
      -- compare value types
      if type(t1) ~= type(t2) then return false end
      -- Base case: compare simple values
      if type(t1) ~= "table" then return t1 == t2 end
      -- Now, on to tables.
      -- First, let's avoid looping forever.
      if avoid_loops[t1] then return avoid_loops[t1] == t2 end
      avoid_loops[t1] = t2
      -- Copy keys from t2
      local t2keys = {}
      local t2tablekeys = {}
      for k, _ in pairs(t2) do
         if type(k) == "table" then table.insert(t2tablekeys, k) end
         t2keys[k] = true
      end
      -- Let's iterate keys from t1
      for k1, v1 in pairs(t1) do
         local v2 = t2[k1]
         if type(k1) == "table" then
            -- if key is a table, we need to find an equivalent one.
            local ok = false
            for i, tk in ipairs(t2tablekeys) do
               if table_eq(k1, tk) and recurse(v1, t2[tk]) then
                  table.remove(t2tablekeys, i)
                  t2keys[tk] = nil
                  ok = true
                  break
               end
            end
            if not ok then return false end
         else
            -- t1 has a key which t2 doesn't have, fail.
            if v2 == nil then return false end
            t2keys[k1] = nil
            if not recurse(v1, v2) then return false end
         end
      end
      -- if t2 has a key which t1 doesn't have, fail.
      if next(t2keys) then return false end
      return true
   end
   return recurse(table1, table2)
end

function CDOTA_BaseNPC:CenterCameraOnEntity(hTarget, iDuration)
  PlayerResource:SetCameraTarget(self:GetPlayerID(), hTarget)
  if iDuration == nil then iDuration = FrameTime() end
  if iDuration ~= -1 then
    Timers:CreateTimer(iDuration, function()
      PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
      Timers:CreateTimer(FrameTime(), function() --fail-safe
        PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
      end)
      Timers:CreateTimer(FrameTime() * 3, function() --fail-safe
        PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
      end)
    end)
  end
end

function IsPvP()
  return GetMapName() == "tcotrpg1v1"
end

function DebugPrint(...)
	if USE_DEBUG then
		print(...)
	end
end

function GetPerpendicularVector(vector)
  return Vector(vector.y, -vector.x)
end

function GetLevelFromDifficulty()
  local level = 1
  local difficulty = KILL_VOTE_RESULT:upper()
  if difficulty == "HARD" then
      level = 2
  elseif difficulty == "IMPOSSIBLE" then
    level = 3
  elseif difficulty == "HELL" then
    level = 4
  elseif difficulty == "HARDCORE" then
    level = 5
  end

  return level
end

function CalculateDistance(ent1, ent2, b3D)
  local pos1 = ent1
  local pos2 = ent2
  if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
  if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
  local vector = (pos1 - pos2)
  if b3D then
    return vector:Length()
  else
    return vector:Length2D()
  end
end

function CalculateDirection(ent1, ent2)
  local pos1 = ent1
  local pos2 = ent2
  if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
  if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
  local direction = (pos1 - pos2)
  direction.z = 0
  return direction:Normalized()
end

function SetBoonsAndBuffs(mode)
  if mode == "HARDCORE" or mode == "IMPOSSIBLE" or mode == "HELL" then
    local numEnemyBuffs = 1

    if mode == "HELL" then
      numEnemyBuffs = 2
    elseif mode == "HARDCORE" then
      numEnemyBuffs = 3
    end

    t = PLAYER_ALL_BOONS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyHardcorePlayerBoons, t[index])
      table.remove(t, index)
    end

    t = ENEMY_ALL_BUFFS

    for i = 1, numEnemyBuffs, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyEnemyBuffs, t[index])
      table.remove(t, index)
    end

    _G.DifficultyChatTablePlayers = _G.DifficultyHardcorePlayerBoons
    _G.DifficultyChatTableEnemies = _G.DifficultyEnemyBuffs
  end

  if mode == "EASY" then
    t = PLAYER_EASY_BUFFS
    for i = 1, 2, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyEasyBuffs, t[index])
      table.remove(t, index)
    end
    _G.DifficultyChatTablePlayers = _G.DifficultyEasyBuffs
  end

  if mode == "NORMAL" then
    t = PLAYER_NORMAL_BUFFS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyNormalPlayerBuffs, t[index])
      table.remove(t, index)
    end

    t = ENEMY_ALL_BUFFS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyEnemyBuffs, t[index])
      table.remove(t, index)
    end

    _G.DifficultyChatTablePlayers = _G.DifficultyNormalPlayerBuffs
    _G.DifficultyChatTableEnemies = _G.DifficultyEnemyBuffs
  end

  if mode == "HARD" then
    t = PLAYER_ALL_BOONS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyHardPlayerBoons, t[index])
      table.remove(t, index)
    end

    t = ENEMY_ALL_BUFFS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyEnemyBuffs, t[index])
      table.remove(t, index)
    end

    _G.DifficultyChatTablePlayers = _G.DifficultyHardPlayerBoons
    _G.DifficultyChatTableEnemies = _G.DifficultyEnemyBuffs
  end

  if mode == "UNFAIR" then
    t = PLAYER_ALL_BOONS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyUnfairPlayerBoons, t[index])
      table.remove(t, index)
    end

    t = ENEMY_ALL_BUFFS
    for i = 1, 1, 1 do
      local index = RandomInt(1, #t)
      table.insert(_G.DifficultyEnemyBuffs, t[index])
      table.remove(t, index)
    end

    _G.DifficultyChatTablePlayers = _G.DifficultyUnfairPlayerBoons
    _G.DifficultyChatTableEnemies = _G.DifficultyEnemyBuffs
  end
end

function DespawnMobsResetOutposts()
  local start = Entities:FindByName(nil, "starting_zone_emitter")
  if not start then return end

  function IsAllowed(mob)
    local dontDespawnUnits = {
      "",
    }

    for _,dd in pairs(dontDespawnUnits) do
      if dd == mob then
        return false
      end
    end

    return true
  end
end

function ResetHeroes()
  local start = Entities:FindByName(nil, "starting_zone_emitter")
  if not start then return end

  function RepositionHero(target)
    if not target or target == nil then return end
    if not target:IsAlive() then return end
    
    local point = Entities:FindByName(nil, "trigger_spawn_tp")
    if point ~= nil then
      FindClearSpaceForUnit(target, point:GetAbsOrigin(), false)
      target:RemoveModifierByName("modifier_invulnerable")
      target:RemoveModifierByName("modifier_stunned")
    end
  end

  local mode = KILL_VOTE_RESULT:upper()
  --if (mode == "HELL" or mode == "IMPOSSIBLE" or mode == "HARDCORE") and not hero:HasModifier("") then break end

  local heroes = HeroList:GetAllHeroes()
  for _,hero in ipairs(heroes) do
      if UnitIsNotMonkeyClone(hero) then
        if hero:IsRealHero() and not hero:IsTempestDouble() then
          -- Update lives if they have any
          if hero:HasModifier("modifier_limited_lives") then
            local limitedLives = hero:FindModifierByName("modifier_limited_lives")
            if limitedLives ~= nil then
              for i = 1,limitedLives:GetStackCount(),1 do
                hero:AddItemByName("item_tome_un_600")
              end
            end
          end

          -- Gold Bank
          local accountID = PlayerResource:GetSteamAccountID(hero:GetPlayerID())
          local bankBalance = _G.PlayerGoldBank[accountID]

          if not bankBalance or bankBalance < 0 or bankBalance > INT_MAX_LIMIT then
            bankBalance = 0
          end

          CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
            userEntIndex = hero:GetEntityIndex(),
            amount = -math.abs(bankBalance),
          })

          _G.PlayerGoldBank[accountID] = 0
          hero:SetGold(0, false)
        end

        -- Clear inventory
        for i = 0, 20, 1 do
            local item = hero:GetItemInSlot(i)
            if item ~= nil then
              if item:GetAbilityName() ~= "item_tome_un_600" and item:GetAbilityName() ~= "item_swiftness_boots" and item:GetAbilityName() ~= "item_armor_piercing_crossbow_8" and item:GetAbilityName() ~= "item_veil_of_discord_custom8" then
                hero:RemoveItem(item)
              end
            end
        end

        -- Clear courier inventory too
        local courier = PlayerResource:GetPreferredCourierForPlayer(hero:GetPlayerID())
        if courier ~= nil then
          for i = 0, 20, 1 do
            local item = courier:GetItemInSlot(i)
              if item ~= nil then
                if item:GetAbilityName() ~= "item_swiftness_boots" then
                  courier:RemoveItem(item)
                end
              end
          end
        end

        -- Respawn hero, remove disables
        if hero:GetOwner() ~= nil and hero:GetOwner():IsPlayerController() then
          if mode == "HELL" or mode == "IMPOSSIBLE" or mode == "HARDCORE" then
            if hero:HasModifier("modifier_limited_lives") then
              RepositionHero(hero)
            end
          else
            RepositionHero(hero)
          end
        else
          local con = PlayerResource:GetConnectionState(hero:GetPlayerID())
          if con == DOTA_CONNECTION_STATE_DISCONNECTED or con == DOTA_CONNECTION_STATE_ABANDONED then
            RepositionHero(hero)
          else
            hero:SetRespawnsDisabled(true)
            hero:RemoveModifierByName("modifier_limited_lives")
            hero:ForceKill(false)
          end
        end
      end
  end

  -- Clear items on the ground
  local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
  for _,item in pairs(items_on_the_ground) do
      local containedItem = item:GetContainedItem()
      if containedItem then
          local name = containedItem:GetAbilityName()

          UTIL_RemoveImmediate(item)
          UTIL_RemoveImmediate(containedItem)
      end
  end
end

function GetPlayerDamageReduction(id)
  if not id or id == nil then return end
  if not _G.PlayerDamageReduction[id] or _G.PlayerDamageReduction[id] == nil then return end

  local first = 0
  local skip = 0

  for _,reduction in pairs(_G.PlayerDamageReduction[id]) do
    skip = skip + 1

    if reduction ~= nil and type(reduction) == "number" and math.abs(reduction) > 0 then
      first = math.abs(reduction) --convert to positive number
      break
    end
  end

  local value = (1 - (first/100))
  local i = 0

  for _,reduction in pairs(_G.PlayerDamageReduction[id]) do
    if reduction ~= nil and type(reduction) == "number" and math.abs(reduction) > 0 then
      i = i + 1

      if i > skip then
        value = value * (1 - (math.abs(reduction)/100))
      end
    end
  end

  local final = (value-1)*100

  return final
  -- return this as the value in the damage incoming prop
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shuffleTable(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function FindUnitsInCone(nTeamNumber, vCenterPos, vStartPos, vEndPos, fStartRadius, fEndRadius, hCacheUnit, nTeamFilter, nTypeFilter, nFlagFilter, nOrderFilter, bCanGrowCache)
  -- vCenterPos is used to determine searching center (FIND_CLOSEST will refer to units closest to vCenterPos)

  -- get cast direction and length distance
  local direction = vEndPos-vStartPos
  direction.z = 0

  local distance = direction:Length2D()
  direction = direction:Normalized()

  -- get max radius circle search
  local big_radius = distance + math.max(fStartRadius, fEndRadius)

  -- find enemies closest to primary target within max radius
  local units = FindUnitsInRadius(
      nTeamNumber,    -- int, your team number
      vCenterPos, -- point, center point
      nil,    -- handle, cacheUnit. (not known)
      big_radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
      nTeamFilter,    -- int, team filter
      nTypeFilter,    -- int, type filter
      nFlagFilter,    -- int, flag filter
      nOrderFilter,   -- int, order filter
      bCanGrowCache   -- bool, can grow cache
  )

  -- Filter within cone
  local targets = {}
  for _,unit in pairs(units) do

      -- get unit vector relative to vStartPos
      local vUnitPos = unit:GetOrigin()-vStartPos

      -- get projection scalar of vUnitPos onto direction using dot-product
      local fProjection = vUnitPos.x*direction.x + vUnitPos.y*direction.y + vUnitPos.z*direction.z

      -- clamp projected scalar to [0,distance]
      fProjection = math.max(math.min(fProjection,distance),0)
      
      -- get projected vector of vUnitPos onto direction
      local vProjection = direction*fProjection

      -- calculate distance between vUnitPos and the projected vector
      local fUnitRadius = (vUnitPos - vProjection):Length2D()

      -- calculate interpolated search radius at projected vector
      local fInterpRadius = (fProjection/distance)*(fEndRadius-fStartRadius) + fStartRadius

      -- if unit is within distance, add them
      if fUnitRadius<=fInterpRadius then
          table.insert( targets, unit )
      end
  end

  return targets
end

function SwapHeroWithTCOTRPG(npc, newHeroName, dummy)
    if not npc:IsRealHero() or IsSummonTCOTRPG(npc) then return end

    -- Talent hacks --
    --[[
    TalentManager:ResetTalents(PlayerResource:GetPlayer(npc:GetPlayerID()), npc)
    _G.PlayerTalentList[npc:GetUnitName()] = nil

    if _G.PlayerTalentList[newHeroName] == nil then
        _G.PlayerTalentList[newHeroName] = TalentManager:LoadKVDataForHero(newHeroName)
    end

    local talents = TalentManager:GetKVDataForHero(newHeroName)
    --]]
    npc:AddNewModifier(npc, nil, "modifier_stunned", {
      duration = 3
    })

    local oldXP = PlayerResource:GetTotalEarnedXP(npc:GetPlayerID())

    local oldAccountID = PlayerResource:GetSteamAccountID(npc:GetPlayerID())
    local oldUnitName = npc:GetUnitName()
    local oldPlayerID = npc:GetPlayerID()
    local goldBankAmount = _G.PlayerGoldBank[oldAccountID]
    local oldPlayerBuffs = {}
    local oldPrimaryAttribute = npc:GetPrimaryAttribute()

    local temp = PLAYER_ALL_BUFFS
    local playerModifiers = npc:FindAllModifiers()
    for _,mod in ipairs(playerModifiers) do
        for i,t in ipairs(temp) do
            if mod:GetName() == t then
                table.insert(oldPlayerBuffs, t)
            end
        end
    end

    local oldBootsLevel = npc:FindItemInInventory("item_swiftness_boots"):GetLevel()

    local items = {}
    for i = 0, 20, 1 do
        local item = npc:GetItemInSlot(i)
        if item ~= nil then
            if item:GetAbilityName() ~= "item_akasha_conversion" and item:GetAbilityName() ~= "item_carl_conversion" and not string.match(item:GetAbilityName(), "book") then
              table.insert(items, item:GetAbilityName())
            end
        end
    end

    -- Remove all abilities
    for i=0, npc:GetAbilityCount()-1 do
        local abil = npc:GetAbilityByIndex(i)
        if abil ~= nil then
            npc:RemoveAbilityByHandle(abil)
        end
    end

    _G.PlayerAddedAbilityCount[oldAccountID] = 0
    _G.PlayerBookRandomAbilities[oldAccountID] = {}
    _G.PlayerStoredAbilities[oldAccountID] = {}

    npc:RemoveModifierByName("modifier_gold_bank")
    npc:RemoveModifierByName("modifier_chicken_ability_1_target_transmute")

    local newNPC = PlayerResource:ReplaceHeroWith(npc:GetPlayerID(), newHeroName, npc:GetGold(), 0)
    newNPC:AddNewModifier(npc, nil, "modifier_stunned", {
      duration = 3
    })

    PlayerResource:GetPlayer(newNPC:GetPlayerID()):SetAssignedHeroEntity(newNPC)

    Timers:CreateTimer(1.0, function()
        if dummy ~= nil then
          -- Sometimes it's possible for these "clones" to remain when changing heroes multiple times
          -- This way we remove duplicates before a new one is being created
          local ownedUnits = newNPC:GetAdditionalOwnedUnits()
          for _,ownedUnit in ipairs(ownedUnits) do
            if ownedUnit ~= nil and not ownedUnit:IsNull() then
              if ownedUnit:HasModifier("modifier_dummy_wearable_hero") then
                UTIL_RemoveImmediate(ownedUnit)
              end
            end
          end

          CreateUnitByNameAsync(dummy, newNPC:GetAbsOrigin(), false, nil, nil, newNPC:GetTeamNumber(), function(unit)
            unit:AddNewModifier(newNPC, nil, "modifier_dummy_wearable_hero", {})
          end)
        end

        Timers:CreateTimer(1.0, function()
          -- Remove all active talent modifiers if the new hero is of a different attribute (except Universal)
          if oldPrimaryAttribute ~= newNPC:GetPrimaryAttribute() then
            XpManager:HeroSwapFix(newNPC)
          end

            -- Temporarily disable XP gain because it interfers with talents
            --newNPC:AddExperience(oldXP, DOTA_ModifyXP_Outpost, false, true)
            newNPC:AddNewModifier(newNPC, nil, "modifier_gold_bank", {})

            if newHeroName == "npc_dota_hero_visage" then
              newNPC:AddNewModifier(newNPC, nil, "modifier_walking_animation_fix", {})
            end

            for _,oldBuff in ipairs(oldPlayerBuffs) do
              newNPC:AddNewModifier(newNPC, nil, oldBuff, {})
            end

            -- Talent hacks --
            --[[
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(newNPC:GetPlayerID()), "talent_manager_hero_changed", {
                talents = talents,
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })
            --]]
            --

            local newAccountID = PlayerResource:GetSteamAccountID(newNPC:GetPlayerID())
            local sNewAccountID = tostring(newAccountID)

            DpsManager:Reset(sNewAccountID)


            _G.PlayerGoldBank[oldAccountID] = nil
            _G.PlayerGoldBank[newAccountID] = _G.PlayerGoldBank[newAccountID] or 0

            if goldBankAmount ~= nil then
              _G.PlayerGoldBank[newAccountID] = goldBankAmount
            end

            CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
              userEntIndex = newNPC:GetEntityIndex(),
              amount = _G.PlayerGoldBank[newAccountID],
            })

            -- Runes --
            newNPC:RemoveModifierByName("modifier_rune_manager_player_thinker")
            _G.PlayerRunes[newNPC:GetPlayerID()] = _G.PlayerRunes[oldPlayerID]

            _G.PlayerRuneInventory[newNPC:GetPlayerID()] = _G.PlayerRuneInventory[oldPlayerID]

            _G.PlayerRuneItems[newNPC:GetPlayerID()] = _G.PlayerRuneItems[oldPlayerID]

            newNPC:AddNewModifier(newNPC, nil, "modifier_rune_manager_player_thinker", {})

            if newHeroName == "npc_dota_hero_arena_hero_carl" or newHeroName == "npc_dota_hero_invoker" then
              _G.PlayerAddedAbilityCount[newAccountID] = 0
              _G.PlayerBookRandomAbilities[newAccountID] = {}
              _G.PlayerStoredAbilities[newAccountID] = {}
            end

            _G.autoPickup[oldPlayerID] = _G.autoPickup[newNPC:GetPlayerID()]

            for _,item in ipairs(items) do
                newNPC:AddItemByName(item)
            end

            local boots = newNPC:FindItemInInventory("item_swiftness_boots")
            if boots ~= nil then
              boots:SetLevel(oldBootsLevel)
            end

            if newNPC:FindAbilityByName("elder_titan_return_spirit") ~= nil then
              newNPC:RemoveAbility("elder_titan_return_spirit")
            end

            local newElementalDamageModifier = newNPC:AddNewModifier(newNPC, nil, "modifier_elemental_ailments", {})
            newElementalDamageModifier.outgoingDamage = oldElementalDamageProps


            newNPC:RespawnHero(false, false)
        end)
    end)

    --todo: remember to change global variables that use hero names to store data
end

function FormatLongNumber(n)
  if n >= 10^9 then
        return string.format("%.2fb", n / 10^9)
    elseif n >= 10^6 then
        return string.format("%.2fm", n / 10^6)

    elseif n >= 10^3 then
        return string.format("%.2fk", n / 10^3)
    else
        return tostring(n)
    end
end

function callIfCallable(f)
    return function(...)
        error, result = pcall(f, ...)
        if error then -- f exists and is callable
            print('ok')
            return result
        end
        -- nothing to do, as though not called, or print('error', result)
    end
end

function GetOneRandomHero()
  local heroes = HeroList:GetAllHeroes()
  for _,hero in ipairs(heroes) do
      if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
          return hero
      end
  end
end

function CDOTA_BaseNPC:FindItemInAnyInventory(name)
  local pass = nil

  for i=0,14 do
      local item = self:GetItemInSlot(i)
      if item ~= nil then
          if item:GetAbilityName() == name then
              pass = item
              break
          end
      end
  end

  return pass
end

function CDOTA_BaseNPC:HasShard()
  return self:HasModifier("modifier_item_aghanims_shard")
end


function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function ToRadians(degrees)
  return degrees * math.pi / 180
end

function RotateVector2D(vector, theta)
    local xp = vector.x*math.cos(theta)-vector.y*math.sin(theta)
    local yp = vector.x*math.sin(theta)+vector.y*math.cos(theta)
    return Vector(xp,yp,vector.z):Normalized()
end

function CDOTABaseAbility:FireLinearProjectile(FX, velocity, distance, width, data, bDelete, bVision, vision)
  local internalData = data or {}
  local delete = false
  if bDelete then delete = bDelete end
  local provideVision = true
  if bVision then provideVision = bVision end
  if internalData.source and not internalData.origin then
    internalData.origin = internalData.source:GetAbsOrigin()
  end
  local info = {
    EffectName = FX,
    Ability = self,
    vSpawnOrigin = internalData.origin or self:GetCaster():GetAbsOrigin(), 
    fStartRadius = width,
    fEndRadius = internalData.width_end or width,
    vVelocity = velocity,
    fDistance = distance or 1000,
    Source = internalData.source or self:GetCaster(),
    iUnitTargetTeam = internalData.team or DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = internalData.type or DOTA_UNIT_TARGET_ALL,
    iUnitTargetFlags = internalData.type or DOTA_UNIT_TARGET_FLAG_NONE,
    iSourceAttachment = internalData.attach or DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    bDeleteOnHit = delete,
    fExpireTime = GameRules:GetGameTime() + 10.0,
    bProvidesVision = provideVision,
    iVisionRadius = vision or 100,
    iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
    ExtraData = internalData.extraData
  }
  local projectile = ProjectileManager:CreateLinearProjectile( info )
  return projectile
end

function CDOTABaseAbility:FireTrackingProjectile(FX, target, speed, data, iAttach, bDodge, bVision, vision)
  local internalData = data or {}
  local dodgable = true
  if bDodge ~= nil then dodgable = bDodge end
  local provideVision = false
  if bVision ~= nil then provideVision = bVision end
  origin = self:GetCaster():GetAbsOrigin()
  if internalData.origin then
    origin = internalData.origin
  elseif internalData.source then
    origin = internalData.source:GetAbsOrigin()
  end
  local projectile = {
    Target = target,
    Source = internalData.source or self:GetCaster(),
    Ability = self, 
    EffectName = FX,
      iMoveSpeed = speed,
    vSourceLoc= origin or self:GetCaster():GetAbsOrigin(),
    bDrawsOnMinimap = false,
        bDodgeable = dodgable,
        bIsAttack = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        flExpireTime = internalData.duration,
    bProvidesVision = provideVision,
    iVisionRadius = vision or 100,
    iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
    iSourceAttachment = iAttach or 3,
    ExtraData = internalData.extraData
  }
  return ProjectileManager:CreateTrackingProjectile(projectile)
end

function CDOTA_BaseNPC:HasTalent(talentName)
  if self and not self:IsNull() and self:FindAbilityByName(talentName) ~= nil then
    if self:FindAbilityByName(talentName):GetLevel() > 0 then return true end
  end

  return false
end

function maxFreq(arr, n, fallback)
  table.sort(arr)
  -- we do this so it falls back to the default value
  table.insert(arr, fallback)
  n= n + 1
  --

  local max_count = 1
  local res = arr[1]

  local curr_count = 1

  for i = 1, n do 
    if arr[i] == arr[i - 1] then
        curr_count = curr_count + 1
    else
        if curr_count > max_count then
            max_count = curr_count
            res = arr[i - 1]
        end

        curr_count = 1
    end
  end

  if curr_count > max_count then
    max_count = curr_count
    res = arr[n - 1]
  end

  return res
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function DebugPrintTable(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  if spew == 1 then
    PrintTable(...)
  end
end

function UnitIsNotMonkeyClone(hero)
    return (not hero:HasModifier("modifier_monkey_king_fur_army_soldier") and 
            not hero:HasModifier("modifier_monkey_king_fur_army_soldier_hidden") and
            not hero:HasModifier("modifier_monkey_king_fur_army_soldier_inactive") and
            not hero:HasModifier("modifier_monkey_king_fur_army_soldier_in_position") and
            hero:GetUnitName() ~= "npc_dota_monkey_clone_custom")
end

function IsCreepTCOTRPG(unit)
  if not unit or unit:IsNull() then return false end
  local unitName = unit:GetUnitName()

  if not unitName or unitName == nil then return false end

  if string.find(unitName, "npc_dota_wave") then return true end

  local unitNames = {
    "npc_dota_creature_wave_enemy",
    "npc_dota_creature_skafian_summon_wolves",
    "npc_dota_creature_1_crip",
    "npc_dota_creature_30_crip",
    "npc_dota_creature_40_crip",
    "npc_dota_creature_40_crip_2",
    "npc_dota_creature_130_crip2_death",
    "npc_dota_creature_130_crip1_death",
    "npc_dota_creature_70_crip",
    "npc_dota_creature_50_crip",
    "npc_dota_creature_100_crip",
    "npc_dota_creature_10_crip_2",
    "npc_dota_creature_10_crip_3",
    "npc_dota_creature_30_crip_2",
    "npc_dota_creature_30_crip_3",
    "npc_dota_creature_140_crip_Robo",
    "npc_dota_creature_120_crip_snow",
    "npc_dota_creature_100_crip_2",
    "npc_dota_creature_10_crip_4",
    "npc_dota_creature_70_crip_2",
    "npc_dota_creature_supercamp_1",
    "npc_dota_creature_supercamp_2",
    "npc_dota_creature_supercamp_3",
    "npc_dota_creature_supercamp_4",
    "npc_dota_creature_supercamp_5",
    "npc_dota_creature_supercamp_6",
    "npc_dota_creature_130_crip3_death",
    "npc_dota_creature_130_crip4_death",
    "npc_dota_creature_130_crip5_death",
    "npc_dota_creature_30_crip_3",
    "npc_dota_creature_lava_1",
    "npc_dota_creature_lava_2",
    "npc_dota_creature_greedy_goblin",
    "npc_dota_creature_40_crip_3",
    "npc_dota_creature_40_crip_4",
    "npc_dota_creature_40_crip_5",
    "npc_dota_creature_40_crip_6",
    "npc_dota_creature_40_crip_7",
    "npc_dota_creature_40_crip_8",
    "npc_dota_creature_40_crip_9",
    "npc_dota_creature_40_crip_10",
  }

  for _,theUnit in ipairs(unitNames) do
    if unit:GetUnitName() == theUnit then return true end
  end

  return false
end

-- This is called on our summon-type units
-- Mostly created for Lone Druid's Spirit Bear to create item compability for items using attributes in their abilities
--[[
function CDOTA_BaseNPC:GetAgility()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetAgility()
end

function CDOTA_BaseNPC:GetStrength()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetStrength()
end

function CDOTA_BaseNPC:GetBaseIntellect()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetBaseIntellect()
end

function CDOTA_BaseNPC:GetBaseAgility()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetBaseAgility()
end

function CDOTA_BaseNPC:GetBaseStrength()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetBaseStrength()
end

function CDOTA_BaseNPC:GetBaseIntellect()
  if not IsSummonTCOTRPG(self) then return 0 end

  local owner = self:GetOwner()

  if not owner or owner:IsNull() then return 0 end 
  if not owner:IsRealHero() then return 0 end

  return owner:GetBaseIntellect()
end
--]]

function IsSummonTCOTRPG(unit)
  local unitNames = {
    "npc_dota_shadow_shaman_death_ward",
    "npc_dota_shadow_shaman_healing_ward",
    "npc_dota_shadow_shaman_plague_ward",
    "npc_dota_shadow_shaman_cog",
    "npc_dota_necronomicon_archer_custom",
    "npc_dota_doom_infernal_servant",
    "npc_dota_lycan_wolf_custom1",
    "npc_dota_lone_druid_bear_custom",
    "npc_dota_lone_druid_bear_custom2"
  }

  for _,theUnit in ipairs(unitNames) do
    if unit:GetUnitName() == theUnit then return true end
  end

  return false
end

function IsShamanWard(unit)
  if not unit or unit:IsNull() then return false end

  local unitNames = {
    "npc_dota_shadow_shaman_death_ward",
    "npc_dota_shadow_shaman_healing_ward",
    "npc_dota_shadow_shaman_plague_ward",
    "npc_dota_shadow_shaman_cog",
  }

  for _,theUnit in ipairs(unitNames) do
    if unit:GetUnitName() == theUnit then return true end
  end

  return false
end

function DisplayError(playerID, message)
  local player = PlayerResource:GetPlayer(playerID)
  if player then
    CustomGameEventManager:Send_ServerToPlayer(player, "CreateIngameErrorMessage", {message=message})
  end
end

function IsBossAghanim(unit)
  if not unit or unit:IsNull() then return false end

  return unit:GetUnitName() == "npc_dota_boss_aghanim"
end

function IsBossTCOTRPG(unit)
  if not unit or unit:IsNull() then return false end

  local bossNames = {
    "npc_dota_creature_80_boss",
    "npc_dota_creature_70_boss",
    "npc_dota_creature_40_boss_2",
    "npc_dota_creature_30_boss",
    "npc_dota_creature_40_boss",
    "npc_dota_creature_50_boss",
    "npc_dota_creature_100_boss",
    "npc_dota_creature_100_boss_2",
    "npc_dota_creature_130_boss_death",
    "npc_dota_creature_150_boss_last",
    "npc_dota_creature_10_boss",
    "npc_dota_creature_20_boss",
    "npc_dota_creature_roshan_boss",
    "npc_dota_creature_100_boss_3",
    "npc_dota_creature_100_boss_4",
    "npc_dota_creature_100_boss_5",
    "npc_dota_creature_target_dummy",
    "boss_queen_of_pain",
    "boss_invoker",
    "npc_dota_boss_aghanim",
    "boss_hephaestus",
    "npc_dota_creature_wave_enemy_razor",
    "npc_dota_creature_wave_enemy_underlord",
    "npc_dota_boss_keymaster_1",
    "npc_dota_boss_keymaster_2",
    "npc_dota_boss_keymaster_3",
    "npc_dota_creature_wave_enemy_necrolyte",
    "npc_tcot_tormentor",
    "boss_destruction_lord",
    "boss_arc_warden",
  }

  for _,boss in ipairs(bossNames) do
    if unit:GetUnitName() == boss then return true end
  end

  return false
end

function CreateParticleWithTargetAndDuration(particleName, target, duration)
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

  Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(particle, true)
      ParticleManager:ReleaseParticleIndex(particle)
  end)

  return particle
end

function ClearItems(mustHaveOwner)
  local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
  for _,item in pairs(items_on_the_ground) do
    local containedItem = item:GetContainedItem()
    if containedItem then
      local owner = containedItem:GetOwnerEntity()

      local creationTime = math.floor(item:GetCreationTime())
      local gameTime = math.floor(GameRules:GetGameTime())

      local name = containedItem:GetAbilityName()

      if string.find(name, "recipe") or string.find(name, "asan") then
        break
      end

      local limitSeconds = 90

      if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" then
        limitSeconds = 30
      end

      if containedItem and (mustHaveOwner and owner == nil and ((gameTime - creationTime) > limitSeconds)) then
        UTIL_RemoveImmediate(item)
        UTIL_RemoveImmediate(containedItem)
      end
    end
  end
end

-- Necessary function because some heroes (like Huskar) have abilities that change their max health
function CDOTA_BaseNPC:GetMaxHealthTCOTRPG()
  local mayhem = self:FindAbilityByName("huskar_mayhem_custom")
  if mayhem ~= nil and mayhem:GetLevel() > 0 then
    return self:GetMaxHealth() * (mayhem:GetSpecialValueFor("max_hp_threshold") / 100)
  end

  return self:GetMaxHealth()
end

function GetSteamIDPlayerList()
  local playerList = {}
  local heroes = HeroList:GetAllHeroes()
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and hero:GetUnitName() ~= "outpost_placeholder_unit" then
      local steamID = PlayerResource:GetSteamID(hero:GetPlayerID())
      local sSteamID = tostring(steamID)
      if sSteamID ~= "0" then
        table.insert(playerList, sSteamID)
      end
    end
  end

  return playerList
end

function GetRealConnectedHeroCount()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())
    if connectionState == DOTA_CONNECTION_STATE_CONNECTED and UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      amount = amount + 1
    end
  end

  return amount
end

function GetDeadOrReincarnatingPlayersWithLives()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      if not hero:IsAlive() and (hero:HasModifier("modifier_limited_lives") or hero:IsReincarnating() or hero:WillReincarnate()) then
        amount = amount + 1
      end
    end
  end

  return amount
end

function GetDeadPlayersConnected()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      if not hero:IsAlive() then
        local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())
        if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
          amount = amount + 1
        end
      end
    end
  end

  return amount
end

function GetDeadOrReincarnatingPlayersWithNoLives()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      if not hero:IsAlive() and (not hero:HasModifier("modifier_limited_lives") and not hero:IsReincarnating() and not hero:WillReincarnate()) then
        amount = amount + 1
      end
    end
  end

  return amount
end

function GetNumAliveHeroesWithLives()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      if not hero:IsAlive() and (hero:HasModifier("modifier_limited_lives") or hero:IsReincarnating() or hero:WillReincarnate()) then
        --If the hero is dead but has lives, then it's technically alive
        amount = amount + 1
      elseif hero:IsAlive() then
        amount = amount + 1
      end
    end
  end

  return amount
end

function GetNumAliveHeroesNormal()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and hero:IsAlive() and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      amount = amount + 1
    end
  end

  return amount
end

function GetRealHeroCountConnected()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED and UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      amount = amount + 1
    end
  end

  return amount
end

function GetRealHeroCount()
  local heroes = HeroList:GetAllHeroes()
  local amount = 0
  for _,hero in ipairs(heroes) do
    if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
      amount = amount + 1
    end
  end

  return amount
end

function IsInTriggerX(entity, trigger)
  if not entity:IsAlive() then return false end

  local triggerOrigin = trigger:GetAbsOrigin()
  local bounds = trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + triggerOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + triggerOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end

  return true
end

function IsInTrigger(entity, trigger)
  if not entity:IsAlive() then return false end

  local triggerOrigin = trigger:GetAbsOrigin()
  local bounds = trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + triggerOrigin.x then
    return false
  end
  if origin.y < bounds.Mins.y + triggerOrigin.y then
    return false
  end
  if origin.x > bounds.Maxs.x + triggerOrigin.x then
    return false
  end
  if origin.y > bounds.Maxs.y + triggerOrigin.y then
    return false
  end

  return true
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Requires an element and a table, returns true if element is in the table.
function TableContains(t, element)
    if t == nil then return false end
    for k,v in pairs(t) do
        if k == element then
            return true
        end
    end
    return false
end

-- Return length of the table even if the table is nil or empty
function TableLength(t)
    if t == nil or t == {} then
        return 0
    end
    local length = 0
    for k,v in pairs(t) do
        length = length + 1
    end
    return length
end

function GetRandomTableElement(t)
    -- iterate over whole table to get all keys
    local keyset = {}
    for k in pairs(t) do
        table.insert(keyset, k)
    end
    -- now you can reliably return a random key
    return t[keyset[RandomInt(1, #keyset)]]
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

function DebugAllCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end

-- Author: Noya
-- This function hides all dota item cosmetics (hats/wearables) from the hero/unit and store them into a handle variable
-- Works only for wearables added with code
function HideWearables(unit)
  unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
  local model = unit:FirstMoveChild()
  while model ~= nil do
    if model:GetClassname() == "dota_item_wearable" then
      model:AddEffects(EF_NODRAW) -- Set model hidden
      table.insert(unit.hiddenWearables, model)
    end
    model = model:NextMovePeer()
  end
end

-- Author: Noya
-- This function un-hides (shows) wearables that were hidden with HideWearables() function.
function ShowWearables(unit)
	for i,v in pairs(unit.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

-- Author: Noya
-- This function changes (swaps) dota item cosmetic models (hats/wearables)
-- Works only for wearables added with code
function SwapWearable(unit, target_model, new_model)
    local wearable = unit:FirstMoveChild()
    while wearable ~= nil do
        if wearable:GetClassname() == "dota_item_wearable" then
            if wearable:GetModelName() == target_model then
                wearable:SetModel(new_model)
                return
            end
        end
        wearable = wearable:NextMovePeer()
    end
end

-- This function checks if a given unit is Roshan, returns boolean value;
function CDOTA_BaseNPC:IsRoshan()
	if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
		return true
	end
	
	return false
end

-- This function checks if this entity is a fountain or not; returns boolean value;
function CBaseEntity:IsFountain()
	if self:GetName() == "ent_dota_fountain_bad" or self:GetName() == "ent_dota_fountain_good" then
		return true
	end
	
	return false
end

-- Author: Noya
-- This function is showing custom Error Messages using notifications library
function SendErrorMessage(pID, string)
  if Notifications then
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
  end
  EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function DrawWarningCircle(target, origin, radius, duration)
  local outer = ParticleManager:CreateParticle("particles/darkmoon_calldown_marker_ring.vpcf", PATTACH_POINT, target)
  local alteredOrigin = Vector(origin.x, origin.y, origin.z) -- We need to position the y-pos 1 unit above the ground to match with the inner circle
  ParticleManager:SetParticleControl(outer, 0, alteredOrigin)
  ParticleManager:SetParticleControl(outer, 1, Vector(radius, 0, 0))
  ParticleManager:SetParticleControl(outer, 2, Vector(duration, 0, 0))

  local inner = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_POINT, target)
  ParticleManager:SetParticleControl(inner, 0, origin)
  ParticleManager:SetParticleControl(inner, 1, Vector(radius, 0, 0))
  ParticleManager:SetParticleControl(inner, 2, Vector(duration, 0, 0))

  Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(outer, true)
      ParticleManager:ReleaseParticleIndex(outer)
      ParticleManager:DestroyParticle(inner, true)
      ParticleManager:ReleaseParticleIndex(inner)
  end)
end

function GetPlayerItems(player)
  local t = {}
  for i=0,17 do
        local item = player:GetItemInSlot(i)
        if item ~= nil then
            local pass = false
            if item:GetPurchaser() == player and (item:GetItemSlot() <= DOTA_ITEM_SLOT_6 or item:GetItemSlot() == DOTA_ITEM_NEUTRAL_SLOT) then
                pass = true
            end

            if pass then
                table.insert(t, item:GetAbilityName())
            end
        end
    end

    return t
end

function GetPlayerAbilities(player)
  local t = {}

  for i=0, player:GetAbilityCount()-1 do
      local abil = player:GetAbilityByIndex(i)
      if abil ~= nil then
          local name = abil:GetAbilityName()
          if not string.match(name, "special_bonus") and not string.match(name, "chicken_ability_1_cancel") and not string.match(name, "talent_") and not string.match(name, "generic_hidden") and name ~= "twin_gate_portal_warp" and name ~= "ability_pluck_famango" and name ~= "ability_lamp_use" and name ~= "ability_capture" and name ~= "abyssal_underlord_portal_warp" and name ~= "twin_gate_portal_warp_custom" and name ~= "aghanim_tower_capture" and name ~= "hoodwink_sharpshooter_cancel_custom" then
            table.insert(t, abil:GetAbilityName())
          end
      end
  end

  return t
end

function CDOTA_BaseNPC:GetAllAttributes()
  return self:GetStrength()+self:GetAgility()+self:GetBaseIntellect()
end

function CDOTA_BaseNPC:GetBonusDropRate()
  if not self or self == nil then return 0 end
  if not self:IsRealHero() or self:IsIllusion() then return 0 end 

  local accountID = PlayerResource:GetSteamAccountID(self:GetPlayerID())
  return _G.PlayerBonusDropChance[accountID]
end

function CDOTA_BaseNPC:SetBonusDropRate(amount)
  if not self or self == nil then return end
  if not self:IsRealHero() or self:IsIllusion() then return end 

  local accountID = PlayerResource:GetSteamAccountID(self:GetPlayerID())

  _G.PlayerBonusDropChance[accountID] = _G.PlayerBonusDropChance[accountID] or 0
  _G.PlayerBonusDropChance[accountID] = amount
end

function CDOTA_BaseNPC:GenerateDropChance()
  return RandomFloat(0, 100) - self:GetBonusDropRate()
end

function CDOTA_BaseNPC:IsDonator()
  if not self or self == nil then return end
  if not self:IsRealHero() or self:IsIllusion() then return end 

  local accountID = PlayerResource:GetSteamID(self:GetPlayerID())

  for _,player in pairs(PLAYER_DONATOR_LIST) do
    if tostring(player) == tostring(accountID) then
      return true 
    end
  end

  return false
end

function selectRandomRows(temp, num)
  local result = {}
  local copy = {}
  for _, value in ipairs(temp) do
    table.insert(copy, value)
  end
  for i = 1, num do
    local index = math.random(1, #copy)
    table.insert(result, copy[index])
    table.remove(copy, index)
  end
  return result
end
