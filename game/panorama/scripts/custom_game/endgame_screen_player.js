var PlayerPortrait = /** @class */ (function () {
    function PlayerPortrait(parent, playerSteamID, playerKills, playerDeaths, playerAssists, playerNetWorth, playerPointChanges, playerItem1, playerItem2, playerItem3, playerItem4, playerItem5, playerItem6) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");
        // Find components
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar");
        this.playerLabel = panel.FindChildTraverse("PlayerName");
        this.playerKills = panel.FindChildTraverse("PlayerKills");
        this.playerDeaths = panel.FindChildTraverse("PlayerDeaths");
        this.playerAssists = panel.FindChildTraverse("PlayerAssists");
        this.playerNetWorth = panel.FindChildTraverse("PlayerNetWorth");
        this.playerItem1 = panel.FindChildTraverse("PlayerItem1");
        this.playerItem2 = panel.FindChildTraverse("PlayerItem2");
        this.playerItem3 = panel.FindChildTraverse("PlayerItem3");
        this.playerItem4 = panel.FindChildTraverse("PlayerItem4");
        this.playerItem5 = panel.FindChildTraverse("PlayerItem5");
        this.playerItem6 = panel.FindChildTraverse("PlayerItem6");
        this.playerPointChanges = panel.FindChildTraverse("PlayerPointChanges");
        // Set player points label
        this.playerPointChanges.text = playerPointChanges;
        if (parseInt(this.playerPointChanges.text) > 0) {
            this.playerPointChanges.text = "+" + this.playerPointChanges.text;
            this.playerPointChanges.AddClass("Pos");
        }
        else {
            this.playerPointChanges.text = "-" + this.playerPointChanges.text;
            this.playerPointChanges.AddClass("Neg");
        }
        // Set player name label
        this.playerLabel.steamid = playerSteamID;
        this.playerKills.text = playerKills;
        this.playerDeaths.text = playerDeaths;
        this.playerAssists.text = playerAssists;
        this.playerNetWorth.text = playerNetWorth;
        this.playerItem1.itemname = playerItem1;
        this.playerItem2.itemname = playerItem2;
        this.playerItem3.itemname = playerItem3;
        this.playerItem4.itemname = playerItem4;
        this.playerItem5.itemname = playerItem5;
        this.playerItem6.itemname = playerItem6;
        this.playerItem1.style.marginLeft = "24px";
        this.playerItem6.style.marginRight = "24px";
        // Set hero image
        this.playerAvatar.steamid = playerSteamID;
    }
    return PlayerPortrait;
}());
