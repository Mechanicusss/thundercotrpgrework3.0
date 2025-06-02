var AutoLoot = (function() {
    function AutoLoot(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse"
        this.opacity = "0"

        this.OnRegister = function(data) {
            _this.container.style.visibility = "visible"
            _this.container.style.opacity = "1"

            if(data.autoloot != null) {
                if(data.autoloot == "1") {
                    _this.container.AddClass("toggle")
                } else if(data.autoloot == "0") {
                    _this.container.RemoveClass("toggle")
                }
            }
        }

        this.OnToggle = function(state) {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("autopickup_toggle", { 
                state: state,
                unit: lastRememberedHero
            })
        }
        
        GameEvents.Subscribe("autopickup_register", this.OnRegister);

        const parent = mainHud.FindChildTraverse("left_flare")

        let old = parent.Children();
        if (old) {
            old.forEach(async (child) => {
                if(child.id == "AutoLootContainer") {
                    child.RemoveAndDeleteChildren();
                    await child.DeleteAsync(0);
                }
            });
        }

        this.container = $.CreatePanel("Panel", context, "AutoLootContainer");

        this.label = $.CreatePanel("Label", this.container, "AutoLootContainerLabel");
        this.label.text = " "

        this.container.SetParent(parent)
        
        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity

        this.container.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.container, $.Localize("#autopickup"))
            }
        )

        this.container.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.container.SetPanelEvent(
            "onactivate", 
            function(){
                if(!_this.container.BHasClass("toggle")) {
                    _this.container.AddClass("toggle")
                    _this.OnToggle(1)
                } else {
                    _this.container.RemoveClass("toggle")
                    _this.OnToggle(0)
                }
            }
        )
    }

    return AutoLoot;
}());

var ui = new AutoLoot($.GetContextPanel());
