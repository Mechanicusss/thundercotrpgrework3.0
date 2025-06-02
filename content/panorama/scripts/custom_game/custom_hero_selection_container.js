var CustomHeroSelectionContainer = /** @class */ (function () {
    function CustomHeroSelectionContainer(parent) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        this.panel.BLoadLayoutSnippet("CustomHeroSelection");
    }
    return CustomHeroSelectionContainer;
}());
