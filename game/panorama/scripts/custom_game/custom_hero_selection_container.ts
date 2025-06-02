class CustomHeroSelectionContainer {
    // Instance variables
    panel: Panel;

    constructor(parent: Panel) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");

        this.panel = panel;

        this.panel.BLoadLayoutSnippet("CustomHeroSelection");
    }
}