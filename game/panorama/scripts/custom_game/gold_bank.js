var GoldBankUI = /** @class */ (function () {
    // GoldBankUI constructor
    function GoldBankUI(panel) {
        //GameEvents.Subscribe("modify_gold_bank", this.onModifyGoldBank)
        var _this = this;
        this.onModifyGoldBank = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this.GoldBankText.text = _this.nFormatter(res.amount, 1);
            return;
        };
        CustomNetTables.SubscribeNetTableListener("modify_gold_bank", this.onModifyGoldBank);
        this.panel = panel;
        this.container = this.panel.FindChild("GoldBank");
        var panelContainer = $.CreatePanel("Panel", this.container, "");
        this.panelContainer = panelContainer;
        //this.container.RemoveAndDeleteChildren();
        // Load snippet into panel
        panelContainer.BLoadLayoutSnippet("GoldBank");
        var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent();
        var cParent = mainHud.FindChildTraverse("ShopCourierControls");
        this.container.SetParent(cParent);
        // Find components
        this.GoldBankText = panelContainer.FindChildTraverse("GoldBankText");
        this.GoldBankText.text = this.nFormatter("0", 1);
        panelContainer.SetPanelEvent("onmouseover", function () {
            $.DispatchEvent("DOTAShowTextTooltip", panelContainer, $.Localize("#gold_bank_info"));
        });
        panelContainer.SetPanelEvent("onmouseout", function () {
            $.DispatchEvent("DOTAHideTextTooltip");
        });
        $.Msg(panel); // Print the panel
    }
    GoldBankUI.prototype.nFormatter = function (num, digits) {
        var lookup = [
            { value: 1, symbol: "" },
            { value: 1e3, symbol: "k" },
            { value: 1e6, symbol: "M" },
            { value: 1e9, symbol: "B" },
            { value: 1e12, symbol: "T" },
            { value: 1e15, symbol: "P" },
            { value: 1e18, symbol: "E" }
        ];
        var rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
        var item = lookup.slice().reverse().find(function (item) {
            return num >= item.value;
        });
        return item ? (num / item.value).toFixed(digits).replace(rx, "$1") + item.symbol : "0";
    };
    return GoldBankUI;
}());
var ui = new GoldBankUI($.GetContextPanel());
