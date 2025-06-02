class KillsSelection {
    // Instance variables
    panel: Panel;
    amountLabel: ButtonPanel;

    constructor(parent: Panel, t: string, amount: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("KillsSelection");

        // Find components
        this.amountLabel = panel.FindChildTraverse("DefaultValveButtonID") as Any;

        GameEvents.Subscribe("on_connect_full", this.onConnectFull)

        this.isHost = false;

        // Set player name label
        this.amountLabel.text = "";

        switch(amount.toUpperCase()) {
            case "EASY":
                this.amountLabel.AddClass("diff_easy")
                break;
            case "NORMAL":
                this.amountLabel.AddClass("diff_normal")
                break;
            case "HARD":
                this.amountLabel.AddClass("diff_hard")
                break;
            case "IMPOSSIBLE":
                this.amountLabel.AddClass("diff_impossible")
                break;
            case "HELL":
                this.amountLabel.AddClass("diff_hell")
                break;
            case "HARDCORE":
                this.amountLabel.AddClass("diff_hardcore")
                break;
        }
        

        let btn = this.amountLabel
        let _panel = this.panel;

        btn.SetPanelEvent(
          "onmouseover", 
          function(){
            switch(amount.toUpperCase()) {
                case "EASY":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_easy_info"));
                    break;
                case "NORMAL":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_normal_info"));
                    break;
                case "HARD":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_hard_info"));
                    break;
                case "UNFAIR":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_unfair_info"));
                    break;
                case "IMPOSSIBLE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_impossible_info"));
                    break;
                case "HELL":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_infinity_info"));
                    break;
                case "HARDCORE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_hardcore_info"));
                    break;
                case "APOCALYPSE":
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#difficulty_apocalypse_info"));
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
          "onmouseactivate", () => {
            if(!this.isPlayerHost()) return;
            if(btn.disabled) return

            GameEvents.SendCustomGameEventToServer("killvote", { option: amount, user: Game.GetLocalPlayerID() })

            for(const b of _panel.GetParent().FindChildrenWithClassTraverse("DefaultValveButtonClass")) {
                //b.disabled = true
                //b.AddClass("Clicked")
                b.RemoveClass("diff_easy_chosen")
                b.RemoveClass("diff_normal_chosen")
                b.RemoveClass("diff_hard_chosen")
                b.RemoveClass("diff_impossible_chosen")
                b.RemoveClass("diff_hell_chosen")
                b.RemoveClass("diff_hardcore_chosen")
            }

            switch(amount.toUpperCase()) {
                case "EASY":
                    btn.AddClass("diff_easy_chosen")
                    break;
                case "NORMAL":
                    btn.AddClass("diff_normal_chosen")
                    break;
                case "HARD":
                    btn.AddClass("diff_hard_chosen")
                    break;
                case "IMPOSSIBLE":
                    btn.AddClass("diff_impossible_chosen")
                    break;
                case "HELL":
                    btn.AddClass("diff_hell_chosen")
                    break;
                case "HARDCORE":
                    btn.AddClass("diff_hardcore_chosen")
                    break;
            }

            //btn.AddClass("Chosen")

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