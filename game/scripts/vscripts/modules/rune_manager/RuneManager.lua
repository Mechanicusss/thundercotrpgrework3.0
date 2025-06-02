LinkLuaModifier("modifier_rune_manager_player_thinker", "modules/rune_manager/RuneManager.lua", LUA_MODIFIER_MOTION_NONE)

modifier_rune_manager_player_thinker = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

--[[ 
    Link all rune modifiers,
    It's actually just "modifier + (item name)"
--]]
-- Lesser --
LinkLuaModifier("modifier_item_socket_rune_lesser_strength", "modifiers/runes/modifier_item_socket_rune_lesser_strength.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_agility", "modifiers/runes/modifier_item_socket_rune_lesser_agility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_intellect", "modifiers/runes/modifier_item_socket_rune_lesser_intellect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_armor", "modifiers/runes/modifier_item_socket_rune_lesser_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_spellamp", "modifiers/runes/modifier_item_socket_rune_lesser_spellamp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_gold", "modifiers/runes/modifier_item_socket_rune_lesser_gold.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_lesser_xp", "modifiers/runes/modifier_item_socket_rune_lesser_xp.lua", LUA_MODIFIER_MOTION_NONE)

-- Normal --
LinkLuaModifier("modifier_item_socket_rune_strength", "modifiers/runes/modifier_item_socket_rune_strength.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_agility", "modifiers/runes/modifier_item_socket_rune_agility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_intellect", "modifiers/runes/modifier_item_socket_rune_intellect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_armor", "modifiers/runes/modifier_item_socket_rune_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_spellamp", "modifiers/runes/modifier_item_socket_rune_spellamp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_cdr", "modifiers/runes/modifier_item_socket_rune_cdr.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_damage", "modifiers/runes/modifier_item_socket_rune_damage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_lifesteal", "modifiers/runes/modifier_item_socket_rune_legendary_lifesteal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_gold", "modifiers/runes/modifier_item_socket_rune_gold.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_xp", "modifiers/runes/modifier_item_socket_rune_xp.lua", LUA_MODIFIER_MOTION_NONE)

-- Greater --
LinkLuaModifier("modifier_item_socket_rune_greater_armoramp", "modifiers/runes/modifier_item_socket_rune_greater_armoramp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_cdr", "modifiers/runes/modifier_item_socket_rune_greater_cdr.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_damageamp", "modifiers/runes/modifier_item_socket_rune_greater_damageamp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_damagereduction", "modifiers/runes/modifier_item_socket_rune_greater_damagereduction.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_strength", "modifiers/runes/modifier_item_socket_rune_greater_strength.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_agility", "modifiers/runes/modifier_item_socket_rune_greater_agility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_intellect", "modifiers/runes/modifier_item_socket_rune_greater_intellect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_armor", "modifiers/runes/modifier_item_socket_rune_greater_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_damage", "modifiers/runes/modifier_item_socket_rune_greater_damage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_spellamp", "modifiers/runes/modifier_item_socket_rune_greater_spellamp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_magicres", "modifiers/runes/modifier_item_socket_rune_greater_magicres.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_maxhpregen", "modifiers/runes/modifier_item_socket_rune_greater_maxhpregen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_gold", "modifiers/runes/modifier_item_socket_rune_greater_gold.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_greater_xp", "modifiers/runes/modifier_item_socket_rune_greater_xp.lua", LUA_MODIFIER_MOTION_NONE)

-- Legendary --
LinkLuaModifier("modifier_item_socket_rune_legendary_adrenaline", "modifiers/runes/modifier_item_socket_rune_legendary_adrenaline.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_blood_rush", "modifiers/runes/modifier_item_socket_rune_legendary_blood_rush.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_rejuvenation", "modifiers/runes/modifier_item_socket_rune_legendary_rejuvenation.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_exodus_shield", "modifiers/runes/modifier_item_socket_rune_legendary_exodus_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_evasive_architect", "modifiers/runes/modifier_item_socket_rune_legendary_evasive_architect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_socket_rune_legendary_chronomancer", "modifiers/runes/modifier_item_socket_rune_legendary_chronomancer.lua", LUA_MODIFIER_MOTION_NONE)
--//--

