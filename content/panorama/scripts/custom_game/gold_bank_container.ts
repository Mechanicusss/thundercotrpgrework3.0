class GoldBankContainer {
    // Instance variables
    panel: Panel;

    constructor(parent: Panel) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("GoldBank");
    }
}