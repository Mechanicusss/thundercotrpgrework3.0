class FastBossesSelection {
    // Instance variables
    panel: Panel;
    amountLabel: ButtonPanel;

    constructor(parent: Panel, t: string, amount: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("FastBossesSelection");

        // Find components
        this.amountLabel = panel.FindChildTraverse("DefaultValveButtonIDFASTBOSSES") as Any;

        GameEvents.Subscribe("on_connect_full", this.onConnectFull)

        this.isHost = false;

        // Set player name label
        this.amountLabel.text = t;

        let btn = this.amountLabel
        let _panel = this.panel;

        btn.SetPanelEvent(
          "onmouseover", 
          function(){
            switch(amount.toUpperCase()) {
                case "ENABLE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#fast_bosses_enabled_info"));
                    break;
                case "DISABLE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#fast_bosses_disabled_info"));
                    break;
            }
            
          }
        )

        btn.SetPanelEvent(
          "onmouseout", 
          function(){
            $.DispatchEvent("DOTAHideTextTooltip", btn);
          }
        )

        this.amountLabel.SetPanelEvent(
          "onmouseactivate", 
          () => {
            if(!this.isPlayerHost()) return;
            if(btn.BHasClass("Chosen")) {
              GameEvents.SendCustomGameEventToServer("fastbossesvote", { option: "Disable", user: Game.GetLocalPlayerID() })
              btn.RemoveClass("Chosen")
              return
            }

            GameEvents.SendCustomGameEventToServer("fastbossesvote", { option: amount, user: Game.GetLocalPlayerID() })

            /*for(const b of _panel.GetParent().FindChildrenWithClassTraverse("DefaultValveButtonClassFASTBOSSES")) {
                b.RemoveClass("Chosen")
            }*/

            btn.AddClass("Chosen")
          }
        )
    }

    isPlayerHost = () => {
        return this.isHost
    }

    onConnectFull = (data) => {
        this.isHost = data.isHost;
    }
}