class WavesContainer {
    // Instance variables
    panel: Panel;
    timerLabel: LabelPanel;

    constructor(parent: Panel) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("WavesSnippet");

        // Find components
        this.waves = panel.FindChildTraverse("Waves") as LabelPanel;
        
    }
}