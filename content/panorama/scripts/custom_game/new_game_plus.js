var NewGamePlusUI = /** @class */ (function () {
    // NewGamePlusUI constructor
    function NewGamePlusUI(panel) {
        var _this = this;
        this.countPlayerBoxes = function () {
            var i = 0;
            for (var k in _this.playerBoxes) {
                i++;
            }
            return i;
        };
        this.FetchUserData = function (steam) {
            if (_this.playerBoxes[steam] == null) {
                var row = new NewGamePlusContainer(_this.panelContainer, steam);
                _this.playerBoxes[steam] = row;
            }
        };
        this.onNewGamePlusVoted = function (_, _, res) {
            if (!res) {
                return;
            }
            //if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return
            var vote = res.vote;
            var steam = res.steam;
            var avatar = _this.playerBoxes[steam].playerAvatar;
            if (vote == "1") {
                avatar.RemoveClass("avatarDeclined");
                avatar.AddClass("avatarAccepted");
            }
            else if (vote == "0") {
                avatar.RemoveClass("avatarAccepted");
                avatar.AddClass("avatarDeclined");
            }
            return;
        };
        //the timer is 1 sec off on starts after the first
        this.onNewGamePlusInitiated = function (_, _, res) {
            var user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID());
            var steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid;
            var currentUserConnectionState = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_connection_state;
            if (currentUserConnectionState != 2)
                return;
            Game.EmitSound("WeeklyQuest.ClaimReward");
            _this.timer = TIMER_DEFAULT_TIME;
            _this.buttonAccept[steam].text = "ACCEPT (" + _this.timer + ")";
            var buttonDecline = _this.buttonDecline[steam];
            var buttonAccept = _this.buttonAccept[steam];
            timer = function () {
                _this.timer = _this.timer - 1;
                _this.buttonAccept[steam].text = "ACCEPT (" + _this.timer + ")";
                if (_this.timer > 0) {
                    $.Schedule(1, timer);
                }
            };
            _this.container.style.visibility = "visible";
            _this.toggleUIElements(false);
            $.Schedule(1, timer);
            _this.autoFinishTimer = $.Schedule(TIMER_DEFAULT_TIME, function () {
                GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam });
                if (!buttonDecline.BHasClass("clicked")) {
                    buttonDecline.AddClass("clicked");
                }
                if (!buttonAccept.BHasClass("clicked")) {
                    buttonAccept.AddClass("clicked");
                }
            });
            return;
        };
        this.toggleUIElements = function (state) {
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, state); //Time of day (clock).
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, state); //Heroes and team score at the top of the HUD.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, state); //Lefthand flyout scoreboard.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, state); //Hero actions UI.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, state); //Minimap.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, state); //Entire Inventory UI
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, state); //Shop portion of the Inventory. 
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, state); //Player items.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, state); //Quickbuy.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, state); //Courier controls.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, state); //Glyph.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, state); //Gold display.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, state); //Suggested items shop panel.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, state); //Top-left menu buttons in the HUD.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, state); //Top-left menu buttons in the HUD.
            GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_QUICK_STATS, state); //Top-left menu buttons in the HUD.
        };
        this.onNewGamePlusVoteFinished = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex == Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) {
                var steam = res.steam;
                var avatar = _this.playerBoxes[steam].playerAvatar;
                avatar.RemoveClass("avatarDeclined");
                avatar.RemoveClass("avatarAccepted");
                _this.buttonDecline[steam].RemoveClass("clicked");
                _this.buttonAccept[steam].RemoveClass("clicked");
                _this.buttonAccept[steam].style.borderColor = "transparent";
                _this.buttonAccept[steam].style.color = "white";
                _this.buttonDecline[steam].style.borderColor = "transparent";
                _this.buttonDecline[steam].style.color = "white";
            }
            _this.stateClicks = [];
            _this.toggleUIElements(true);
            _this.container.style.visibility = "collapse";
        };
        CustomNetTables.SubscribeNetTableListener("new_game_plus_voted", this.onNewGamePlusVoted);
        CustomNetTables.SubscribeNetTableListener("new_game_plus_vote_initiate", this.onNewGamePlusInitiated);
        CustomNetTables.SubscribeNetTableListener("new_game_plus_vote_finished", this.onNewGamePlusVoteFinished);
        var TIMER_DEFAULT_TIME = 20;
        this.panel = panel;
        this.container = this.panel.FindChild("NewGamePlus");
        this.container.RemoveAndDeleteChildren();
        var panelContainer = $.CreatePanel("Panel", this.container, "");
        var user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID());
        var steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid;
        this.panelContainer = panelContainer;
        this.container.BLoadLayoutSnippet("HeaderSnippet");
        this.container.BLoadLayoutSnippet("VoteButtons");
        this.panelContainer.style.flowChildren = "right-wrap";
        this.panelContainer.style.horizontalAlign = "center";
        this.panelContainer.AddClass("PortraitContainer");
        this.container.style.visibility = "collapse";
        this.playerBoxes = [];
        this.stateClicks = [];
        var playerIDs = Game.GetAllPlayerIDs();
        for (var id in playerIDs) {
            var player = Game.GetPlayerInfo(playerIDs[id]);
            var connectionState = player.player_connection_state;
            var steam_id = player.player_steamid;
            if (connectionState == 2) {
                this.FetchUserData(steam_id);
            }
        }
        this.buttonAccept = [];
        this.buttonDecline = [];
        this.buttonAccept[steam] = this.container.FindChildTraverse("PlayerVoteYes");
        this.buttonDecline[steam] = this.container.FindChildTraverse("PlayerVoteNo");
        var buttonDecline = this.buttonDecline[steam];
        var buttonAccept = this.buttonAccept[steam];
        this.autoFinishTimer = null;
        buttonAccept.SetPanelEvent("onactivate", function () {
            if (buttonAccept.BHasClass("clicked")) {
                return;
            }
            GameEvents.SendCustomGameEventToServer("new_game_plus_vote", { user: user, steamId: steam, vote: "1" });
            buttonAccept.AddClass("clicked");
            buttonAccept.style.borderColor = "lime";
            buttonAccept.style.color = "lime";
            buttonDecline.AddClass("clicked");
            Game.EmitSound("ui.matchmaking_find");
            _this.stateClicks[steam] = "1";
            if ((_this.countCurrentVotes(_this.stateClicks, true) >= _this.countPlayerBoxes())) {
                GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam });
                _this.onNewGamePlusVoteFinished(null, null, { userEntIndex: Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), steam: steam });
                $.CancelScheduled(_this.autoFinishTimer);
            }
        });
        buttonDecline.SetPanelEvent("onactivate", function () {
            if (buttonDecline.BHasClass("clicked")) {
                return;
            }
            var user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID());
            var steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid;
            GameEvents.SendCustomGameEventToServer("new_game_plus_vote", { user: user, steamId: steam, vote: "0" });
            buttonAccept.AddClass("clicked");
            buttonDecline.AddClass("clicked");
            buttonDecline.style.borderColor = "tomato";
            buttonDecline.style.color = "tomato";
            Game.EmitSound("ui.matchmaking_cancel");
            _this.stateClicks[steam] = "0";
            if ((_this.countCurrentVotes(_this.stateClicks, false) >= _this.countPlayerBoxes())) {
                GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam });
                _this.onNewGamePlusVoteFinished(null, null, { userEntIndex: Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), steam: steam });
                $.CancelScheduled(_this.autoFinishTimer);
            }
        });
        this.timer = TIMER_DEFAULT_TIME;
        buttonAccept.text = "ACCEPT (" + this.timer + ")";
        $.Msg(panel); // Print the panel
    }
    NewGamePlusUI.prototype.countCurrentVotes = function (arr, state) {
        var yes = 0;
        var no = 0;
        for (var k in arr) {
            for (var _i = 0, _a = arr[k]; _i < _a.length; _i++) {
                var z = _a[_i];
                if (z == "1")
                    yes++;
                if (z == "0")
                    no++;
            }
        }
        if (state) {
            return yes;
        }
        else {
            return no;
        }
    };
    return NewGamePlusUI;
}());
var ui = new NewGamePlusUI($.GetContextPanel());
