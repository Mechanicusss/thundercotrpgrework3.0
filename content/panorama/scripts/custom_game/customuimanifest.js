function HidePickScreen() {
    var dotaHud = $.GetContextPanel().GetParent().GetParent();
    if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
        dotaHud.FindChild("PreGame").visible = false;
    }
    else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
        dotaHud.FindChild("PreGame").visible = true;
    }
    else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
        dotaHud.FindChild("PreGame").visible = true;
    }
    else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_PRE_GAME)) {
        dotaHud.FindChild("PreGame").visible = false;
    } else {
        dotaHud.FindChild("PreGame").visible = false;
    }
    if(Game.GetMapInfo().map_display_name == "tcotrpg" || Game.GetMapInfo().map_display_name == "tcotrpgv2") {
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("topbar").FindChildTraverse("TopBarDireTeam").FindChildTraverse("TopBarDirePlayers").visible = false;
    } else {
        $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("topbar").FindChildTraverse("TopBarDireTeam").FindChildTraverse("TopBarDirePlayers").visible = true;
    }

    

    //$.GetContextPanel().GetParent().FindChildTraverse("DotaLoadingScreen").FindChildTraverse("LoadingScreenContent").FindChildTraverse("ChatTipBox").style.opacity = "1"

}
(function()
{
    GameEvents.Subscribe( "game_rules_state_change", HidePickScreen );
})();

// Uncomment any of the following lines in order to disable that portion of the default UI

//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );      //Time of day (clock).
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, true );     //Heroes and team score at the top of the HUD.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_QUICK_STATS, false );     //Heroes and team score at the top of the HUD.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );      //Lefthand flyout scoreboard.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, true );     //Hero actions UI.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     //Minimap.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      //Entire Inventory UI
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     //Shop portion of the Inventory. 
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      //Player items.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     //Quickbuy.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      //Glyph.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     //Gold display.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );     //Hero selection Radiant and Dire player lists.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );     //Hero selection game mode name display.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     //Top-left menu buttons in the HUD.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );      //Endgame scoreboard.    
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );     //Top-left menu buttons in the HUD.
// These lines set up the panorama colors used by each team (for game select/setup, etc)
GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#3dd296;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#F3C909;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#c54da8;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#3455FF;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#65d413;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#815336;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#1bc0d8;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#c7e40d;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#8c2af4;";

GameEvents.Subscribe("CreateIngameErrorMessage", function(data) 
    {
        const str = data.message

        const regex = /#[^\s\W]+/g; // Matches '#' followed by any non-space character one or more times, and 'g' for global search

        let replacedString = str.replace(regex, (match) => {
            const extractedString = match;
            const localizedString = $.Localize(extractedString); // Call $.Localize() separately
            $.Msg(localizedString)
            return localizedString;
        });

        GameEvents.SendEventClientSide("dota_hud_error_message", 
        {
            "splitscreenplayer": 0,
            "reason": data.reason || 80,
            "message": replacedString
        })
    })

    

    var skip = false

    

    function Selection_New(msg)
{
var entities = msg.entities
//$.Msg("Selection_New ", entities)
for (var i in entities) {
    if (i==1)
        GameUI.SelectUnit(entities[i], false) //New
    else
        GameUI.SelectUnit(entities[i], true) //Add
};
OnUpdateSelectedUnit()
}

// Recieves a list of entities to add to the current selection
function Selection_Add(msg)
{
var entities = msg.entities
//$.Msg("Selection_Add ", entities)
for (var i in entities) {
    GameUI.SelectUnit(entities[i], true)
};
OnUpdateSelectedUnit()
}

// Removes a list of entities from the current selection
function Selection_Remove(msg)
{
var remove_entities = msg.entities
//$.Msg("Selection_Remove ", remove_entities)
var selected_entities = GetSelectedEntities();
for (var i in remove_entities) {
    var index = selected_entities.indexOf(remove_entities[i])
    if (index > -1)
        selected_entities.splice(index, 1)
};

if (selected_entities.length == 0)
{
    Selection_Reset()
    return
}

for (var i in selected_entities) {
    if (i==0)
        GameUI.SelectUnit(selected_entities[i], false) //New
    else
        GameUI.SelectUnit(selected_entities[i], true) //Add
};
OnUpdateSelectedUnit()
}

// Fall back to the default selection
function Selection_Reset(msg)
{
var playerID = Players.GetLocalPlayer()
var heroIndex = Players.GetPlayerHeroEntityIndex(playerID)
GameUI.SelectUnit(heroIndex, false)
OnUpdateSelectedUnit()
}

// Filter & Sending
function OnUpdateSelectedUnit()
{
//$.Msg( "OnUpdateSelectedUnit ", Players.GetLocalPlayerPortraitUnit() );
if (skip == true){
    skip = false;
    return
}

// Skips units from the selected group
SelectionFilter(GetSelectedEntities())

$.Msg(Entities.GetSelectionEntities(Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())))

$.Schedule(0.03, SendSelectedEntities);
}

// Updates the list of selected entities on server for this player
function SendSelectedEntities() {
GameEvents.SendCustomGameEventToServer("selection_update", {entities: GetSelectedEntities()})
}

// Local player shortcut
function GetSelectedEntities() {
return Players.GetSelectedEntities(Players.GetLocalPlayer());
}

// Returns an index of an override defined on lua with npcHandle:SetSelectionOverride(reselect_unit)
function GetSelectionOverride(entityIndex) {
var table = CustomNetTables.GetTableValue("selection", entityIndex)
return table ? table.entity : -1
}

function OnUpdateQueryUnit()
{
//$.Msg( "OnUpdateQueryUnit ", Players.GetQueryUnit(Players.GetLocalPlayer()));
}

(function () {
// Custom event listeners
GameEvents.Subscribe( "selection_new", Selection_New);
GameEvents.Subscribe( "selection_add", Selection_Add);
GameEvents.Subscribe( "selection_remove", Selection_Remove);
GameEvents.Subscribe( "selection_reset", Selection_Reset);

// Built-In Dota client events
GameEvents.Subscribe( "dota_player_update_selected_unit", OnUpdateSelectedUnit );
//  GameEvents.Subscribe( "dota_player_update_query_unit", OnUpdateQueryUnit );
})();