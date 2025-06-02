var GoldBankContainer = /** @class */ (function () {
    function GoldBankContainer(parent) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("GoldBank");
    }
    return GoldBankContainer;
}());
