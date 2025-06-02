var WavesContainer = /** @class */ (function () {
    function WavesContainer(parent) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("WavesSnippet");
        // Find components
        this.waves = panel.FindChildTraverse("Waves");
    }
    return WavesContainer;
}());
