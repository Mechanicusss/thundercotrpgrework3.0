class PlayerPortrait {
    // Instance variables
    panel: Panel;
    playerRank: LabelPanel;
    playerAvatar: ImagePanel;
    playerPoints: LabelPanel;

    constructor(parent: Panel, playerRank: string, playerSteamID: string, playerPoints: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");

        // Find components
        this.playerRank = panel.FindChildTraverse("PlayerRank") as LabelPanel;
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar") as ImagePanel;
        this.playerPoints = panel.FindChildTraverse("PlayerPoints") as LabelPanel;

        // Set player rank label
        this.playerRank.text = playerRank;

        // Set player points label
        this.playerPoints.text = playerPoints;

        // Set player name label

        // Set hero image
       this.playerAvatar.steamid = playerSteamID
    }

    // Set the health bar to a certain percentage (0-100)
    SetHealthPercent(percentage: number) {
        this.hpBar.style.width = Math.floor(percentage) + "%";
    }
}