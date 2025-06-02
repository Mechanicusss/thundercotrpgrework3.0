class BossHealth {
    // Instance variables
    panel: Panel;
    timerLabel: LabelPanel;

    constructor(parent: Panel, attach: any) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        

        // Load snippet into panel
        panel.BLoadLayoutSnippet("BossHealth");

        //this.panel.SetParent("")

        // Find components
        this.bar = panel.FindChildTraverse("Bar") as LabelPanel;     

        GameEvents.Subscribe("boss_health_bar", (event) => this.OnHealthUpdated(event));
        GameEvents.Subscribe("boss_health_bar_init", (event) => this.OnBossInit(event));
        GameEvents.Subscribe("boss_health_bar_remove", (event) => this.OnHealthDepleted(event));

        this.bossId = null
    }

    OnBossInit = (event: any) => {
        this.bossId = event.boss
        this.panel.style.visibility = "visible"
        this.bar.style.width = "592px"

        this.UpdatePosition()
    }

    OnHealthUpdated = (event: any) => {
        this.bar.style.width = 592 * (parseInt(event.hp) / 100) + "px"
    }

    OnHealthDepleted = (event: any) => {
        this.panel.style.visibility = "collapse"
    }

    UpdatePosition = () => {
        var panel = this.panel

        if(this.bossId != null) {
            var origin = Entities.GetAbsOrigin(this.bossId);
            var ratio = 1080 / Game.GetScreenHeight();

            if(origin) {
                var offset = Entities.GetHealthBarOffset(this.bossId);
                offset = offset == -1 ? 100 : offset;
                var x = Game.WorldToScreenX(origin[0], origin[1], origin[2] + offset);
                var y = Game.WorldToScreenY(origin[0], origin[1], origin[2] + offset);  
                panel.SetPositionInPixels(ratio * (x - panel.actuallayoutwidth / 2), ratio * (y - panel.actuallayoutheight), 0);
            }
        }

        $.Schedule(Game.GetGameFrameTime(), this.UpdatePosition);
    }
}