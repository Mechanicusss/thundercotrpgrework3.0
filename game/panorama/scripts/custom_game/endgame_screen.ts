class EndGameScreenUI {
    // Instance variables
    panel: Panel;

    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("EndGameScreen")
        this.container.RemoveAndDeleteChildren();

        const endGameScreenHeader = $.CreatePanel("Panel", this.container, "");
        endGameScreenHeader.BLoadLayoutSnippet("EndGameScreenHeaderSnippet");

        endGameScreenHeader.RemoveAndDeleteChildren();

        const playersContainerRadiant = $.CreatePanel("Panel", this.container, "");
        playersContainerRadiant.BLoadLayoutSnippet("PlayersContainerRadiantSnippet");

        playersContainerRadiant.RemoveAndDeleteChildren();

        let t1 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "22", "4", "0", "2", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista")
        let t2 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "44", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista")
        let t3 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "21", "44", "65", "200000", "2", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista")
        let t4 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "4", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista")
        let t5 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "4", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista")

        $.Msg(panel); // Print the panel
    }
}

let ui = new EndGameScreenUI($.GetContextPanel());