RuneManager = RuneManager or class({})

function RuneManager:Init()
    RuneManager:SetupSocketableItems()

    if not IsServer() then return end

    RuneManager:AddThinkers()

    CustomGameEventManager:RegisterListener("rune_manager_equipment_reload_rune", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountID = PlayerResource:GetSteamAccountID(id)

        CustomGameEventManager:Send_ServerToPlayer(player, "rune_manager_rune_send", {
            steamID = accountID,
            runes = _G.PlayerRunes[id],
            runeInventory = _G.PlayerRuneInventory[id],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("rune_manager_equipment_delete_rune", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)
        local runeUID = event.rune

        if not unit or unit == nil or unit:IsNull() then return end

        _G.PlayerRuneInventory[id] = _G.PlayerRuneInventory[id] or {}
        for i,rune in pairs(_G.PlayerRuneInventory[id]) do
            if rune.uId == runeUID then
                _G.PlayerRuneInventory[id][i] = nil
            end
        end

        local accountID = PlayerResource:GetSteamAccountID(id)

        CustomGameEventManager:Send_ServerToPlayer(player, "rune_manager_rune_send", {
            steamID = accountID,
            runes = _G.PlayerRunes[id],
            runeInventory = _G.PlayerRuneInventory[id],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("rune_manager_send_data", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local accountID = PlayerResource:GetSteamAccountID(id)

        CustomGameEventManager:Send_ServerToPlayer(player, "rune_manager_get_data", {
            steamID = accountID,
            runes = _G.PlayerRunes[id],
            runeInventory = _G.PlayerRuneInventory[id],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("rune_manager_equipment_remove_rune", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)
        local runeUID = event.rune
        local permanent = event.permanent

        if not unit or unit == nil or unit:IsNull() then return end

        _G.PlayerRunes[id] = _G.PlayerRunes[id] or {}
        for slot,rune in pairs(_G.PlayerRunes[id]) do
            if rune.uId == runeUID then
                _G.PlayerRuneInventory[id] = _G.PlayerRuneInventory[id] or {}
                table.insert(_G.PlayerRuneInventory[id], rune)
                
                -- Remove the modifier assosciated with the rune --
                local assignedHero = player:GetAssignedHero()
                self:RemoveRuneModifier(assignedHero, rune.name)

                -- We are removing the first rune we come across
                _G.PlayerRunes[id][slot] = nil
            end
        end

        --[[
        if item ~= nil then
            if _G.PlayerRunes[id][item] ~= nil then
                for slot = 1, 2, 1 do -- (2) is max rune sockets
                    if _G.PlayerRunes[id][item][slot] ~= nil and _G.PlayerRunes[id][item][slot].uId == runeUID then
                        -- Add the rune back into the rune inventory
                        local tRune = _G.PlayerRunes[id][item][slot]

                        _G.PlayerRuneInventory[id] = _G.PlayerRuneInventory[id] or {}
                        table.insert(_G.PlayerRuneInventory[id], tRune) 

                        -- Remove the modifier assosciated with the rune --
                        local assignedHero = player:GetAssignedHero()
                        self:RemoveRuneModifier(assignedHero, tRune.name)

                        -- We are removing the first rune we come across
                        _G.PlayerRunes[id][item][slot] = nil
                        break 
                    end
                end
            end
        end
        --]]

        local accountID = PlayerResource:GetSteamAccountID(id)

        CustomGameEventManager:Send_ServerToPlayer(player, "rune_manager_rune_send", {
            steamID = accountID,
            runes = _G.PlayerRunes[id],
            runeInventory = _G.PlayerRuneInventory[id],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    -- This event takes care of adding runes to items and the inventory
    CustomGameEventManager:RegisterListener("rune_manager_equipment_add_rune", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then 
            DisplayError(id, "Cannot Socket Rune. Error code (0)")
            return 
        end

        local unit = EntIndexToHScript(event.unit)
        local rune = event.rune -- table (rune.uId, rune.name, rune.isLegendary)
        --local item = event.item -- index
        local slot = 0 -- default 0, but 0 doesn't exist. it's 1-6

        if not unit or unit == nil or unit:IsNull() then 
            DisplayError(id, "Cannot Socket Rune. Error code (1)")
            return 
        end

        local accountID = PlayerResource:GetSteamAccountID(unit:GetPlayerID())

        if self:HasLegendaryRune(id) and rune.isLegendary then
            DisplayError(id, "#rune_only_one_legendary")
            return
        end

        _G.PlayerRunes[id] = _G.PlayerRunes[id] or {}

        -- Check for existing runes
        for i = 1, MAX_ALLOWED_RUNES do
            if _G.PlayerRunes[id][i] == nil then
                slot = i
                break
            end
        end

        if slot == 0 then
            -- Return an error saying all sockets are taken
            DisplayError(id, "#rune_no_free_sockets")
            return
        end

        -- If the player's rune inventory exists and is not empty we remove the rune 
        -- since it's being added into the equipment
        if _G.PlayerRuneInventory[id] ~= nil and type(_G.PlayerRuneInventory[id]) == "table" then
            for i,tRune in pairs(_G.PlayerRuneInventory[id]) do
                if tRune.uId == rune.uId then
                    -- Remove the first rune that matches in the rune inventory
                    _G.PlayerRuneInventory[id][i] = nil
                    break
                end
            end
        end

        _G.PlayerRunes[id][slot] = _G.PlayerRunes[id][slot] or nil
        _G.PlayerRunes[id][slot] = rune

        -- Add the assosciated modifier of the rune --
        local assignedHero = player:GetAssignedHero()
        local modifierName = "modifier_" .. rune.name
        local buff = assignedHero:FindModifierByName(modifierName)
        if not buff then
            buff = assignedHero:AddNewModifier(assignedHero, nil, modifierName, {})
        end

        if buff then
            buff:IncrementStackCount()
            buff:ForceRefresh()
            assignedHero:CalculateStatBonus(true)
        end

        CustomGameEventManager:Send_ServerToPlayer(player, "rune_manager_rune_send", {
            steamID = accountID,
            runes = _G.PlayerRunes[id],
            runeInventory = _G.PlayerRuneInventory[id],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)
end

function RuneManager:AddThinkers()
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and  hero:GetUnitName() ~= "outpost_placeholder_unit" then
            hero:AddNewModifier(hero, nil, "modifier_rune_manager_player_thinker", {})
        end
    end
end

function RuneManager:RemoveRuneModifier(hero, runeName)
    local modifierName = "modifier_" .. runeName
    local buff = hero:FindModifierByName(modifierName)
    if buff then
        if buff:GetStackCount() > 1 then
            buff:DecrementStackCount()
        else
            buff:Destroy()
        end
    end
end

function RuneManager:SetupSocketableItems()
    self.socketableItems = {}
    self.shopsData = LoadKeyValues("scripts/npc/overrides/socketable_items.txt")
    for item,_ in pairs(self.shopsData) do
        table.insert(self.socketableItems, item)
    end
end

function RuneManager:CanBeSocketed(itemName)
    if not self.socketableItems or self.socketableItems == nil then return false end

    local pass = false 
    --local nameWithoutRecipe = itemName:gsub("_recipe", "") -- Removes the _recipe part

    for _,item in pairs(self.socketableItems) do
        if string.match(itemName, item) then
            pass = true
            break
        end
    end

    return pass
end

function RuneManager:HasLegendaryRune(playerId)
    local t = _G.PlayerRunes[playerId]
    if not t or t == nil then return false end

    local pass = false

    for _,tRune in pairs(t) do
        local isLegendary = tRune.isLegendary
        if isLegendary then
            pass = isLegendary
            break
        end
    end

    return pass
end
--------------------------------------------------------------
function modifier_rune_manager_player_thinker:OnCreated()
    if not IsServer() then return end

    self.cache = nil

    self.items = {}

    local parent = self:GetParent()
    local id = parent:GetPlayerID()
    local accountID = PlayerResource:GetSteamAccountID(id)

    _G.PlayerRunes[id] = _G.PlayerRunes[id] or {}

    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(id), "rune_manager_rune_send", {
        steamID = accountID,
        runes = _G.PlayerRunes[id],
        runeInventory = _G.PlayerRuneInventory[id],
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })

    --self:StartIntervalThink(FrameTime())
end

function modifier_rune_manager_player_thinker:ItemExists(player, itemIndex)
    local pass = false

    for i = 0, 18, 1 do
        if i < 6 or i == 16 then
            local hItemInSlot = player:GetItemInSlot(i)
            if hItemInSlot ~= nil then
                local index = hItemInSlot:entindex()
                if itemIndex == index then
                    pass = true
                end
            end
        end
    end

    return pass
end
--[[
function modifier_rune_manager_player_thinker:OnIntervalThink()
    self.items = {}

    local hPlayer = self:GetParent()
    local playerID = hPlayer:GetPlayerID()
    local forceUpdate = false

    -- This should always be at the start because it's when we populate the self.items table
    -- Because we reset the table on every interval, running it after the validation check when it has no content 
    -- makes no sense and will most likely break it
    for i = 0, 18, 1 do
        if i < 6 or i == 16 then
            local hItemInSlot = hPlayer:GetItemInSlot(i)
            if hItemInSlot ~= nil then
                local itemIndex = hItemInSlot:entindex()
                local itemIndexToHScript = EntIndexToHScript(itemIndex)

                if IsValidEntity(itemIndexToHScript) and RuneManager:CanBeSocketed(hItemInSlot:GetName()) and self.items[itemIndex] == nil then
                    self.items[itemIndex] = itemIndex
                end
            end 
        end
    end

    -- When an item is being upgraded from e.g. green>purple, the original green item disappears (as in the index is lost)
    -- We can check for this, meaning that if the index of an equipped item ever becomes nil, we know it has been upgraded (or removed),
    -- and we simply remove all runes from it.
    if _G.PlayerRunes[playerID] ~= nil then
        for index,obj in pairs(_G.PlayerRunes[playerID]) do
            local hItem = EntIndexToHScript(index)
            local bRemove = false

            if hItem ~= nil then
                -- Double check if an item with runes is in an item slot it's not supposed to be in,
                -- and remove the runes from it if that's the case (we cant always trust the order filter)
                local slot = hItem:GetItemSlot()
                if slot > 5 and slot ~= DOTA_ITEM_NEUTRAL_SLOT then
                    bRemove = true
                end
            end

            if hItem == nil or not IsValidEntity(hItem) or bRemove then
                for i = 1, 2, 1 do
                    if obj[i] ~= nil then
                        _G.PlayerRuneInventory[playerID] = _G.PlayerRuneInventory[playerID] or {}

                        table.insert(_G.PlayerRuneInventory[playerID], {
                            uId = DoUniqueString("item_socket_rune"),
                            name = obj[i].name,
                            isLegendary = obj[i].isLegendary
                        }) 

                        RuneManager:RemoveRuneModifier(hPlayer, obj[i].name)

                        _G.PlayerRunes[playerID][index][i] = nil

                        forceUpdate = true
                        bRemove = false
                    end
                end

                _G.PlayerRunes[playerID][index] = nil

                _G.PlayerRuneItems[playerID][index] = nil

                self.items[index] = nil
            end
        end
    end

    _G.PlayerRuneItems[playerID] = self.items

    --can check the length of self.items to be > 0 if its weird on first item
    if self.cache == nil then
        self.cache = self.items
    end

    if self.cache ~= nil or forceUpdate then
        local equal = table_eq(self.cache, self.items)
        if not equal or forceUpdate then
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "rune_manager_rune_send", {
                items = _G.PlayerRuneItems[playerID],
                runes = _G.PlayerRunes[playerID],
                runeInventory = _G.PlayerRuneInventory[playerID],
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })

            self.cache = nil
            forceUpdate = false
        end
    end
end
--]]