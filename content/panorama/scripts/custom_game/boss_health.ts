interface BossHealthUIEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class BossHealthUI {
    // Instance variables
    panel: Panel;

    // DuelUI constructor
    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("BossHealth")
        //this.container.RemoveAndDeleteChildren();

        this.timerPanel = new BossHealth(this.container, "")

        //GameEvents.Subscribe<BossHealthUIEvent>("boss_health_bar", (event) => this.OnHealthChanged(event));

        this.panel.GetParent().GetParent().style.zIndex = "-1"

        $.Msg(panel); // Print the panel
    }

    
}

let ui = new BossHealthUI($.GetContextPanel());