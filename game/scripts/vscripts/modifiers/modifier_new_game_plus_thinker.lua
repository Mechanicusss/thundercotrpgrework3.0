LinkLuaModifier("modifier_new_game_plus_thinker", "modifiers/modifier_new_game_plus_thinker", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_new_game_plus_thinker = class(ItemBaseClass)
modifier_new_game_plus_thinker = class(modifier_new_game_plus_thinker)

_G.NewGamePlusThinker = {}
-----------------
function modifier_new_game_plus_thinker:GetIntrinsicModifierName()
    return "modifier_new_game_plus_thinker"
end
-----------------
function modifier_new_game_plus_thinker:OnCreated(params)
    local parent = self:GetParent()
    local entindex = parent:entindex()

    _G.NewGamePlusThinker[entindex] = _G.NewGamePlusThinker[entindex] or nil
    _G.NewGamePlusThinker[entindex] = false

    if IsServer() then
        self.damage = params.damage
        self.armor = params.armor
        self:StartIntervalThink(0.1)
    end
end

function modifier_new_game_plus_thinker:UpdateStats(mode, npc)
    local multiplierDamage = 0
    local multiplierArmor = 0

    local multiplierDamageConst = 0
    local multiplierArmorConst = 0

    if mode == "EASY" then
      multiplierDamage = DIFFICULTY_ENEMY_DAMAGE_EASY
      multiplierArmor = DIFFICULTY_ENEMY_ARMOR_EASY
    elseif mode == "NORMAL" then
      multiplierDamageConst = DIFFICULTY_ENEMY_DAMAGE_NORMAL
      multiplierArmorConst = DIFFICULTY_ENEMY_ARMOR_NORMAL
    elseif mode == "HARD" then
      multiplierDamage = DIFFICULTY_ENEMY_DAMAGE_HARD
      multiplierArmor = DIFFICULTY_ENEMY_ARMOR_HARD
    elseif mode == "IMPOSSIBLE" then
      multiplierDamage = DIFFICULTY_ENEMY_DAMAGE_IMPOSSIBLE
      multiplierArmor = DIFFICULTY_ENEMY_ARMOR_IMPOSSIBLE
    elseif mode == "HELL" then
      multiplierDamage = DIFFICULTY_ENEMY_DAMAGE_HELL
      multiplierArmor = DIFFICULTY_ENEMY_ARMOR_HELL
    elseif mode == "HARDCORE" then
      multiplierDamage = DIFFICULTY_ENEMY_DAMAGE_HARDCORE
      multiplierArmor = DIFFICULTY_ENEMY_ARMOR_HARDCORE

      --if not npc:HasModifier("modifier_scaling_damage_reduction") then
       --   npc:AddNewModifier(npc, nil, "modifier_scaling_damage_reduction", {})
      --end
    end

    local entindex = npc:entindex()

    if multiplierDamageConst > 0 and multiplierArmorConst > 0 and _G.NewGamePlusThinker[entindex] == false then
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
      end

      -- DAMAGE --
      local damage = self.damage * multiplierDamage
      if damage > INT_MAX_LIMIT or damage <= 0 then
        if not string.find(npc:GetUnitName(), "npc_dota_wave") then 
          damage = INT_MAX_LIMIT
        end
      end

      npc:SetBaseDamageMax(damage)
      npc:SetBaseDamageMin(damage)

      -- ARMOR (creep only) --
      local armor = self.armor * multiplierArmor
      if armor > INT_MAX_LIMIT or armor <= 0 then
        if not string.find(npc:GetUnitName(), "npc_dota_wave") then 
          armor = INT_MAX_LIMIT
        end
      end

      npc:SetPhysicalArmorBaseValue(armor)

       _G.NewGamePlusThinker[entindex] = true

      Timers:CreateTimer(10.0, function()
          _G.NewGamePlusThinker[entindex] = false
      end)
    end
end

function modifier_new_game_plus_thinker:OnIntervalThink()
    local mode = KILL_VOTE_RESULT:upper()
    local netTable = CustomNetTables:GetTableValue("new_game_plus_vote_reload_enemies", "game_info")
    
    local parent = self:GetParent()
    local entindex = parent:entindex()

    if netTable ~= nil then
        if netTable.newGamePlus == "1" and _G.NewGamePlusThinker[entindex] == false then 
            self:UpdateStats(mode, parent)
            barebones:InitiateBoonsAndBuffs(mode, parent, 2)
        end
    end
end