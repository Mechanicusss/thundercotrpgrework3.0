PlayerBuffs = PlayerBuffs or class({})

function PlayerBuffs:Init()
    CustomGameEventManager:RegisterListener("player_buffs_activated", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local modifierName = event.buff

        if type(modifierName) ~= "string" then return end

        local accountID = PlayerResource:GetSteamAccountID(id)

        local buff = unit:AddNewModifier(unit, nil, modifierName, {})

        _G.PlayerBuffList[accountID] = _G.PlayerBuffList[accountID] or {}
        table.insert(_G.PlayerBuffList[accountID], modifierName)

        if _G.PlayerBuffCountdownPanoramaTimers[accountID] ~= nil then
            Timers:RemoveTimer(_G.PlayerBuffCountdownPanoramaTimers[accountID])
        end

        if _G.PlayerBuffTimers[accountID] ~= nil then
            Timers:RemoveTimer(_G.PlayerBuffTimers[accountID])
        end

        -- We send this to update the current player buff UI
        CustomGameEventManager:Send_ServerToPlayer(player, "player_buff_selection_connect", {
            buffs = _G.PlayerBuffList[accountID],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("player_buffs_chat_notify", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local buff = event.buff 
        if not buff then return end

        Say(unit, "Affected by ("..buff..")", true)
    end)

    CustomGameEventManager:RegisterListener("player_buffs_reroll", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountID = PlayerResource:GetSteamAccountID(id)

        -- Remove modifiers the player already has
        local temp = PLAYER_ALL_BUFFS
        local playerModifiers = unit:FindAllModifiers()
        for _,mod in ipairs(playerModifiers) do
            for i,t in ipairs(temp) do
                if mod:GetName() == t then
                    table.remove(temp, i)
                end
            end
        end
        
        _G.PlayerBuffRerollRemaining[accountID] = _G.PlayerBuffRerollRemaining[accountID] or 3
        _G.PlayerBuffRerollRemaining[accountID] = _G.PlayerBuffRerollRemaining[accountID] - 1

        if _G.PlayerBuffRerollRemaining[accountID] <= -1 then
            DisplayError(id, "#player_buffs_no_rerolls_left")
            return
        else
            local randomBuffs = selectRandomRows(temp, 3)
            _G.PlayerBuffListRandom[accountID] = randomBuffs
            
            CustomGameEventManager:Send_ServerToPlayer(player, "player_buff_selection_reroll", {
                buffs = randomBuffs,
                remaining = _G.PlayerBuffRerollRemaining[accountID]
            })
        end
    end)
end

function PlayerBuffs:OpenBuffWindow(player)
    --EmitGlobalSound("TCOTRPG.Buffs.Open")
    
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and hero == player then
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