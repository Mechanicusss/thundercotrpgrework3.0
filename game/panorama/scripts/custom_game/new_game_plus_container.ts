class NewGamePlusContainer {
    // Instance variables
    panel: Panel;

    constructor(parent: Panel, steamId: Any) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");

        // Find components
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar") as ImagePanel;
        this.PlayerVoteYes = panel.FindChildTraverse("PlayerVoteYes") as LabelPanel;
        this.PlayerVoteNo = panel.FindChildTraverse("PlayerVoteNo") as LabelPanel;

        // Set hero image
       this.playerAvatar.steamid = steamId
    }
}