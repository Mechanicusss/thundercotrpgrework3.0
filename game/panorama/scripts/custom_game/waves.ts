interface TimerChangedEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class WavesUI {
    // Instance variables
    panel: Panel;

    // WavesUI constructor
    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("Waves")

        const panelContainer = $.CreatePanel("Panel", this.container, "");
        this.panelContainer = panelContainer;

        // Load snippet into panel
        panelContainer.BLoadLayoutSnippet("WavesSnippet");

        CustomNetTables.SubscribeNetTableListener("waves", this.onWaveUpdate);
        GameEvents.Subscribe<TimerChangedEvent>("waves_disable", (event) => this.onWaveDisable(event));
        //CustomNetTables.SubscribeNetTableListener("waves_disable", this.onWaveDisable);

        // Find components
        this.waves = panelContainer.FindChildTraverse("Waves") as LabelPanel;
        this.wavesCountCurrent = panelContainer.FindChildTraverse("waves-count-current") as LabelPanel;
        this.wavesCountCurrent.text = 0

        this.wavesCountMax = panelContainer.FindChildTraverse("waves-count-max") as LabelPanel;
        this.wavesCountMax.text = "/57"

        this.wavesCountLabel = panelContainer.FindChildTraverse("waves-count-label") as LabelPanel;
        this.wavesCountLabel.text = $.Localize("#waves_time_remaining")

        this.wavesBar = panelContainer.FindChildTraverse("waves-bar") as LabelPanel;

        this.wavesBarInfo = panelContainer.FindChildTraverse("waves-bar-info") as LabelPanel;

        this.wavesLabel = panelContainer.FindChildTraverse("waves-label") as LabelPanel;
        this.wavesLabel.text = $.Localize("#waves_label")

        // We add this so it's the default appearance!
        this.wavesBar.AddClass("flashing")
        this.wavesBarInfo.text = $.Localize("#waves_preparing")

        this.disabled = false

        $.Msg(panel); // Print the panel
    }

    onWaveUpdate = (_, _, res) => {
        if (!res || this.disabled) {
            return
        }

        let maxWidth = 296

        if(res.state == 2) {
            this.wavesBar.RemoveClass("flashing")
            this.wavesBar.AddClass("counting")
            this.wavesBar.style.width = ((maxWidth / res.max_interval) * parseInt(res.progress)) + "px"
            this.wavesBarInfo.text = res.interval + "s"
            this.wavesCountCurrent.text = res.wave
        }

        if(res.state == 1) {
            this.wavesBar.RemoveClass("counting")
            this.wavesBar.AddClass("flashing")
            this.wavesBarInfo.text = $.Localize("#waves_preparing")
        }
    }

    onWaveDisable = () => {
        this.disabled = true
        this.container.RemoveAndDeleteChildren();
    }
}

let ui = new WavesUI($.GetContextPanel());