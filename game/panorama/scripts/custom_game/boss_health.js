var BossHealthUI = /** @class */ (function () {
    // DuelUI constructor
    function BossHealthUI(panel) {
        this.panel = panel;
        this.container = this.panel.FindChild("BossHealth");
        //this.container.RemoveAndDeleteChildren();
        this.timerPanel = new BossHealth(this.container, "");
        //GameEvents.Subscribe<BossHealthUIEvent>("boss_health_bar", (event) => this.OnHealthChanged(event));
        this.panel.GetParent().GetParent().style.zIndex = "-1";
        $.Msg(panel); // Print the panel
    }
    return BossHealthUI;
}());
var ui = new BossHealthUI($.GetContextPanel());
