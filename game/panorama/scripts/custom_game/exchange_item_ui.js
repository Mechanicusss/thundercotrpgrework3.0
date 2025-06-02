var ExchangeItemUI = /** @class */ (function () {
    function ExchangeItemUI(parent, item) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("ExchangeItemUI");
        // Find components
        this.itemName = panel.FindChildTraverse("ItemName");
        this.itemImage = panel.FindChildTraverse("ItemImage");
        this.itemImage.SetImage("s2r://panorama/images/items/chronoshourglass.png");
        this.itemName.text = item.name;
    }
    return ExchangeItemUI;
}());
