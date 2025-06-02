interface BossKillEvent {
    playerID: PlayerID;
}

//interface DuelEndEvent {}

class BossKillScreenUI {
    // Instance variables
    panel: Panel;

    // BossKillScreenUI constructor
    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("BossKillScreen")

        this.container.RemoveAndDeleteChildren();

        GameEvents.Subscribe<BossKillEvent>("boss_killed", (event) => this.OnBossKilled(event));

        $.Msg(panel); // Print the panel
    }

    OnBossKilled(event: TimerChangedEvent) {
        let parentContainer = this.container
        let temporaryFrame = new BossKillScreenFrame(this.container, event.name, event.killingTeam, event.level)

        $.Schedule(10, function() {
            parentContainer.RemoveAndDeleteChildren();
        })
    }
}

let ui = new BossKillScreenUI($.GetContextPanel());