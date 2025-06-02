interface TimerChangedEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class NewGamePlusUI {
    // Instance variables
    panel: Panel;

    // NewGamePlusUI constructor
    constructor(panel: Panel) {
        CustomNetTables.SubscribeNetTableListener("new_game_plus_voted", this.onNewGamePlusVoted);
        CustomNetTables.SubscribeNetTableListener("new_game_plus_vote_initiate", this.onNewGamePlusInitiated);
        CustomNetTables.SubscribeNetTableListener("new_game_plus_vote_finished", this.onNewGamePlusVoteFinished);

        const TIMER_DEFAULT_TIME = 20

        this.panel = panel;

        this.container = this.panel.FindChild("NewGamePlus")
        this.container.RemoveAndDeleteChildren();

        const panelContainer = $.CreatePanel("Panel", this.container, "");
        const user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())
        const steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid

        this.panelContainer = panelContainer;

        this.container.BLoadLayoutSnippet("HeaderSnippet");
        this.container.BLoadLayoutSnippet("VoteButtons");

        this.panelContainer.style.flowChildren = "right-wrap"
        this.panelContainer.style.horizontalAlign = "center"
        this.panelContainer.AddClass("PortraitContainer")

        this.container.style.visibility = "collapse"

        this.playerBoxes = []
        this.stateClicks = []

        let playerIDs = Game.GetAllPlayerIDs()
        for(const id in playerIDs) {
          let player = Game.GetPlayerInfo(playerIDs[id])
          let connectionState = player.player_connection_state
          let steam_id = player.player_steamid
          if(connectionState == 2) {
            this.FetchUserData(steam_id)
          }
        }

        this.buttonAccept = []
        this.buttonDecline = []

        this.buttonAccept[steam] = this.container.FindChildTraverse("PlayerVoteYes") as LabelPanel;
        this.buttonDecline[steam] = this.container.FindChildTraverse("PlayerVoteNo") as LabelPanel;

        const buttonDecline = this.buttonDecline[steam]
        const buttonAccept = this.buttonAccept[steam]

        this.autoFinishTimer = null

        buttonAccept.SetPanelEvent(
            "onactivate", 
            () => {
              if(buttonAccept.BHasClass("clicked")) { return }
              GameEvents.SendCustomGameEventToServer("new_game_plus_vote", { user: user, steamId: steam, vote: "1" })
              
              buttonAccept.AddClass("clicked")
              buttonAccept.style.borderColor = "lime"
              buttonAccept.style.color = "lime"

              buttonDecline.AddClass("clicked")

              Game.EmitSound("ui.matchmaking_find")

              this.stateClicks[steam] = "1"

              if((this.countCurrentVotes(this.stateClicks, true) >= this.countPlayerBoxes())) {
                GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam })
                this.onNewGamePlusVoteFinished(null, null, { userEntIndex: Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), steam: steam })

                $.CancelScheduled(this.autoFinishTimer)
              }
            }
          )

        
        buttonDecline.SetPanelEvent(
            "onactivate", 
            () => {
              if(buttonDecline.BHasClass("clicked")) { return } 

              const user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())
              const steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid
              GameEvents.SendCustomGameEventToServer("new_game_plus_vote", { user: user, steamId: steam, vote: "0" })
              
              buttonAccept.AddClass("clicked")

              buttonDecline.AddClass("clicked")
              buttonDecline.style.borderColor = "tomato"
              buttonDecline.style.color = "tomato"

              Game.EmitSound("ui.matchmaking_cancel")

              this.stateClicks[steam] = "0"

              if((this.countCurrentVotes(this.stateClicks, false) >= this.countPlayerBoxes())) {
                GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam })
                this.onNewGamePlusVoteFinished(null, null, { userEntIndex: Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), steam: steam })

                $.CancelScheduled(this.autoFinishTimer)
              }
            }
          )

        this.timer = TIMER_DEFAULT_TIME
        buttonAccept.text = `ACCEPT (${this.timer})`

        $.Msg(panel); // Print the panel
    }

    countCurrentVotes(arr, state) {
      let yes = 0
      let no = 0
      for(const k in arr) {
        for(const z of arr[k]) {
          if(z == "1") yes++;
          if(z == "0") no++;
        }
      } 

      if(state) {
        return yes
      } else {
        return no
      }
    }

    countPlayerBoxes = () => {
      let i = 0;
      for(const k in this.playerBoxes) {
        i++;
      }

      return i
    }

    FetchUserData = (steam) => {
      if(this.playerBoxes[steam] == null) {
        let row = new NewGamePlusContainer(this.panelContainer, steam)
        this.playerBoxes[steam] = row
      }
    }

    onNewGamePlusVoted = (_, _, res) => {
      if (!res) {
          return
      }

      //if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return

      const vote = res.vote
      const steam = res.steam

      const avatar = this.playerBoxes[steam].playerAvatar

      if(vote == "1") {
        avatar.RemoveClass("avatarDeclined")
        avatar.AddClass("avatarAccepted")
      } else if(vote == "0") {
        avatar.RemoveClass("avatarAccepted")
        avatar.AddClass("avatarDeclined")
      }

      return
    }

    //the timer is 1 sec off on starts after the first
    onNewGamePlusInitiated = (_, _, res) => {
      const user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())
      const steam = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_steamid
      const currentUserConnectionState = Game.GetPlayerInfo(Game.GetLocalPlayerID()).player_connection_state
      if(currentUserConnectionState != 2) return

      Game.EmitSound("WeeklyQuest.ClaimReward")

      this.timer = TIMER_DEFAULT_TIME
      this.buttonAccept[steam].text = `ACCEPT (${this.timer})`

      const buttonDecline = this.buttonDecline[steam]
      const buttonAccept = this.buttonAccept[steam]

      timer = () => {
        this.timer = this.timer-1
        this.buttonAccept[steam].text = `ACCEPT (${this.timer})`
        if(this.timer>0) {
          $.Schedule(1, timer)
        }
      }

      this.container.style.visibility = "visible"
      this.toggleUIElements(false)
      $.Schedule(1, timer)

      this.autoFinishTimer = $.Schedule(TIMER_DEFAULT_TIME, () => {
        GameEvents.SendCustomGameEventToServer("new_game_plus_vote_complete", { user: user, steamId: steam })
        if(!buttonDecline.BHasClass("clicked")) {
          buttonDecline.AddClass("clicked")
        }

        if(!buttonAccept.BHasClass("clicked")) {
          buttonAccept.AddClass("clicked")
        }
      })
      return
    }

    toggleUIElements = (state) => {
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, state );      //Time of day (clock).
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, state );     //Heroes and team score at the top of the HUD.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, state );      //Lefthand flyout scoreboard.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, state );     //Hero actions UI.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, state );     //Minimap.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, state );      //Entire Inventory UI
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, state );     //Shop portion of the Inventory. 
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, state );      //Player items.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, state );     //Quickbuy.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, state );      //Courier controls.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, state );      //Glyph.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, state );     //Gold display.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, state );      //Suggested items shop panel.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, state );     //Top-left menu buttons in the HUD.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, state );     //Top-left menu buttons in the HUD.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_QUICK_STATS, state );     //Top-left menu buttons in the HUD.
    }

    onNewGamePlusVoteFinished = (_, _, res) => {
      if (!res) {
          return
      }

      if(res.userEntIndex == Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) {
        const steam = res.steam

        const avatar = this.playerBoxes[steam].playerAvatar

        avatar.RemoveClass("avatarDeclined")
        avatar.RemoveClass("avatarAccepted")

        this.buttonDecline[steam].RemoveClass("clicked")
        this.buttonAccept[steam].RemoveClass("clicked")

        this.buttonAccept[steam].style.borderColor = "transparent"
        this.buttonAccept[steam].style.color = "white"

        this.buttonDecline[steam].style.borderColor = "transparent"
        this.buttonDecline[steam].style.color = "white"
      }

      this.stateClicks = []

      this.toggleUIElements(true)
      this.container.style.visibility = "collapse"
    }
}

let ui = new NewGamePlusUI($.GetContextPanel());