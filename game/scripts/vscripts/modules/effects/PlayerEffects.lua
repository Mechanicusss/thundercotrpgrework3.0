PlayerEffects = PlayerEffects or class({})

require("modules/effects/player/private")
require("modules/effects/player/firstPlaceEvent")
require("modules/effects/player/firstPlaceScoreboard_Easy")
require("modules/effects/player/firstPlaceScoreboard_Normal")
require("modules/effects/player/firstPlaceScoreboard_Hell")
require("modules/effects/player/firstPlaceScoreboard_Hard")
require("modules/effects/player/firstPlaceScoreboard_Impossible")
require("modules/effects/player/firstPlaceScoreboard_Hardcore")
require("modules/effects/player/thirdPlaceRank")
require("modules/effects/player/donator")

function PlayerEffects:OnPlayerSpawnedForTheFirstTime(player)
    if not player or player:IsNull() then return end
    if not player:IsRealHero() then return end

    local playerID = player:GetPlayerID()
    local steamID = tostring(PlayerResource:GetSteamID(playerID))

    if player:IsDonator() then
        player:AddNewModifier(player, nil, "modifier_effect_private", {})
    end

    for _,id in pairs(PRIVATE_IDS) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_private", {})
        end
    end

    for _,id in pairs(FIRST_PLACE_EVENT_PRIVATE_IDS) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_event_first", {})
        end
    end

    -- Seasonal
    for _,id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_EASY) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_easy", {})
        end
    end

    for _,id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_NORMAL) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_normal", {})
        end
    end

    for _,id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HARD) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_hard", {})
        end
    end

    for _,id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_IMPOSSIBLE) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_impossible", {})
        end
    end

    for _,id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HELL) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_hell", {})
        end
    end

    for _, id in pairs(FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HARDCORE) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_scoreboard_first_hardcore", {})
            --player:AddNewModifier(player, nil, "modifier_auto_pickup", {})  
        end
    end



    for _,id in pairs(THIRD_PLACE_RANK_PRIVATE_IDS) do
        if steamID == id then
            player:AddNewModifier(player, nil, "modifier_effect_thirdplace_rank", {})
        end
    end
end