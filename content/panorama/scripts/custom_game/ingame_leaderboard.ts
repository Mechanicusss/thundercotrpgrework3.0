class InGameLeaderboardUI {
    // Instance variables
    panel: Panel;

    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("InGameLeaderboard")
        this.container.RemoveAndDeleteChildren();

        this.headerPanel = $.CreatePanel("Panel", this.container, "");
        this.headerPanel.BLoadLayoutSnippet("InGameLeaderboardButtonSnippet");
        this.headerPanelActivator = this.headerPanel.FindChild("Activator")

        this.playersContainer = $.CreatePanel("Panel", this.container, "");
        this.playersContainer.BLoadLayoutSnippet("InGameLeaderboardPlayersContainerSnippet");

        this.receivedCount = 0
        this.leaderboardData = []

        this.headerPanelActivator.text = "OFF"

        this.headerPanelActivator.SetPanelEvent(
          "onmouseactivate", 
          () => {
            if(this.headerPanelActivator.text == "OFF") {
                this.headerPanelActivator.text = "ON"
                this.headerPanelActivator.RemoveClass("off")
                this.headerPanelActivator.AddClass("on")

                GameEvents.SendCustomGameEventToServer("auto_pickup", { option: "on", playerID: Game.GetLocalPlayerID() })
            } else if(this.headerPanelActivator.text == "ON") {
                this.headerPanelActivator.text = "NO SOULS"

                GameEvents.SendCustomGameEventToServer("auto_pickup", { option: "on_nosouls", playerID: Game.GetLocalPlayerID() })
            }  else {
                this.headerPanelActivator.RemoveClass("on")
                this.headerPanelActivator.AddClass("off")
                this.headerPanelActivator.text = "OFF"

                GameEvents.SendCustomGameEventToServer("auto_pickup", { option: "off", playerID: Game.GetLocalPlayerID() })
            }

            //send event to game
            if(this.playersContainer.BHasClass("InGameLeaderboardContainerVisible")) {
                this.playersContainer.RemoveClass("InGameLeaderboardContainerVisible")
            } else {
                this.playersContainer.AddClass("InGameLeaderboardContainerVisible")
            }
          }
        )

        $.Msg(panel); // Print the panel
    }
}

let ui = new InGameLeaderboardUI($.GetContextPanel());