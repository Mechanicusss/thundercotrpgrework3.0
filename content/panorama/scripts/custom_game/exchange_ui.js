var ExchangeUI = /** @class */ (function () {
    // DuelUI constructor
    function ExchangeUI(panel) {
        this.panel = panel;
        //this.panel.enabled(false)
        //this.panel.visible(false)
        var container = this.panel.FindChild("Exchange");
        container.RemoveAndDeleteChildren();
        var availableItems = [
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
            {
                "name": "Desolator",
                "cost": "item_token_exchange",
                "image": "desolator"
            },
            {
                "name": "Trident of the Depths",
                "cost": "item_token_exchange",
                "image": "trident"
            },
        ]; //should contain all item info to be sold!
        this.items = [];
        for (var _i = 0, availableItems_1 = availableItems; _i < availableItems_1.length; _i++) {
            var item = availableItems_1[_i];
            var ui_1 = new ExchangeItemUI(container, item);
            this.items.push(ui_1);
        }
        $.Msg(panel); // Print the panel
    }
    return ExchangeUI;
}());
var ui = new ExchangeUI($.GetContextPanel());
