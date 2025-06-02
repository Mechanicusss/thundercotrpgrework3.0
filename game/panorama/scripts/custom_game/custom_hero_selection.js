var CustomHeroSelectionUI = /** @class */ (function () {
    // CustomHeroSelectionUI constructor
    function CustomHeroSelectionUI(panel) {
        var _this = this;
        this.onSelectCustomHeroOpen = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this.container.style.visibility = "visible";
            return;
        };
        this.onSelectCustomHero = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this.container.style.visibility = "collapse";
            return;
        };
        CustomNetTables.SubscribeNetTableListener("select_custom_hero", this.onSelectCustomHero);
        CustomNetTables.SubscribeNetTableListener("select_custom_hero_open", this.onSelectCustomHeroOpen);
        this.panel = panel;
        this.container = this.panel.FindChild("CustomHeroSelection");
        this.container.RemoveAndDeleteChildren();
        var panelContainer = $.CreatePanel("Panel", this.container, "");
        this.panelContainer = panelContainer;
        this.container.style.visibility = "collapse";
        // Load snippet into panel
        panelContainer.BLoadLayoutSnippet("CustomHeroSelection");
        this.close = this.panelContainer.FindChildTraverse("Close");
        this.close.SetPanelEvent("onactivate", function () {
            _this.container.style.visibility = "collapse";
        });
        $.Msg(panel); // Print the panel
    }
    return CustomHeroSelectionUI;
}());
function ChangeHero(hero, dummy) {
    var user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID());
    GameEvents.SendCustomGameEventToServer("select_custom_hero", { user: user, hero: hero, dummy: dummy });
}
var ui = new CustomHeroSelectionUI($.GetContextPanel());
