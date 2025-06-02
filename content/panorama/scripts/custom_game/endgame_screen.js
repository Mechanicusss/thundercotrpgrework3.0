var EndGameScreenUI = /** @class */ (function () {
    function EndGameScreenUI(panel) {
        this.panel = panel;
        this.container = this.panel.FindChild("EndGameScreen");
        this.container.RemoveAndDeleteChildren();
        var endGameScreenHeader = $.CreatePanel("Panel", this.container, "");
        endGameScreenHeader.BLoadLayoutSnippet("EndGameScreenHeaderSnippet");
        endGameScreenHeader.RemoveAndDeleteChildren();
        var playersContainerRadiant = $.CreatePanel("Panel", this.container, "");
        playersContainerRadiant.BLoadLayoutSnippet("PlayersContainerRadiantSnippet");
        playersContainerRadiant.RemoveAndDeleteChildren();
        var t1 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "22", "4", "0", "2", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista");
        var t2 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "44", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista");
        var t3 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "21", "44", "65", "200000", "2", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista");
        var t4 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "4", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista");
        var t5 = new PlayerPortrait(playersContainerRadiant, "76561198082943320", "2", "4", "0", "200000", "20", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista", "item_ballista");
        $.Msg(panel); // Print the panel
    }
    return EndGameScreenUI;
}());
var ui = new EndGameScreenUI($.GetContextPanel());
