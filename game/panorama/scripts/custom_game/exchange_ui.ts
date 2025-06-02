class ExchangeUI {
    // Instance variables
    panel: Panel;

    // DuelUI constructor
    constructor(panel: Panel) {
        this.panel = panel;
        //this.panel.enabled(false)
        //this.panel.visible(false)

        const container = this.panel.FindChild("Exchange")
        container.RemoveAndDeleteChildren();

        let availableItems = [
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
        ] //should contain all item info to be sold!

        this.items = []
        for(const item of availableItems) {
            let ui = new ExchangeItemUI(container, item)
            this.items.push(ui)
        }

        $.Msg(panel); // Print the panel
    }
}

let ui = new ExchangeUI($.GetContextPanel());