interface TimerChangedEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class DuelUI {
    // Instance variables
    panel: Panel;

    // DuelUI constructor
    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("Timer")
        

        this.timerPanel = new DuelTimer(this.container, "NORMAL")

        if(Game.GetMapInfo().map_display_name == "tcotrpg1v1") {
            this.container.AddClass("PvPDifficulty")
        } else {
            this.container.AddClass("Difficulty")
        }

        GameEvents.Subscribe<TimerChangedEvent>("duel_timer_changed", (event) => this.OnTimerChanged(event));

        $.Msg(panel); // Print the panel
    }

    OnTimerChanged(event: TimerChangedEvent) {
        // Get portrait for this player
        const timerPanel = this.timerPanel;

        // Set HP on the player panel
        timerPanel.UpdateTimer(event.isDuelActive);
    }
}

let ui = new DuelUI($.GetContextPanel());