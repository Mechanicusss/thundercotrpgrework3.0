var DuelUI = /** @class */ (function () {
    // DuelUI constructor
    function DuelUI(panel) {
        var _this = this;
        this.panel = panel;
        this.container = this.panel.FindChild("Timer");
        this.timerPanel = new DuelTimer(this.container, "NORMAL");
        if (Game.GetMapInfo().map_display_name == "tcotrpg1v1") {
            this.container.AddClass("PvPDifficulty");
        }
        else {
            this.container.AddClass("Difficulty");
        }
        GameEvents.Subscribe("duel_timer_changed", function (event) { return _this.OnTimerChanged(event); });
        $.Msg(panel); // Print the panel
    }
    DuelUI.prototype.OnTimerChanged = function (event) {
        // Get portrait for this player
        var timerPanel = this.timerPanel;
        // Set HP on the player panel
        timerPanel.UpdateTimer(event.isDuelActive);
    };
    return DuelUI;
}());
var ui = new DuelUI($.GetContextPanel());
