var PlayerPortrait = /** @class */ (function () {
    function PlayerPortrait(parent, playerRank, playerSteamID, playerPoints) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");
        // Find components
        this.playerRank = panel.FindChildTraverse("PlayerRank");
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar");
        this.playerPoints = panel.FindChildTraverse("PlayerPoints");
        // Set player rank label
        this.playerRank.text = playerRank;
        // Set player points label
        this.playerPoints.text = playerPoints;
        // Set player name label
        // Set hero image
        this.playerAvatar.steamid = playerSteamID;
    }
    // Set the health bar to a certain percentage (0-100)
    PlayerPortrait.prototype.SetHealthPercent = function (percentage) {
        this.hpBar.style.width = Math.floor(percentage) + "%";
    };
    return PlayerPortrait;
}());
