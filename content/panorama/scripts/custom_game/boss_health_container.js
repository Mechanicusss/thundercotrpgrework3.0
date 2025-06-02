var BossHealth = /** @class */ (function () {
    function BossHealth(parent, attach) {
        var _this = this;
        this.OnBossInit = function (event) {
            _this.bossId = event.boss;
            _this.panel.style.visibility = "visible";
            _this.bar.style.width = "592px";
            _this.UpdatePosition();
        };
        this.OnHealthUpdated = function (event) {
            _this.bar.style.width = 592 * (parseInt(event.hp) / 100) + "px";
        };
        this.OnHealthDepleted = function (event) {
            _this.panel.style.visibility = "collapse";
        };
        this.UpdatePosition = function () {
            var panel = _this.panel;
            if (_this.bossId != null) {
                var origin = Entities.GetAbsOrigin(_this.bossId);
                var ratio = 1080 / Game.GetScreenHeight();
                if (origin) {
                    var offset = Entities.GetHealthBarOffset(_this.bossId);
                    offset = offset == -1 ? 100 : offset;
                    var x = Game.WorldToScreenX(origin[0], origin[1], origin[2] + offset);
                    var y = Game.WorldToScreenY(origin[0], origin[1], origin[2] + offset);
                    panel.SetPositionInPixels(ratio * (x - panel.actuallayoutwidth / 2), ratio * (y - panel.actuallayoutheight), 0);
                }
            }
            $.Schedule(Game.GetGameFrameTime(), _this.UpdatePosition);
        };
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("BossHealth");
        //this.panel.SetParent("")
        // Find components
        this.bar = panel.FindChildTraverse("Bar");
        GameEvents.Subscribe("boss_health_bar", function (event) { return _this.OnHealthUpdated(event); });
        GameEvents.Subscribe("boss_health_bar_init", function (event) { return _this.OnBossInit(event); });
        GameEvents.Subscribe("boss_health_bar_remove", function (event) { return _this.OnHealthDepleted(event); });
        this.bossId = null;
    }
    return BossHealth;
}());
