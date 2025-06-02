class BossKillScreenFrame {
    // Instance variables
    panel: Panel;
    killingTeamLabel: LabelPanel;
    bossNameLabel: LabelPanel;
    bossLevelLabel: LabelPanel;
    bossIcon: Image;

    constructor(parent: Panel, bossName: string, team: string, bossLevel: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("BossKillScreenFrame");

        // Find components
        this.killingTeamLabel = panel.FindChildTraverse("KillingTeam") as LabelPanel;
        this.bossNameLabel = panel.FindChildTraverse("BossName") as LabelPanel;
        this.bossLevelLabel = panel.FindChildTraverse("BossLevel") as LabelPanel;
        this.bossIcon = panel.FindChildTraverse("BossIcon") as Image;
        this.hexagon = panel.FindChildTraverse("HexagonMid") as Image;

        this.bossLevelLabel.text = "Level " + bossLevel
        this.bossIcon.style.backgroundImage = "url('file://{images}/custom_game/"+bossName+".png')"
        this.hexagon.style.backgroundImage = "url('file://{images}/custom_game/"+bossName+".png')"

        switch(bossName) {
            case "huskar": {
                this.bossNameLabel.text = "Sacred Warrior"
                break
            }

            case "windrunner": {
                this.bossNameLabel.text = "Lyralei"
                break
            }

            case "roshan": {
                this.bossNameLabel.text = "Roshan"
                break
            }

            case "butcher": {
                this.bossNameLabel.text = "The Butcher"
                break
            }
        }

        switch(team) {
            case "angels": {
                this.killingTeamLabel.text = "Angels defeated"
                this.killingTeamLabel.AddClass("angels")
                break
            }

            case "demons": {
                this.killingTeamLabel.text = "Demons defeated"
                this.killingTeamLabel.AddClass("demons")
                break
            }
        }
    }
}