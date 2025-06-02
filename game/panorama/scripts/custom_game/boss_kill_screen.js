//interface DuelEndEvent {}
var BossKillScreenUI = /** @class */ (function () {
    // BossKillScreenUI constructor
    function BossKillScreenUI(panel) {
        var _this = this;
        this.panel = panel;
        this.container = this.panel.FindChild("BossKillScreen");
        this.container.RemoveAndDeleteChildren();
        GameEvents.Subscribe("boss_killed", function (event) { return _this.OnBossKilled(event); });
        $.Msg(panel); // Print the panel
    }
    BossKillScreenUI.prototype.OnBossKilled = function (event) {
        var parentContainer = this.container;
        var temporaryFrame = new BossKillScreenFrame(this.container, event.name, event.killingTeam, event.level);
        $.Schedule(10, function () {
            parentContainer.RemoveAndDeleteChildren();
        });
    };
    return BossKillScreenUI;
}());
var ui = new BossKillScreenUI($.GetContextPanel());
