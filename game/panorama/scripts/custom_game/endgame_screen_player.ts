class PlayerPortrait {
    // Instance variables
    panel: Panel;
    playerAvatar: ImagePanel;
    playerLabel: LabelPanel;
    playerPointChanges: LabelPanel;
    playerKills: LabelPanel;
    playerDeaths: LabelPanel;
    playerAssists: LabelPanel;
    playerNetWorth: LabelPanel;
    playerItem1: DOTAItemImage;
    playerItem2: DOTAItemImage;
    playerItem3: DOTAItemImage;
    playerItem4: DOTAItemImage;
    playerItem5: DOTAItemImage;
    playerItem6: DOTAItemImage;

    constructor(parent: Panel, playerSteamID: string, playerKills: string, playerDeaths: string, playerAssists: string, playerNetWorth: string, playerPointChanges: string, playerItem1: string, playerItem2: string, playerItem3: string, playerItem4: string, playerItem5: string, playerItem6: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("PlayerPortrait");

        // Find components
        this.playerAvatar = panel.FindChildTraverse("PlayerAvatar") as ImagePanel;
        this.playerLabel = panel.FindChildTraverse("PlayerName") as LabelPanel;
        this.playerKills = panel.FindChildTraverse("PlayerKills") as LabelPanel;
        this.playerDeaths = panel.FindChildTraverse("PlayerDeaths") as LabelPanel;
        this.playerAssists = panel.FindChildTraverse("PlayerAssists") as LabelPanel;
        this.playerNetWorth = panel.FindChildTraverse("PlayerNetWorth") as LabelPanel;
        this.playerItem1 = panel.FindChildTraverse("PlayerItem1") as LabelPanel;
        this.playerItem2 = panel.FindChildTraverse("PlayerItem2") as LabelPanel;
        this.playerItem3 = panel.FindChildTraverse("PlayerItem3") as LabelPanel;
        this.playerItem4 = panel.FindChildTraverse("PlayerItem4") as LabelPanel;
        this.playerItem5 = panel.FindChildTraverse("PlayerItem5") as LabelPanel;
        this.playerItem6 = panel.FindChildTraverse("PlayerItem6") as LabelPanel;
        this.playerPointChanges = panel.FindChildTraverse("PlayerPointChanges") as LabelPanel;

        // Set player points label
        this.playerPointChanges.text = playerPointChanges;
        if(parseInt(this.playerPointChanges.text) > 0) {
            this.playerPointChanges.text = "+" + this.playerPointChanges.text
            this.playerPointChanges.AddClass("Pos")
        } else {
            this.playerPointChanges.text = "-" + this.playerPointChanges.text
            this.playerPointChanges.AddClass("Neg")
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

        this.playerItem1.style.marginLeft = "24px"
        this.playerItem6.style.marginRight = "24px"

        // Set hero image
       this.playerAvatar.steamid = playerSteamID;
    }
}