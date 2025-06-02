var NewGamePlusContainer = /** @class */ (function () {
    function NewGamePlusContainer(parent, steamId) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");
        // Find components
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar");
        this.PlayerVoteYes = panel.FindChildTraverse("PlayerVoteYes");
        this.PlayerVoteNo = panel.FindChildTraverse("PlayerVoteNo");
        // Set hero image
        this.playerAvatar.steamid = steamId;
    }
    return NewGamePlusContainer;
}());
