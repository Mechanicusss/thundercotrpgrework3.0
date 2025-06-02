class EffectSelection {
    // Instance variables
    panel: Panel;
    amountLabel: ButtonPanel;

    constructor(parent: Panel, t: string, amount: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("EffectSelection");

        // Find components
        this.amountLabel = panel.FindChildTraverse("DefaultValveButtonIDEFFECT") as Any;

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
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#effects_enabled_info"));
                    break;
                case "DISABLE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#effects_disabled_info"));
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
            if(btn.disabled) return

            GameEvents.SendCustomGameEventToServer("effectvote", { option: amount, user: Game.GetLocalPlayerID() })

            for(const b of _panel.GetParent().FindChildrenWithClassTraverse("DefaultValveButtonClassEFFECT")) {
                b.RemoveClass("Chosen")
            }

            btn.AddClass("Chosen")

            //let VotingDoneLabel = btn.GetParent().GetParent().GetParent().FindChildTraverse("HasVoted")
            //VotingDoneLabel.text = `Waiting for game to start...`
            //VotingDoneLabel.visible = true
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