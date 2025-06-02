class ExchangeItemUI {
    // Instance variables
    panel: Panel;
    itemImage: ImagePanel;
    itemName: LabelPanel
    itemContainer: LabelPanel;

    constructor(parent: Panel, item: Array) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("ExchangeItemUI");

        // Find components
        this.itemName = panel.FindChildTraverse("ItemName") as LabelPanel;
        this.itemImage = panel.FindChildTraverse("ItemImage") as ImagePanel;

        this.itemImage.SetImage("s2r://panorama/images/items/custom/" + item.image + ".png");
        this.itemName.text = item.name;
    }
}